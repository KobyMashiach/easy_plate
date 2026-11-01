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

test("the forwarded call is bounded below the function's own timeout", () => {
  const { upstreamTimeoutMs } = require("./aiProxy").internals;
  assert.equal(upstreamTimeoutMs(120), 115000);
  assert.ok(upstreamTimeoutMs(540) < 540000);
  // A tiny console value still leaves the model a usable window.
  assert.equal(upstreamTimeoutMs(1), 10000);
  // An unreadable value falls back to the 120 s default.
  assert.equal(upstreamTimeoutMs(undefined), 115000);
});

test("Google's own failures (5xx) give the slot back; a 429 and the caller's 4xx do not", () => {
  const { upstreamRefundable } = require("./aiProxy").internals;
  for (const status of [500, 502, 503, 504]) assert.equal(upstreamRefundable(status), true, String(status));
  for (const status of [200, 400, 401, 403, 404, 413, 429]) assert.equal(upstreamRefundable(status), false, String(status));
});

test("a hung model call is aborted and marked as timed out; the key goes in a header", async () => {
  const { callUpstream, ALLOWED_PATH } = require("./aiProxy").internals;
  let seen;
  const hang = (url, opts) => {
    seen = { url, opts };
    return new Promise((_resolve, reject) => opts.signal.addEventListener("abort", () => reject(opts.signal.reason)));
  };
  await assert.rejects(callUpstream("{}", "KEY", { fetchImpl: hang, timeoutMs: 30 }), (err) => err.timedOut === true);
  assert.ok(seen.url.endsWith(ALLOWED_PATH));
  assert.equal(seen.opts.headers["x-goog-api-key"], "KEY");
  assert.ok(!seen.url.includes("KEY"));
});

test("a network failure is not mistaken for a timeout; an answer passes its status through", async () => {
  const { callUpstream } = require("./aiProxy").internals;
  const down = async () => { throw new TypeError("fetch failed"); };
  await assert.rejects(callUpstream("{}", "K", { fetchImpl: down, timeoutMs: 1000 }), (err) => !err.timedOut);
  const busy = async () => ({ status: 429, text: async () => '{"error":{"status":"RESOURCE_EXHAUSTED"}}', headers: { get: () => null } });
  const out = await callUpstream("{}", "K", { fetchImpl: busy, timeoutMs: 1000 });
  assert.equal(out.status, 429);
  assert.equal(out.contentType, "application/json");
});

test("Auth failing to answer is a 503 for a paid endpoint, not a sign-in-again 401", async () => {
  const { checkToken, verifyPaidCaller } = require("./aiProxy").internals;
  const req = (token) => ({ get: (h) => (h.toLowerCase() === "authorization" && token ? `Bearer ${token}` : "") });
  const failing = (code) => ({ verifyIdToken: async () => { throw Object.assign(new Error(code), { code }); } });
  assert.deepEqual(await checkToken(req("t"), { auth: failing("auth/internal-error") }), { caller: null, unavailable: true });
  assert.deepEqual(await checkToken(req("t"), { auth: failing("app/network-error") }), { caller: null, unavailable: true });
  assert.deepEqual(await checkToken(req("t"), { auth: failing("auth/id-token-expired") }), { caller: null, unavailable: false });
  assert.deepEqual(await checkToken(req("t"), { auth: failing("auth/id-token-revoked") }), { caller: null, unavailable: false });
  assert.deepEqual(await checkToken(req(null), { auth: failing("auth/internal-error") }), { caller: null, unavailable: false });
  const ok = { verifyIdToken: async () => ({ uid: "u", phone_number: "+972500000000" }) };
  assert.equal((await checkToken(req("t"), { auth: ok })).caller.uid, "u");
  const down = await verifyPaidCaller(req("t"), { auth: failing("auth/internal-error") });
  assert.equal(down.caller, null);
  assert.equal(down.refusal.status, 503);
  assert.equal(down.refusal.code, "auth_unavailable");
  const expired = await verifyPaidCaller(req("t"), { auth: failing("auth/id-token-expired") });
  assert.equal(expired.refusal.status, 401);
});

test("size limits come from the console; a missing, bad or non-positive value falls back", () => {
  const p = require("./aiProxy").internals;
  const fallback = { promptChars: p.MAX_PROMPT_CHARS, schemaChars: p.MAX_SCHEMA_CHARS, outputTokens: p.MAX_OUTPUT_TOKENS };
  assert.deepEqual(p.sizeLimitsFrom({}), fallback);
  assert.deepEqual(p.sizeLimitsFrom(undefined), fallback);
  const v = (value) => ({ defaultValue: { value } });
  assert.deepEqual(
    p.sizeLimitsFrom({ [p.PROMPT_CHARS_PARAM]: v("5000"), [p.SCHEMA_CHARS_PARAM]: v("100"), [p.OUTPUT_TOKENS_PARAM]: v("2048") }),
    { promptChars: 5000, schemaChars: 100, outputTokens: 2048 },
  );
  assert.deepEqual(
    p.sizeLimitsFrom({ [p.PROMPT_CHARS_PARAM]: v("0"), [p.SCHEMA_CHARS_PARAM]: v("abc"), [p.OUTPUT_TOKENS_PARAM]: v("-1") }),
    fallback,
  );
});

