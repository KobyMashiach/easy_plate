// Folds throwaway probe accounts into the single "claude" usage row.
//
// Live server tests (socialRecipe, imageSearch, suggestions…) need a real
// ID token, so each one makes a temporary email user, calls once and
// deletes the user. That left one uid-named row per probe in the console's
// "accounts by AI cost". This script keeps only the numbers (calls, input,
// output, cache, cost per model) under the uid "claude" and removes every
// other trace of each probe uid:
//
//   merged   ai_usage/{uid}                 → ai_usage/claude
//            ai_daily/{day}.users.{uid}     → ai_daily/{day}.users.claude
//            ai_daily/{day}/users/{uid}     → ai_daily/{day}/users/claude
//   renamed  ai_calls (uid), admin_audit (params.uid) → "claude"
//   deleted  ai_interactions, usage_budgets, user_directory, share_codes,
//            share_invites, users/{uid} (+ subcollections), notifications,
//            public_profiles, entitlements, account_status, sessions,
//            stripe_customers, web_customers, Storage users/{uid}/…, the
//            Auth account.
//
// Counters are merged with atomic increments in the same commit that
// deletes the source, so a live write is never lost. The quota counter
// (ai_usage.count / day) is not merged: it belongs to the deleted account.
//
// Auth: the firebase CLI's OAuth token (run any `firebase` command first
// if it has expired).
//
//   node tools/claude_probe/cleanup.mjs [--dry-run] <uid> [<uid> …]
import fs from "node:fs";
import os from "node:os";

