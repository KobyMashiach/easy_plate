const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { nextRun, cleanSchedule, zonedTime, localParts } = require("./adminNotifications").internals;

const iso = (ms) => new Date(ms).toISOString();
// 2026-10-15 10:00 Israel (summer time, UTC+3) = 07:00Z.
const THU_10 = Date.parse("2026-10-15T07:00:00Z");

test("Israel wall clock to an instant, both sides of the clock change", () => {
  assert.equal(iso(zonedTime(2026, 10, 15, 9, 0)), "2026-10-15T06:00:00.000Z");
  assert.equal(iso(zonedTime(2026, 11, 2, 9, 0)), "2026-11-02T07:00:00.000Z");
  assert.deepEqual(localParts(THU_10).hour, 10);
});

test("daily runs today when the time is still ahead, otherwise tomorrow", () => {
  assert.equal(iso(nextRun({ kind: "daily", time: "18:30" }, THU_10)), "2026-10-15T15:30:00.000Z");
  assert.equal(iso(nextRun({ kind: "daily", time: "09:00" }, THU_10)), "2026-10-16T06:00:00.000Z");
});

test("daily keeps Israel time across the end of summer time", () => {
  const afterChange = nextRun({ kind: "daily", time: "09:00" }, Date.parse("2026-11-01T12:00:00Z"));
  assert.equal(iso(afterChange), "2026-11-02T07:00:00.000Z");
});

test("weekly picks the next chosen weekday", () => {
  // Thursday now; Sunday (0) and Tuesday (2) chosen → Sunday the 18th.
  assert.equal(iso(nextRun({ kind: "weekly", time: "08:00", weekdays: [0, 2] }, THU_10)), "2026-10-18T05:00:00.000Z");
  // Thursday itself, later today.
  assert.equal(iso(nextRun({ kind: "weekly", time: "20:00", weekdays: [4] }, THU_10)), "2026-10-15T17:00:00.000Z");
  assert.equal(nextRun({ kind: "weekly", time: "08:00", weekdays: [] }, THU_10), null);
});

test("monthly uses the last day of a short month", () => {
  assert.equal(iso(nextRun({ kind: "monthly", time: "10:00", dayOfMonth: 31 }, THU_10)), "2026-10-31T08:00:00.000Z");
  const nov = nextRun({ kind: "monthly", time: "10:00", dayOfMonth: 31 }, Date.parse("2026-11-01T00:00:00Z"));
  assert.equal(iso(nov), "2026-11-30T08:00:00.000Z");
});

test("once fires only in the future; manual never", () => {
  assert.equal(nextRun({ kind: "once", at: THU_10 + 1000 }, THU_10), THU_10 + 1000);
  assert.equal(nextRun({ kind: "once", at: THU_10 - 1000 }, THU_10), null);
  assert.equal(nextRun({ kind: "manual" }, THU_10), null);
});

test("schedules are checked before they are stored", () => {
  assert.deepEqual(cleanSchedule({ kind: "daily", time: "7:05" }), { schedule: { kind: "daily", time: "07:05" } });
  assert.deepEqual(cleanSchedule({ kind: "weekly", time: "08:00", weekdays: [5, 1, 1, 9] }), { schedule: { kind: "weekly", time: "08:00", weekdays: [1, 5] } });
  assert.ok(cleanSchedule({ kind: "weekly", time: "08:00", weekdays: [] }).error);
  assert.ok(cleanSchedule({ kind: "daily", time: "25:00" }).error);
  assert.ok(cleanSchedule({ kind: "monthly", time: "08:00", dayOfMonth: 0 }).error);
  assert.ok(cleanSchedule({ kind: "yearly" }).error);
  assert.deepEqual(cleanSchedule(null), { schedule: { kind: "manual" } });
});
