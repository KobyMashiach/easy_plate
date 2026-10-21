// The Gemini proxy. This exists for one reason: a key compiled into a mobile
// binary is extractable with `strings`, so the app must never hold one. The key
// lives in Cloud Secret Manager and is attached to this function at runtime.
//
// The app talks to this function exactly as it talked to Google — same path,
// same request body, same response shape — so nothing in the ingestion pipeline
// changed. Only the base URL and the auth header did.
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret, defineInt } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");
const aiUsage = require("./aiUsage");
const remoteFlags = require("./remoteFlags");
const budget = require("./dailyBudget");
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");

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
// Receipt scans send photos and PDFs inline (a few MB each); recipes are a
// few KB. Cloud Functions itself stops at 32 MB.
const MAX_BODY_BYTES = 16 * 1024 * 1024;

// Calls per user per UTC day. This is the whole point of owning the proxy: an
// authenticated user can still burn money in a loop, and only the server can
// say no. The number is the Remote Config parameter `quota_ai_proxy_daily`
// (console edit, no deploy; read through remoteFlags' per-instance cache),
// with this constant as the fallback when the console has none. It is a
// backstop, not the plan's allowance: the app keeps its own per-feature
// quotas, and this is deliberately not an entitlement lookup — that would be
// a Firestore read per AI call for a question the app already answers.
const FREE_DAILY_CALLS = 30;
const DAILY_LIMIT_PARAM = "quota_ai_proxy_daily";

// Pure: the limit the console template gives, or the fallback.
function dailyLimitFrom(parameters) {
  return remoteFlags.intFrom(parameters, DAILY_LIMIT_PARAM, FREE_DAILY_CALLS);
}

