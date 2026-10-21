// One signed-in device per account, for a month at a time.
//
//   claim   { deviceId, hardwareId?, platform }
//                                   the device asks to be the account's
//                                   session; refused (200, ok:false) while
//                                   another device holds a live one
//   release { deviceId }            the device signs out and frees it
//   requestRelease { deviceId, platform, pushToken?, title, body }
//                                   a refused device asks the holder to
//                                   sign out: the request lands on the
//                                   record (the holder's app listens) and a
//                                   push goes to the holder's own token
//   declineRelease { deviceId }     the holder chose to stay signed in
//   takeover { deviceId, hardwareId?, platform, pushToken? }
//                                   "no access to the other device": the
//                                   caller has just confirmed the account's
//                                   phone with a fresh SMS code (the ID
//                                   token's sign-in provider is phone and its
//                                   auth_time is minutes old), so this device
//                                   becomes the session and the other one is
//                                   signed out by its own watcher
//
// Administrators (users/{uid}.permission == "admin", see permissions.js)
// may be signed in on any number of devices: like the exempt numbers they
// keep no record.
//
// A holder that can no longer answer does not lock the account: if the push
// to it fails because its token is gone (the app was deleted there), the
// record is freed on the spot; and a request nobody declined lets the asker
// in after `session_release_wait_hours` (Remote Config, default 24, 0 =
// never), at `releaseRequest.takeoverAt`, signing the old device out.
//
// Accounts whose phone number is in `session_exempt_phones` (Remote Config,
// comma separated; the App Store review account by default) are never
// refused and keep no record: a record naming another device would sign
// the older builds out, which still watch it.
//
// The record is sessions/{uid}: deviceId, hardwareId, platform, startedAt,
// expiresAt, lastSeenAt. deviceId lives in the app's own storage and is new
// after the app is deleted and installed again; hardwareId is a hash of the
// phone's own id (ANDROID_ID, a Keychain item on iOS) that survives that,
// so a reinstall on the holder's phone is the same device, not a second one. Only this function writes it; the app reads its own (and
// listens to it, so a release elsewhere or an expiry signs it out live).
// expireSessions runs daily and revokes the refresh tokens of accounts
// whose session has run out, so the month is enforced by the server, not
// by a clock on the phone.
//
// Replay: the record is readable by the account, so another device signed in
// to the same account could copy deviceId + hardwareId out of it and claim
// as "the same device". A device that can keep one draws its own random
// secret, stores it, and sends it with `wantsSecret`; when its session
// starts (or on its next claim, if the record has none yet) the server binds
// it — only the secret's SHA-256 is stored (`secretHash`). The device drew
// it before asking, so a response lost on the way back cannot leave the
// record bound to a secret nobody holds (the server-drawn secret of the
// first version could, locking the holder out). From then on the
// record is the same device only for a caller that presents the secret —
// claim, release and declineRelease alike. Records without a hash (older
// builds, which never ask for one) keep matching on the ids, so nothing
// changes for them. A reinstall loses the secret: that phone is then
// "another device", and its request to the old install frees the record at
// once (the old install's push token is gone), or the SMS takeover does.
//
// Two console knobs: `session_days` (how long a session lives, 0 = never
// expires) and `ff_single_session` (2 = one device at a time, anything
// else = several devices may share the account; sessions are still kept).
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const proxy = require("./aiProxy").internals;
const permissions = require("./permissions");
const remoteFlags = require("./remoteFlags");

const DEFAULT_DAYS = 30;
const DEFAULT_WAIT_HOURS = 24;
const HOUR_MS = 60 * 60 * 1000;
// FCM's answer for a token whose app is no longer installed.
const GONE_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);
const DAY_MS = 24 * 60 * 60 * 1000;
const PLATFORMS = new Set(["ios", "android", "web", "macos", "windows", "linux", "other"]);
// Apple's reviewers sign in on several devices with the review account.
const DEFAULT_EXEMPT = "+972501564465";
const MAX_TEXT = 200;
// How fresh the SMS confirmation behind a takeover must be.
const TAKEOVER_FRESH_MS = 10 * 60 * 1000;

