// Self-service account deletion, as the stores require: the signed-in user
// asks, and everything the account holds goes — the Auth user, the profile
// and its mirrored boxes, the inbox, the photos, the shared documents it
// owns, its codes and invites, and what it posted in the community. The
// administrator's `delete` action in adminUsers.js does the core of this;
// here the caller can only ever delete themselves.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const adminUsers = require("./adminUsers").internals;
const households = require("./households").internals;
const stripe = require("./stripeClient");
const billingSecrets = require("./billingSecrets");
const payplus = require("./payplusClient");
const paddle = require("./paddleClient");
const rc = require("./revenueCatClient");
// The website's own origins (the account page has a "Delete account" card):
// the same list the web checkout and the upgrade links answer.
const { ORIGINS } = require("./webBilling").internals;

// The same key webBilling uses. Unset on a deploy that has no web checkout
// yet: then the Stripe step is skipped with a warning, never a failure.
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_CUSTOMERS = "stripe_customers";
// Subscription states with nothing left to cancel. Anything else — live, in
// grace, still unknown — is cancelled; one Stripe no longer has is fine.
const STRIPE_ENDED = new Set(["canceled", "incomplete_expired"]);

// Pure: the request has to say so in as many words. A stray POST from a
// retry or a misrouted client must not take an account down.
function parseRequest(body) {
  if (!body || body.confirm !== true) return { error: "confirm is required" };
  return { confirm: true };
}

async function deleteQuery(db, query, { subtrees = false } = {}) {
  const snap = await query.get();
  if (subtrees) {
    for (const doc of snap.docs) await db.recursiveDelete(doc.ref);
    return snap.size;
  }
  let batch = db.batch();
  let pending = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    if (++pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending) await batch.commit();
  return snap.size;
}

function profilePhotoPath(uid) {
  return `profile_photos/${uid}.jpg`;
}

async function deleteStorage(uid, bucket = admin.storage().bucket()) {
  const counts = {};
  for (const prefix of [`recipe_images/${uid}/`]) {
    try {
      const [files] = await bucket.getFiles({ prefix });
      await Promise.all(files.map((f) => f.delete({ ignoreNotFound: true })));
      counts[prefix] = files.length;
    } catch (err) {
      // Photos that cannot be listed are not a reason to keep the account;
      // they carry no name, and the log says they are still there.
      logger.warn("storage cleanup incomplete", { uid, prefix, reason: err.message });
    }
  }
  // The profile photo by its exact name (both clients write
  // profile_photos/{uid}.jpg). It used to be a prefix listing of
  // `profile_photos/{uid}`, which also matched — and deleted — the photo of
  // any account whose uid starts with this one's.
  const photo = profilePhotoPath(uid);
  try {
    await bucket.file(photo).delete({ ignoreNotFound: true });
    counts[photo] = 1;
  } catch (err) {
    logger.warn("storage cleanup incomplete", { uid, path: photo, reason: err.message });
  }
  return counts;
}

