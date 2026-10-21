// The administrator's account actions. Everything here needs the Admin SDK
// (disabling an Auth user, deleting one, sending FCM), so it cannot be done
// from the app with Firestore rules alone. One endpoint, one `action` field:
//
//   disable    { uid, message }  hold the account on the blocked screen
//   enable     { uid }           let it back in
//   delete     { uid }           remove the Auth user and every trace
//   notify     { uid, title, body }   an inbox item (+ push, via the trigger)
//   notifyAll  { title, body }        one inbox item per account, one multicast
//   syncPricing {}                    refresh admin_config/pricing from the catalog
//
// The caller is the administrator alone, by the email on the ID token — the
// same check the Firestore rules make.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const notificationPrefs = require("./notificationPrefs");
const remoteFlags = require("./remoteFlags");

const proxy = require("./aiProxy").internals;
const { syncPricing, syncRate } = require("./pricingCatalog");
const { repairUsage, deleteUserUsage } = require("./aiUsage");

// The web checkout's key (webBilling.js): an account deleted here must not
// leave a Stripe subscription charging a card, nor a customer record with
// its name and phone behind.
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const billingSecrets = require("./billingSecrets");

const MAX_TITLE = 80;
const MAX_BODY = 1000;
const FCM_BATCH = 500;
// How many preference documents are read at once for a broadcast.
const PREFS_BATCH = 50;

// The administrator is whoever has `permission: "admin"` on their users
// document (see permissions.js), never an address in the code.
const permissions = require("./permissions");
const { isAdmin } = permissions;
// Every send is logged for the web console's notifications page.
const notificationLog = require("./adminNotifications");

function text(value, max) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

// A document id Firestore takes as one segment: no slash (which would turn
// `users/${uid}` into another path), not "." or "..", not `__…__`.
function validId(value) {
  return typeof value === "string" && /^[^/]{1,128}$/.test(value) && value !== "." && value !== ".." && !/^__.*__$/.test(value);
}

/// The request, checked and trimmed, or the reason it is refused.
function parseRequest(body) {
  const action = text(body && body.action, 20);
  const uid = text(body && body.uid, 128);
  const title = text(body && body.title, MAX_TITLE);
  const message = text(body && (body.body ?? body.message), MAX_BODY);
  if (uid && !validId(uid)) return { error: "uid is not a valid id" };
  switch (action) {
    case "disable":
    case "enable":
    case "delete":
    case "releaseSession":
      if (!uid) return { error: "uid is required" };
      return { action, uid, message };
    case "notify":
      if (!uid) return { error: "uid is required" };
      if (!message) return { error: "body is required" };
      return { action, uid, title, message };
    case "notifyAll":
      if (!message) return { error: "body is required" };
      return { action, title, message };
    case "syncPricing":
      return { action };
    case "setPermission": {
      if (!uid) return { error: "uid is required" };
      const permission = text(body && body.permission, 20);
      if (!permissions.GRANTABLE.includes(permission)) return { error: "permission must be user, superuser or admin" };
      return { action, uid, permission };
    }
    default:
      return { error: "unknown action" };
  }
}

