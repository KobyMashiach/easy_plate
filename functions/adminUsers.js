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
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const notificationPrefs = require("./notificationPrefs");
const remoteFlags = require("./remoteFlags");

const proxy = require("./aiProxy").internals;
const { syncPricing, syncRate } = require("./pricingCatalog");
const { repairUsage } = require("./aiUsage");

const ADMIN_EMAIL = "koby9779@gmail.com";
const MAX_TITLE = 80;
const MAX_BODY = 1000;
const FCM_BATCH = 500;
// How many preference documents are read at once for a broadcast.
const PREFS_BATCH = 50;

function isAdmin(caller) {
  return !!caller && String(caller.email || "").trim().toLowerCase() === ADMIN_EMAIL;
}

function text(value, max) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

/// The request, checked and trimmed, or the reason it is refused.
function parseRequest(body) {
  const action = text(body && body.action, 20);
  const uid = text(body && body.uid, 128);
  const title = text(body && body.title, MAX_TITLE);
  const message = text(body && (body.body ?? body.message), MAX_BODY);
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

async function enable(uid) {
  await admin.firestore().doc(`account_status/${uid}`).set(
    {
      disabled: false,
      message: "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
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

async function remove(uid) {
  const db = admin.firestore();
  const directory = await db.collection("user_directory").where("uid", "==", uid).get();
  const batch = db.batch();
  for (const doc of directory.docs) batch.delete(doc.ref);
  for (const path of [
    `public_profiles/${uid}`,
    `entitlements/${uid}`,
    `ai_usage/${uid}`,
    `account_status/${uid}`,
    `sessions/${uid}`,
  ]) {
    batch.delete(db.doc(path));
  }
  await batch.commit();
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
async function notifyAll({ fromUid, title, message }) {
  const db = admin.firestore();
  const users = await db.collection("users").select("pushToken").get();
  // Plans are in entitlements/{uid}: read once, keyed by uid, and only when
  // the gate is on, since with it off the answer is never consulted.
  const pushFlag = remoteFlags.intFrom(await remoteFlags.params(), remoteFlags.NOTIFICATIONS_FLAG, 2);
  const entitlementByUid = new Map();
  if (pushFlag === 3) {
    const entitlements = await db.collection("entitlements").select("premium", "premiumFrom", "premiumUntil").get();
    for (const d of entitlements.docs) entitlementByUid.set(d.id, d);
  }
  const tokens = [];
  let items = 0;
  let batch = db.batch();
  let pending = 0;
  // Each account's notification choices, read in bounded parallel groups:
  // the item is written for everyone (an announcement has to be readable),
  // the push only to those who left announcements on.
  const prefsByUid = new Map();
  for (let i = 0; i < users.docs.length; i += PREFS_BATCH) {
    const chunk = users.docs.slice(i, i + PREFS_BATCH);
    const loaded = await Promise.all(chunk.map((doc) => notificationPrefs.load(db, doc.id)));
    chunk.forEach((doc, j) => prefsByUid.set(doc.id, loaded[j]));
  }
  for (const doc of users.docs) {
    batch.set(
      db.collection("notifications").doc(doc.id).collection("items").doc(),
      inboxItem({ fromUid, title, message, silent: true }),
    );
    items++;
    pending++;
    if (pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
    const token = doc.get("pushToken");
    const prefs = prefsByUid.get(doc.id) || notificationPrefs.DEFAULTS;
    // The plan gate applies to a broadcast as to any push: the inbox item
    // is written for everyone, the ring only for accounts the plan allows.
    const planAllows = remoteFlags.pushAllowed({ flag: pushFlag, premium: remoteFlags.isPremium(entitlementByUid.get(doc.id)) });
    if (typeof token === "string" && token && planAllows && notificationPrefs.wantsPush(prefs, { type: "adminMessage" })) {
      tokens.push(token);
    }
  }
  if (pending > 0) await batch.commit();

  let sent = 0;
  let failed = 0;
  for (let i = 0; i < tokens.length; i += FCM_BATCH) {
    const chunk = tokens.slice(i, i + FCM_BATCH);
    try {
      const result = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title: title || "EasyPlate", body: message },
        data: { type: "adminMessage" },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      });
      sent += result.successCount;
      failed += result.failureCount;
    } catch (err) {
      failed += chunk.length;
      logger.warn("broadcast chunk failed", { reason: err.message });
    }
  }
  return { items, sent, failed };
}

exports.adminUsers = onRequest(
  { region: "europe-west1", minInstances: 0, maxInstances: 2, timeoutSeconds: 300, memory: "256MiB", cors: false },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    if (!isAdmin(caller)) return res.status(403).json({ error: { message: "Administrator only" } });

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
        case "delete":
          await remove(request.uid);
          break;
        case "releaseSession":
          await releaseSession(request.uid);
          break;
        case "notify":
          await notifyOne({ fromUid: caller.uid, ...request });
          break;
        case "notifyAll":
          result = await notifyAll({ fromUid: caller.uid, ...request });
          break;
        case "syncPricing":
          // The repair rides along: both exist to make the cost figure
          // right, and both are idempotent.
          result = { ...(await repairUsage()), ...(await syncRate()), ...(await syncPricing()) };
          break;
      }
      logger.info("admin action", { action: request.action, uid: request.uid || null, ...result });
      return res.status(200).json({ ok: true, ...result });
    } catch (err) {
      logger.error("admin action failed", { action: request.action, reason: err.message });
      return res.status(500).json({ error: { message: err.message } });
    }
  },
);

// The account actions are shared with adminPanel.js (the web console), which
// adds its own actions on top of the same checks.
exports.internals = { parseRequest, isAdmin, remove, disable, enable, releaseSession, notifyOne, notifyAll, ADMIN_EMAIL };
