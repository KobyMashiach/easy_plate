// The Gemini proxy. This exists for one reason: a key compiled into a mobile
// binary is extractable with `strings`, so the app must never hold one. The key
// lives in Cloud Secret Manager and is attached to this function at runtime.
//
// The app talks to this function exactly as it talked to Google — same path,
// same request body, same response shape — so nothing in the ingestion pipeline
// changed. Only the base URL and the auth header did.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineInt } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

// The proxy's sizing, owned by Remote Config rather than by this file. These
// three are deploy-time properties of the function, so they cannot be read per
// request; scripts/syncRuntimeOptions.js copies the console's `gemini_*`
// parameters into .env.<project> before each deploy and these params resolve
// from there. The defaults below are what a deploy falls back to when that
// sync could not reach the console.
const minInstances = defineInt("GEMINI_MIN_INSTANCES", { default: 1 });
const maxInstances = defineInt("GEMINI_MAX_INSTANCES", { default: 10 });
const timeoutSeconds = defineInt("GEMINI_TIMEOUT_SECONDS", { default: 120 });

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

// ---------------------------------------------------------------------------
// The URL cache. A recipe page does not change between two people pasting
// it, and the model call is the one thing in here that costs money — so a
// link that has been extracted before is answered from Firestore, for free,
// without touching the quota. The app names the link in two headers (see
// GeminiRecipeAiDataSource.sourceUrlHeaders); the prompt itself is still in
// the body, and the response goes back byte-for-byte as Gemini sent it, so
// the app cannot tell a hit from a miss except by the `x-easyplate-cache`
// header.
// ---------------------------------------------------------------------------

const CACHE_COLLECTION = "ai_url_cache";
const SOURCE_URL_HEADER = "x-easyplate-source-url";
const SOURCE_KIND_HEADER = "x-easyplate-source-kind";
const CACHE_KINDS = new Set(["url", "social"]);

// Half a year. Recipes are edited rarely; the odd stale one is the price of
// never paying twice for the same page.
const CACHE_TTL_MS = 180 * 24 * 60 * 60 * 1000;

// Query parameters that identify the *visit*, not the page. Stripped so a
// TikTok link shared from two phones, each with its own tracking tail, is
// the same recipe.
const TRACKING_PARAMS = new Set([
  "fbclid", "gclid", "dclid", "msclkid", "mc_cid", "mc_eid", "yclid",
  "igsh", "igshid", "ig_rid",
  "si", "feature",
  "_t", "_r", "_d", "is_from_webapp", "is_copy_url", "sender_device",
  "sender_web_id", "web_id", "share_app_id", "share_item_id", "share_link_id",
  "ref", "ref_src", "ref_url", "source", "s", "sfnsn", "mibextid",
]);

/// The canonical form of a link, or null when it is not an http(s) URL.
///
/// Scheme and host are case-folded, a leading `www.` and the default port go,
/// the fragment goes, the tracking parameters above go, the rest are sorted,
/// and a trailing slash is dropped from any path but the root.
function normalizeSourceUrl(raw) {
  if (typeof raw !== "string") return null;
  let url;
  try {
    url = new URL(raw.trim());
  } catch (err) {
    return null;
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return null;

  let host = url.hostname.toLowerCase();
  if (host.startsWith("www.")) host = host.slice(4);

  const kept = [];
  for (const [key, value] of url.searchParams) {
    if (key.startsWith("utm_") || TRACKING_PARAMS.has(key)) continue;
    kept.push([key, value]);
  }
  kept.sort(([a, av], [b, bv]) => (a < b ? -1 : a > b ? 1 : av < bv ? -1 : av > bv ? 1 : 0));
  const query = new URLSearchParams(kept).toString();

  let path = url.pathname || "/";
  if (path.length > 1 && path.endsWith("/")) path = path.slice(0, -1);

  const port = url.port ? `:${url.port}` : "";
  return `${url.protocol}//${host}${port}${path}${query ? `?${query}` : ""}`;
}

function cacheKeyFor(kind, normalizedUrl) {
  return crypto.createHash("sha256").update(`${kind}\n${normalizedUrl}`).digest("hex");
}

/// What this request wants cached, or null when it is not a link extraction.
///
/// The URL named in the header has to appear in the body: the header is what
/// the cache is keyed on, and without that check a client could send the
/// prompt for page A under the header for page B and poison B's entry.
function cacheRequestFor(headers, body) {
  const raw = headers[SOURCE_URL_HEADER];
  const kind = headers[SOURCE_KIND_HEADER];
  if (typeof raw !== "string" || !CACHE_KINDS.has(kind)) return null;
  if (typeof body !== "string" || !body.includes(raw.trim())) return null;
  const normalizedUrl = normalizeSourceUrl(raw);
  if (!normalizedUrl) return null;
  return { kind, url: raw.trim(), normalizedUrl, key: cacheKeyFor(kind, normalizedUrl) };
}

/// The recipe inside a Gemini Interactions response, or null when the body
/// holds no usable one — a refusal, an empty page, a malformed answer. Only a
/// real recipe is worth remembering; caching a "nothing found" would serve
/// that failure to everyone who pastes the link later.
function extractedRecipe(responseText) {
  let data;
  try {
    data = JSON.parse(responseText);
  } catch (err) {
    return null;
  }
  let text = "";
  for (const step of Array.isArray(data?.steps) ? data.steps : []) {
    for (const block of Array.isArray(step?.content) ? step.content : []) {
      if (typeof block?.text === "string") text += block.text;
    }
  }
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) return null;
  let recipe;
  try {
    recipe = JSON.parse(text.slice(start, end + 1));
  } catch (err) {
    return null;
  }
  if (typeof recipe?.title !== "string" || !recipe.title.trim()) return null;
  const ingredients = Array.isArray(recipe.ingredients) ? recipe.ingredients : [];
  const steps = Array.isArray(recipe.steps) ? recipe.steps : [];
  if (ingredients.length === 0 && steps.length === 0) return null;
  return recipe;
}