const PROJECT = "easy-plate";
const BUCKET = "easy-plate.firebasestorage.app";
const TARGET = "claude";
const DB = `projects/${PROJECT}/databases/(default)`;
const API = "https://firestore.googleapis.com/v1";
const TOKEN = JSON.parse(fs.readFileSync(`${os.homedir()}/.config/configstore/firebase-tools.json`, "utf8")).tokens.access_token;
const H = { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json", "X-Goog-User-Project": PROJECT };

const args = process.argv.slice(2);
const dry = args.includes("--dry-run");
const uids = args.filter((a) => !a.startsWith("--"));
if (!uids.length) { console.error("usage: cleanup.mjs [--dry-run] <uid> …"); process.exit(1); }
if (uids.includes(TARGET)) { console.error(`refusing to clean "${TARGET}" itself`); process.exit(1); }

const seg = (s) => (/^[A-Za-z_][A-Za-z_0-9]*$/.test(s) ? s : "`" + s.replace(/[`\\]/g, (c) => "\\" + c) + "`");
const path = (...parts) => parts.map(seg).join(".");

async function req(url, opts = {}) {
  const r = await fetch(url, { headers: H, ...opts });
  const text = await r.text();
  const body = text ? JSON.parse(text) : {};
  if (!r.ok && r.status !== 404) throw new Error(`${r.status} ${url}: ${text.slice(0, 300)}`);
  return r.status === 404 ? null : body;
}
const getDoc = (p) => req(`${API}/${DB}/documents/${p}`);
async function commit(writes) {
  if (!writes.length) return;
  if (dry) { console.log("  [dry] commit", writes.length, "writes"); return; }
  for (let i = 0; i < writes.length; i += 400) await req(`${API}/${DB}/documents:commit`, { method: "POST", body: JSON.stringify({ writes: writes.slice(i, i + 400) }) });
}
async function where(collection, field, value) {
  const q = { structuredQuery: { from: [{ collectionId: collection }], where: { fieldFilter: { field: { fieldPath: field }, op: "EQUAL", value: { stringValue: value } } } } };
  const rows = await req(`${API}/${DB}/documents:runQuery`, { method: "POST", body: JSON.stringify(q) });
  return (rows || []).filter((r) => r.document).map((r) => r.document);
}
async function subcollections(docName) {
  const r = await req(`${API}/${docName}:listCollectionIds`, { method: "POST", body: "{}" });
  return (r && r.collectionIds) || [];
}
async function listDocs(parentName, collection) {
  const out = [];
  let token = "";
  do {
    const r = await req(`${API}/${parentName}/${collection}?pageSize=300&showMissing=true${token ? `&pageToken=${token}` : ""}`);
    out.push(...((r && r.documents) || []));
    token = (r && r.nextPageToken) || "";
  } while (token);
  return out;
}
// Every document under `name` (itself last), depth first.
async function treeOf(name) {
  const out = [];
  for (const c of await subcollections(name)) for (const d of await listDocs(name, c)) out.push(...(await treeOf(d.name)));
  out.push(name);
  return out;
}

// Numeric leaves of a Firestore map as [fieldPathParts, valueObject].
function leaves(fields, prefix = []) {
  const out = [];
  for (const [k, v] of Object.entries(fields || {})) {
    if (v.integerValue !== undefined) out.push([[...prefix, k], { integerValue: v.integerValue }]);
    else if (v.doubleValue !== undefined) out.push([[...prefix, k], { doubleValue: v.doubleValue }]);
    else if (v.mapValue) out.push(...leaves(v.mapValue.fields, [...prefix, k]));
  }
  return out;
}
const increments = (fields, intoPrefix) => leaves(fields).map(([parts, value]) => ({ fieldPath: path(...intoPrefix, ...parts), increment: value }));
const docName = (p) => `${DB}/documents/${p}`;
const later = (a, b) => (!a ? b : !b ? a : a.timestampValue > b.timestampValue ? a : b);

const report = {};
const count = (k, n = 1) => { report[k] = (report[k] || 0) + n; };

for (const uid of uids) {
  console.log(`— ${uid}`);
  const writes = [];

  // ai_usage/{uid} → ai_usage/claude
  const usage = await getDoc(`ai_usage/${uid}`);
  if (usage) {
    const f = usage.fields || {};
    const keep = {};
    for (const k of ["totals", "models", "kinds"]) if (f[k]) keep[k] = f[k];
    const target = await getDoc(`ai_usage/${TARGET}`);
    const last = later(target && target.fields && target.fields.lastCallAt, f.lastCallAt);
    writes.push({
      update: { name: docName(`ai_usage/${TARGET}`), fields: { label: { stringValue: "claude" }, ...(last ? { lastCallAt: last } : {}) } },
      updateMask: { fieldPaths: ["label", ...(last ? ["lastCallAt"] : [])] },
      updateTransforms: [...increments(keep, []), { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" }],
    });
    writes.push({ delete: usage.name });
    count("ai_usage merged");
  }

  // ai_daily: the day map entry and the per-day share document.
  for (const day of await listDocs(DB + "/documents", "ai_daily")) {
    const id = day.name.split("/").pop();
    const users = day.fields && day.fields.users && day.fields.users.mapValue && day.fields.users.mapValue.fields;
    if (users && users[uid]) {
      writes.push({
        update: { name: day.name, fields: {} },
        updateMask: { fieldPaths: [path("users", uid)] },
        updateTransforms: increments(users[uid].mapValue.fields, ["users", TARGET]),
        currentDocument: { exists: true },
      });
      count("ai_daily map entries merged");
    }
    const share = await getDoc(`ai_daily/${id}/users/${uid}`);
    if (share) {
      const { uid: _u, day: _d, updatedAt: _t, ...nums } = share.fields || {};
      writes.push({
        update: { name: docName(`ai_daily/${id}/users/${TARGET}`), fields: { uid: { stringValue: TARGET }, day: { stringValue: id } } },
        updateMask: { fieldPaths: ["uid", "day"] },
        updateTransforms: [...increments(nums, []), { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" }],
      });
      writes.push({ delete: share.name });
      count("ai_daily share docs merged");
    }
  }

  // Logs keep their numbers, lose the uid.
  for (const d of await where("ai_calls", "uid", uid)) {
    writes.push({ update: { name: d.name, fields: { uid: { stringValue: TARGET } } }, updateMask: { fieldPaths: ["uid"] } });
    count("ai_calls renamed");
  }
  for (const d of await where("admin_audit", "params.uid", uid)) {
    writes.push({ update: { name: d.name, fields: { params: { mapValue: { fields: { uid: { stringValue: TARGET } } } } } }, updateMask: { fieldPaths: ["params.uid"] } });
    count("admin_audit renamed");
  }

  // Everything else goes.
  for (const [c, f] of [["ai_interactions", "uid"], ["usage_budgets", "uid"], ["user_directory", "uid"], ["share_codes", "ownerUid"], ["share_invites", "ownerUid"], ["share_invites", "targetUid"]]) {
    for (const d of await where(c, f, uid)) { writes.push({ delete: d.name }); count(`${c} deleted`); }
  }
  for (const c of ["public_profiles", "entitlements", "account_status", "sessions", "stripe_customers", "web_customers"]) {
    if (await getDoc(`${c}/${uid}`)) { writes.push({ delete: docName(`${c}/${uid}`) }); count(`${c} deleted`); }
  }
  for (const root of ["users", "notifications"]) {
    const tree = await treeOf(docName(`${root}/${uid}`));
    const real = [];
    for (const n of tree) if (n !== docName(`${root}/${uid}`) || (await getDoc(`${root}/${uid}`))) real.push(n);
    for (const n of real) writes.push({ delete: n });
    if (real.length) count(`${root} docs deleted`, real.length);
  }

  await commit(writes);

  // Storage users/{uid}/…
  const list = await req(`https://storage.googleapis.com/storage/v1/b/${BUCKET}/o?prefix=${encodeURIComponent(`users/${uid}/`)}`);
  for (const o of (list && list.items) || []) {
    if (!dry) await req(`https://storage.googleapis.com/storage/v1/b/${BUCKET}/o/${encodeURIComponent(o.name)}`, { method: "DELETE" });
    count("storage objects deleted");
  }

  // The Auth account (normally gone already).
  const found = await req(`https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:lookup`, { method: "POST", body: JSON.stringify({ localId: [uid] }) });
  if (found && found.users && found.users.length) {
    if (!dry) await req(`https://identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:delete`, { method: "POST", body: JSON.stringify({ localId: uid }) });
    count("auth accounts deleted");
  }
}

console.log(dry ? "DRY RUN —" : "done —", report);