// The account's seat in other people's shares: a dead uid left in a roster
// keeps being invited (and its inbox tree recreated) on every save.
async function leaveRosters(db, uid) {
  let left = 0;
  for (const collection of ["collab_recipes", "collab_containers"]) {
    const snap = await db.collection(collection).where("memberUids", "array-contains", uid).get();
    for (const doc of snap.docs) {
      await doc.ref.update({
        [`members.${uid}`]: admin.firestore.FieldValue.delete(),
        memberUids: admin.firestore.FieldValue.arrayRemove(uid),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      left++;
    }
  }
  return left;
}

// Replies in other people's threads: each one taken off its thread's count
// as it goes, so "5 replies" does not keep saying so over 3.
async function deleteReplies(db, uid) {
  const snap = await db.collectionGroup("replies").where("authorUid", "==", uid).get();
  const perThread = new Map();
  let batch = db.batch();
  let pending = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    const thread = doc.ref.parent.parent;
    if (thread) perThread.set(thread.path, { ref: thread, count: (perThread.get(thread.path)?.count || 0) + 1 });
    if (++pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending) await batch.commit();
  for (const { ref, count } of perThread.values()) {
    try {
      await ref.update({ replyCount: admin.firestore.FieldValue.increment(-count) });
    } catch (err) {
      // The thread may be gone (its author deleted it, or is this account).
      if (err.code !== 5) throw err;
    }
  }
  return snap.size;
}

// What leaves with the account, beyond what the admin removal covers.
// Likes stay as counters: a like document is keyed by uid under a post with
// no field to query by, and the counter it moved is anonymous.
async function deleteOwned(db, uid) {
  const out = {};
  out.rostersLeft = await leaveRosters(db, uid);
  out.collabRecipes = await deleteQuery(db, db.collection("collab_recipes").where("ownerUid", "==", uid), { subtrees: true });
  out.collabContainers = await deleteQuery(db, db.collection("collab_containers").where("ownerUid", "==", uid), { subtrees: true });
  await db.doc(`sessions/${uid}`).delete().catch(() => {});
  out.shareCodes = await deleteQuery(db, db.collection("share_codes").where("ownerUid", "==", uid));
  out.invitesSent = await deleteQuery(db, db.collection("share_invites").where("ownerUid", "==", uid));
  out.invitesReceived = await deleteQuery(db, db.collection("share_invites").where("targetUid", "==", uid));
  // With their likes: a plain delete left each recipe's likes/{uid}
  // subcollection behind, naming the accounts that liked it.
  out.sharedRecipes = await deleteQuery(db, db.collection("shared_recipes").where("authorUid", "==", uid), { subtrees: true });
  out.forumPosts = await deleteQuery(db, db.collection("forum_posts").where("authorUid", "==", uid), { subtrees: true });
  out.forumReplies = await deleteReplies(db, uid);
  // Keyed by `authorUid` (the field the app writes and the rules check);
  // a query on `uid` matched nothing and left every message behind.
  out.feedback = await deleteQuery(db, db.collection("feedback").where("authorUid", "==", uid));
  return out;
}

// Pure: what the account's Stripe record calls for. The customer goes
// whenever there is one (deleting it is what purges the name, email and
// phone Stripe holds); the subscription is cancelled first when it may
// still be running, so a card is not charged for an account that no longer
// exists.
function stripeCleanupFor(data) {
  const customerId = data && typeof data.stripeCustomerId === "string" && data.stripeCustomerId ? data.stripeCustomerId : null;
  if (!customerId) return { customerId: null, subscriptionId: null };
  const subscriptionId = typeof data.subscriptionId === "string" && data.subscriptionId ? data.subscriptionId : null;
  const live = subscriptionId !== null && !STRIPE_ENDED.has(String(data.subscriptionStatus || ""));
  return { customerId, subscriptionId: live ? subscriptionId : null };
}

function stripeConfigured(secret) {
  return typeof secret === "string" && secret.trim() !== "" && secret.trim() !== "-";
}

// Cancels the web subscription and deletes the Stripe customer, then the
// stripe_customers document. A Stripe failure other than "already gone" is
// thrown: the deletion stops before anything else went, and the account —
// with its subscription still manageable — is left as it was.
async function deleteStripeCustomer(db, uid, secret, request = stripe.request) {
  const ref = db.collection(STRIPE_CUSTOMERS).doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return { customer: false, subscriptionCancelled: false, skipped: false };
  const plan = stripeCleanupFor(snap.data());
  let skipped = false;
  if (plan.customerId && !stripeConfigured(secret)) {
    // Nothing to call Stripe with: the account still goes, and the log
    // names what the operator has to settle in the Stripe dashboard.
    skipped = true;
    logger.warn("stripe cleanup skipped: STRIPE_SECRET_KEY is not set", { uid, customerId: plan.customerId, subscriptionId: plan.subscriptionId });
  } else if (plan.customerId) {
    const tolerant = async (path) => {
      try {
        await request(secret, "DELETE", path);
      } catch (err) {
        if (err instanceof stripe.StripeError && err.status === 404) return;
        throw err;
      }
    };
    if (plan.subscriptionId) await tolerant(`/subscriptions/${plan.subscriptionId}`);
    await tolerant(`/customers/${plan.customerId}`);
  }
  await ref.delete();
  return { customer: !!plan.customerId, subscriptionCancelled: !!plan.subscriptionId && !skipped, skipped };
}

// Pure: what an account's PayPlus / Paddle record calls for. A subscription
// that may still charge (live, in grace, not yet set to end) is stopped at
// the provider; one already ended or set to end needs nothing.
const WEB_ENDED = new Set(["canceled", "refunded", "paused"]);
function webCleanupFor(data) {
  if (!data || !data.provider || !data.subscriptionId) return { provider: null, stop: false };
  const ended = WEB_ENDED.has(String(data.subscriptionStatus || ""));
  const settled = data.provider === "payplus" && data.cancelAtPeriodEnd === true;
  return { provider: data.provider, stop: !ended && !settled };
}

// Whether this account ever bought through RevenueCat's Paddle route: its
// entitlement says so, or one of its purchase_events rows does (the
// entitlement may since have been overwritten by a store purchase).
async function hadRevenueCatPaddle(db, uid) {
  const ent = await db.collection("entitlements").doc(uid).get();
  if (ent.exists && String(ent.get("store") || "").toUpperCase() === "PADDLE") return true;
  // One equality filter (no composite index needed); an account has a
  // handful of rows a year.
  const rows = await db.collection("purchase_events").where("uid", "==", uid).limit(500).get();
  return (rows.docs || []).some((d) => String((typeof d.get === "function" ? d.get("store") : d.data && d.data().store) || "").toUpperCase() === "PADDLE");
}

// Stops a Paddle subscription bought through RevenueCat (the international
// web route). RevenueCat's own cancel endpoint is for RevenueCat Billing
// only, so RevenueCat's API finds the subscription (its
// store_subscription_identifier is Paddle's sub_… id) and Paddle's API
// cancels it. Keys or project id missing: skipped with a warning naming
// what to stop by hand. A provider failure throws, before anything of ours
// is removed (like the Stripe and PayPlus steps).
async function stopRevenueCatPaddle(db, uid, keys, { fetchImpl, catalog = null } = {}) {
  if (!(await hadRevenueCatPaddle(db, uid))) return { stopped: false, skipped: false };
  const secretKey = keys && keys.revenuecat && keys.revenuecat.secretKey;
  const paddleKey = keys && keys.paddle && keys.paddle.apiKey;
  const cat = catalog || (rc.isSet(secretKey) ? (await require("./billingCatalog").load()).catalog : null);
  const projectId = cat && cat.revenuecat ? cat.revenuecat.projectId : null;
  if (!rc.isSet(secretKey) || !projectId || !paddle.isSet(paddleKey)) {
    logger.warn("paddle (revenuecat) cleanup skipped: REVENUECAT_SECRET_KEY, revenuecat.projectId or PADDLE_API_KEY is not set — cancel it in the Paddle dashboard", { uid });
    return { stopped: false, skipped: true };
  }
  const items = await rc.subscriptions(secretKey, projectId, uid, { fetchImpl });
  let stopped = false;
  let skipped = false;
  for (const sub of items) {
    if (String(sub.store || "").toLowerCase() !== "paddle" || !rc.stillCharges(sub)) continue;
    const id = String(sub.store_subscription_identifier || "");
    if (!/^sub_[a-z0-9]+$/i.test(id)) {
      skipped = true;
      logger.warn("paddle (revenuecat) cleanup: no Paddle subscription id — cancel it in the Paddle dashboard", { uid, revenuecatSubscription: sub.id || null });
      continue;
    }
    if (await paddle.cancelSubscription(paddleKey, id, "immediately", fetchImpl)) stopped = true;
  }
  return { stopped, skipped };
}

// Stops the account's web subscriptions — a Paddle one bought through
// RevenueCat, a PayPlus recurring charge, or a legacy direct-Paddle
// subscription — then deletes web_customers/{uid}. Like the Stripe step, a provider failure is
// thrown before anything of ours is removed; a provider not configured yet is
// skipped with a warning naming what to stop by hand.
async function deleteWebCustomer(db, uid, keys, { fetchImpl, catalog } = {}) {
  const viaRc = await stopRevenueCatPaddle(db, uid, keys, { fetchImpl, catalog });
  const ref = db.collection("web_customers").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return { stopped: viaRc.stopped, skipped: viaRc.skipped, provider: viaRc.stopped || viaRc.skipped ? "revenuecat" : null };
  const data = snap.data();
  const plan = webCleanupFor(data);
  let stopped = viaRc.stopped;
  let skipped = viaRc.skipped;
  if (plan.stop && plan.provider === "paddle") {
    if (!paddle.isSet(keys && keys.paddle && keys.paddle.apiKey)) {
      skipped = true;
      logger.warn("paddle cleanup skipped: PADDLE_API_KEY is not set — cancel it in the Paddle dashboard", { uid, subscription: data.subscriptionId });
    } else {
      stopped = (await paddle.cancelSubscription(keys.paddle.apiKey, data.subscriptionId, "immediately", fetchImpl)) || stopped;
    }
  } else if (plan.stop && plan.provider === "payplus") {
    const pk = keys && keys.payplus ? { ...keys.payplus } : null;
    if (!payplus.configured(pk)) {
      skipped = true;
      logger.warn("payplus cleanup skipped: PayPlus keys are not set — stop the recurring charge in the PayPlus dashboard", { uid, subscription: data.subscriptionId, customer: data.payplusCustomerUid || null });
    } else {
      if (!pk.env) pk.env = (await require("./billingCatalog").load()).catalog.payplus.env;
      const recurring = data.payplusRecurringUid || (String(data.subscriptionId).startsWith("page:") ? null : data.subscriptionId);
      if (recurring) {
        try {
          await payplus.request(pk, "POST", `/RecurringPayments/DeleteRecurring/${encodeURIComponent(recurring)}`, { terminal_uid: pk.terminalUid }, { fetchImpl });
          stopped = true;
        } catch (err) {
          if (!(err instanceof payplus.PayPlusError && err.status === 404)) throw err;
        }
      } else {
        skipped = true;
        logger.warn("payplus cleanup: no recurring uid on record — check the PayPlus dashboard", { uid, customer: data.payplusCustomerUid || null });
      }
    }
  }
  await ref.delete();
  return { stopped, skipped, provider: plan.provider };
}

async function deleteAccount(db, uid, { stripeSecret: secret = "", billingKeys = null } = {}) {
  // A household the account owns is not taken down behind the members'
  // backs: the owner closes it first, from the household screen.
  const owned = await db.collection("households").where("ownerUid", "==", uid).limit(1).get();
  if (!owned.empty) return { error: "household_owner" };
  // Stripe before anything of ours, the household included: if the
  // subscription cannot be cancelled the deletion stops here, with an
  // account that still works, is still in its household, and can still
  // reach its billing portal.
  const web = await deleteStripeCustomer(db, uid, secret);
  const webSub = await deleteWebCustomer(db, uid, billingKeys);
  const membership = await households.leave(db, uid);
  if (membership && membership.error && membership.error !== "not_member") {
    logger.warn("household leave on delete", { uid, reason: membership.error });
  }
  // Firestore and Auth first, the photos last: a failure part-way must
  // leave an account that still works, not one with its pictures gone.
  const owned_ = await deleteOwned(db, uid);
  await adminUsers.remove(uid);
  const storage = await deleteStorage(uid);
  return { ok: true, storage, stripe: web, web: webSub, ...owned_ };
}

exports.deleteAccount = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 3, timeoutSeconds: 300, secrets: [stripeSecret, ...billingSecrets.SECRETS] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { code: "method", message: "Method not allowed" } });
    // Revocation checked: deletion cannot be undone, and a token from a
    // session that was signed out (an admin kick, an expired device
    // session) stays valid for up to an hour otherwise.
    const caller = await proxy.verifyCaller(req, { checkRevoked: true });
    if (!caller) return res.status(401).json({ error: { code: "unauthenticated", message: "A valid Firebase ID token is required" } });
    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { code: "invalid", message: request.error } });
    try {
      const result = await deleteAccount(admin.firestore(), caller.uid, { stripeSecret: stripeSecret.value(), billingKeys: billingSecrets.keys() });
      if (result.error) {
        logger.info("account deletion refused", { uid: caller.uid, reason: result.error });
        return res.status(409).json({ error: { code: result.error, message: result.error } });
      }
      logger.info("account deleted", { uid: caller.uid, ...result });
      return res.status(200).json({ ok: true });
    } catch (err) {
      logger.error("account deletion failed", { uid: caller.uid, reason: err.message });
      return res.status(500).json({ error: { code: "failed", message: "Deletion failed" } });
    }
  },
);

exports.internals = { profilePhotoPath, deleteStorage, parseRequest, deleteQuery, deleteOwned, deleteAccount, leaveRosters, deleteReplies, stripeCleanupFor, stripeConfigured, deleteStripeCustomer, STRIPE_CUSTOMERS, webCleanupFor, deleteWebCustomer, stopRevenueCatPaddle, hadRevenueCatPaddle };
