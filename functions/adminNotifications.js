// The administrator's own notifications: a log of every one sent, and
// templates that send on a schedule.
//
//   admin_notifications/{id}   one row per send: who sent it, to whom ("all",
//                              "premium", "free", a picked list of uids, or
//                              one uid with the name at the time), the
//                              title and text, where it came from (the web
//                              console, the app's dashboard or a template's
//                              schedule) and what came of it
//   notification_templates/{id}
//                              name, title, body, target ("all" | "premium" |
//                              "free" | "user" + uid | "users" + uids),
//                              schedule, enabled, nextRunAt, lastRunAt,
//                              and while a broadcast is going out
//                              `broadcast` (its progress) and
//                              `broadcastLeaseUntil` — see continueRun
//
// A schedule is { kind, at?, time?, weekdays?, dayOfMonth? }:
//   manual   sent only with "send now"
//   once     at `at` (millis)
//   daily    every day at `time` ("HH:MM")
//   weekly   on `weekdays` (0 = Sunday … 6) at `time`
//   monthly  on `dayOfMonth` (1–31; a short month uses its last day) at `time`
// Times are Israel time (Asia/Jerusalem), daylight saving included.
// nextRunAt is computed here, never by a client, and is null when nothing is
// due (manual, a past one-off, a disabled template), so the runner's query
// is a single range on nextRunAt.
//
// Both collections are read by the administrator only (firestore.rules) and
// written only through this module (adminPanel actions and the runner).
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const LOG_COLLECTION = "admin_notifications";
const TEMPLATES_COLLECTION = "notification_templates";
const TZ = "Asia/Jerusalem";
const KINDS = new Set(["manual", "once", "daily", "weekly", "monthly"]);
const TARGETS = new Set(["all", "premium", "free", "user", "users"]);
const DAY_MS = 24 * 60 * 60 * 1000;

// ---------------------------------------------------------------------------
// Pure: time.
// ---------------------------------------------------------------------------

const partsFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: TZ, hourCycle: "h23",
  year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit",
});

// The wall clock in Israel at `ms`.
function localParts(ms) {
  const out = {};
  for (const p of partsFormatter.formatToParts(new Date(ms))) if (p.type !== "literal") out[p.type] = Number(p.value);
  return { year: out.year, month: out.month, day: out.day, hour: out.hour, minute: out.minute, second: out.second };
}

// Minutes Israel is ahead of UTC at `ms`.
function offsetMinutes(ms) {
  const p = localParts(ms);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return Math.round((asUtc - Math.floor(ms / 1000) * 1000) / 60000);
}

// The instant whose Israel wall clock reads this date and time.
function zonedTime(year, month, day, hour, minute) {
  const guess = Date.UTC(year, month - 1, day, hour, minute);
  let ms = guess - offsetMinutes(guess) * 60000;
  const second = guess - offsetMinutes(ms) * 60000;
  if (second !== ms) ms = second;
  return ms;
}

function parseTime(value) {
  const match = /^(\d{1,2}):(\d{2})$/.exec(String(value || ""));
  if (!match) return null;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  return hour < 24 && minute < 60 ? { hour, minute } : null;
}

function daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

// The first time the schedule fires strictly after `after`, or null.
function nextRun(schedule, after) {
  if (!schedule || !KINDS.has(schedule.kind) || schedule.kind === "manual") return null;
  if (schedule.kind === "once") {
    const at = Number(schedule.at);
    return Number.isFinite(at) && at > after ? at : null;
  }
  const time = parseTime(schedule.time);
  if (!time) return null;
  const weekdays = new Set((schedule.weekdays || []).map(Number));
  if (schedule.kind === "weekly" && weekdays.size === 0) return null;
  const start = localParts(after);
  for (let i = 0; i < 400; i++) {
    const date = new Date(Date.UTC(start.year, start.month - 1, start.day + i));
    const y = date.getUTCFullYear();
    const m = date.getUTCMonth() + 1;
    const d = date.getUTCDate();
    if (schedule.kind === "weekly" && !weekdays.has(date.getUTCDay())) continue;
    if (schedule.kind === "monthly") {
      const wanted = Math.min(Math.max(1, Number(schedule.dayOfMonth) || 1), daysInMonth(y, m));
      if (d !== wanted) continue;
    }
    const at = zonedTime(y, m, d, time.hour, time.minute);
    if (at > after) return at;
  }
  return null;
}

