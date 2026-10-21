const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { extractUsage, kindOf, modelKey } = require("./aiUsage");

test("reads the Interactions API usage block", () => {
  const u = extractUsage({
    usage: { input_tokens: 1200, output_tokens: 300, thoughts_tokens: 50, total_tokens: 1550 },
  });
  assert.deepEqual(
    { input: u.input, output: u.output, thoughts: u.thoughts, cached: u.cached, total: u.total },
    { input: 1200, output: 300, thoughts: 50, cached: 0, total: 1550 },
  );
  assert.equal(u.raw.input_tokens, 1200);
});

test("reads generateContent usageMetadata", () => {
  const u = extractUsage({
    usageMetadata: {
      promptTokenCount: 9000,
      candidatesTokenCount: 400,
      thoughtsTokenCount: 120,
      cachedContentTokenCount: 800,
      totalTokenCount: 9520,
    },
  });
  assert.equal(u.input, 9000);
  assert.equal(u.output, 400);
  assert.equal(u.thoughts, 120);
  assert.equal(u.cached, 800);
  assert.equal(u.total, 9520);
});

test("reads the Interactions API as it really answers", () => {
  const u = extractUsage({
    usage: {
      total_input_tokens: 133,
      total_output_tokens: 1567,
      total_thought_tokens: 0,
      total_cached_tokens: 0,
      total_tokens: 1700,
      total_tool_use_tokens: 0,
      input_tokens_by_modality: [{ modality: "text", tokens: 133 }],
      output_tokens_by_modality: [{ modality: "image", tokens: 1120 }],
      raw_prompt_token: 575,
      model_invocation_token_counts: [
        { prompt_tokens_details: [{ modality: "text", tokens: 575 }], candidates_tokens_details: [{ modality: "text", tokens: 449 }] },
      ],
      grounding_tool_count: [{ type: "google_search", count: 2, search_query_count: 2 }],
    },
  });
  assert.equal(u.input, 133);
  assert.equal(u.output, 1567);
  assert.equal(u.total, 1700);
  assert.equal(u.imageOutput, 1120);
  assert.equal(u.searches, 2);
});

test("a missing total is the sum of the parts", () => {
  const u = extractUsage({ usage: { input_tokens: 10, output_tokens: 5 } });
  assert.equal(u.total, 15);
});

test("an answer without usage yields null, not zeros", () => {
  assert.equal(extractUsage({ steps: [] }), null);
  assert.equal(extractUsage(null), null);
  assert.equal(extractUsage("text"), null);
});

test("the feature header names the kind", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-feature": "receipt" } }), "receipt");
});

test("a bad feature header is ignored", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-feature": "<script>" }, body: {} }), "other");
});

test("without a feature header the cache kind, tools or model decide", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-source-kind": "url" } }), "url");
  assert.equal(kindOf({ headers: {}, body: { tools: [{ google_search: {} }] } }), "search");
  assert.equal(kindOf({ headers: {}, body: { model: "gemini-3.1-flash-image" } }), "image");
  assert.equal(kindOf({ headers: {}, body: { model: "gemini-3.8-flash" } }), "text");
  assert.equal(kindOf({ fn: "socialRecipe", headers: {} }), "social_video");
});

test("model keys are safe Firestore field names", () => {
  assert.equal(modelKey("gemini-3.8-flash"), "gemini-3_8-flash");
  assert.equal(modelKey(""), "unknown");
  assert.equal(modelKey(undefined), "unknown");
});

test("a call's share of the day goes to the day's map and to its own document", () => {
  const { aggregateWrites } = require("./aiUsage");
  const w = aggregateWrites({ uid: "u1", kind: "text", key: "m", spent: null, tally: {}, day: "2026-10-18", now: "NOW" });
  assert.ok(w.daily.users && w.daily.users.u1, "the map stays while the dashboards read it");
  assert.equal(w.dailyUser.uid, "u1");
  assert.equal(w.dailyUser.day, "2026-10-18");
  assert.ok(w.dailyUser.models.m);
  assert.ok("calls" in w.dailyUser);
});