test("the prompt counts every text field, not inline media or the schema", () => {
  const p = require("./aiProxy").internals;
  const media = "A".repeat(500000);
  const withMedia = {
    model: "m",
    system_instruction: "sys",
    input: [{ type: "image", mime_type: "image/jpeg", data: media }, { type: "text", text: "read it" }],
    response_format: { type: "text", mime_type: "application/json", schema: { description: "s".repeat(1000) } },
  };
  assert.ok(p.promptChars(withMedia) < 300, "the photo and the schema are not prompt");
  assert.ok(p.schemaChars(withMedia) > 1000);
  // Text smuggled anywhere else counts: tool declarations, function results.
  assert.ok(p.promptChars({ model: "m", input: "hi", tools: [{ type: "function", description: "t".repeat(5000) }] }) > 5000);
  assert.ok(p.promptChars({ model: "m", input: [{ type: "function_result", call_id: "1", result: { text: "r".repeat(5000) } }] }) > 5000);
  // A `data` that is not an attachment's (no mime_type) is text.
  assert.ok(p.promptChars({ model: "m", input: [{ type: "text", text: "x", data: "d".repeat(5000) }] }) > 5000);
  assert.equal(p.promptChars(null), 0);
  assert.equal(p.schemaChars({ model: "m" }), 0);
});

test("a prompt or schema past its limit is a typed 413; the app's largest bodies pass", () => {
  const p = require("./aiProxy").internals;
  const limits = p.sizeLimitsFrom({});
  // The 30,000-character paste with the extraction prompt and a recipe schema.
  const paste = {
    model: "gemini-3.8-flash",
    system_instruction: "ס".repeat(3000),
    input: `נתח את המתכון הבא לפורמט מובנה:\n\n${"מ".repeat(30000)}`,
    generation_config: { thinking_level: "low" },
    response_format: { type: "text", mime_type: "application/json", schema: { type: "object", description: "r".repeat(4000) } },
  };
  assert.equal(p.sizeRefusal(paste, limits), null);
  // The assistant: instructions + snapshot, 29 tool declarations, a function result.
  const assistant = {
    model: "gemini-3.8-flash",
    system_instruction: "a".repeat(4000) + "s".repeat(30000),
    input: [{ type: "function_result", call_id: "c", name: "search_recipes", result: { hits: "h".repeat(40000) } }],
    previous_interaction_id: "v1_abc",
    tools: Array.from({ length: 29 }, (_, i) => ({ type: "function", name: `t${i}`, description: "d".repeat(500), parameters: { type: "object" } })),
  };
  assert.equal(p.sizeRefusal(assistant, limits), null);

  const long = p.sizeRefusal({ model: "m", input: "x".repeat(limits.promptChars + 1) }, limits);
  assert.equal(long.status, 413);
  assert.equal(long.code, "prompt_too_large");
  const schema = p.sizeRefusal({ model: "m", input: "x", response_format: { schema: { d: "y".repeat(limits.schemaChars) } } }, limits);
  assert.equal(schema.status, 413);
  assert.equal(schema.code, "schema_too_large");
});

test("max_output_tokens is clamped to the ceiling; a smaller value is kept; a picture gets none it did not ask for", () => {
  const { withOutputCeiling } = require("./aiProxy").internals;
  // The app sends none: the ceiling is added, the rest of the config kept.
  const body = { model: "m", input: "hi", generation_config: { thinking_level: "low" } };
  const out = withOutputCeiling(body, 32768).body;
  assert.deepEqual(out.generation_config, { thinking_level: "low", max_output_tokens: 32768 });
  assert.deepEqual(body.generation_config, { thinking_level: "low" }, "the caller's body is not changed");
  assert.equal(withOutputCeiling({ model: "m", input: "hi" }, 100).body.generation_config.max_output_tokens, 100);
  // Smaller than the ceiling: the same body, untouched.
  const small = { model: "m", generation_config: { max_output_tokens: 500 } };
  assert.equal(withOutputCeiling(small, 32768).body, small);
  // Larger: brought down.
  assert.equal(withOutputCeiling({ model: "m", generation_config: { max_output_tokens: 1e6 } }, 32768).body.generation_config.max_output_tokens, 32768);
  // Not a positive integer, or a config that is not an object: 400.
  for (const bad of [0, -5, 1.5, "100", null]) {
    assert.equal(withOutputCeiling({ model: "m", generation_config: { max_output_tokens: bad } }, 10).refusal.status, 400, String(bad));
  }
  assert.equal(withOutputCeiling({ model: "m", generation_config: "x" }, 10).refusal.status, 400);
  // The image request (generateImage): no ceiling added, but one it sent is clamped.
  const image = { model: "img", input: "a cake", response_format: { type: "image", aspect_ratio: "4:3" } };
  assert.equal(withOutputCeiling(image, 32768).body, image);
  assert.equal(withOutputCeiling({ ...image, generation_config: { max_output_tokens: 1e6 } }, 32768).body.generation_config.max_output_tokens, 32768);
});
