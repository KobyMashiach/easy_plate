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

test("a release request is read and written inside one transaction", async () => {
  const { requestRelease } = require("./sessions").internals;
  const admin = require("firebase-admin");
  const now = 1_700_000_000_000;
  const store = new Map([["sessions/u1", {
    deviceId: "A",
    platform: "ios",
    expiresAt: admin.firestore.Timestamp.fromMillis(now + DAY_MS),
    releaseRequest: { deviceId: "B", at: admin.firestore.Timestamp.fromMillis(now - 1000), declinedAt: admin.firestore.Timestamp.fromMillis(now - 500) },
  }]]);
  const outside = [];
  const inside = [];
  const docRef = (path) => ({
    path,
    get: async () => { outside.push(`get ${path}`); return { exists: store.has(path), data: () => store.get(path), get: (f) => (store.get(path) || {})[f] }; },
    set: async () => { outside.push(`set ${path}`); },
  });
  const db = {
    doc: docRef,
    runTransaction: async (fn) => fn({
      get: async (ref) => { inside.push(`get ${ref.path}`); return { exists: store.has(ref.path), data: () => store.get(ref.path) }; },
      set: (ref, data) => { inside.push(`set ${ref.path}`); store.set(ref.path, { ...store.get(ref.path), ...data }); },
    }),
  };
  const out = await requestRelease("u1", { deviceId: "B", platform: "android", pushToken: null, title: "t", body: "b" }, { db, now, settings: async () => ({ waitHours: 24 }) });
  assert.deepEqual(inside, ["get sessions/u1", "set sessions/u1"]);
  assert.ok(!outside.includes("get sessions/u1") && !outside.includes("set sessions/u1"), "the record is never touched outside the transaction");
  // The earlier request was declined, so the clock starts over now.
  assert.equal(out.takeoverAt, now + 24 * 60 * 60 * 1000);
  assert.equal(store.get("sessions/u1").releaseRequest.declinedAt, null);

  // The holder itself asking finds the account free and writes nothing.
  inside.length = 0;
  const own = await requestRelease("u1", { deviceId: "A", platform: "ios" }, { db, now, settings: async () => ({ waitHours: 24 }) });
  assert.deepEqual(own, { ok: true, free: true });
  assert.deepEqual(inside, ["get sessions/u1"]);
});

const DEVICE_SECRET = "d".repeat(43);

test("a device that sends its own secret gets it bound; only its hash is kept", () => {
  const { secretHash } = require("./sessions").internals;
  const out = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true, bind: DEVICE_SECRET });
  assert.equal(out.secretBound, true);
  assert.equal(out.record.secretHash, secretHash(DEVICE_SECRET));
  assert.equal(JSON.stringify(out).includes(DEVICE_SECRET), false);
  // An older build asks for nothing: the record is exactly as before.
  const old = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true });
  assert.equal(old.secretBound, undefined);
  assert.equal("secretHash" in old.record, false);
});

test("copied ids no longer make the same device once the record carries a secret", () => {
  const { secretHash } = require("./sessions").internals;
  const held = { ...phone, hardwareId: "H", secretHash: secretHash("the-secret") };
  // Another phone with the ids read out of sessions/{uid}: refused.
  const replay = decide({ existing: held, deviceId: "A", hardwareId: "H", platform: "android", now: NOW, days: 30, enforce: true });
  assert.equal(replay.ok, false);
  const wrong = decide({ existing: held, deviceId: "A", hardwareId: "H", platform: "android", now: NOW, days: 30, enforce: true, secret: "guess", bind: "guess" });
  assert.equal(wrong.ok, false);
  // The holder with its secret: the same device, the month kept, nothing rebound.
  const holder = decide({ existing: held, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true, secret: "the-secret", bind: "the-secret" });
  assert.equal(holder.ok, true);
  assert.equal(holder.sameDevice, true);
  assert.equal(holder.record.startedAt, phone.startedAt);
  assert.equal(holder.record.secretHash, secretHash("the-secret"));
  assert.equal(holder.secretBound, undefined);
  assert.equal(sameDevice(held, "A", "H"), false);
  assert.equal(sameDevice(held, "Z", null, "the-secret"), true);
});

test("an existing record without a secret binds the holder's own on its next claim", () => {
  const { secretHash } = require("./sessions").internals;
  const out = decide({ existing: phone, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true, secret: DEVICE_SECRET, bind: DEVICE_SECRET });
  assert.equal(out.ok, true);
  assert.equal(out.secretBound, true);
  assert.equal(out.record.secretHash, secretHash(DEVICE_SECRET));
  assert.equal(out.record.startedAt, phone.startedAt);
});

test("a lost answer does not lock the holder out: the retry presents the same secret", () => {
  const first = decide({ existing: phone, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true, secret: DEVICE_SECRET, bind: DEVICE_SECRET });
  // The response never arrived; the device still holds what it drew and asks again.
  const retry = decide({ existing: first.record, deviceId: "A", platform: "ios", now: NOW + 1000, days: 30, enforce: true, secret: DEVICE_SECRET, bind: DEVICE_SECRET });
  assert.equal(retry.ok, true);
  assert.equal(retry.sameDevice, true);
  assert.equal(retry.secretBound, undefined);
});