// Pure: a schedule from a request, checked; or the reason it is refused.
function cleanSchedule(raw) {
  const s = raw && typeof raw === "object" ? raw : { kind: "manual" };
  const kind = KINDS.has(s.kind) ? s.kind : null;
  if (!kind) return { error: "unknown schedule" };
  if (kind === "manual") return { schedule: { kind } };
  if (kind === "once") {
    const at = Number(s.at);
    if (!Number.isFinite(at) || at <= 0) return { error: "a one-off needs a date and time" };
    return { schedule: { kind, at } };
  }
  const time = parseTime(s.time);
  if (!time) return { error: "a time is needed (HH:MM)" };
  const hhmm = `${String(time.hour).padStart(2, "0")}:${String(time.minute).padStart(2, "0")}`;
  if (kind === "daily") return { schedule: { kind, time: hhmm } };
  if (kind === "weekly") {
    const weekdays = [...new Set((Array.isArray(s.weekdays) ? s.weekdays : []).map(Number).filter((n) => Number.isInteger(n) && n >= 0 && n <= 6))].sort();
    if (!weekdays.length) return { error: "pick at least one day" };
    return { schedule: { kind, time: hhmm, weekdays } };
  }
  const dayOfMonth = Number(s.dayOfMonth);
  if (!Number.isInteger(dayOfMonth) || dayOfMonth < 1 || dayOfMonth > 31) return { error: "day of month must be 1–31" };
  return { schedule: { kind, time: hhmm, dayOfMonth } };
}

// ---------------------------------------------------------------------------
// The log.
// ---------------------------------------------------------------------------

async function log(db, { by, target, uid = null, uids = null, title, body, source, templateId = null, result = {}, error = null }) {
  let targetName = null;
  if (target === "user" && uid) {
    try {
      const user = await db.doc(`users/${uid}`).get();
      targetName = user.exists ? user.get("fullName") || user.get("email") || user.get("phoneNumber") || null : null;
    } catch (_) {}
  }
  try {
    await db.collection(LOG_COLLECTION).add({
      at: admin.firestore.Timestamp.now(),
      by: by || null,
      target,
      uid,
      uids: target === "users" ? (uids || []).slice(0, 500) : null,
      targetName,
      title: title || "",
      body: body || "",
      source,
      templateId,
      items: Number(result.items || (target === "user" && !error ? 1 : 0)),
      sent: result.sent === undefined ? null : Number(result.sent),
      failed: result.failed === undefined ? null : Number(result.failed),
      error,
    });
  } catch (err) {
    logger.warn("notification log failed", { reason: err.message });
  }
}

// ---------------------------------------------------------------------------
// Templates.
// ---------------------------------------------------------------------------

function templateFields(request) {
  const { schedule, error } = cleanSchedule(request.schedule);
  if (error) return { error };
  const target = TARGETS.has(request.target) ? request.target : "all";
  if (target === "user" && !request.uid) return { error: "pick the user" };
  if (target === "users" && !(request.uids || []).length) return { error: "pick at least one user" };
  return {
    fields: {
      name: String(request.name || request.title || "").trim().slice(0, 80),
      title: String(request.title || "").trim().slice(0, 80),
      body: String(request.body || "").trim().slice(0, 1000),
      target,
      uid: target === "user" ? request.uid : null,
      uids: target === "users" ? request.uids : null,
      schedule,
      enabled: request.enabled !== false,
    },
  };
}

async function saveTemplate(db, request, by) {
  const { fields, error } = templateFields(request);
  if (error) throw Object.assign(new Error(error), { status: 400 });
  if (!fields.body) throw Object.assign(new Error("the text is empty"), { status: 400 });
  const now = Date.now();
  const nextRunAt = fields.enabled ? nextRun(fields.schedule, now) : null;
  const ref = request.id ? db.collection(TEMPLATES_COLLECTION).doc(request.id) : db.collection(TEMPLATES_COLLECTION).doc();
  const ts = (ms) => (ms === null ? null : admin.firestore.Timestamp.fromMillis(ms));
  await ref.set({
    ...fields,
    nextRunAt: ts(nextRunAt),
    updatedAt: admin.firestore.Timestamp.now(),
    updatedBy: by,
    ...(request.id ? {} : { createdAt: admin.firestore.Timestamp.now(), lastRunAt: null, runs: 0 }),
  }, { merge: true });
  return { id: ref.id, nextRunAt };
}

