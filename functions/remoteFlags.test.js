const test = require("node:test");
const assert = require("node:assert/strict");
const flags = require("./remoteFlags");

test("the gate withholds pushes from free accounts only", () => {
  assert.equal(flags.pushAllowed({ premiumOnly: true, premium: false }), false);
  assert.equal(flags.pushAllowed({ premiumOnly: true, premium: undefined }), false);
  assert.equal(flags.pushAllowed({ premiumOnly: true, premium: true }), true);
  assert.equal(flags.pushAllowed({ premiumOnly: false, premium: false }), true);
});

test("a missing or blank parameter falls back to gated", () => {
  assert.equal(flags.boolFrom({}, "notifications_premium_only", true), true);
  assert.equal(flags.boolFrom({ notifications_premium_only: { defaultValue: { value: "" } } }, "notifications_premium_only", true), true);
  assert.equal(flags.boolFrom({ notifications_premium_only: { defaultValue: { value: "false" } } }, "notifications_premium_only", true), false);
  assert.equal(flags.boolFrom({ notifications_premium_only: { defaultValue: { value: "TRUE" } } }, "notifications_premium_only", false), true);
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
    parameterGroups: { Plans: { parameters: { notifications_premium_only: { defaultValue: { value: "false" } } } } },
  });
  assert.equal(flags.boolFrom(flat, "notifications_premium_only", true), false);
  assert.equal(flags.boolFrom(flat, "a", false), false);
});