function text(value, max = MAX_TEXT) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

// The device-drawn secret the server binds: 32 random bytes, base64url
// without padding — exactly 43 characters. Anything else is not bound.
const DEVICE_SECRET = /^[A-Za-z0-9_-]{43}$/;

// A session secret: 32 random bytes, base64url. Only its hash is stored.
// (The device draws its own; this is for the tests and tools.)
function newSecret() {
  return crypto.randomBytes(32).toString("base64url");
}

function secretHash(secret) {
  return crypto.createHash("sha256").update(String(secret)).digest("hex");
}

// Pure: whether a presented secret matches the stored hash (constant time).
function secretMatches(storedHash, secret) {
  if (typeof storedHash !== "string" || !storedHash || typeof secret !== "string" || !secret) return false;
  const a = Buffer.from(secretHash(secret), "hex");
  const b = Buffer.from(storedHash, "hex");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function parseRequest(body) {
  const parsed = parseFields(body);
  if (parsed.error) return parsed;
  // Only when the device sent them, so older builds' requests read as before.
  const secret = text(body && body.secret, 128);
  if (secret) parsed.secret = secret;
  // The ask counts only with a device-drawn secret worth binding.
  if (body && body.wantsSecret === true && (parsed.action === "claim" || parsed.action === "takeover") && DEVICE_SECRET.test(secret)) parsed.wantsSecret = true;
  return parsed;
}

function parseFields(body) {
  const action = String((body && body.action) || "").trim();
  const deviceId = String((body && body.deviceId) || "").trim();
  if (!deviceId || deviceId.length > 128) return { error: "deviceId is required" };
  const hardwareId = text(body && body.hardwareId, 128) || null;
  const platformOf = () => {
    const platform = String((body && body.platform) || "other").trim().toLowerCase();
    return PLATFORMS.has(platform) ? platform : "other";
  };
  if (action === "claim" || action === "takeover") {
    return { action, deviceId, hardwareId, platform: platformOf(), pushToken: text(body && body.pushToken, 4096) || null };
  }
  if (action === "release") return { action, deviceId, hardwareId };
  if (action === "declineRelease") return { action, deviceId };
  if (action === "requestRelease") {
    return {
      action,
      deviceId,
      hardwareId,
      platform: platformOf(),
      pushToken: text(body && body.pushToken, 4096) || null,
      title: text(body && body.title) || "Easy Plate",
      body: text(body && body.body),
    };
  }
  return { error: "unknown action" };
}

// Pure: whether the caller is the phone that holds the record: the same
// app install, or the same phone after a reinstall.
// A record that carries a secret hash is the same device only for the
// holder of that secret: the ids are readable by the account, the secret
// is not.
function sameDevice(existing, deviceId, hardwareId, secret = null) {
  if (!existing) return false;
  if (existing.secretHash) return secretMatches(existing.secretHash, secret);
  if (existing.deviceId === deviceId) return true;
  return Boolean(hardwareId) && existing.hardwareId === hardwareId;
}

// Pure: whether a release request from this caller has waited long enough
// without being declined for the caller to take the account over.
function takeoverDue(existing, deviceId, hardwareId, now) {
  const request = existing && existing.releaseRequest;
  if (!request || request.declinedAt || !request.takeoverAt) return false;
  const asker = request.deviceId === deviceId ||
    (Boolean(hardwareId) && request.hardwareId === hardwareId);
  return asker && request.takeoverAt <= now;
}

// Pure: what to do with a claim, given the record as it stands.
//   existing  { deviceId, platform, startedAt, expiresAt } with millis, or null
//   days      0 = sessions never expire
//   enforce   false = other devices never refuse
// Returns { ok: true, record } to write, or { ok: false, refusal }.
// `secret` is what the caller presented, `bind` the device's own secret to
// store the hash of when the caller asked (wantsSecret) and the record has
// none yet (or is started afresh); the outcome's `secretBound` says so.
function decide({ existing, deviceId, hardwareId = null, platform, now, days, enforce, pushToken = null, secret = null, bind = null }) {
  const live = existing && (existing.expiresAt === null || existing.expiresAt > now);
  const same = sameDevice(existing, deviceId, hardwareId, secret);
  if (live && !same && enforce && !takeoverDue(existing, deviceId, hardwareId, now)) {
    return {
      ok: false,
      refusal: { code: "other_device", platform: existing.platform || "other", since: existing.startedAt || null },
    };
  }
  if (live && same) {
    // The same device again: the month keeps counting from the first
    // sign-in, only the last-seen stamp moves. After a reinstall the
    // record takes the new install's deviceId, which the app now follows.
    const minted = !existing.secretHash && bind ? bind : null;
    const record = {
      ...existing,
      deviceId,
      hardwareId: hardwareId || existing.hardwareId || null,
      platform,
      lastSeenAt: now,
      pushToken: pushToken || existing.pushToken || null,
    };
    if (minted) record.secretHash = secretHash(minted);
    return { ok: true, sameDevice: true, record, ...(minted ? { secretBound: true } : {}) };
  }
  // No session, an expired one, or a takeover allowed by the console.
  const record = {
    deviceId,
    hardwareId: hardwareId || null,
    platform,
    startedAt: now,
    expiresAt: days > 0 ? now + days * DAY_MS : null,
    lastSeenAt: now,
    pushToken: pushToken || null,
  };
  if (bind) record.secretHash = secretHash(bind);
  return { ok: true, record, ...(bind ? { secretBound: true } : {}) };
}

function toMillis(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === "number") return value;
  if (typeof value.toMillis === "function") return value.toMillis();
  return null;
}

