// Run with: npm test  (node's built-in runner, no extra dependency)
const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { decideQuota, utcDay, ALLOWED_PATH, FREE_DAILY_CALLS } =
  require("./aiProxy").internals;

const TODAY = "2026-09-07";

test("a user with no record gets their first call", () => {
  const d = decideQuota(null, TODAY, 30);
  assert.equal(d.allowed, true);
  assert.equal(d.used, 1);
});

test("a call part-way through the day increments", () => {
  const d = decideQuota({ day: TODAY, count: 7 }, TODAY, 30);
  assert.equal(d.allowed, true);
  assert.equal(d.used, 8);
});

test("the call that reaches the limit is still allowed", () => {
  const d = decideQuota({ day: TODAY, count: 29 }, TODAY, 30);
  assert.equal(d.allowed, true);
  assert.equal(d.used, 30);
});

test("the call past the limit is refused", () => {
  const d = decideQuota({ day: TODAY, count: 30 }, TODAY, 30);
  assert.equal(d.allowed, false);
  assert.equal(d.used, 30);
});

test("yesterday's exhausted count does not carry into today", () => {
  const d = decideQuota({ day: "2026-09-06", count: 30 }, TODAY, 30);
  assert.equal(d.allowed, true);
  assert.equal(d.used, 1);
});

test("a malformed record is treated as no usage rather than as a lockout", () => {
  assert.equal(decideQuota({}, TODAY, 30).allowed, true);
  assert.equal(decideQuota({ day: TODAY }, TODAY, 30).used, 1);
});

test("a zero limit refuses everything", () => {
  assert.equal(decideQuota(null, TODAY, 0).allowed, false);
});

test("utcDay is a plain ISO date", () => {
  assert.match(utcDay(), /^\d{4}-\d{2}-\d{2}$/);
});

test("the forwarded path is the one the app calls", () => {
  assert.equal(ALLOWED_PATH, "/v1beta/interactions");
  assert.ok(FREE_DAILY_CALLS > 0);
});

test("the daily backstop comes from the console, with the constant as the fallback", () => {
  const { dailyLimitFrom, DAILY_LIMIT_PARAM } = require("./aiProxy").internals;
  assert.equal(DAILY_LIMIT_PARAM, "quota_ai_proxy_daily");
  assert.equal(dailyLimitFrom({ quota_ai_proxy_daily: { defaultValue: { value: "50" } } }), 50);
  assert.equal(dailyLimitFrom({ quota_ai_proxy_daily: { defaultValue: { value: "0" } } }), 0, "0 closes the proxy");
  assert.equal(dailyLimitFrom({ quota_ai_proxy_daily: { defaultValue: { value: "lots" } } }), FREE_DAILY_CALLS);
  assert.equal(dailyLimitFrom({}), FREE_DAILY_CALLS);
  assert.equal(dailyLimitFrom(undefined), FREE_DAILY_CALLS);
});

test("a paid endpoint needs a verified phone in the token", () => {
  const { paidCallerRefusal } = require("./aiProxy").internals;
  assert.equal(paidCallerRefusal(null).status, 401);
  const noPhone = paidCallerRefusal({ uid: "u1", email: "x@y.z" });
  assert.equal(noPhone.status, 403);
  assert.equal(noPhone.code, "phone_required");
  assert.equal(paidCallerRefusal({ uid: "u1", phone_number: "" }).code, "phone_required");
  assert.equal(paidCallerRefusal({ uid: "u1", phone_number: "+972500000000" }), null);
});

test("agent and background runs are refused; the app's bodies pass", () => {
  const { bodyRefusal } = require("./aiProxy").internals;
  assert.equal(bodyRefusal({ model: "m", input: "hi", tools: [] }), null);
  assert.equal(bodyRefusal({ model: "m", input: "hi", previous_interaction_id: "abc" }), null);
  assert.ok(bodyRefusal({ agent: "deep-research", input: "hi" }));
  assert.ok(bodyRefusal({ model: "m", input: "hi", agent: null }));
  assert.ok(bodyRefusal({ model: "m", input: "hi", background: true }));
  assert.equal(bodyRefusal({ model: "m", input: "hi", background: false }), null);
  assert.ok(bodyRefusal({ model: "m", previous_interaction_id: { a: 1 } }));
  assert.ok(bodyRefusal({ model: "m", previous_interaction_id: "x".repeat(600) }));
});

test("a conversation is continued only by the account that started it", () => {
  const { interactionAllowed, interactionIdOf, interactionDocId } = require("./aiProxy").internals;
  assert.equal(interactionAllowed({ uid: "u1" }, "u1"), true);
  assert.equal(interactionAllowed({ uid: "u1" }, "u2"), false);
  assert.equal(interactionAllowed(null, "u2"), true, "no row: from before the rows existed");
  assert.equal(interactionIdOf(JSON.stringify({ id: "v1_abc", steps: [] })), "v1_abc");
  assert.equal(interactionIdOf("not json"), null);
  assert.equal(interactionIdOf(JSON.stringify({ id: 5 })), null);
  assert.match(interactionDocId("a/b/c"), /^[0-9a-f]{64}$/);
});

test("expired interaction owners are deleted in pages until a short page, within the time budget", async () => {
  const { cleanupInteractions, INTERACTION_OWNERS } = require("./aiProxy").internals;
  let left = 10;
  const queries = [];
  const db = {
    collection: (name) => {
      const q = {
        where: (field, op, value) => { queries.push({ name, field, op, ms: value.toMillis() }); return q; },
        orderBy: () => q,
        limit: (n) => ({ select: () => ({ get: async () => {
          const size = Math.min(n, left);
          return { empty: size === 0, size, docs: Array.from({ length: size }, () => ({ ref: {} })) };
        } }) }),
      };
      return q;
    },
    batch: () => {
      let n = 0;
      return { delete: () => n++, commit: async () => { left -= n; } };
    },
  };
  assert.equal(await cleanupInteractions({ db, now: 5000, page: 4 }), 10);
  assert.equal(left, 0);
  assert.deepEqual(queries[0], { name: INTERACTION_OWNERS, field: "expireAt", op: "<", ms: 5000 });

  // Out of time after the first full page: stops, tomorrow carries on.
  left = 10;
  let t = 0;
  assert.equal(await cleanupInteractions({ db, now: 5000, page: 4, budgetMs: 1, clock: () => (t += 10) }), 4);
});

test("cache hits draw on their own daily budget and refuse with a quota body", async () => {
  const { cacheHitRefusal } = require("./aiProxy").internals;
  let asked = null;
  assert.equal(await cacheHitRefusal("u1", async (a) => { asked = a; return { allowed: true, used: 1, limit: 200 }; }), null);
  assert.deepEqual(asked, { uid: "u1", kind: "aiCacheHits" });
  const refused = await cacheHitRefusal("u1", async () => ({ allowed: false, used: 200, limit: 200 }));
  assert.equal(refused.error.code, "quota");
  assert.deepEqual(refused.error.quota, { used: 200, limit: 200, kind: "aiCacheHits" });
  // A budget that cannot be read does not block a cached answer.
  assert.equal(await cacheHitRefusal("u1", async () => { throw new Error("down"); }), null);
});

test("a switched-off account is refused by every paid endpoint", () => {
  const { paidCallerRefusal } = require("./aiProxy").internals;
  assert.equal(paidCallerRefusal({ uid: "u", phone_number: "+972500000000" }), null);
  assert.deepEqual(paidCallerRefusal({ uid: "u", phone_number: "+972500000000", disabled: true }), { status: 403, code: "account_disabled", message: "This account is disabled" });
});