test("repairUsage reads the call log in id-ordered pages after a cursor", async () => {
  const { forEachPage } = require("./aiUsage");
  const ids = Array.from({ length: 7 }, (_, i) => `r${i}`);
  const queries = [];
  const db = {
    collection: (name) => {
      const q = { name, after: null, size: null, ordered: false };
      const query = {
        orderBy: () => { q.ordered = true; return query; },
        limit: (n) => { q.size = n; return query; },
        startAfter: (id) => { q.after = id; return query; },
        get: async () => {
          queries.push({ ...q });
          const from = q.after === null ? 0 : ids.indexOf(q.after) + 1;
          const docs = ids.slice(from, from + q.size).map((id) => ({ id }));
          return { empty: docs.length === 0, size: docs.length, docs };
        },
      };
      return query;
    },
  };
  const seen = [];
  await forEachPage(db, "ai_calls", async (docs) => seen.push(docs.map((d) => d.id)), 3);
  assert.deepEqual(seen, [["r0", "r1", "r2"], ["r3", "r4", "r5"], ["r6"]]);
  assert.deepEqual(queries.map((q) => q.after), [null, "r2", "r5"]);
  assert.ok(queries.every((q) => q.ordered && q.size === 3 && q.name === "ai_calls"));

  // An exact multiple ends on the empty page after it.
  const six = [];
  ids.pop();
  await forEachPage(db, "ai_calls", async (docs) => six.push(docs.length), 3);
  assert.deepEqual(six, [3, 3]);
});

test("a kind Firestore reserves as a field name falls back instead of failing the record", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-feature": "__x__" }, body: {} }), "other");
  assert.equal(kindOf({ headers: { "x-easyplate-source-kind": "__name__" }, body: {} }), "other");
  assert.equal(kindOf({ headers: { "x-easyplate-feature": "assistant" } }), "assistant");
});

test("an unknown kind collapses to one key instead of a new map entry per value", () => {
  for (const v of ["meal_plan", "zz_random_1", "a".repeat(500), "x.y"]) {
    assert.equal(kindOf({ headers: { "x-easyplate-feature": v } }), "other");
  }
  assert.equal(kindOf({ headers: { "x-easyplate-source-kind": "video" } }), "video");
});

test("a deleted account's call rows, day shares and map entries are removed; totals stay", async () => {
  const { deleteUserUsage } = require("./aiUsage");
  const ops = [];
  const rows = Array.from({ length: 5 }, (_, i) => ({ ref: { path: `ai_calls/r${i}` } }));
  let served = 0;
  const dayDoc = (id, users) => ({
    id,
    get: (f) => (f === "users" ? users : undefined),
    ref: { path: `ai_daily/${id}`, collection: (c) => ({ doc: (d) => ({ path: `ai_daily/${id}/${c}/${d}` }) }) },
  });
  const db = {
    batch: () => ({ delete: (ref) => ops.push(`delete ${ref.path}`), update: (ref, field) => ops.push(`update ${ref.path} ${field.toString()}`), commit: async () => {} }),
    collection: (name) => ({
      where: (f, op, v) => {
        assert.deepEqual([name, f, op, v], ["ai_calls", "uid", "==", "u1"]);
        return { limit: (n) => ({ select: () => ({ get: async () => {
          const docs = rows.slice(served, served + n);
          served += docs.length;
          return { empty: docs.length === 0, size: docs.length, docs };
        } }) }) };
      },
      select: () => ({ get: async () => ({ docs: [dayDoc("2026-10-01", { u1: {}, u2: {} }), dayDoc("2026-10-02", { u2: {} })] }) }),
    }),
  };
  const out = await deleteUserUsage(db, "u1", { page: 2 });
  assert.deepEqual(out, { calls: 5, days: 1 });
  assert.equal(ops.filter((o) => o.startsWith("delete ai_calls/")).length, 5);
  assert.ok(ops.includes("delete ai_daily/2026-10-01/users/u1"));
  assert.ok(ops.some((o) => o.startsWith("update ai_daily/2026-10-01 users.u1")));
  assert.ok(!ops.some((o) => o.includes("2026-10-02")));
  assert.deepEqual(await deleteUserUsage(db, "a/b"), { calls: 0, days: 0 });
});
