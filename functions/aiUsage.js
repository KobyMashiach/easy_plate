// Token accounting for the administrator's dashboard. Every model call that
// passes through aiProxy or socialRecipe leaves three traces:
//
//   ai_calls/{auto}      one row per call — the audit trail
//   ai_daily/{YYYY-MM-DD} per-day totals, split by model and by user
//   ai_usage/{uid}        per-user all-time totals, split by model and kind
//
// The dashboard prices tokens itself from an editable table, so nothing here
// knows what a token costs — a price change in the app needs no redeploy.
// Writes are best effort and never delay the answer the user is waiting for.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");

const CALLS_COLLECTION = "ai_calls";
const DAILY_COLLECTION = "ai_daily";
const USAGE_COLLECTION = "ai_usage";

const FEATURE_HEADER = "x-easyplate-feature";
const SOURCE_KIND_HEADER = "x-easyplate-source-kind";

function num(value) {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function first(obj, keys) {
  for (const key of keys) {
    if (obj[key] !== undefined && obj[key] !== null) return obj[key];
  }
  return undefined;
}

/// Numeric leaves of `[{modality, tokens}]` lists, summed by modality.
function byModality(list) {
  const out = {};
  for (const item of Array.isArray(list) ? list : []) {
    if (!item || typeof item !== "object") continue;
    const modality = String(item.modality || "").toLowerCase();
    out[modality] = (out[modality] || 0) + num(Number(item.tokens));
  }
  return out;
}

/// The token counts of an answer, whichever endpoint produced it.
///
/// The Interactions API (`usage`) reports `total_input_tokens`,
/// `total_output_tokens`, `total_thought_tokens`, `total_cached_tokens`,
/// `total_tokens`, the output split by modality (image tokens are billed at
/// their own rate) and `grounding_tool_count` (each Google Search query is
/// billed on its own). generateContent reports `usageMetadata` in camelCase.
/// Unknown shapes yield zeros but keep the raw object, so a field that was
/// missed can still be read back later — which is how this list was built.
function extractUsage(data) {
  if (!data || typeof data !== "object") return null;
  const u = data.usage || data.usageMetadata || data.usage_metadata;
  if (!u || typeof u !== "object") return null;

  const input = num(
    Number(first(u, [
      "total_input_tokens",
      "input_tokens",
      "prompt_tokens",
      "promptTokenCount",
      "prompt_token_count",
    ])),
  );
  const output = num(
    Number(first(u, [
      "total_output_tokens",
      "output_tokens",
      "completion_tokens",
      "candidatesTokenCount",
      "candidates_token_count",
    ])),
  );
  const thoughts = num(
    Number(first(u, [
      "total_thought_tokens",
      "thoughts_tokens",
      "reasoning_tokens",
      "thoughtsTokenCount",
      "thoughts_token_count",
    ])),
  );
  const cached = num(
    Number(first(u, [
      "total_cached_tokens",
      "cached_tokens",
      "cached_content_tokens",
      "cachedContentTokenCount",
      "cached_content_token_count",
    ])),
  );
  let total = num(Number(first(u, ["total_tokens", "totalTokenCount", "total_token_count"])));
  if (!total) total = input + output + thoughts;

  const outputModalities = byModality(u.output_tokens_by_modality || u.candidatesTokensDetails);
  const imageOutput = num(outputModalities.image);

  let searches = 0;
  for (const tool of Array.isArray(u.grounding_tool_count) ? u.grounding_tool_count : []) {
    if (tool && typeof tool === "object") {
      searches += num(Number(tool.search_query_count ?? tool.count ?? 0));
    }
  }

  return { input, output, thoughts, cached, total, imageOutput, searches, raw: u };
}

/// What the call was for. The app names its feature in a header; older
/// builds do not, and then the cache kind or the request shape decides.
function kindOf({ headers = {}, body = null, fn = "aiProxy" } = {}) {
  const feature = headers[FEATURE_HEADER];
  if (typeof feature === "string" && /^[a-z_]{1,32}$/.test(feature)) return feature;
  if (fn === "socialRecipe") return "social_video";
  const sourceKind = headers[SOURCE_KIND_HEADER];
  if (typeof sourceKind === "string" && sourceKind) return sourceKind;
  if (body && Array.isArray(body.tools) && body.tools.length > 0) return "search";
  if (body && typeof body.model === "string" && body.model.includes("image")) return "image";
  return "text";
}

/// Firestore map keys may not contain dots, and model ids do.
function modelKey(model) {
  const m = typeof model === "string" && model.trim() ? model.trim() : "unknown";
  return m.replace(/[.~/*\[\]]/g, "_");
}

function utcDay(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

const EMPTY_USAGE = { input: 0, output: 0, thoughts: 0, cached: 0, total: 0, imageOutput: 0, searches: 0 };

function counters(usage, { calls = 1, cacheHits = 0, errors = 0 } = {}) {
  const inc = admin.firestore.FieldValue.increment;
  const u = usage || EMPTY_USAGE;
  return {
    calls: inc(calls),
    cacheHits: inc(cacheHits),
    errors: inc(errors),
    input: inc(u.input),
    output: inc(u.output),
    thoughts: inc(u.thoughts),
    cached: inc(u.cached),
    total: inc(u.total),
    imageOutput: inc(num(u.imageOutput)),
    searches: inc(num(u.searches)),
  };
}

/// The row's token fields from a usage object; shared with the repair.
function rowTokens(spent) {
  return {
    inputTokens: spent ? spent.input : 0,
    outputTokens: spent ? spent.output : 0,
    thoughtTokens: spent ? spent.thoughts : 0,
    cachedTokens: spent ? spent.cached : 0,
    totalTokens: spent ? spent.total : 0,
    imageOutputTokens: spent ? num(spent.imageOutput) : 0,
    searchQueries: spent ? num(spent.searches) : 0,
  };
}

/// The two aggregate documents one call contributes to, as set-merge data.
function aggregateWrites({ uid, kind, key, spent, tally, day, now }) {
  return {
    daily: {
      day,
      updatedAt: now,
      ...counters(spent, tally),
      models: { [key]: counters(spent, tally) },
      kinds: { [kind]: counters(spent, tally) },
      users: { [uid]: { ...counters(spent, tally), models: { [key]: counters(spent, tally) } } },
    },
    usage: {
      lastCallAt: now,
      totals: counters(spent, tally),
      models: { [key]: counters(spent, tally) },
      kinds: { [kind]: counters(spent, tally) },
    },
  };
}

/// Records one call. Never throws and is not awaited by the callers: the
/// user's answer goes out first, the bookkeeping lands a moment later.
function recordCall({ uid, fn, model, kind, status, ms, usage, cacheHit = false }) {
  const db = admin.firestore();
  const day = utcDay();
  const key = modelKey(model);
  const ok = status === 200;
  const spent = ok && !cacheHit ? usage : null;
  const tally = { cacheHits: cacheHit ? 1 : 0, errors: ok ? 0 : 1 };
  const now = admin.firestore.FieldValue.serverTimestamp();

  const row = {
    uid,
    fn,
    model: typeof model === "string" ? model : "",
    kind,
    status,
    ms: num(ms),
    cacheHit: !!cacheHit,
    ...rowTokens(spent),
    usage: spent && spent.raw ? spent.raw : null,
    day,
    at: now,
  };

  const writes = aggregateWrites({ uid, kind, key, spent, tally, day, now });
  const batch = db.batch();
  batch.set(db.collection(CALLS_COLLECTION).doc(), row);
  batch.set(db.collection(DAILY_COLLECTION).doc(day), writes.daily, { merge: true });
  batch.set(db.collection(USAGE_COLLECTION).doc(uid), writes.usage, { merge: true });

  return batch.commit().catch((err) => {
    logger.warn("ai usage record failed", { uid, fn, reason: err.message });
  });
}

/// Re-reads every stored call's raw `usage` with the current parser and
/// rebuilds the per-day and per-user totals from scratch. For the rows
/// written before the parser knew the Interactions API's field names;
/// harmless to run again. Reads every row, so it is a repair, not a habit.
async function repairUsage() {
  const db = admin.firestore();
  const calls = await db.collection(CALLS_COLLECTION).get();
  const daily = {};
  const usage = {};
  let rowsFixed = 0;
  let batch = db.batch();
  let pending = 0;
  const flush = async () => {
    if (pending === 0) return;
    await batch.commit();
    batch = db.batch();
    pending = 0;
  };

  for (const doc of calls.docs) {
    const row = doc.data();
    const ok = row.status === 200;
    const parsed = row.usage ? extractUsage({ usage: row.usage }) : null;
    const spent = ok && !row.cacheHit ? parsed : null;
    const tokens = rowTokens(spent);
    const changed = Object.keys(tokens).some((k) => num(row[k]) !== tokens[k]);
    if (changed) {
      batch.update(doc.ref, tokens);
      rowsFixed++;
      if (++pending === 400) await flush();
    }
    const day = row.day || utcDay(row.at && row.at.toDate ? row.at.toDate() : new Date());
    const key = modelKey(row.model);
    const kind = row.kind || "text";
    const tally = { cacheHits: row.cacheHit ? 1 : 0, errors: ok ? 0 : 1 };
    const plain = (u) => ({
      calls: 1,
      cacheHits: tally.cacheHits,
      errors: tally.errors,
      input: u ? u.input : 0,
      output: u ? u.output : 0,
      thoughts: u ? u.thoughts : 0,
      cached: u ? u.cached : 0,
      total: u ? u.total : 0,
      imageOutput: u ? num(u.imageOutput) : 0,
      searches: u ? num(u.searches) : 0,
    });
    const add = (target, u) => {
      const p = plain(u);
      for (const k of Object.keys(p)) target[k] = num(target[k]) + p[k];
      return target;
    };
    const d = (daily[day] = daily[day] || { day, models: {}, kinds: {}, users: {} });
    add(d, spent);
    add((d.models[key] = d.models[key] || {}), spent);
    add((d.kinds[kind] = d.kinds[kind] || {}), spent);
    const du = (d.users[row.uid] = d.users[row.uid] || { models: {} });
    add(du, spent);
    add((du.models[key] = du.models[key] || {}), spent);
    const u = (usage[row.uid] = usage[row.uid] || { totals: {}, models: {}, kinds: {}, lastCallAt: null });
    add(u.totals, spent);
    add((u.models[key] = u.models[key] || {}), spent);
    add((u.kinds[kind] = u.kinds[kind] || {}), spent);
    if (row.at && (!u.lastCallAt || row.at.toMillis() > u.lastCallAt.toMillis())) u.lastCallAt = row.at;
  }
  await flush();

  // Replace, not merge: a day's document must not keep counters from rows
  // that no longer exist. Days and users with no rows left are removed.
  const now = admin.firestore.FieldValue.serverTimestamp();
  const [oldDays, oldUsage] = await Promise.all([
    db.collection(DAILY_COLLECTION).get(),
    db.collection(USAGE_COLLECTION).get(),
  ]);
  for (const doc of oldDays.docs) {
    if (!daily[doc.id]) batch.delete(doc.ref);
    if (++pending === 400) await flush();
  }
  for (const [day, data] of Object.entries(daily)) {
    batch.set(db.collection(DAILY_COLLECTION).doc(day), { ...data, updatedAt: now });
    if (++pending === 400) await flush();
  }
  for (const doc of oldUsage.docs) {
    // ai_usage also holds the quota counter (day, count): keep it, drop the totals.
    const data = usage[doc.id];
    const quota = { day: doc.get("day") ?? null, count: doc.get("count") ?? 0, updatedAt: doc.get("updatedAt") ?? null };
    batch.set(doc.ref, data ? { ...quota, ...data } : quota);
    delete usage[doc.id];
    if (++pending === 400) await flush();
  }
  for (const [uid, data] of Object.entries(usage)) {
    batch.set(db.collection(USAGE_COLLECTION).doc(uid), data, { merge: true });
    if (++pending === 400) await flush();
  }
  await flush();
  logger.info("usage repaired", { rows: calls.size, rowsFixed, days: Object.keys(daily).length });
  return { rows: calls.size, rowsFixed, days: Object.keys(daily).length };
}

function safeJson(text) {
  try {
    return JSON.parse(text);
  } catch (err) {
    return null;
  }
}

module.exports = {
  extractUsage,
  repairUsage,
  kindOf,
  modelKey,
  recordCall,
  safeJson,
  utcDay,
  FEATURE_HEADER,
  CALLS_COLLECTION,
  DAILY_COLLECTION,
  USAGE_COLLECTION,
};
