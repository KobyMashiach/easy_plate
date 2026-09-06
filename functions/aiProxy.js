// The Gemini proxy. This exists for one reason: a key compiled into a mobile
// binary is extractable with `strings`, so the app must never hold one. The key
// lives in Cloud Secret Manager and is attached to this function at runtime.
//
// The app talks to this function exactly as it talked to Google — same path,
// same request body, same response shape — so nothing in the ingestion pipeline
// changed. Only the base URL and the auth header did.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const GOOGLE_ORIGIN = "https://generativelanguage.googleapis.com";

// The one path the app uses. Anything else is refused rather than forwarded,
// so a stolen ID token cannot turn this into an open Gemini relay.
const ALLOWED_PATH = "/v1beta/interactions";

// Requests larger than this are refused before they reach Google. The app's
// biggest body is a pasted recipe plus a schema, which is nowhere near this.
const MAX_BODY_BYTES = 512 * 1024;

// Calls per user per UTC day. This is the whole point of owning the proxy: an
// authenticated user can still burn money in a loop, and only the server can
// say no. When entitlements land, this becomes a lookup rather than a constant.
const FREE_DAILY_CALLS = 30;

function dailyLimitForUser(_uid) {
  // Premium and trial will raise this. Deliberately not reading an entitlement
  // document yet — there is nothing to read until RevenueCat is wired, and an
  // unconditional read would cost a Firestore op per AI call for no answer.
  return FREE_DAILY_CALLS;
}

function utcDay() {
  return new Date().toISOString().slice(0, 10);
}

async function verifyCaller(req) {
  const header = req.get("authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) return null;
  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch (err) {
    logger.warn("rejected an ID token", { reason: err.code || err.message });
    return null;
  }
}

/// The quota decision, with no Firestore in it. A stored count only applies to
/// the day it was written, so a document from yesterday starts over at zero
/// rather than locking the user out until they happen to make no calls.
function decideQuota(stored, day, limit) {
  const used = stored && stored.day === day ? stored.count || 0 : 0;
  if (used >= limit) return { allowed: false, used, limit };
  return { allowed: true, used: used + 1, limit };
}

/// Counts the call before forwarding it. Counting afterwards would let a burst
/// of parallel requests all pass the check before any of them recorded a use.
async function claimQuotaSlot(uid, limit) {
  const ref = admin.firestore().doc(`ai_usage/${uid}`);
  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const day = utcDay();
    const decision = decideQuota(snap.exists ? snap.data() : null, day, limit);

    if (!decision.allowed) return decision;

    tx.set(ref, {
      day,
      count: decision.used,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return decision;
  });
}

/// Gives a slot back when Google itself failed. The user should not pay a day's
/// quota for our upstream being down. Best effort: if this write loses a race
/// the worst case is one over-counted call.
async function refundQuotaSlot(uid) {
  try {
    const ref = admin.firestore().doc(`ai_usage/${uid}`);
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const data = snap.data();
      if (data.day !== utcDay() || !data.count) return;
      tx.update(ref, { count: data.count - 1 });
    });
  } catch (err) {
    logger.warn("quota refund failed", { uid, reason: err.message });
  }
}

exports.aiProxy = onRequest(
  {
    secrets: [geminiApiKey],
    // The app caps an analysis at 30s and gives the socket 120s. Matching the
    // socket keeps a slow model from being cut off here first.
    timeoutSeconds: 120,
    memory: "256MiB",
    // Bounded so a burst cannot fan out into an unbounded Gemini bill.
    maxInstances: 10,
    cors: false,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: { message: "Method not allowed" } });
    }

    // req.path is the part after the function name, which is what the app
    // appends to its base URL.
    if (req.path !== ALLOWED_PATH) {
      return res.status(404).json({ error: { message: "Unknown path" } });
    }

    const caller = await verifyCaller(req);
    if (!caller) {
      return res
        .status(401)
        .json({ error: { message: "A valid Firebase ID token is required" } });
    }

    const body = JSON.stringify(req.body ?? {});
    if (Buffer.byteLength(body, "utf8") > MAX_BODY_BYTES) {
      return res.status(413).json({ error: { message: "Request too large" } });
    }

    const uid = caller.uid;
    const limit = dailyLimitForUser(uid);

    let slot;
    try {
      slot = await claimQuotaSlot(uid, limit);
    } catch (err) {
      logger.error("quota check failed", { uid, reason: err.message });
      return res.status(503).json({ error: { message: "Try again shortly" } });
    }

    if (!slot.allowed) {
      logger.info("quota exhausted", { uid, limit });
      // 429 is what the app already reads as "overloaded"; the body carries the
      // detail so a quota screen can tell the two apart later.
      return res.status(429).json({
        error: {
          status: "RESOURCE_EXHAUSTED",
          message: `Daily limit of ${limit} AI requests reached`,
          quota: { used: slot.used, limit },
        },
      });
    }

    try {
      const upstream = await fetch(`${GOOGLE_ORIGIN}${ALLOWED_PATH}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": geminiApiKey.value(),
        },
        body,
      });

      const text = await upstream.text();

      if (upstream.status >= 500) {
        await refundQuotaSlot(uid);
      }

      logger.info("proxied", {
        uid,
        status: upstream.status,
        used: slot.used,
        limit,
      });

      return res
        .status(upstream.status)
        .set("Content-Type", upstream.headers.get("content-type") || "application/json")
        .send(text);
    } catch (err) {
      await refundQuotaSlot(uid);
      logger.error("upstream call failed", { uid, reason: err.message });
      return res.status(502).json({ error: { message: "Upstream request failed" } });
    }
  },
);

// Exported for the unit test. The transaction body is the part worth pinning:
// a mistake here either gives away unlimited AI or locks everyone out.
exports.internals = {
  decideQuota,
  utcDay,
  dailyLimitForUser,
  ALLOWED_PATH,
  MAX_BODY_BYTES,
  FREE_DAILY_CALLS,
};