function isFresh(createdAt, now) {
  const created = createdAt && typeof createdAt.toMillis === "function" ? createdAt.toMillis() : null;
  return created !== null && now - created < CACHE_TTL_MS;
}

async function readCache(entry) {
  try {
    const snap = await admin.firestore().doc(`${CACHE_COLLECTION}/${entry.key}`).get();
    if (!snap.exists) return null;
    const data = snap.data();
    if (!isFresh(data.createdAt, Date.now()) || typeof data.body !== "string") return null;
    return data;
  } catch (err) {
    logger.warn("url cache read failed", { key: entry.key, reason: err.message });
    return null;
  }
}

async function writeCache(entry, body, contentType, model) {
  try {
    await admin.firestore().doc(`${CACHE_COLLECTION}/${entry.key}`).set({
      kind: entry.kind,
      url: entry.url,
      normalizedUrl: entry.normalizedUrl,
      body,
      contentType,
      model: typeof model === "string" ? model : null,
      hits: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastHitAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    logger.warn("url cache write failed", { key: entry.key, reason: err.message });
  }
}

function countHit(entry) {
  admin
    .firestore()
    .doc(`${CACHE_COLLECTION}/${entry.key}`)
    .update({
      hits: admin.firestore.FieldValue.increment(1),
      lastHitAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    .catch((err) => logger.warn("url cache hit count failed", { reason: err.message }));
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
    // Close to the users. Every call from an Israeli phone used to cross to
    // Iowa and back before Gemini was even reached. Note this is only the HTTP
    // proxy — pushOnNotification is a Firestore trigger and has to stay in the
    // database's own region.
    region: "europe-west1",
    // The app caps an analysis at 45s and gives the socket 120s, so the console
    // value wants to stay at or above that or a slow model gets cut off here
    // first.
    timeoutSeconds,
    memory: "256MiB",
    // Warm instances. A cold start plus the secret mount costs several seconds
    // on the one request the user is actually watching, and with few users the
    // function was idle between almost every call — so this is normally 1, and
    // billed as idle time. Set gemini_minInstances to 0 in the console (and
    // redeploy) to stop that charge and accept the cold starts again.
    minInstances,
    // Bounded so a burst cannot fan out into an unbounded Gemini bill.
    maxInstances,
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

    // A link already extracted is answered here, for nothing: no model call,
    // no quota slot. The app still shows its rewarded video for it — that is
    // the app's business, and its daily count is the app's to keep.
    const cacheEntry = cacheRequestFor(req.headers, body);
    if (cacheEntry) {
      const cached = await readCache(cacheEntry);
      if (cached) {
        countHit(cacheEntry);
        logger.info("url cache hit", { uid, kind: cacheEntry.kind, key: cacheEntry.key });
        return res
          .status(200)
          .set("Content-Type", cached.contentType || "application/json")
          .set("x-easyplate-cache", "hit")
          .send(cached.body);
      }
    }

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

      const contentType = upstream.headers.get("content-type") || "application/json";

      // Remembered only when the answer holds a recipe; a 200 that says
      // "nothing here" is not worth serving to the next person.
      if (cacheEntry && upstream.status === 200 && extractedRecipe(text)) {
        await writeCache(cacheEntry, text, contentType, req.body?.model);
      }

      logger.info("proxied", {
        uid,
        status: upstream.status,
        used: slot.used,
        limit,
        cache: cacheEntry ? "miss" : "n/a",
      });

      return res
        .status(upstream.status)
        .set("Content-Type", contentType)
        .set("x-easyplate-cache", cacheEntry ? "miss" : "none")
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
  normalizeSourceUrl,
  cacheKeyFor,
  cacheRequestFor,
  extractedRecipe,
  isFresh,
  ALLOWED_PATH,
  MAX_BODY_BYTES,
  FREE_DAILY_CALLS,
  CACHE_COLLECTION,
  CACHE_TTL_MS,
  SOURCE_URL_HEADER,
  SOURCE_KIND_HEADER,
};
