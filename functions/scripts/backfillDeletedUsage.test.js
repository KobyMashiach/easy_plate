const test = require("node:test");
const assert = require("node:assert/strict");
const { deletedUids, summarize, PERSONA_PREFIX } = require("./backfillDeletedUsage");

test("a uid is swept only when both Auth and the profile say it is gone; personas and paths never", () => {
  const seen = new Set(["gone", "authOnly", "profileOnly", "alive", `${PERSONA_PREFIX}abc`, "a/b", ""]);
  const authMissing = new Set(["gone", "authOnly", `${PERSONA_PREFIX}abc`, "a/b", ""]);
  const profileMissing = new Set(["gone", "profileOnly", `${PERSONA_PREFIX}abc`, "a/b", ""]);
  assert.deepEqual(deletedUids(seen, authMissing, profileMissing), ["gone"]);
});

test("the report totals what each deleted account left behind", () => {
  const { totals, rows } = summarize({
    b: { calls: 3, dayMapEntries: 2, dayUserDocs: 2, usageDoc: true },
    a: { calls: 0, dayMapEntries: 1, dayUserDocs: 0, usageDoc: false },
  });
  assert.deepEqual(totals, { uids: 2, calls: 3, dayMapEntries: 3, dayUserDocs: 2, usageDocs: 1 });
  assert.deepEqual(rows.map((r) => r.uid), ["a", "b"]);
});
