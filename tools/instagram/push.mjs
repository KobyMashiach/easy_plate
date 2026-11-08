// Sends Claude's drafts to the web console's Instagram page.
//
//   python3 tools/instagram/compose.py <id>      # render posts/<id>/out/*.jpg
//   node tools/instagram/push.mjs <id> [<id> …]  # upload + create the draft
//   node tools/instagram/push.mjs --all
//
// Each image goes to Storage at marketing/instagram/<consoleId>/NN.jpg and
// the post becomes a draft in instagram_posts/<consoleId> (source
// "claude"). Koby reviews, edits, approves, schedules or publishes it in
// the console; nothing here talks to Instagram. post.json keeps the
// consoleId, so pushing again updates the same draft (back to draft, the
// old images replaced) unless it is already publishing or published.
//
// Auth: the firebase CLI's own OAuth token (run any firebase command first
// if it has expired) — the same as tools/claude_probe/cleanup.mjs.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const POSTS = path.join(HERE, "posts");
const PROJECT = "easy-plate";
const BUCKET = "easy-plate.firebasestorage.app";
const DOCS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const TOKEN = JSON.parse(fs.readFileSync(`${os.homedir()}/.config/configstore/firebase-tools.json`, "utf8")).tokens.access_token;
const H = { Authorization: `Bearer ${TOKEN}`, "X-Goog-User-Project": PROJECT };

const die = (m) => { console.error(m); process.exit(1); };

// Firestore REST values.
function enc(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number") return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
}

// Width and height of a JPEG, from its SOF marker.
function jpegSize(buf) {
  let i = 2;
  while (i < buf.length) {
    if (buf[i] !== 0xff) { i++; continue; }
    const marker = buf[i + 1];
    const len = buf.readUInt16BE(i + 2);
    if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
    i += 2 + len;
  }
  return {};
}

async function upload(file, name) {
  const meta = JSON.stringify({ name, contentType: "image/jpeg", metadata: { firebaseStorageDownloadTokens: crypto.randomUUID() } });
  const boundary = "ig" + crypto.randomBytes(8).toString("hex");
  const body = Buffer.concat([
    Buffer.from(`--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${meta}\r\n--${boundary}\r\nContent-Type: image/jpeg\r\n\r\n`),
    fs.readFileSync(file),
    Buffer.from(`\r\n--${boundary}--`),
  ]);
  const r = await fetch(`https://storage.googleapis.com/upload/storage/v1/b/${BUCKET}/o?uploadType=multipart`, {
    method: "POST", headers: { ...H, "Content-Type": `multipart/related; boundary=${boundary}` }, body,
  });
  if (!r.ok) die(`upload ${name}: ${r.status} ${(await r.text()).slice(0, 300)} (run any firebase command to refresh the login)`);
}

async function removeObject(name) {
  await fetch(`https://storage.googleapis.com/storage/v1/b/${BUCKET}/o/${encodeURIComponent(name)}`, { method: "DELETE", headers: H });
}

async function getDoc(id) {
  const r = await fetch(`${DOCS}/instagram_posts/${id}`, { headers: H });
  if (r.status === 404) return null;
  if (!r.ok) die(`read ${id}: ${r.status} ${(await r.text()).slice(0, 300)}`);
  return r.json();
}

async function push(id) {
  const dir = path.join(POSTS, id);
  const specFile = path.join(dir, "post.json");
  if (!fs.existsSync(specFile)) die(`no post ${id}`);
  const spec = JSON.parse(fs.readFileSync(specFile, "utf8"));
  const out = path.join(dir, "out");
  const files = fs.existsSync(out) ? fs.readdirSync(out).filter((f) => f.endsWith(".jpg")).sort() : [];
  if (!files.length) die(`${id}: no images; run python3 tools/instagram/compose.py ${id}`);
  if (files.length !== (spec.slides || []).length) die(`${id}: ${files.length} images for ${spec.slides.length} slides; re-run compose.py`);

  const consoleId = spec.consoleId || `claude_${id}`;
  const existing = await getDoc(consoleId);
  const status = existing && existing.fields.status && existing.fields.status.stringValue;
  if (status === "published" || status === "publishing") { console.log(`skip ${id}: already ${status} in the console`); return; }
  const oldPaths = existing ? ((existing.fields.media && existing.fields.media.arrayValue.values) || []).map((v) => v.mapValue.fields.path.stringValue) : [];

  const media = [];
  for (const f of files) {
    const name = `marketing/instagram/${consoleId}/${f}`;
    await upload(path.join(out, f), name);
    media.push({ path: name, kind: "image", contentType: "image/jpeg", ...jpegSize(fs.readFileSync(path.join(out, f))) });
  }
  for (const p of oldPaths) if (!media.some((m) => m.path === p)) await removeObject(p);

  const now = new Date();
  const fields = {
    type: spec.type, title: spec.title || id.replace(/^\d+_/, "").replace(/_/g, " "), caption: spec.caption || "",
    media, source: "claude", status: "draft", updatedAt: now, updatedBy: "claude",
    createdAt: existing && existing.fields.createdAt ? new Date(existing.fields.createdAt.timestampValue) : now,
  };
  const mask = Object.keys(fields).map((k) => `updateMask.fieldPaths=${k}`).join("&");
  // scheduledAt and error are dropped: a re-pushed draft starts clean.
  const body = JSON.stringify({ fields: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, enc(v)])) });
  const r = await fetch(`${DOCS}/instagram_posts/${consoleId}?${mask}&updateMask.fieldPaths=scheduledAt&updateMask.fieldPaths=error`, {
    method: "PATCH", headers: { ...H, "Content-Type": "application/json" }, body,
  });
  if (!r.ok) die(`write ${consoleId}: ${r.status} ${(await r.text()).slice(0, 300)}`);
  if (spec.consoleId !== consoleId) {
    spec.consoleId = consoleId;
    fs.writeFileSync(specFile, JSON.stringify(spec, null, 2) + "\n");
  }
  console.log(`${existing ? "updated" : "created"} ${consoleId}: ${media.length} images${status && status !== "draft" ? ` (was ${status}, now draft)` : ""}`);
}

const args = process.argv.slice(2);
const ids = args.includes("--all") ? fs.readdirSync(POSTS).filter((d) => fs.existsSync(path.join(POSTS, d, "post.json"))).sort() : args;
if (!ids.length) die("usage: push.mjs <id> [<id> …] | --all");
for (const id of ids) await push(id);