async function disable(uid, message) {
  const db = admin.firestore();
  await db.doc(`account_status/${uid}`).set(
    {
      disabled: true,
      message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  // The same verdict in the account's ID token (`disabled` claim), so the
  // paid endpoints (aiProxy.paidCallerRefusal) can refuse it without a
  // Firestore read per call: the Auth user stays enabled (below), so a
  // switched-off account could sign in again — on the website, or with a
  // script — and keep spending AI, speech and search on our keys.
  await setDisabledClaim(uid, true);
  // Tokens already issued stay valid for up to an hour; revoking them makes
  // the app's next refresh fail and re-run the gate, which then reads the
  // status above. The Auth user itself stays enabled so it can still sign
  // in far enough to be shown the reason.
  try {
    await admin.auth().revokeRefreshTokens(uid);
  } catch (err) {
    logger.warn("revoke failed", { uid, reason: err.message });
  }
}

/// Pure: the custom claims with `disabled` set or cleared, the rest kept.
function claimsWithDisabled(current, disabled) {
  const claims = { ...(current && typeof current === "object" ? current : {}) };
  if (disabled) claims.disabled = true;
  else delete claims.disabled;
  return claims;
}

async function setDisabledClaim(uid, disabled, authImpl = null) {
  try {
    const auth = authImpl || admin.auth();
    const user = await auth.getUser(uid);
    await auth.setCustomUserClaims(uid, claimsWithDisabled(user.customClaims, disabled));
  } catch (err) {
    logger.warn("disabled claim not written", { uid, disabled, reason: err.code || err.message });
  }
}

async function enable(uid) {
  await admin.firestore().doc(`account_status/${uid}`).set(
    {
      disabled: false,
      message: "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  // Takes effect on the account's next token refresh (within the hour, or
  // at once on a new sign-in).
  await setDisabledClaim(uid, false);
}

/// Every place an account leaves a trace, in one sweep. Community posts and
/// shared recipes are left standing under the author's uid, the way a
/// forum keeps posts of departed members; they can be removed by hand.
// Frees the account's device session (a phone lost or wiped without
// signing out would otherwise hold it for the month) and revokes the
// tokens, so the device that held it is signed out as well.
async function releaseSession(uid) {
  await admin.firestore().doc(`sessions/${uid}`).delete();
  try {
    await admin.auth().revokeRefreshTokens(uid);
  } catch (err) {
    logger.warn("revoke failed", { uid, reason: err.message });
  }
}

// `stripeSecret` given (the administrator's delete): the web subscription
// is cancelled and the Stripe customer deleted first, with deleteAccount's
// rule — a Stripe failure throws before anything of ours is removed, so the
// account is left whole and the delete can be retried. deleteAccount.js
// settles Stripe itself and calls this without one.
//
// The household, the same way too: an owner is refused (`household_owner`
// — the household is dissolved first, from the console's household page),
// a member leaves after Stripe is settled. Without it the deleted uid kept
// its seat and, for an owner, the members kept inheriting a plan whose
// owner no longer existed. Returns `{ error }` on a refusal.
async function deleteInteractionOwners(db, uid, page = 400) {
  let deleted = 0;
  for (;;) {
    const snap = await db.collection("ai_interactions").where("uid", "==", uid).limit(page).select().get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += snap.size;
    if (snap.size < page) break;
  }
  return deleted;
}

async function remove(uid, { stripeSecret: secret, billingKeys = null, db = admin.firestore() } = {}) {
  if (secret !== undefined) {
    // Required here, not at the top: deleteAccount.js requires this module.
    const { deleteStripeCustomer, deleteWebCustomer, leaveRosters, deleteQuery } = require("./deleteAccount").internals;
    const households = require("./households").internals;
    const owned = await db.collection("households").where("ownerUid", "==", uid).limit(1).get();
    if (!owned.empty) return { error: "household_owner" };
    await deleteStripeCustomer(db, uid, secret);
    await deleteWebCustomer(db, uid, billingKeys);
    const membership = await households.leave(db, uid);
    if (membership && membership.error && membership.error !== "not_member") {
      logger.warn("household leave on admin delete", { uid, reason: membership.error });
    }
    // Its seats in other people's shares and its codes and invites go as
    // with deleteAccount: a dead uid left in a roster is re-invited (and its
    // inbox tree recreated) on every save, and a code it owned could still
    // be redeemed. Its own shared documents, posts and photos stay (see
    // above), as an administrator's removal always left them.
    await leaveRosters(db, uid);
    await deleteQuery(db, db.collection("share_codes").where("ownerUid", "==", uid));
    await deleteQuery(db, db.collection("share_invites").where("ownerUid", "==", uid));
    await deleteQuery(db, db.collection("share_invites").where("targetUid", "==", uid));
  }
  const [directory, budgets] = await Promise.all([
    db.collection("user_directory").where("uid", "==", uid).get(),
    // The day's counters (dailyBudget.js), keyed {uid}_{kind}: a handful of
    // rows naming the uid, left behind until now.
    db.collection("usage_budgets").where("uid", "==", uid).get(),
  ]);
  const batch = db.batch();
  for (const doc of directory.docs) batch.delete(doc.ref);
  for (const doc of budgets.docs) batch.delete(doc.ref);
  for (const path of [
    `public_profiles/${uid}`,
    `entitlements/${uid}`,
    `ai_usage/${uid}`,
    `account_status/${uid}`,
    `sessions/${uid}`,
    // Normally gone already (the Stripe step deletes it), but the
    // subscription's own "deleted" webhook can arrive while the rest of
    // the removal runs, and wrote it back for an account about to vanish.
    `stripe_customers/${uid}`,
    // Same for the PayPlus (or legacy Paddle) record (deleteWebCustomer).
    `web_customers/${uid}`,
  ]) {
    batch.delete(db.doc(path));
  }
  await batch.commit();
  // Which account started each assistant conversation (aiProxy.js): rows
  // naming the uid, up to a month of them, so paged rather than folded into
  // the batch above (a busy account would push it past 500 operations).
  await deleteInteractionOwners(db, uid);
  // Its AI call log rows and per-day shares (aiUsage.js): the audit trail
  // named the account by uid long after it was gone.
  await deleteUserUsage(db, uid);
  // Subtrees: the profile with its mirrored boxes, and the inbox.
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.recursiveDelete(db.doc(`notifications/${uid}`));
  try {
    await admin.auth().deleteUser(uid);
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
  }
}

function inboxItem({ fromUid, title, message, silent }) {
  return {
    type: "adminMessage",
    fromUid,
    title,
    message,
    read: false,
    silent: !!silent,
    createdAt: admin.firestore.Timestamp.now(),
  };
}

/// One inbox item; the pushOnNotification trigger sends the push.
async function notifyOne({ fromUid, uid, title, message }) {
  await admin
    .firestore()
    .collection("notifications")
    .doc(uid)
    .collection("items")
    .add(inboxItem({ fromUid, title, message, silent: false }));
}

/// An inbox item for every account, written silent, and one multicast to
/// every registered device. Accounts with no push token still get the item.
// Pure: whether an account is in a broadcast's audience.
//   all      every account
//   premium  accounts whose plan is active now
//   free     every other account
//   users    the uids picked by hand
const AUDIENCES = ["all", "premium", "free", "users"];
function inAudience({ audience = "all", uid, uidSet = null, premium = false }) {
  if (audience === "premium") return premium;
  if (audience === "free") return !premium;
  if (audience === "users") return !!uidSet && uidSet.has(uid);
  return true;
}

// Accounts per page of a broadcast: one batch of inbox items (under
// Firestore's 500 writes) and one multicast (FCM takes 500 tokens).
const BROADCAST_PAGE = 400;

// Pure: the inbox item a resumable run writes for each account. Fixed per
// run, so a page written twice (the instance died between the batch and
// the progress record) lands on the same documents instead of doubling.
function broadcastItemId(runKey) {
  return `broadcast_${String(runKey).replace(/\//g, "_")}`;
}

// The accounts are walked in pages, in document-id order. `resume` ({cursor,
// items, sent, failed}) continues an earlier run after its last page;
// `deadline` (millis) stops after the page that crosses it and returns
// `done: false` with the cursor; `onProgress` is told after every page. A
// call without them (the console's "send now") runs to the end as before.
async function notifyAll({
  fromUid, title, message, audience = "all", uids = null,
  resume = null, deadline = null, onProgress = null, runKey = null,
  db = admin.firestore(), messaging = null, pushFlag = null,
}) {
  // Plans are in entitlements/{uid}: read per page, and only when the push
  // gate or the audience needs them.
  const flag = pushFlag ?? remoteFlags.intFrom(await remoteFlags.params(), remoteFlags.NOTIFICATIONS_FLAG, remoteFlags.NOTIFICATIONS_FALLBACK);
  const needPlans = flag === 3 || audience === "premium" || audience === "free";
  const uidSet = audience === "users" ? new Set(uids || []) : null;
  const count = (v) => (Number.isFinite(Number(v)) ? Number(v) : 0);
  const totals = { items: count(resume && resume.items), sent: count(resume && resume.sent), failed: count(resume && resume.failed) };
  let cursor = (resume && typeof resume.cursor === "string" && resume.cursor) || null;

  for (;;) {
    let query = db.collection("users").orderBy(admin.firestore.FieldPath.documentId()).select("pushToken").limit(BROADCAST_PAGE);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;

    const entitlementByUid = new Map();
    if (needPlans) {
      const snaps = await db.getAll(...page.docs.map((doc) => db.collection("entitlements").doc(doc.id)));
      for (const snap of snaps) if (snap.exists) entitlementByUid.set(snap.id, snap);
    }
    const premiumOf = (uid) => remoteFlags.isPremium(entitlementByUid.get(uid));
    const targets = page.docs.filter((doc) => inAudience({ audience, uid: doc.id, uidSet, premium: premiumOf(doc.id) }));

    // Each account's notification choices, read in bounded parallel groups:
    // the item is written for everyone (an announcement has to be readable),
    // the push only to those who left announcements on.
    const prefsByUid = new Map();
    for (let i = 0; i < targets.length; i += PREFS_BATCH) {
      const chunk = targets.slice(i, i + PREFS_BATCH);
      const loaded = await Promise.all(chunk.map((doc) => notificationPrefs.load(db, doc.id)));
      chunk.forEach((doc, j) => prefsByUid.set(doc.id, loaded[j]));
    }

    const tokens = [];
    if (targets.length) {
      const batch = db.batch();
      for (const doc of targets) {
        const items = db.collection("notifications").doc(doc.id).collection("items");
        batch.set(runKey ? items.doc(broadcastItemId(runKey)) : items.doc(), inboxItem({ fromUid, title, message, silent: true }));
        const token = doc.get("pushToken");
        const prefs = prefsByUid.get(doc.id) || notificationPrefs.DEFAULTS;
        // The plan gate applies to a broadcast as to any push: the inbox item
        // is written for everyone, the ring only for accounts the plan allows.
        const planAllows = remoteFlags.pushAllowed({ flag, premium: premiumOf(doc.id) });
        if (typeof token === "string" && token && planAllows && notificationPrefs.wantsPush(prefs, { type: "adminMessage" })) {
          tokens.push(token);
        }
      }
      await batch.commit();
      totals.items += targets.length;
    }

    for (let i = 0; i < tokens.length; i += FCM_BATCH) {
      const chunk = tokens.slice(i, i + FCM_BATCH);
      try {
        const result = await (messaging || admin.messaging()).sendEachForMulticast({
          tokens: chunk,
          notification: { title: title || "EasyPlate", body: message },
          data: { type: "adminMessage" },
          android: { priority: "high" },
          apns: { payload: { aps: { sound: "default" } } },
        });
        totals.sent += result.successCount;
        totals.failed += result.failureCount;
      } catch (err) {
        totals.failed += chunk.length;
        logger.warn("broadcast chunk failed", { reason: err.message });
      }
    }

    cursor = page.docs[page.docs.length - 1].id;
    if (onProgress) await onProgress({ cursor, ...totals });
    if (page.size < BROADCAST_PAGE) break;
    if (deadline !== null && Date.now() >= deadline) return { ...totals, done: false, cursor };
  }
  return { ...totals, done: true, cursor: null };
}

// A direct broadcast (no template) keeps no run record, so it has to end
// inside the one request that started it; a large audience would stop at
// the function's timeout part-way, with nothing to resume from. Above this
// many accounts it is refused, and a template's "send now" — resumable,
// see adminNotifications.continueRun — is the way. 5000 accounts is about
// thirteen pages, far inside the 300 seconds.
const DIRECT_SEND_MAX = 5000;

// Null when a direct broadcast may go, else the refusal. Every broadcast
// walks the whole users collection (the audience is filtered per page), so
// the collection's size is what counts, whatever the audience.
async function directSendRefusal(db = admin.firestore(), max = DIRECT_SEND_MAX) {
  const snap = await db.collection("users").count().get();
  const accounts = Number(snap.data().count) || 0;
  if (accounts <= max) return null;
  return { error: "too_many_recipients", accounts, message: `${accounts} accounts are too many for a direct send: save it as a template and use Send now` };
}

exports.adminUsers = onRequest(
  { region: "europe-west1", minInstances: 0, maxInstances: 2, timeoutSeconds: 300, memory: "256MiB", cors: false, secrets: [stripeSecret, ...billingSecrets.SECRETS] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    if (!(await isAdmin(caller))) return res.status(403).json({ error: { message: "Administrator only" } });

    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { message: request.error } });
    if (request.uid === caller.uid && request.action !== "notify") {
      return res.status(400).json({ error: { message: "Not on your own account" } });
    }

    try {
      let result = {};
      switch (request.action) {
        case "disable":
          await disable(request.uid, request.message);
          break;
        case "enable":
          await enable(request.uid);
          break;
        case "delete": {
          const removed = await remove(request.uid, { stripeSecret: stripeSecret.value() || "", billingKeys: billingSecrets.keys() });
          if (removed && removed.error) {
            logger.info("admin delete refused", { uid: request.uid, reason: removed.error });
            return res.status(409).json({ error: { code: removed.error, message: "The account owns a household: dissolve it first" } });
          }
          break;
        }
        case "releaseSession":
          await releaseSession(request.uid);
          break;
        case "notify":
          await notifyOne({ fromUid: caller.uid, ...request });
          await notificationLog.log(admin.firestore(), { by: caller.uid, target: "user", uid: request.uid, title: request.title, body: request.message, source: "app" });
          break;
        case "notifyAll": {
          const refusal = await directSendRefusal();
          if (refusal) return res.status(409).json({ error: { code: refusal.error, message: refusal.message } });
          result = await notifyAll({ fromUid: caller.uid, ...request });
          await notificationLog.log(admin.firestore(), { by: caller.uid, target: "all", title: request.title, body: request.message, source: "app", result });
          break;
        }
        case "syncPricing":
          // The repair rides along: both exist to make the cost figure
          // right, and both are idempotent.
          result = { ...(await repairUsage()), ...(await syncRate()), ...(await syncPricing()) };
          break;
        case "setPermission":
          result = { permission: await permissions.setPermission(request.uid, request.permission) };
          break;
      }
      logger.info("admin action", { action: request.action, uid: request.uid || null, ...result });
      return res.status(200).json({ ok: true, ...result });
    } catch (err) {
      // The detail (a Stripe or Firestore message) stays in the log.
      logger.error("admin action failed", { action: request.action, uid: request.uid || null, reason: err.message });
      return res.status(500).json({ error: { code: "failed", message: "Admin action failed" } });
    }
  },
);

// The account actions are shared with adminPanel.js (the web console), which
// adds its own actions on top of the same checks.
exports.internals = { claimsWithDisabled, setDisabledClaim, parseRequest, validId, isAdmin, remove, deleteInteractionOwners, disable, enable, releaseSession, notifyOne, notifyAll, inAudience, broadcastItemId, directSendRefusal, AUDIENCES, BROADCAST_PAGE, DIRECT_SEND_MAX };
