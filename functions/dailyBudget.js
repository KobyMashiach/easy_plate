// Per-user daily budgets for the paid helpers that are not the Gemini proxy:
// translation lines, cloud-voice calls, image searches — and the shared
// price records, which cost nothing but shape what everyone sees. Each sits
// behind an endpoint any signed-in account may call in a loop, and only the
// server can say "enough for today".
//
// Same shape as aiProxy's quota: one document per user per kind,
// usage_budgets/{uid}_{kind}, holding the UTC day and the count for that day,
// claimed in a transaction before the paid call so a burst cannot slip past
// the check together. The limits are Remote Config parameters (console
// edits, no deploy), read through the cached template.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const remoteFlags = require("./remoteFlags");

const COLLECTION = "usage_budgets";

// The parameter each budget reads, and the number used when the console has
// none. `unit` names what is counted, for the refusal message.
const KINDS = Object.freeze({
  translate: { param: "quota_translate_lines_daily", fallback: 3000, unit: "translated lines" },
  // The cache lookups a translate request causes (translateContent.readCache:
  // one Firestore read per distinct line, up to 3000 a call). Only lines the
  // cache lacked cost translate units, so a loop of all-cached requests was
  // unbounded reads for free. Counted in lines looked up; wide enough for a
  // whole library on a first language switch (the finished variants are
  // stored per account, so a second switch asks for far less).
  translateCache: { param: "quota_translate_cache_reads_daily", fallback: 50000, unit: "translation lookups" },
  speak: { param: "quota_speak_calls_daily", fallback: 300, unit: "voice replies" },
  imageSearch: { param: "quota_image_search_daily", fallback: 150, unit: "image searches" },
  // Not a bill but the community's price medians: one account feeding
  // thousands of made-up prices a day would move them for everyone.
  priceRecords: { param: "quota_price_records_daily", fallback: 500, unit: "shared prices" },
  // Pushes for share invites a client wrote (index.js pushOnNotification):
  // per sender, and per sender and recipient. Not a bill: a ceiling on how
  // often one account can make other people's phones ring.
  invitePush: { param: "quota_invite_push_daily", fallback: 100, unit: "invite notifications" },
  invitePushPair: { param: "quota_invite_push_pair_daily", fallback: 10, unit: "invite notifications" },
  // Forum replies whose participants are told (index.js onForumReplyCreated):
  // each one writes an inbox item and rings a phone for up to every earlier
  // participant, and a reply is a client write nothing else limits.
  forumReplyFanout: { param: "quota_forum_reply_fanout_daily", fallback: 200, unit: "reply notifications" },
  // Edits of a community recipe whose savers are told (index.js
  // onSharedRecipeUpdated): each edit is an inbox item and a push for every
  // account that saved it, and an edit is a client write — a loop of
  // one-character edits rang every saver's phone each time.
  recipeUpdateFanout: { param: "quota_recipe_update_fanout_daily", fallback: 20, unit: "recipe update notifications" },
  // Answers served from the URL cache (aiProxy, socialRecipe). Free of model
  // tokens, but each one is a cache read, a hit-count write and four usage
  // writes, and it took no quota slot — a loop of the same cached link was
  // unbounded Firestore traffic. Far above what a person pastes in a day.
  aiCacheHits: { param: "quota_ai_cache_hits_daily", fallback: 200, unit: "cached recipe answers" },
  // socialRecipe links that turned out unreadable (private, blocked): the
  // model is never called, so the AI slot is given back — but only this
  // many times a day, since each one still ran a yt-dlp probe and page
  // fetches on our servers.
  socialProbe: { param: "quota_social_probe_daily", fallback: 15, unit: "unreadable video lookups" },
});

function utcDay(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function docId(uid, kind) {
  return `${uid}_${kind}`;
}

// Pure, like aiProxy.decideQuota, with an amount: a stored count applies to
// its own day only, and a request is allowed only when it fits in what is
// left of the day. It used to be enough for the count to be under the line
// before the request, so one request of any size could follow 2,999 lines
// and spend many days' worth at once. The first request of the day may use
// the whole allowance and no more (`firstMax`, the limit unless a caller
// bounds it lower).
function decide(stored, day, limit, amount = 1, { firstMax = limit } = {}) {
  const used = stored && stored.day === day ? Number(stored.count) || 0 : 0;
  const want = Math.max(1, Number(amount) || 0);
  if (limit <= 0 || used >= limit) return { allowed: false, used, limit };
  if (used + want <= limit || (used === 0 && want <= Math.min(firstMax, limit))) {
    return { allowed: true, used: used + want, limit };
  }
  return { allowed: false, used, limit, requested: want };
}

async function limitFor(kind) {
  const spec = KINDS[kind];
  if (!spec) throw new Error(`unknown budget kind ${kind}`);
  return remoteFlags.intFrom(await remoteFlags.params(), spec.param, spec.fallback);
}

// Counts `amount` against the budget before the paid call, inside a
// transaction. Returns the decision.
async function claim(db, { uid, kind, limit, amount = 1, day = utcDay() }) {
  const ref = db.collection(COLLECTION).doc(docId(uid, kind));
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const decision = decide(snap.exists ? snap.data() : null, day, limit, amount);
    if (decision.allowed) {
      tx.set(ref, { uid, kind, day, count: decision.used, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    }
    return decision;
  });
}

// Gives a claim back when the upstream failed: the user does not pay a
// day's budget for Google being down. Best effort, like aiProxy's refund.
async function refund(db, { uid, kind, amount = 1, day = utcDay() }) {
  try {
    const ref = db.collection(COLLECTION).doc(docId(uid, kind));
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists || snap.get("day") !== day) return;
      tx.update(ref, { count: Math.max(0, (Number(snap.get("count")) || 0) - amount) });
    });
  } catch (err) {
    logger.warn("budget refund failed", { uid, kind, reason: err.message });
  }
}

// The limit from the console, then the claim. What every endpoint calls.
async function spend({ uid, kind, amount = 1, db = admin.firestore() }) {
  const limit = await limitFor(kind);
  return claim(db, { uid, kind, limit, amount });
}

// The 429 body. `quota` is what the app's HttpCalls.errorTypeFor keys on to
// tell a spent allowance (do not retry) from an overloaded upstream (retry),
// so it has to be there whatever else the body says; `code: "quota"` is the
// name the other endpoints' refusals use.
function refusalBody(decision, kind) {
  const unit = (KINDS[kind] || {}).unit || "calls";
  return {
    error: {
      code: "quota",
      status: "RESOURCE_EXHAUSTED",
      message: decision.requested
        ? `This request needs ${decision.requested} ${unit}; ${Math.max(0, decision.limit - decision.used)} of today's ${decision.limit} are left`
        : `Daily limit of ${decision.limit} ${unit} reached`,
      quota: { used: decision.used, limit: decision.limit, kind, ...(decision.requested ? { requested: decision.requested } : {}) },
    },
  };
}

// The refusal as an error, for code paths that are deep inside a helper
// (imageSearch.search's cache-miss hook) and can only throw.
function exhausted(decision, kind) {
  const error = new Error(`daily ${kind} budget reached`);
  error.status = 429;
  error.code = "quota";
  error.body = refusalBody(decision, kind);
  return error;
}

module.exports = { COLLECTION, KINDS, utcDay, docId, decide, limitFor, claim, refund, spend, refusalBody, exhausted };
