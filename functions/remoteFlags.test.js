const test = require("node:test");
const assert = require("node:assert/strict");
const flags = require("./remoteFlags");

test("the flag decides who gets a push: 2 everyone, 3 Premium, 0/1/4 nobody", () => {
  assert.equal(flags.pushAllowed({ flag: 4, premium: true }), false);
  assert.equal(flags.pushAllowed({ flag: 3, premium: false }), false);
  assert.equal(flags.pushAllowed({ flag: 3, premium: undefined }), false);
  assert.equal(flags.pushAllowed({ flag: 3, premium: true }), true);
  assert.equal(flags.pushAllowed({ flag: 2, premium: false }), true);
  assert.equal(flags.pushAllowed({ flag: 1, premium: true }), false);
  assert.equal(flags.pushAllowed({ flag: 0, premium: true }), false);
});

test("only 2 and 3 open a feature; maintenance (4) closes it like 0 and 1", () => {
  assert.equal(flags.isOpen(2), true);
  assert.equal(flags.isOpen(3), true);
  for (const v of [0, 1, 4, 5, -1]) assert.equal(flags.isOpen(v), false, String(v));
});

test("a missing, blank or garbled flag falls back to the default", () => {
  assert.equal(flags.intFrom({}, "ff_notifications", 2), 2);
  assert.equal(flags.intFrom({ ff_notifications: { defaultValue: { value: "" } } }, "ff_notifications", 2), 2);
  assert.equal(flags.intFrom({ ff_notifications: { defaultValue: { value: "3" } } }, "ff_notifications", 2), 3);
  assert.equal(flags.intFrom({ ff_notifications: { defaultValue: { value: "x" } } }, "ff_notifications", 2), 2);
  assert.equal(flags.boolFrom({ a: { defaultValue: { value: "TRUE" } } }, "a", false), true);
});

test("premium follows the same window as the app", () => {
  const now = Date.parse("2026-10-06T12:00:00Z");
  const ts = (iso) => ({ toMillis: () => Date.parse(iso) });
  assert.equal(flags.isPremium({ premium: true }, now), true);
  assert.equal(flags.isPremium({ premium: false }, now), false);
  assert.equal(flags.isPremium({ premium: true, premiumUntil: ts("2026-10-05T00:00:00Z") }, now), false);
  assert.equal(flags.isPremium({ premium: true, premiumUntil: ts("2026-11-05T00:00:00Z") }, now), true);
  assert.equal(flags.isPremium({ premium: true, premiumFrom: ts("2026-10-07T00:00:00Z") }, now), false);
  // A query snapshot exposes fields through get().
  assert.equal(flags.isPremium({ get: (f) => ({ premium: true })[f] }, now), true);
});

test("a parameter inside a parameter group is found", () => {
  const flat = flags.flatten({
    parameters: { a: { defaultValue: { value: "1" } } },
    parameterGroups: { featureFlags: { parameters: { ff_notifications: { defaultValue: { value: "3" } } } } },
  });
  assert.equal(flags.intFrom(flat, "ff_notifications", 2), 3);
  assert.equal(flags.boolFrom(flat, "a", false), false);
});

test("with no Remote Config read, the notifications flag is gated, not on", () => {
  assert.equal(flags.NOTIFICATIONS_FALLBACK, 0);
  const flag = flags.intFrom({}, flags.NOTIFICATIONS_FLAG, flags.NOTIFICATIONS_FALLBACK);
  assert.equal(flags.pushAllowed({ flag, premium: true }), false);
});

test("a burst of reads on a cold instance shares one template fetch", async () => {
  const rf = require("./remoteFlags");
  rf.resetForTest();
  let calls = 0;
  let release;
  const gate = new Promise((r) => (release = r));
  const fetchTemplate = async () => {
    calls++;
    await gate;
    return { parameters: { q: { defaultValue: { value: "7" } } } };
  };
  const reads = Array.from({ length: 10 }, () => rf.params(Date.now(), fetchTemplate));
  release();
  const all = await Promise.all(reads);
  assert.equal(calls, 1);
  assert.ok(all.every((p) => rf.intFrom(p, "q", 0) === 7));
  rf.resetForTest();
});

test("a template read that hangs gives up at its timeout: the fallbacks apply and the read is retried soon", async () => {
  const rf = require("./remoteFlags");
  rf.resetForTest();
  const hang = () => new Promise(() => {});
  const started = Date.now();
  const p = await rf.params(1000, hang, 30);
  assert.deepEqual(p, {});
  assert.ok(Date.now() - started < 1000);
  // Within the retry window the failed read is not repeated; after it, it is.
  let calls = 0;
  const ok = async () => { calls++; return { parameters: { q: { defaultValue: { value: "3" } } } }; };
  await rf.params(1000 + 10, ok, 30);
  assert.equal(calls, 0);
  const later = await rf.params(1000 + 31_000, ok, 30);
  assert.equal(calls, 1);
  assert.equal(rf.intFrom(later, "q", 0), 3);
  rf.resetForTest();
});