function fromDoc(snapshot) {
  if (!snapshot.exists) return null;
  const d = snapshot.data() || {};
  return {
    deviceId: String(d.deviceId || ""),
    hardwareId: d.hardwareId ? String(d.hardwareId) : null,
    platform: String(d.platform || "other"),
    startedAt: toMillis(d.startedAt),
    expiresAt: toMillis(d.expiresAt),
    pushToken: d.pushToken ? String(d.pushToken) : null,
    secretHash: typeof d.secretHash === "string" && d.secretHash ? d.secretHash : null,
    releaseRequest: d.releaseRequest ? {
      deviceId: String(d.releaseRequest.deviceId || ""),
      hardwareId: d.releaseRequest.hardwareId ? String(d.releaseRequest.hardwareId) : null,
      at: toMillis(d.releaseRequest.at),
      takeoverAt: toMillis(d.releaseRequest.takeoverAt),
      declinedAt: toMillis(d.releaseRequest.declinedAt),
      notifiedAt: toMillis(d.releaseRequest.notifiedAt),
    } : null,
  };
}

function toDoc(record) {
  const ts = (ms) => (ms === null ? null : admin.firestore.Timestamp.fromMillis(ms));
  return {
    deviceId: record.deviceId,
    hardwareId: record.hardwareId || null,
    platform: record.platform,
    startedAt: ts(record.startedAt),
    expiresAt: ts(record.expiresAt),
    lastSeenAt: ts(record.lastSeenAt),
    pushToken: record.pushToken || null,
    secretHash: record.secretHash || null,
  };
}

// Pure: whether an ID token proves a fresh SMS confirmation of the
// account's own phone number.
function freshPhoneProof(caller, now) {
  if (!caller || !caller.phone_number) return false;
  if (!caller.firebase || caller.firebase.sign_in_provider !== "phone") return false;
  const authMs = Number(caller.auth_time || 0) * 1000;
  return authMs > 0 && now - authMs <= TAKEOVER_FRESH_MS && authMs <= now + 60 * 1000;
}

// Pure: whether the caller's phone number is on the exempt list.
function isExempt(phone, list) {
  const wanted = String(phone || "").replace(/[^+\d]/g, "");
  if (!wanted) return false;
  return String(list || "")
    .split(/[,;\n]+/)
    .map((p) => p.replace(/[^+\d]/g, ""))
    .filter(Boolean)
    .includes(wanted);
}

