const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { parseRequest, decide, DAY_MS } = require("./sessions").internals;

const NOW = 1_800_000_000_000;
const phone = { deviceId: "A", platform: "ios", startedAt: NOW - 5 * DAY_MS, expiresAt: NOW + 25 * DAY_MS };

test("the request names an action, a device and a known platform", () => {
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "iOS" }), { action: "claim", deviceId: "A", platform: "ios" });
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "fridge" }), { action: "claim", deviceId: "A", platform: "other" });
  assert.deepEqual(parseRequest({ action: "release", deviceId: "A" }), { action: "release", deviceId: "A" });
  assert.equal(parseRequest({ action: "claim" }).error, "deviceId is required");
  assert.equal(parseRequest({ action: "dance", deviceId: "A" }).error, "unknown action");
});

test("a first claim opens a month-long session", () => {
  const out = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, true);
  assert.deepEqual(out.record, { deviceId: "A", platform: "ios", startedAt: NOW, expiresAt: NOW + 30 * DAY_MS, lastSeenAt: NOW });
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