test("the app's exact claim shape binds its 43-char base64url secret end to end; nothing is drawn by the server", () => {
  const { secretHash, secretMatches } = require("./sessions").internals;
  const secret = require("node:crypto").randomBytes(32).toString("base64url");
  assert.equal(secret.length, 43);
  const req = parseRequest({ action: "claim", deviceId: "A", hardwareId: "H", platform: "android", wantsSecret: true, secret });
  assert.equal(req.wantsSecret, true);
  const out = decide({ existing: null, deviceId: req.deviceId, hardwareId: req.hardwareId, platform: req.platform, now: NOW, days: 30, enforce: true, secret: req.secret, bind: req.wantsSecret ? req.secret : null });
  assert.equal(out.record.secretHash, secretHash(secret));
  assert.equal(secretMatches(out.record.secretHash, secret), true);
  assert.equal(JSON.stringify(out).includes(secret), false);
  // Takeover: the same shape, a fresh record bound to it.
  const take = parseRequest({ action: "takeover", deviceId: "B", platform: "ios", wantsSecret: true, secret });
  assert.equal(take.wantsSecret, true);
  // wantsSecret with an invalid secret (padded, 44 chars, wrong alphabet): nothing bound, nothing drawn.
  for (const bad of [secret + "=", secret + "A", secret.slice(0, 42) + "+", undefined]) {
    const r = parseRequest({ action: "claim", deviceId: "A", platform: "ios", wantsSecret: true, secret: bad });
    assert.equal(r.wantsSecret, undefined);
    const d = decide({ existing: null, deviceId: "A", platform: "ios", now: NOW, days: 30, enforce: true, secret: r.secret || null, bind: r.wantsSecret ? r.secret : null });
    assert.equal("secretHash" in d.record, false);
  }
});

test("the request carries the secret and the ask only when the device sent them", () => {
  assert.deepEqual(parseRequest({ action: "claim", deviceId: "A", platform: "ios", secret: DEVICE_SECRET, wantsSecret: true }), { action: "claim", deviceId: "A", hardwareId: null, platform: "ios", pushToken: null, secret: DEVICE_SECRET, wantsSecret: true });
  // A short secret is presented but never bound.
  assert.equal(parseRequest({ action: "claim", deviceId: "A", platform: "ios", secret: "x", wantsSecret: true }).wantsSecret, undefined);
  assert.equal(parseRequest({ action: "takeover", deviceId: "A", platform: "ios", wantsSecret: true }).wantsSecret, undefined);
  assert.deepEqual(parseRequest({ action: "release", deviceId: "A", secret: "x" }), { action: "release", deviceId: "A", hardwareId: null, secret: "x" });
  assert.equal(parseRequest({ action: "release", deviceId: "A", wantsSecret: true }).wantsSecret, undefined);
  assert.equal(parseRequest({ action: "claim", deviceId: "A", secret: 5 }).secret, undefined);
});

test("expiry pages until no session is left, by cursor", async () => {
  const { expire } = require("./sessions").internals;
  const all = Array.from({ length: 5 }, (_, i) => ({ id: `u${i}`, updateTime: i, ref: { delete: async () => { if (i === 1) throw new Error("renewed"); } } }));
  const queries = [];
  const query = (cursor) => ({
    orderBy: () => query(cursor),
    limit: (n) => ({ ...query(cursor), n }),
    startAfter: (doc) => query(doc),
    get: async function () {
      const from = cursor ? all.indexOf(cursor) + 1 : 0;
      queries.push(from);
      return { docs: all.slice(from, from + 2) };
    },
  });
  const db = { collection: () => ({ where: () => query(null) }) };
  const revoked = [];
  const count = await expire(Date.now(), { db, auth: { revokeRefreshTokens: async (uid) => revoked.push(uid) }, page: 2 });
  assert.equal(count, 4);
  assert.deepEqual(revoked, ["u0", "u2", "u3", "u4"]);
  assert.deepEqual(queries, [0, 2, 4]);
});

test("the holder is pushed once per asker per ten minutes; the record still refreshes", () => {
  const { releasePushDue, RELEASE_PUSH_GAP_MS } = require("./sessions").internals;
  const now = 1_700_000_000_000;
  const ask = { deviceId: "B", hardwareId: "hw" };
  assert.equal(releasePushDue(null, ask, now), true);
  const recent = { deviceId: "B", hardwareId: "hw", notifiedAt: now - 60_000, declinedAt: null };
  assert.equal(releasePushDue(recent, ask, now), false);
  assert.equal(releasePushDue({ ...recent, notifiedAt: now - RELEASE_PUSH_GAP_MS }, ask, now), true);
  assert.equal(releasePushDue({ ...recent, declinedAt: now - 1000 }, ask, now), true);
  assert.equal(releasePushDue({ ...recent, deviceId: "C", hardwareId: "other" }, ask, now), true);
  assert.equal(releasePushDue({ deviceId: "B", at: now - 1000 }, ask, now), true, "a request from before the stamp pushes");
});
