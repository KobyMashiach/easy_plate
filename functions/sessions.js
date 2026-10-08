// One signed-in device per account, for a month at a time.
//
//   claim   { deviceId, platform }  the device asks to be the account's
//                                   session; refused (200, ok:false) while
//                                   another device holds a live one
//   release { deviceId }            the device signs out and frees it
//
// The record is sessions/{uid}: deviceId, platform, startedAt, expiresAt,
// lastSeenAt. Only this function writes it; the app reads its own (and
// listens to it, so a release elsewhere or an expiry signs it out live).
// expireSessions runs daily and revokes the refresh tokens of accounts
// whose session has run out, so the month is enforced by the server, not
// by a clock on the phone.
//
// Two console knobs: `session_days` (how long a session lives, 0 = never
// expires) and `ff_single_session` (2 = one device at a time, anything
// else = several devices may share the account; sessions are still kept).
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const remoteFlags = require("./remoteFlags");

const DEFAULT_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;
const PLATFORMS = new Set(["ios", "android", "web", "macos", "windows", "linux", "other"]);

function parseRequest(body) {
  const action = String((body && body.action) || "").trim();
  const deviceId = String((body && body.deviceId) || "").trim();
  if (!deviceId || deviceId.length > 128) return { error: "deviceId is required" };
  if (action === "claim") {
    const platform = String((body && body.platform) || "other").trim().toLowerCase();
    return { action, deviceId, platform: PLATFORMS.has(platform) ? platform : "other" };
  }
  if (action === "release") return { action, deviceId };
  return { error: "unknown action" };
}

// Pure: what to do with a claim, given the record as it stands.
//   existing  { deviceId, platform, startedAt, expiresAt } with millis, or null
//   days      0 = sessions never expire
//   enforce   false = other devices never refuse
// Returns { ok: true, record } to write, or { ok: false, refusal }.
function decide({ existing, deviceId, platform, now, days, enforce }) {
  const live = existing && (existing.expiresAt === null || existing.expiresAt > now);
  if (live && existing.deviceId !== deviceId && enforce) {
    return {
      ok: false,
      refusal: { code: "other_device", platform: existing.platform || "other", since: existing.startedAt || null },
    };
  }
  if (live && existing.deviceId === deviceId) {
    // The same device again: the month keeps counting from the first
    // sign-in, only the last-seen stamp moves.
    return { ok: true, record: { ...existing, platform, lastSeenAt: now } };
  }
  // No session, an expired one, or a takeover allowed by the console.
  return {
    ok: true,
    record: { deviceId, platform, startedAt: now, expiresAt: days > 0 ? now + days * DAY_MS : null, lastSeenAt: now },
  };
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
    platform: String(d.platform || "other"),
    startedAt: toMillis(d.startedAt),
    expiresAt: toMillis(d.expiresAt),
  };
}

function toDoc(record) {
  const ts = (ms) => (ms === null ? null : admin.firestore.Timestamp.fromMillis(ms));
  return {
    deviceId: record.deviceId,
    platform: record.platform,
    startedAt: ts(record.startedAt),
    expiresAt: ts(record.expiresAt),
    lastSeenAt: ts(record.lastSeenAt),
  };
}

async function knobs() {
  const params = await remoteFlags.params();
  return {
    days: remoteFlags.intFrom(params, "session_days", DEFAULT_DAYS),
    enforce: remoteFlags.intFrom(params, "ff_single_session", 2) === 2,
  };
}

async function claim(uid, request) {
  const db = admin.firestore();
  const ref = db.doc(`sessions/${uid}`);
  const { days, enforce } = await knobs();
  const now = Date.now();
  return db.runTransaction(async (tx) => {
    const existing = fromDoc(await tx.get(ref));
    const outcome = decide({ existing, deviceId: request.deviceId, platform: request.platform, now, days, enforce });
    if (outcome.ok) tx.set(ref, toDoc(outcome.record));
    return outcome;
  });
}

async function release(uid, request) {
  const db = admin.firestore();
  const ref = db.doc(`sessions/${uid}`);
  await db.runTransaction(async (tx) => {
    const existing = fromDoc(await tx.get(ref));
    // Another device's session is not this device's to free.
    if (existing && existing.deviceId !== request.deviceId) return;
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
      if (request.action === "claim") {
        const outcome = await claim(caller.uid, request);
        if (!outcome.ok) {
          logger.info("session refused", { uid: caller.uid, platform: outcome.refusal.platform });
          return res.status(200).json({ ok: false, refusal: outcome.refusal });
        }
        return res.status(200).json({ ok: true, startedAt: outcome.record.startedAt, expiresAt: outcome.record.expiresAt });
      }
      await release(caller.uid, request);
      return res.status(200).json({ ok: true });
    } catch (err) {
      logger.error("session action failed", { action: request.action, reason: err.message });
      return res.status(500).json({ error: { message: err.message } });
    }
  },
);

// Sessions past their month: the record goes and the refresh tokens are
// revoked, so the device's ID token stops renewing within the hour and the
// app's gate sends it back to sign in.
async function expire(now = Date.now()) {
  const db = admin.firestore();
  const due = await db.collection("sessions").where("expiresAt", "<=", admin.firestore.Timestamp.fromMillis(now)).limit(500).get();
  let count = 0;
  for (const doc of due.docs) {
    try {
      await admin.auth().revokeRefreshTokens(doc.id);
    } catch (err) {
      logger.warn("revoke failed", { uid: doc.id, reason: err.message });
    }
    await doc.ref.delete();
    count++;
  }
  return count;
}

exports.expireSessions = onSchedule(
  { schedule: "every day 04:10", timeZone: "Asia/Jerusalem", region: "europe-west1", retryCount: 1 },
  async () => {
    const count = await expire();
    logger.info("sessions expired", { count });
  },
);

exports.internals = { parseRequest, decide, DEFAULT_DAYS, DAY_MS, expire };