async function knobs() {
  const params = await remoteFlags.params();
  return {
    days: remoteFlags.intFrom(params, "session_days", DEFAULT_DAYS),
    enforce: remoteFlags.intFrom(params, "ff_single_session", 2) === 2,
    exempt: (params?.session_exempt_phones?.defaultValue?.value ?? DEFAULT_EXEMPT),
    waitHours: remoteFlags.intFrom(params, "session_release_wait_hours", DEFAULT_WAIT_HOURS),
  };
}

async function claim(caller, request) {
  const uid = caller.uid;
  const db = admin.firestore();
  const ref = db.doc(`sessions/${uid}`);
  const { days, enforce, exempt } = await knobs();
  // The administrator and a superuser have no device limit (ff_single_session
  // is a flag, and flags do not apply to them).
  if (isExempt(caller.phone_number, exempt) || permissions.hasAllFeatures(await permissions.permissionFor(caller.uid))) {
    // No record at all: nothing to refuse with, nothing for an older
    // build's watcher to read as "another device".
    await ref.delete().catch(() => {});
    return { ok: true, exempt: true, record: { startedAt: null, expiresAt: null } };
  }
  const now = Date.now();
  return db.runTransaction(async (tx) => {
    const existing = fromDoc(await tx.get(ref));
    const outcome = decide({
      existing, deviceId: request.deviceId, hardwareId: request.hardwareId, platform: request.platform, now, days, enforce, pushToken: request.pushToken,
      secret: request.secret || null, bind: request.wantsSecret ? request.secret : null,
    });
    // The same device again merges, so a pending release request survives
    // the holder's own app start (it is what that app is about to show).
    if (outcome.ok) tx.set(ref, toDoc(outcome.record), outcome.sameDevice ? { merge: true } : {});
    return outcome;
  });
}

// "No access to the other device": after a fresh SMS code, this device
// takes the session over. The record is replaced whole, so the old
// device's watcher sees another deviceId and signs out, and any pending
// release request goes with it.
async function takeover(caller, request) {
  const now = Date.now();
  if (!freshPhoneProof(caller, now)) return { ok: false, code: "verify_phone" };
  const { days } = await knobs();
  const outcome = decide({
    existing: null, deviceId: request.deviceId, hardwareId: request.hardwareId,
    platform: request.platform, now, days, enforce: true, pushToken: request.pushToken,
    bind: request.wantsSecret ? request.secret : null,
  });
  await admin.firestore().doc(`sessions/${caller.uid}`).set(toDoc(outcome.record));
  logger.info("session taken over after SMS", { uid: caller.uid, platform: request.platform });
  return outcome;
}

// One push to the holder per asker per this long: the request record is
// still refreshed on every ask, but a refused device tapping "ask" in a loop
// used to ring the holder's phone each time.
const RELEASE_PUSH_GAP_MS = 10 * 60 * 1000;

/// Pure: whether this ask may push the holder — not when the same asker's
/// undeclined request already pushed within RELEASE_PUSH_GAP_MS.
function releasePushDue(previous, request, now) {
  if (!previous || previous.declinedAt || !previous.notifiedAt) return true;
  const asker = previous.deviceId === request.deviceId ||
    (Boolean(request.hardwareId) && previous.hardwareId === request.hardwareId);
  return !asker || now - previous.notifiedAt >= RELEASE_PUSH_GAP_MS;
}

