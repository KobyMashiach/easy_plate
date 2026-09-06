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