// Refused while a broadcast of it is going out: the run keeps its progress
// on the template, and deleting it mid-run stopped the send part-way with
// nothing left to resume from. A run that keeps failing is given up after
// MAX_ATTEMPTS, so the refusal does not last.
async function deleteTemplate(db, id) {
  const ref = db.collection(TEMPLATES_COLLECTION).doc(id);
  const snap = await ref.get();
  if (snap.exists && snap.get("broadcast")) {
    throw Object.assign(new Error("this template is still being sent"), { status: 409, code: "in_progress" });
  }
  await ref.delete();
  return {};
}

// A broadcast to many accounts outlives one invocation: it walks the
// accounts in pages, records its progress on the template (`broadcast`:
// the run's text and audience as claimed, the last account done and the
// running counts) and holds a lease (`broadcastLeaseUntil`). A run that ran
// out of time, or whose instance died, is picked up by a later runner tick
// once the lease lapses, from the cursor on. `lastRunAt` and `runs` — what
// the console shows — move only when the run is finished.
const LEASE_MS = 6 * 60 * 1000;
// How long one tick sends before it hands the rest to the next tick; the
// runner's own timeout is 300 seconds.
const RUN_BUDGET_MS = 240 * 1000;
// A run that keeps failing is given up after this many tries.
const MAX_ATTEMPTS = 5;

// Pure: the run a claim starts, frozen from the template as it is now, so a
// later edit does not change a broadcast half sent.
function newRun(template, runAt) {
  return {
    runAt,
    cursor: null,
    items: 0,
    sent: 0,
    failed: 0,
    attempts: 0,
    title: template.title || "",
    body: template.body || "",
    target: template.target || "all",
    uid: template.uid || null,
    uids: template.uids || null,
    by: template.updatedBy || null,
  };
}

// Pure: whether a stored run may be taken over now (its lease ran out).
function resumable(data, now) {
  const lease = data && data.broadcastLeaseUntil;
  return !!(data && data.broadcast && lease && typeof lease.toMillis === "function" && lease.toMillis() <= now);
}

// Pure: the key a run's inbox items are written under (adminUsers.notifyAll).
function runKey(templateId, run) {
  return `tpl_${templateId}_${run.runAt}`;
}

// Sends one template now. `send` is { one, all } from adminUsers. `run`
// carries the paging options for notifyAll; a result with `done: false` is
// part of a run and is logged when the run completes.
async function sendTemplate(db, template, { by, source, send, run = null }) {
  const payload = { fromUid: by, title: template.title || "", message: template.body };
  try {
    if (template.target === "user") {
      await send.one({ ...payload, uid: template.uid });
      await log(db, { by, target: "user", uid: template.uid, title: template.title, body: template.body, source, templateId: template.id });
      return { items: 1 };
    }
    const audience = TARGETS.has(template.target) ? template.target : "all";
    const result = await send.all({ ...payload, audience, uids: template.uids || null, ...(run || {}) });
    if (result && result.done === false) return result;
    await log(db, { by, target: audience, uids: template.uids, title: template.title, body: template.body, source, templateId: template.id, result });
    return result;
  } catch (err) {
    await log(db, { by, target: template.target, uid: template.uid, uids: template.uids, title: template.title, body: template.body, source, templateId: template.id, error: err.message });
    throw err;
  }
}

// One stretch of a claimed run, up to `deadline`. Progress, completion and
// failure are written back on the template; a template deleted meanwhile
// only loses its bookkeeping.
async function continueRun(db, ref, templateId, run, { send, source, deadline }) {
  const ts = admin.firestore.Timestamp.fromMillis;
  const save = async (patch) => {
    try {
      await ref.update(patch);
    } catch (err) {
      logger.warn("broadcast progress not saved", { id: templateId, reason: err.message });
    }
  };
  const finish = (extra = {}) => save({
    broadcast: admin.firestore.FieldValue.delete(),
    broadcastLeaseUntil: null,
    lastRunAt: ts(run.runAt),
    runs: admin.firestore.FieldValue.increment(1),
    ...extra,
  });
  const template = { id: templateId, title: run.title, body: run.body, target: run.target, uid: run.uid, uids: run.uids };
  let result;
  try {
    result = await sendTemplate(db, template, {
      by: run.by,
      source,
      send,
      run: {
        resume: run,
        deadline,
        runKey: runKey(templateId, run),
        onProgress: (p) => save({
          broadcast: { ...run, cursor: p.cursor, items: p.items, sent: p.sent, failed: p.failed },
          broadcastLeaseUntil: ts(Date.now() + LEASE_MS),
        }),
      },
    });
  } catch (err) {
    const attempts = (Number(run.attempts) || 0) + 1;
    if (attempts >= MAX_ATTEMPTS) {
      logger.error("broadcast given up", { id: templateId, attempts, reason: err.message });
      await finish();
    } else {
      // Retried by a later tick once this short lease lapses.
      await save({ "broadcast.attempts": attempts, broadcastLeaseUntil: ts(Date.now() + 60 * 1000) });
    }
    throw err;
  }
  if (result && result.done === false) {
    // Out of time, not failed: the next tick takes it from the cursor.
    await save({ broadcastLeaseUntil: ts(Date.now()) });
    return result;
  }
  await finish();
  return result;
}