// A refused device asks the holder to sign out.
async function requestRelease(uid, request, { db = admin.firestore(), now = Date.now(), settings = knobs } = {}) {
  const ref = db.doc(`sessions/${uid}`);
  const { waitHours } = await settings();
  const ts = (ms) => (ms === null ? null : admin.firestore.Timestamp.fromMillis(ms));
  // Read and write in one transaction: a decline the holder sends while this
  // request is in flight must not be overwritten by a request computed from
  // the record as it stood before the decline (the clock would restart from
  // a stale `at` and the declinedAt would be wiped).
  const pending = await db.runTransaction(async (tx) => {
    const existing = fromDoc(await tx.get(ref));
    const live = existing && (existing.expiresAt === null || existing.expiresAt > now);
    if (!live || sameDevice(existing, request.deviceId, request.hardwareId, request.secret || null)) return null;
    const at = pendingSince(existing.releaseRequest, request, now);
    const takeoverAt = waitHours > 0 ? at + waitHours * HOUR_MS : null;
    const push = releasePushDue(existing.releaseRequest, request, now);
    const notifiedAt = push ? now : existing.releaseRequest.notifiedAt;
    tx.set(ref, {
      releaseRequest: {
        at: ts(at),
        takeoverAt: ts(takeoverAt),
        deviceId: request.deviceId,
        hardwareId: request.hardwareId || null,
        platform: request.platform,
        declinedAt: null,
        notifiedAt: ts(notifiedAt),
      },
    }, { merge: true });
    return { existing, takeoverAt, push };
  });
  if (!pending) return { ok: true, free: true };
  const { existing, takeoverAt, push } = pending;
  // The holder was told a moment ago; to the asker that is "sent".
  if (!push) return { ok: true, notified: true, recentlyNotified: true, takeoverAt };

  // The holder's own token, saved with its claim. An older build saved
  // none: then the account's last token, unless that is the asker's.
  let token = existing.pushToken;
  if (!token) {
    const user = await db.doc(`users/${uid}`).get();
    const last = user.exists ? user.get("pushToken") : null;
    if (last && last !== request.pushToken) token = last;
  }
  if (!token) return { ok: true, notified: false, takeoverAt };
  try {
    await admin.messaging().send({
      token,
      notification: { title: request.title, body: request.body },
      data: { type: "session_release", platform: request.platform },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
    return { ok: true, notified: true, takeoverAt };
  } catch (err) {
    logger.warn("release push failed", { uid, reason: err.code || err.message });
    // The holder's own token is dead: the app is gone from that phone, so
    // nobody is left to sign out. Free the account now.
    if (token === existing.pushToken && GONE_TOKEN_CODES.has(err.code)) {
      const freed = await db.runTransaction(async (tx) => {
        const current = fromDoc(await tx.get(ref));
        if (!current || current.deviceId !== existing.deviceId) return false;
        tx.delete(ref);
        return true;
      });
      if (freed) {
        logger.info("session freed, holder uninstalled", { uid });
        return { ok: true, free: true };
      }
    }
    return { ok: true, notified: false, takeoverAt };
  }
}

// Pure: when the caller's request started. Asking again keeps the clock of
// a request that is still waiting; a declined one starts over.
function pendingSince(previous, request, now) {
  if (!previous || previous.declinedAt || !previous.at) return now;
  const asker = previous.deviceId === request.deviceId ||
    (Boolean(request.hardwareId) && previous.hardwareId === request.hardwareId);
  return asker ? previous.at : now;
}

async function declineRelease(uid, request) {
  const db = admin.firestore();
  const ref = db.doc(`sessions/${uid}`);
  await db.runTransaction(async (tx) => {
    const existing = fromDoc(await tx.get(ref));
    if (!existing) return;
    if (existing.secretHash ? !secretMatches(existing.secretHash, request.secret) : existing.deviceId !== request.deviceId) return;
    tx.set(ref, { releaseRequest: { declinedAt: admin.firestore.Timestamp.now() } }, { merge: true });
  });
}

async function release(uid, request) {
  const db = admin.firestore();
  const ref = db.doc(`sessions/${uid}`);
  await db.runTransaction(async (tx) => {
    const existing = fromDoc(await tx.get(ref));
    // Another device's session is not this device's to free.
    if (existing && !sameDevice(existing, request.deviceId, request.hardwareId, request.secret || null)) return;
    tx.delete(ref);
  });
}

exports.sessions = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 5 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { message: request.error } });
    try {
      if (request.action === "requestRelease") {
        return res.status(200).json(await requestRelease(caller.uid, request));
      }
      if (request.action === "declineRelease") {
        await declineRelease(caller.uid, request);
        return res.status(200).json({ ok: true });
      }
      if (request.action === "takeover") {
        const outcome = await takeover(caller, request);
        if (!outcome.ok) return res.status(200).json({ ok: false, code: outcome.code });
        return res.status(200).json({
          ok: true,
          startedAt: outcome.record.startedAt,
          expiresAt: outcome.record.expiresAt,
          ...(outcome.secretBound ? { secretBound: true } : {}),
        });
      }
      if (request.action === "claim") {
        const outcome = await claim(caller, request);
        if (!outcome.ok) {
          logger.info("session refused", { uid: caller.uid, platform: outcome.refusal.platform });
          return res.status(200).json({ ok: false, refusal: outcome.refusal });
        }
        return res.status(200).json({
          ok: true,
          exempt: outcome.exempt === true,
          startedAt: outcome.record.startedAt,
          expiresAt: outcome.record.expiresAt,
          ...(outcome.secretBound ? { secretBound: true } : {}),
        });
      }
      await release(caller.uid, request);
      return res.status(200).json({ ok: true });
    } catch (err) {
      // The reason stays in the log: an SDK message can name a path or a
      // project, which is nothing a phone needs to be told.
      logger.error("session action failed", { uid: caller.uid, action: request.action, reason: err.message });
      return res.status(500).json({ error: { message: "Session action failed" } });
    }
  },
);

