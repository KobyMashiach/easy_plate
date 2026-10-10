const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { parseRequest, decide, isExempt, DAY_MS } = require("./sessions").internals;

const NOW = 1_800_000_000_000;
const phone = { deviceId: "A", platform: "ios", startedAt: NOW - 5 * DAY_MS, expiresAt: NOW + 25 * DAY_MS };

test("the request names an action, a device and a known platform", () => {
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "iOS" }), { action: "claim", deviceId: "A", platform: "ios", pushToken: null });
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "fridge" }), { action: "claim", deviceId: "A", platform: "other", pushToken: null });
  assert.deepEqual(parseRequest({ action: "release", deviceId: "A" }), { action: "release", deviceId: "A" });
  assert.equal(parseRequest({ action: "claim" }).error, "deviceId is required");
  assert.equal(parseRequest({ action: "dance", deviceId: "A" }).error, "unknown action");
});

test("a first claim opens a month-long session", () => {
  const out = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, true);
  assert.deepEqual(out.record, { deviceId: "A", platform: "ios", startedAt: NOW, expiresAt: NOW + 30 * DAY_MS, lastSeenAt: NOW, pushToken: null });
});

test("the same device keeps its month; only last-seen moves", () => {
  const out = decide({ existing: phone, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, true);
  assert.equal(out.record.startedAt, phone.startedAt);
  assert.equal(out.record.expiresAt, phone.expiresAt);
  assert.equal(out.record.lastSeenAt, NOW);
});

test("another device is refused while the session is live", () => {
  const out = decide({ existing: phone, deviceId: "B", platform: "android", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, false);
  assert.deepEqual(out.refusal, { code: "other_device", platform: "ios", since: phone.startedAt });
});

test("an expired session is taken over, and so is any session when not enforced", () => {
  const stale = { ...phone, expiresAt: NOW - 1 };
  const taken = decide({ existing: stale, deviceId: "B", platform: "android", now: NOW, days: 30, enforce: true });
  assert.equal(taken.ok, true);
  assert.equal(taken.record.deviceId, "B");
  assert.equal(taken.record.startedAt, NOW);
  const shared = decide({ existing: phone, deviceId: "B", platform: "android", now: NOW, days: 30, enforce: false });
  assert.equal(shared.ok, true);
  assert.equal(shared.record.deviceId, "B");
});

test("zero days means a session that never expires", () => {
  const out = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 0, enforce: true });
  assert.equal(out.record.expiresAt, null);
  const other = decide({ existing: { ...phone, expiresAt: null }, deviceId: "B", platform: "ios", now: NOW + 400 * DAY_MS, days: 0, enforce: true });
  assert.equal(other.ok, false);
});

test("the exempt list matches the caller's number, however it is written", () => {
  assert.equal(isExempt("+972501564465", "+972501564465"), true);
  assert.equal(isExempt("+972501564465", "+972508247743, +972 50-156-4465"), true);
  assert.equal(isExempt("+972508247743", "+972501564465"), false);
  assert.equal(isExempt(undefined, "+972501564465"), false);
  assert.equal(isExempt("+972501564465", ""), false);
});

test("the holder keeps its push token, and a new one replaces it", () => {
  const held = { ...phone, pushToken: "old" };
  assert.equal(decide({ existing: held, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true }).record.pushToken, "old");
  assert.equal(decide({ existing: held, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true, pushToken: "new" }).record.pushToken, "new");
  assert.equal(decide({ existing: held, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true }).sameDevice, true);
});

test("release requests carry the texts for the holder's push", () => {
  const r = parseRequest({ action: "requestRelease", deviceId: "B", platform: "android", title: " בקשה ", body: "x".repeat(500) });
  assert.equal(r.action, "requestRelease");
  assert.equal(r.title, "בקשה");
  assert.equal(r.body.length, 200);
  assert.deepEqual(parseRequest({ action: "declineRelease", deviceId: "A" }), { action: "declineRelease", deviceId: "A" });
});