// Claims a template for a new run in a transaction: refused while an
// earlier run of it is still going. `advance` moves nextRunAt (the
// schedule); "send now" leaves it.
async function claimRun(db, ref, now, { advance, due = false }) {
  return db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    const data = fresh.data();
    if (!data) return { missing: true };
    if (data.broadcast) return { busy: true };
    if (due && (!data.enabled || !data.nextRunAt || data.nextRunAt.toMillis() > now)) return null;
    const run = newRun(data, now);
    const patch = { broadcast: run, broadcastLeaseUntil: admin.firestore.Timestamp.fromMillis(now + LEASE_MS) };
    if (advance) {
      const next = nextRun(data.schedule, now);
      patch.nextRunAt = next === null ? null : admin.firestore.Timestamp.fromMillis(next);
    }
    tx.update(ref, patch);
    return { run };
  });
}

async function sendTemplateNow(db, id, { by, send, now = Date.now() }) {
  const ref = db.collection(TEMPLATES_COLLECTION).doc(id);
  const claim = await claimRun(db, ref, now, { advance: false });
  if (claim.missing) throw Object.assign(new Error("template not found"), { status: 404 });
  if (claim.busy) throw Object.assign(new Error("this template is still being sent"), { status: 409, code: "in_progress" });
  // Sent in the administrator's name, whoever last edited the template.
  return continueRun(db, ref, id, { ...claim.run, by }, { send, source: "template", deadline: now + RUN_BUDGET_MS });
}

// Runs whose lease lapsed are continued first, then every due template is
// claimed in a transaction (its nextRunAt moves on before the send), so two
// overlapping runs never send the same one twice.
async function runDue(db, send, now = Date.now()) {
  const ts = admin.firestore.Timestamp.fromMillis;
  const deadline = now + RUN_BUDGET_MS;
  let count = 0;

  const stalled = await db.collection(TEMPLATES_COLLECTION).where("broadcastLeaseUntil", "<=", ts(now)).limit(20).get();
  for (const doc of stalled.docs) {
    const run = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      const data = fresh.data();
      if (!resumable(data, now)) return null;
      tx.update(doc.ref, { broadcastLeaseUntil: ts(now + LEASE_MS) });
      return data.broadcast;
    });
    if (!run) continue;
    try {
      const result = await continueRun(db, doc.ref, doc.id, run, { send, source: "schedule", deadline });
      if (result.done !== false) count++;
    } catch (err) {
      logger.warn("resumed notification failed", { id: doc.id, reason: err.message });
    }
  }

  const due = await db.collection(TEMPLATES_COLLECTION)
    .where("nextRunAt", "<=", ts(now)).limit(50).get();
  for (const doc of due.docs) {
    const claim = await claimRun(db, doc.ref, now, { advance: true, due: true });
    if (!claim || !claim.run) continue;
    try {
      const result = await continueRun(db, doc.ref, doc.id, claim.run, { send, source: "schedule", deadline });
      if (result.done !== false) count++;
    } catch (err) {
      logger.warn("scheduled notification failed", { id: doc.id, reason: err.message });
    }
  }
  return count;
}

const runNotificationTemplates = onSchedule(
  { schedule: "every 5 minutes", timeZone: TZ, region: "europe-west1", retryCount: 0, timeoutSeconds: 300 },
  async () => {
    const accounts = require("./adminUsers").internals;
    const count = await runDue(admin.firestore(), { one: accounts.notifyOne, all: accounts.notifyAll });
    if (count) logger.info("scheduled notifications sent", { count });
  },
);

module.exports = {
  LOG_COLLECTION, TEMPLATES_COLLECTION, TZ,
  log, saveTemplate, deleteTemplate, sendTemplateNow, runDue, runNotificationTemplates,
  internals: { nextRun, cleanSchedule, zonedTime, localParts, offsetMinutes, newRun, resumable, runKey, continueRun, LEASE_MS, MAX_ATTEMPTS },
};
