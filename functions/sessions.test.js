const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { parseRequest, decide, sameDevice, isExempt, DAY_MS } = require("./sessions").internals;

const NOW = 1_800_000_000_000;
const phone = { deviceId: "A", platform: "ios", startedAt: NOW - 5 * DAY_MS, expiresAt: NOW + 25 * DAY_MS };

test("the request names an action, a device and a known platform", () => {
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "iOS" }), { action: "claim", deviceId: "A", hardwareId: null, platform: "ios", pushToken: null });
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "fridge" }), { action: "claim", deviceId: "A", hardwareId: null, platform: "other", pushToken: null });
  assert.deepEqual(parseRequest({ action: "release", deviceId: "A" }), { action: "release", deviceId: "A", hardwareId: null });
  assert.deepEqual(parseRequest({ action: "declineRelease", deviceId: "A" }), { action: "declineRelease", deviceId: "A" });
  assert.equal(parseRequest({ action: "claim" }).error, "deviceId is required");
  assert.equal(parseRequest({ action: "dance", deviceId: "A" }).error, "unknown action");
});

test("a first claim opens a month-long session", () => {
  const out = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, true);
  assert.deepEqual(out.record, { deviceId: "A", hardwareId: null, platform: "ios", startedAt: NOW, expiresAt: NOW + 30 * DAY_MS, lastSeenAt: NOW, pushToken: null });
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

test("a reinstall on the holder's phone is the same device, under its new install id", () => {
  const held = { ...phone, hardwareId: "H1" };
  const out = decide({ existing: held, deviceId: "A2", hardwareId: "H1", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, true);
  assert.equal(out.sameDevice, true);
  assert.equal(out.record.deviceId, "A2");
  assert.equal(out.record.hardwareId, "H1");
  assert.equal(out.record.startedAt, held.startedAt);
  assert.equal(out.record.expiresAt, held.expiresAt);
});

test("another phone is still refused, and a record without a hardware id matches only its install", () => {
  const held = { ...phone, hardwareId: "H1" };
  assert.equal(decide({ existing: held, deviceId: "B", hardwareId: "H2", platform: "android", now: NOW, days: 30, enforce: true }).ok, false);
  assert.equal(decide({ existing: phone, deviceId: "A2", hardwareId: "H1", platform: "ios", now: NOW, days: 30, enforce: true }).ok, false);
  assert.equal(sameDevice(held, "B", null), false);
  assert.equal(sameDevice({ ...phone, hardwareId: null }, "B", null), false);
});

test("the holder's install records its hardware id on the next claim", () => {
  const out = decide({ existing: phone, deviceId: "A", hardwareId: "H1", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(out.record.hardwareId, "H1");
});

const { takeoverDue, pendingSince } = require("./sessions").internals;
const HOUR = 60 * 60 * 1000;
const asked = (extra = {}) => ({
  ...phone,
  hardwareId: "H1",
  releaseRequest: { deviceId: "B", hardwareId: "HB", at: NOW - 25 * HOUR, takeoverAt: NOW - HOUR, declinedAt: null, ...extra },
});

test("an unanswered request lets the asker in once its time has come", () => {
  const out = decide({ existing: asked(), deviceId: "B", hardwareId: "HB", platform: "android", now: NOW, days: 30, enforce: true });
  assert.equal(out.ok, true);
  assert.equal(out.record.deviceId, "B");
  assert.equal(out.record.startedAt, NOW);
});

test("no takeover before the time, after a decline, or for a device that did not ask", () => {
  const claim = (existing, deviceId = "B") =>
    decide({ existing, deviceId, hardwareId: null, platform: "android", now: NOW, days: 30, enforce: true }).ok;
  assert.equal(claim(asked({ takeoverAt: NOW + HOUR })), false);
  assert.equal(claim(asked({ declinedAt: NOW - 2 * HOUR })), false);
  assert.equal(claim(asked({ takeoverAt: null })), false);
  assert.equal(claim(asked(), "C"), false);
  assert.equal(takeoverDue(asked(), "X", "HB", NOW), true);
});

test("asking again keeps the waiting request's clock; a declined one starts over", () => {
  const previous = asked().releaseRequest;
  assert.equal(pendingSince(previous, { deviceId: "B" }, NOW), previous.at);
  assert.equal(pendingSince({ ...previous, declinedAt: NOW - HOUR }, { deviceId: "B" }, NOW), NOW);
  assert.equal(pendingSince(previous, { deviceId: "C" }, NOW), NOW);
  assert.equal(pendingSince(null, { deviceId: "B" }, NOW), NOW);
});

const { freshPhoneProof } = require("./sessions").internals;

test("a takeover needs a fresh SMS confirmation of the account's phone", () => {
  const fresh = { phone_number: "+972500000000", firebase: { sign_in_provider: "phone" }, auth_time: (NOW - 60 * 1000) / 1000 };
  assert.equal(freshPhoneProof(fresh, NOW), true);
  assert.equal(freshPhoneProof({ ...fresh, auth_time: (NOW - 11 * 60 * 1000) / 1000 }, NOW), false);
  assert.equal(freshPhoneProof({ ...fresh, firebase: { sign_in_provider: "google.com" } }, NOW), false);
  assert.equal(freshPhoneProof({ ...fresh, phone_number: undefined }, NOW), false);
  assert.equal(freshPhoneProof(null, NOW), false);
  assert.deepEqual(parseRequest({ action: "takeover", deviceId: "B", platform: "android" }), { action: "takeover", deviceId: "B", hardwareId: null, platform: "android", pushToken: null });
});