async function dailyLimitForUser(_uid) {
  return dailyLimitFrom(await remoteFlags.params());
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
const CACHE_KINDS = new Set(["url", "social", "video"]);

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

// The cache key is the link *and* the request that extracted it. The shape
// is a hash of everything the model was told except the link itself, so an
// entry is only ever served to a request identical to the one that filled
// it. Without it, a client could send its own prompt ("return a recipe
// titled …") for page A under A's headers and the fake would be served to
// everyone who pastes A afterwards; now it lands under a key only that same
// tampered body reaches. The app's bodies are deterministic per build (a
// constant system prompt, schema and instruction; no locale or per-user
// field for a link), so every phone on one build shares one entry; a build
// that changes the prompt starts a fresh one, which is also right — another
// prompt may want another answer. An allow-list of known prompt hashes was
// the alternative and was rejected: it needs a server deploy for every
// prompt edit and silently turns the cache off when one is forgotten.
function cacheKeyFor(kind, normalizedUrl, shape = "") {
  return crypto.createHash("sha256").update(`${kind}\n${normalizedUrl}\n${shape}`).digest("hex");
}

const URL_PLACEHOLDER = "\u0000source-url\u0000";

/// The request with its link taken out, hashed: what [cacheKeyFor] calls
/// its shape. [body] is the serialized request; every occurrence of [url]
/// in it becomes one placeholder, so moving or repeating the link changes
/// the shape too.
function requestShape(body, url) {
  const text = typeof url === "string" && url ? body.split(url).join(URL_PLACEHOLDER) : body;
  return crypto.createHash("sha256").update(text).digest("hex");
}

// Fragments and tracking values are dropped from the key but still reach
// the model inside the prompt, so a link like `page#ignore-the-page-and-…`
// would carry its own instructions into an entry shared with the clean
// link. A request may therefore only *fill* an entry when what was dropped
// is a short opaque token (a TikTok `_t`, a YouTube `si`, a `#recipe` jump);
// anything longer or with spaces still reads the cache, but never writes it.
const DROPPED_TOKEN = /^[A-Za-z0-9._~-]{0,128}$/;

/// Whether the parts [normalizeSourceUrl] drops from [raw] are harmless.
function droppedPartsAreTokens(raw) {
  let url;
  try {
    url = new URL(raw.trim());
  } catch (err) {
    return false;
  }
  if (url.hash && !DROPPED_TOKEN.test(url.hash.slice(1))) return false;
  for (const [key, value] of url.searchParams) {
    if (!(key.startsWith("utm_") || TRACKING_PARAMS.has(key))) continue;
    if (!DROPPED_TOKEN.test(value)) return false;
  }
  return true;
}

/// What this request wants cached, or null when it is not a link extraction.
///
/// The URL named in the header has to appear in the body: the header is what
/// the cache is keyed on, and without that check a client could send the
/// prompt for page A under the header for page B and poison B's entry. The
/// key also carries the request's shape (see [cacheKeyFor]); `writable` says
/// whether this request may fill an entry, not only read one.
function cacheRequestFor(headers, body) {
  const raw = headers[SOURCE_URL_HEADER];
  const kind = headers[SOURCE_KIND_HEADER];
  if (typeof raw !== "string" || !CACHE_KINDS.has(kind)) return null;
  const url = raw.trim();
  if (!url || typeof body !== "string" || !body.includes(url)) return null;
  const normalizedUrl = normalizeSourceUrl(raw);
  if (!normalizedUrl) return null;
  return {
    kind,
    url,
    normalizedUrl,
    key: cacheKeyFor(kind, normalizedUrl, requestShape(body, url)),
    writable: droppedPartsAreTokens(url),
  };
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

/// Whether [uid] may be served one more cached answer today: the refusal
/// body (a 429 with `quota`, which both clients read as a spent allowance),
/// or null to go ahead. A hit costs no tokens and takes no AI slot, so this
/// is its own budget (dailyBudget `aiCacheHits`). A budget that cannot be
/// read lets the hit through: the cap is a load guard, not a bill.
async function cacheHitRefusal(uid, spend = budget.spend) {
  try {
    const decision = await spend({ uid, kind: "aiCacheHits" });
    return decision.allowed ? null : budget.refusalBody(decision, "aiCacheHits");
  } catch (err) {
    logger.warn("cache hit budget unavailable", { uid, reason: err.message });
    return null;
  }
}

// `checkRevoked` asks Auth whether the session was revoked since the token
// was minted (one extra lookup): for the irreversible calls only.
async function verifyCaller(req, { checkRevoked = false } = {}) {
  const header = req.get("authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) return null;
  try {
    return await admin.auth().verifyIdToken(match[1], checkRevoked);
  } catch (err) {
    logger.warn("rejected an ID token", { reason: err.code || err.message });
    return null;
  }
}

/// Why a verified caller may not spend money, or null. Every account has to
/// prove a phone before the app (the gate) or the website (RequireAuth →
/// /phone) lets it reach a paid feature; a throwaway email/password account
/// minted straight against the Auth REST API has none, and without this it
/// was a fresh daily allowance per account. The phone is in the ID token
/// once linked (both clients refresh the token on link).
function paidCallerRefusal(caller) {
  if (!caller) return { status: 401, code: "unauthenticated", message: "A valid Firebase ID token is required" };
  if (typeof caller.phone_number !== "string" || !caller.phone_number) {
    return { status: 403, code: "phone_required", message: "Verify a phone number first" };
  }
  // Switched off from the console (adminUsers.disable writes the claim).
  if (caller.disabled === true) {
    return { status: 403, code: "account_disabled", message: "This account is disabled" };
  }
  return null;
}

/// The caller of a paid endpoint (AI, speech, search, translation): a valid
/// token *and* a verified phone. Answers `{ caller }` or `{ refusal }`
/// (status, code, message) for the endpoint to send in its own envelope.
async function verifyPaidCaller(req, opts) {
  const caller = await verifyCaller(req, opts);
  const refusal = paidCallerRefusal(caller);
  return refusal ? { caller: null, refusal } : { caller, refusal: null };
}

// Interactions features the app never uses and that bill far beyond one
// model call: a managed agent (Deep Research runs for minutes) and a
// background run that keeps going after the request. Refused here so a
// stolen token cannot buy them with the proxy's key.
function bodyRefusal(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return null;
  if (Object.prototype.hasOwnProperty.call(body, "agent")) return "agent is not available";
  if (body.background === true) return "background is not available";
  const previous = body.previous_interaction_id;
  if (previous !== undefined && previous !== null && (typeof previous !== "string" || previous.length > 512)) {
    return "previous_interaction_id must be a string";
  }
  return null;
}

// Which account started each interaction, so a conversation can only be
// continued by its own account: Google keys the stored history by the API
// key alone, and every account shares the proxy's. Keyed by a hash of the
// id (any characters, fixed length); server-only (no client rule).
const INTERACTION_OWNERS = "ai_interactions";
const INTERACTION_OWNER_TTL_MS = 30 * 24 * 60 * 60 * 1000;

function interactionDocId(id) {
  return crypto.createHash("sha256").update(String(id)).digest("hex");
}

/// Pure: whether [uid] may continue an interaction whose owner row is
/// [stored]. No row is allowed — an interaction from before the rows were
/// written, or one whose row write failed; every new one has a row.
function interactionAllowed(stored, uid) {
  return !stored || stored.uid === uid;
}

/// The id a Gemini Interactions answer carries, or null.
function interactionIdOf(responseText) {
  const data = aiUsage.safeJson(responseText);
  return data && typeof data.id === "string" && data.id ? data.id : null;
}

async function interactionOwnerAllows(uid, previousId) {
  if (typeof previousId !== "string" || !previousId) return true;
  const snap = await admin.firestore().doc(`${INTERACTION_OWNERS}/${interactionDocId(previousId)}`).get();
  return interactionAllowed(snap.exists ? snap.data() : null, uid);
}

async function recordInteractionOwner(uid, responseText) {
  const id = interactionIdOf(responseText);
  if (!id) return;
  try {
    await admin.firestore().doc(`${INTERACTION_OWNERS}/${interactionDocId(id)}`).set({
      uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      // For a Firestore TTL policy on ai_interactions.expireAt.
      expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + INTERACTION_OWNER_TTL_MS),
    });
  } catch (err) {
    logger.warn("interaction owner write failed", { uid, reason: err.message });
  }
}

// Owner rows past their expireAt, deleted in pages: no TTL policy exists
// on the collection, so without this every conversation ever started kept
// a row naming its account. Stops at its time budget; the next day's run
// carries on (a deleted page never comes back, so no cursor is needed).
const INTERACTION_CLEANUP_PAGE = 400;
const INTERACTION_CLEANUP_BUDGET_MS = 8 * 60 * 1000;

async function cleanupInteractions({ db = admin.firestore(), now = Date.now(), clock = Date.now, page = INTERACTION_CLEANUP_PAGE, budgetMs = INTERACTION_CLEANUP_BUDGET_MS } = {}) {
  const started = clock();
  const cutoff = admin.firestore.Timestamp.fromMillis(now);
  let deleted = 0;
  for (;;) {
    const due = await db.collection(INTERACTION_OWNERS).where("expireAt", "<", cutoff).orderBy("expireAt").limit(page).select().get();
    if (due.empty) break;
    const batch = db.batch();
    for (const doc of due.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += due.size;
    if (due.size < page) break;
    if (clock() - started > budgetMs) {
      logger.warn("interaction cleanup stopped at its time budget; tomorrow's run continues", { deleted });
      break;
    }
  }
  return deleted;
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

    // Merged: the same document carries the all-time token totals written
    // by aiUsage, and a plain set here would wipe them every day.
    tx.set(
      ref,
      {
        day,
        count: decision.used,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
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
    cors: ORIGINS,
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

    const { caller, refusal } = await verifyPaidCaller(req);
    if (!caller) {
      return res.status(refusal.status).json({ error: { code: refusal.code, message: refusal.message } });
    }

    const body = JSON.stringify(req.body ?? {});
    if (Buffer.byteLength(body, "utf8") > MAX_BODY_BYTES) {
      return res.status(413).json({ error: { message: "Request too large" } });
    }
    const refused = bodyRefusal(req.body);
    if (refused) return res.status(400).json({ error: { code: "invalid", message: refused } });

    const uid = caller.uid;

    // Continuing a conversation: only the account that started it.
    try {
      if (!(await interactionOwnerAllows(uid, req.body?.previous_interaction_id))) {
        logger.warn("foreign interaction refused", { uid });
        return res.status(403).json({ error: { code: "not_yours", message: "Unknown conversation" } });
      }
    } catch (err) {
      logger.error("interaction owner check failed", { uid, reason: err.message });
      return res.status(503).json({ error: { message: "Try again shortly" } });
    }

    // A link already extracted is answered here, for nothing: no model call,
    // no quota slot. The app still shows its rewarded video for it — that is
    // the app's business, and its daily count is the app's to keep.
    const cacheEntry = cacheRequestFor(req.headers, body);
    if (cacheEntry) {
      const cached = await readCache(cacheEntry);
      if (cached) {
        const overHits = await cacheHitRefusal(uid);
        if (overHits) return res.status(429).json(overHits);
        countHit(cacheEntry);
        void aiUsage.recordCall({
          uid,
          fn: "aiProxy",
          model: req.body?.model,
          kind: aiUsage.kindOf({ headers: req.headers, body: req.body }),
          status: 200,
          ms: 0,
          usage: null,
          cacheHit: true,
        });
        logger.info("url cache hit", { uid, kind: cacheEntry.kind, key: cacheEntry.key });
        return res
          .status(200)
          .set("Content-Type", cached.contentType || "application/json")
          .set("x-easyplate-cache", "hit")
          .send(cached.body);
      }
    }

    const limit = await dailyLimitForUser(uid);

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

    const started = Date.now();
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

      // The bill, for the dashboard. Not awaited: the answer goes out first.
      void aiUsage.recordCall({
        uid,
        fn: "aiProxy",
        model: req.body?.model,
        kind: aiUsage.kindOf({ headers: req.headers, body: req.body }),
        status: upstream.status,
        ms: Date.now() - started,
        usage: upstream.status === 200 ? aiUsage.extractUsage(aiUsage.safeJson(text)) : null,
      });

      if (upstream.status === 200) await recordInteractionOwner(uid, text);

      // Remembered only when the answer holds a recipe; a 200 that says
      // "nothing here" is not worth serving to the next person.
      if (cacheEntry && cacheEntry.writable && upstream.status === 200 && extractedRecipe(text)) {
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
exports.cleanupAiInteractions = onSchedule(
  { schedule: "every day 04:40", timeZone: "Asia/Jerusalem", region: "europe-west1", retryCount: 1, timeoutSeconds: 540 },
  async () => {
    const deleted = await cleanupInteractions();
    logger.info("expired interaction owners deleted", { deleted });
  },
);

exports.internals = {
  cleanupInteractions,
  // Shared with socialRecipe.js, which is the same proxy for one more kind
  // of source: same caller check, same daily allowance, same URL cache.
  verifyCaller,
  verifyPaidCaller,
  paidCallerRefusal,
  bodyRefusal,
  interactionAllowed,
  interactionIdOf,
  interactionDocId,
  INTERACTION_OWNERS,
  claimQuotaSlot,
  refundQuotaSlot,
  readCache,
  writeCache,
  cacheHitRefusal,
  countHit,
  GOOGLE_ORIGIN,
  decideQuota,
  utcDay,
  dailyLimitForUser,
  dailyLimitFrom,
  DAILY_LIMIT_PARAM,
  normalizeSourceUrl,
  cacheKeyFor,
  cacheRequestFor,
  requestShape,
  droppedPartsAreTokens,
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