// Sessions past their month: the record goes and the refresh tokens are
// revoked, so the device's ID token stops renewing within the hour and the
// app's gate sends it back to sign in.
// Pages of 500 until none is left or the time budget runs out (the next
// day's run carries on): one page a day fell behind as soon as more than
// 500 sessions ran out on the same day. Paged by cursor, so a session kept
// because it was renewed is never read twice.
const EXPIRE_PAGE = 500;
const EXPIRE_BUDGET_MS = 8 * 60 * 1000;

async function expire(now = Date.now(), { db = admin.firestore(), auth = admin.auth(), clock = Date.now, budgetMs = EXPIRE_BUDGET_MS, page = EXPIRE_PAGE } = {}) {
  const started = clock();
  let count = 0;
  let cursor = null;
  for (;;) {
    let query = db.collection("sessions").where("expiresAt", "<=", admin.firestore.Timestamp.fromMillis(now)).orderBy("expiresAt").limit(page);
    if (cursor) query = query.startAfter(cursor);
    const due = await query.get();
    for (const doc of due.docs) {
      // Deleted only if untouched since the query read it: a device that
      // claimed again in between holds a fresh month, and deleting (then
      // revoking) it would have signed a just-renewed session out. Revoked
      // after the delete, for the same reason.
      try {
        await doc.ref.delete({ lastUpdateTime: doc.updateTime });
      } catch (err) {
        logger.info("session renewed before expiry, kept", { uid: doc.id, reason: err.code || err.message });
        continue;
      }
      try {
        await auth.revokeRefreshTokens(doc.id);
      } catch (err) {
        logger.warn("revoke failed", { uid: doc.id, reason: err.message });
      }
      count++;
    }
    if (due.docs.length < page) break;
    cursor = due.docs[due.docs.length - 1];
    if (clock() - started > budgetMs) {
      logger.warn("session expiry stopped at its time budget; tomorrow's run continues", { count });
      break;
    }
  }
  return count;
}

exports.expireSessions = onSchedule(
  { schedule: "every day 04:10", timeZone: "Asia/Jerusalem", region: "europe-west1", retryCount: 1, timeoutSeconds: 540 },
  async () => {
    const count = await expire();
    logger.info("sessions expired", { count });
  },
);

exports.internals = { releasePushDue, RELEASE_PUSH_GAP_MS, secretHash, secretMatches, newSecret, release, declineRelease, requestRelease, parseRequest, decide, sameDevice, takeoverDue, pendingSince, freshPhoneProof, isExempt, DEFAULT_DAYS, DAY_MS, expire };
