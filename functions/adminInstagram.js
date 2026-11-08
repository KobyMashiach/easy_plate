// The app's Instagram account, run from the web console (Instagram page).
//
// Instagram's own API ("Instagram API with Instagram Login": a professional
// account, no Facebook Page) is free; the media it publishes is fetched by
// Instagram from a public URL, which here is a Storage download-token URL
// added at publish time.
//
//   instagram_posts/{id}          one post: type, caption, media (Storage
//                                 paths), status, schedule, what came of it
//   admin_config/instagram        the account as the console shows it
//   admin_config/instagram_private
//                                 the access token — read by the server
//                                 only (firestore.rules), never sent back
//
// Status: draft → approved → scheduled → publishing → published | failed.
// Only an approved (or scheduled) post goes out, and editing one sends it
// back to draft, so what is published is exactly what was approved.
// `scheduledAt` exists only while a post is scheduled, so the runner's
// query is one range on it.
//
// Captions are written by hand (Claude or Koby); nothing here calls a
// model, so the whole feature costs nothing beyond Firestore/Storage.
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

const POSTS = "instagram_posts";
const ACCOUNT_DOC = "admin_config/instagram";
const TOKEN_DOC = "admin_config/instagram_private";
const GRAPH = "https://graph.instagram.com/v23.0";
const MEDIA_PREFIX = "marketing/instagram/";
const TZ = "Asia/Jerusalem";
const DAY_MS = 24 * 3600 * 1000;
const TOKEN_LIFE_MS = 60 * DAY_MS;
const REFRESH_EVERY_MS = 7 * DAY_MS;
const INSIGHTS_EVERY_MS = DAY_MS;
const INSIGHTS_WINDOW_MS = 30 * DAY_MS;
const STUCK_MS = 15 * 60 * 1000;
const MIN_LEAD_MS = 60 * 1000;
const MAX_AHEAD_MS = 75 * DAY_MS;

const TYPES = ["image", "carousel", "reel", "story"];
const STATUSES = ["draft", "approved", "scheduled", "publishing", "published", "failed"];
const EDITABLE = new Set(["draft", "approved", "scheduled", "failed"]);
const IMAGE_TYPES = new Set(["image/jpeg"]);
const VIDEO_TYPES = new Set(["video/mp4", "video/quicktime"]);
const MAX_CAPTION = 2200;
const MAX_HASHTAGS = 30;
const MAX_MENTIONS = 20;
const MAX_TITLE = 120;

// Koby's creative rule: nothing public mentions prices, plans, tiers,
// Premium/Pro or trials; every feature is presented as open to everyone.
// "מחיר"/"price" alone is allowed: the receipt scanner is about grocery
// prices, and that is a feature, not the app's own price.
const CREATIVE_RULE = /premium|פרימיום|פרמיום|\bpro\b|מנוי|subscription|abonnement|подписк|اشتراك|₪|€|\$\s?\d|\d\s?\$|trial|תקופת ניסיון|ניסיון חינם|חינם|unlimited|ללא הגבלה|בלי הגבלה/i;

function refused(message, code = "invalid", status = 400) {
  return Object.assign(new Error(message), { status, code });
}

// ---------------------------------------------------------------------------
// Pure: validation.
// ---------------------------------------------------------------------------

function hashtags(caption) {
  return (String(caption || "").match(/(^|\s)#[^\s#]+/g) || []).length;
}
function mentions(caption) {
  return (String(caption || "").match(/(^|\s)@[A-Za-z0-9._]+/g) || []).length;
}

// One media item as the console or push.mjs sent it, or null.
function cleanMedia(item) {
  if (!item || typeof item !== "object") return null;
  const path = typeof item.path === "string" ? item.path.trim() : "";
  if (!path.startsWith(MEDIA_PREFIX) || path.includes("..") || path.length > 300) return null;
  const contentType = String(item.contentType || "").toLowerCase();
  const kind = IMAGE_TYPES.has(contentType) ? "image" : VIDEO_TYPES.has(contentType) ? "video" : null;
  if (!kind) return null;
  const out = { path, kind, contentType };
  for (const k of ["width", "height"]) {
    const n = Number(item[k]);
    if (Number.isFinite(n) && n > 0 && n < 20000) out[k] = Math.round(n);
  }
  return out;
}

// Why this post cannot go to Instagram as it is: a list of problems, empty
// when it can. Checked on approve, on publish and shown by the console.
function problems(post) {
  const out = [];
  const media = Array.isArray(post.media) ? post.media : [];
  const caption = String(post.caption || "");
  const images = media.filter((m) => m.kind === "image").length;
  const videos = media.length - images;
  switch (post.type) {
    case "image":
      if (media.length !== 1 || images !== 1) out.push("an image post takes exactly one image");
      break;
    case "carousel":
      if (media.length < 2 || media.length > 10) out.push("a carousel takes 2 to 10 items");
      break;
    case "reel":
      if (media.length !== 1 || videos !== 1) out.push("a reel takes exactly one video");
      break;
    case "story":
      if (media.length !== 1) out.push("a story takes exactly one image or video");
      break;
    default:
      out.push("unknown post type");
  }
  if (post.type !== "story") {
    // Feed images: Instagram refuses anything outside 4:5 … 1.91:1.
    for (const m of media) {
      if (m.kind !== "image" || !m.width || !m.height) continue;
      const ratio = m.width / m.height;
      if (ratio < 0.8 - 0.01 || ratio > 1.91 + 0.01) { out.push("feed images must be between 4:5 (portrait) and 1.91:1 (landscape)"); break; }
    }
  }
  if (post.type !== "story" && !caption.trim()) out.push("the caption is empty");
  if (caption.length > MAX_CAPTION) out.push(`the caption is ${caption.length} characters (at most ${MAX_CAPTION})`);
  if (hashtags(caption) > MAX_HASHTAGS) out.push(`more than ${MAX_HASHTAGS} hashtags`);
  if (mentions(caption) > MAX_MENTIONS) out.push(`more than ${MAX_MENTIONS} mentions`);
  if (CREATIVE_RULE.test(caption)) out.push("the caption mentions a price, a plan or Premium (creative rule)");
  return out;
}

// The post document from a save request, or { error }.
function cleanPost(request) {
  const type = TYPES.includes(request.type) ? request.type : null;
  if (!type) return { error: "type must be one of " + TYPES.join(", ") };
  const raw = Array.isArray(request.media) ? request.media : [];
  const media = raw.map(cleanMedia);
  if (media.some((m) => !m)) return { error: `media must be JPEG images or MP4/MOV videos under ${MEDIA_PREFIX}` };
  if (!media.length) return { error: "add at least one image or video" };
  if (media.length > 10) return { error: "at most 10 items" };
  const caption = String(request.caption || "").replace(/\r\n/g, "\n").trim();
  if (caption.length > MAX_CAPTION) return { error: `the caption is longer than ${MAX_CAPTION} characters` };
  const title = String(request.title || "").trim().slice(0, MAX_TITLE);
  const source = request.source === "claude" ? "claude" : "upload";
  return { post: { type, caption, media, title, source } };
}

// ---------------------------------------------------------------------------
// Graph API.
// ---------------------------------------------------------------------------

async function graph(fetchImpl, token, method, path, params = {}) {
  const query = new URLSearchParams({ ...params, access_token: token });
  const url = method === "GET" || method === "DELETE" ? `${GRAPH}/${path}?${query}` : `${GRAPH}/${path}`;
  const res = await fetchImpl(url, method === "GET" ? {} : { method, body: method === "DELETE" ? undefined : query });
  let body = {};
  try { body = await res.json(); } catch (_) {}
  if (!res.ok || body.error) {
    const e = body.error || {};
    const message = e.error_user_msg || e.message || `HTTP ${res.status}`;
    // A dead token is the operator's to fix (reconnect), not a crash.
    const expired = e.code === 190;
    throw refused(`Instagram: ${message}`, expired ? "ig_token" : "upstream", expired ? 409 : 502);
  }
  return body;
}

async function loadToken(db) {
  const snap = await db.doc(TOKEN_DOC).get();
  const token = snap.exists ? snap.get("accessToken") : "";
  if (!token) throw refused("Instagram is not connected yet", "ig_not_connected", 409);
  return { token, userId: snap.get("userId") };
}

// ---------------------------------------------------------------------------
// Account.
// ---------------------------------------------------------------------------

const PROFILE_FIELDS = "user_id,username,name,profile_picture_url,followers_count,follows_count,media_count,account_type";

async function profileSummary(fetchImpl, token) {
  const me = await graph(fetchImpl, token, "GET", "me", { fields: PROFILE_FIELDS });
  return {
    userId: String(me.user_id || me.id || ""),
    username: me.username || "",
    name: me.name || "",
    picture: me.profile_picture_url || "",
    followers: Number(me.followers_count) || 0,
    follows: Number(me.follows_count) || 0,
    mediaCount: Number(me.media_count) || 0,
    accountType: me.account_type || "",
  };
}

async function connect(db, fetchImpl, rawToken, now = Date.now()) {
  const token = String(rawToken || "").trim();
  if (!/^[A-Za-z0-9_\-.|]{20,1000}$/.test(token)) throw refused("That does not look like an Instagram access token");
  const profile = await profileSummary(fetchImpl, token);
  if (!profile.userId) throw refused("Instagram did not return the account id");
  const ts = admin.firestore.Timestamp.fromMillis;
  await db.doc(TOKEN_DOC).set({ accessToken: token, userId: profile.userId, refreshedAt: ts(now) });
  await db.doc(ACCOUNT_DOC).set({
    ...profile, connected: true, refreshedAt: ts(now), expiresAt: ts(now + TOKEN_LIFE_MS), profileAt: ts(now),
  }, { merge: true });
  return { account: profile };
}

async function disconnect(db) {
  await db.doc(TOKEN_DOC).delete();
  await db.doc(ACCOUNT_DOC).set({ connected: false }, { merge: true });
  return {};
}

// The console's header: the stored summary, refreshed live when connected,
// plus how many API posts are left in the rolling 24 hours.
async function accountInfo(db, fetchImpl, now = Date.now()) {
  const stored = await db.doc(ACCOUNT_DOC).get();
  const base = stored.exists ? stored.data() : {};
  let tokenDoc;
  try { tokenDoc = await loadToken(db); } catch (_) { return { connected: false, account: null }; }
  const out = { connected: true, account: { ...base } };
  try {
    const profile = await profileSummary(fetchImpl, tokenDoc.token);
    out.account = { ...out.account, ...profile };
    await db.doc(ACCOUNT_DOC).set({ ...profile, profileAt: admin.firestore.Timestamp.fromMillis(now) }, { merge: true });
    const limit = await graph(fetchImpl, tokenDoc.token, "GET", `${tokenDoc.userId}/content_publishing_limit`, { fields: "quota_usage,config" });
    const row = (limit.data && limit.data[0]) || {};
    out.quota = { used: Number(row.quota_usage) || 0, total: Number(row.config && row.config.quota_total) || 50 };
  } catch (err) {
    out.error = err.message;
    if (err.code === "ig_token") out.tokenExpired = true;
  }
  for (const k of ["refreshedAt", "expiresAt", "profileAt", "insightsAt"]) {
    const v = out.account[k];
    if (v && typeof v.toMillis === "function") out.account[k] = v.toMillis();
  }
  return out;
}

async function refreshToken(db, fetchImpl, now = Date.now()) {
  const { token } = await loadToken(db);
  const res = await fetchImpl(`https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=${encodeURIComponent(token)}`);
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.access_token) throw refused(`Instagram token refresh: ${(body.error && body.error.message) || res.status}`, "upstream", 502);
  const ts = admin.firestore.Timestamp.fromMillis;
  const life = Number(body.expires_in) > 0 ? Number(body.expires_in) * 1000 : TOKEN_LIFE_MS;
  await db.doc(TOKEN_DOC).set({ accessToken: body.access_token, refreshedAt: ts(now) }, { merge: true });
  await db.doc(ACCOUNT_DOC).set({ refreshedAt: ts(now), expiresAt: ts(now + life) }, { merge: true });
  return { expiresAt: now + life };
}

// ---------------------------------------------------------------------------
// Posts: state changes.
// ---------------------------------------------------------------------------

const stamp = (caller, now) => ({ updatedAt: admin.firestore.Timestamp.fromMillis(now), updatedBy: (caller && caller.uid) || "system" });
const del = () => admin.firestore.FieldValue.delete();

async function getPost(db, id) {
  const ref = db.collection(POSTS).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw refused("No such post", "not_found", 404);
  return { ref, post: snap.data() };
}

// Every listed file has to exist in the bucket: a path typed by hand, or an
// upload that never finished, would only fail at publish time otherwise.
async function assertMediaExists(bucket, media) {
  for (const m of media) {
    const [exists] = await bucket.file(m.path).exists();
    if (!exists) throw refused(`missing file ${m.path}`);
  }
}

async function savePost(db, bucket, request, caller, now = Date.now()) {
  const { post, error } = cleanPost(request);
  if (error) throw refused(error);
  await assertMediaExists(bucket, post.media);
  const ts = admin.firestore.Timestamp.fromMillis;
  if (request.id) {
    const ref = db.collection(POSTS).doc(request.id);
    const snap = await ref.get();
    if (snap.exists) {
      const status = snap.get("status");
      if (!EDITABLE.has(status)) throw refused(`a ${status} post cannot be edited`, "conflict", 409);
      const before = snap.get("media") || [];
      // Back to draft: what goes out must be what was approved.
      await ref.update({ ...post, source: snap.get("source") || post.source, status: "draft", scheduledAt: del(), error: del(), ...stamp(caller, now) });
      await removeUnused(bucket, before, post.media);
      return { id: ref.id, status: "draft", problems: problems(post) };
    }
    await ref.set({ ...post, status: "draft", createdAt: ts(now), ...stamp(caller, now) });
    return { id: ref.id, status: "draft", problems: problems(post) };
  }
  const ref = db.collection(POSTS).doc();
  await ref.set({ ...post, status: "draft", createdAt: ts(now), ...stamp(caller, now) });
  return { id: ref.id, status: "draft", problems: problems(post) };
}

async function removeUnused(bucket, before, after) {
  const keep = new Set(after.map((m) => m.path));
  for (const m of before) if (m && m.path && !keep.has(m.path)) await bucket.file(m.path).delete().catch(() => {});
}

async function approve(db, id, caller, now = Date.now()) {
  const { ref, post } = await getPost(db, id);
  if (!["draft", "failed"].includes(post.status)) throw refused(`a ${post.status} post cannot be approved`, "conflict", 409);
  const found = problems(post);
  if (found.length) throw refused(found.join("; "));
  await ref.update({ status: "approved", approvedAt: admin.firestore.Timestamp.fromMillis(now), approvedBy: caller.uid, error: del(), ...stamp(caller, now) });
  return { status: "approved" };
}

// Back to draft without editing: the operator changed their mind.
async function unapprove(db, id, caller, now = Date.now()) {
  const { ref, post } = await getPost(db, id);
  if (!["approved", "scheduled", "failed"].includes(post.status)) throw refused(`a ${post.status} post is not approved`, "conflict", 409);
  await ref.update({ status: "draft", scheduledAt: del(), ...stamp(caller, now) });
  return { status: "draft" };
}

async function schedule(db, id, at, caller, now = Date.now()) {
  const when = Number(at);
  if (!Number.isFinite(when) || when < now + MIN_LEAD_MS) throw refused("pick a time at least a minute from now");
  if (when > now + MAX_AHEAD_MS) throw refused("pick a time within 75 days");
  const { ref, post } = await getPost(db, id);
  if (!["approved", "scheduled"].includes(post.status)) throw refused("approve the post before scheduling it", "conflict", 409);
  await ref.update({ status: "scheduled", scheduledAt: admin.firestore.Timestamp.fromMillis(when), ...stamp(caller, now) });
  return { status: "scheduled", scheduledAt: when };
}

async function unschedule(db, id, caller, now = Date.now()) {
  const { ref, post } = await getPost(db, id);
  if (post.status !== "scheduled") throw refused("the post is not scheduled", "conflict", 409);
  await ref.update({ status: "approved", scheduledAt: del(), ...stamp(caller, now) });
  return { status: "approved" };
}

async function removePost(db, bucket, id) {
  const { ref, post } = await getPost(db, id);
  if (post.status === "publishing") throw refused("the post is being published right now", "conflict", 409);
  await ref.delete();
  for (const m of post.media || []) if (m && m.path) await bucket.file(m.path).delete().catch(() => {});
  // A published post stays on Instagram; the API cannot delete it.
  return { stillOnInstagram: post.status === "published" ? (post.published && post.published.permalink) || true : false };
}

// ---------------------------------------------------------------------------
// Publishing.
// ---------------------------------------------------------------------------

// A public URL Instagram can fetch: the Firebase download-token URL, the
// token added to the object's metadata if it has none yet.
async function publicUrl(bucket, path) {
  const file = bucket.file(path);
  const [meta] = await file.getMetadata();
  let token = meta && meta.metadata && meta.metadata.firebaseStorageDownloadTokens;
  token = token ? String(token).split(",")[0] : "";
  if (!token) {
    token = crypto.randomUUID();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  }
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

// Pure: the container requests for a post, given the public URL of each
// item. The last request is the one that gets published.
function containerRequests(post, urls) {
  const caption = post.caption || "";
  const item = (m, url, extra = {}) => (m.kind === "video" ? { media_type: "VIDEO", video_url: url, ...extra } : { image_url: url, ...extra });
  switch (post.type) {
    case "carousel":
      return { children: post.media.map((m, i) => item(m, urls[i], { is_carousel_item: "true" })), parent: { media_type: "CAROUSEL", caption } };
    case "reel":
      return { children: [], parent: { media_type: "REELS", video_url: urls[0], caption, share_to_feed: "true" } };
    case "story":
      return { children: [], parent: post.media[0].kind === "video" ? { media_type: "STORIES", video_url: urls[0] } : { media_type: "STORIES", image_url: urls[0] } };
    default:
      return { children: [], parent: { image_url: urls[0], caption } };
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitReady(fetchImpl, token, container, deadline, pause = 4000) {
  while (true) {
    const { status_code: code, status } = await graph(fetchImpl, token, "GET", container, { fields: "status_code,status" });
    if (code === "FINISHED" || code === "PUBLISHED") return;
    if (code === "ERROR" || code === "EXPIRED") throw refused(`Instagram could not process the media: ${status || code}`, "upstream", 502);
    if (Date.now() + pause > deadline) throw refused("Instagram is still processing the media; try again in a few minutes", "upstream", 502);
    await sleep(pause);
  }
}

// Claims the post (→ publishing) in a transaction, so a click and the
// runner, or two clicks, never publish it twice. Returns the post or null.
async function claim(db, ref, { now, scheduledOnly }) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const post = snap.data();
    if (scheduledOnly) {
      if (post.status !== "scheduled" || !post.scheduledAt || post.scheduledAt.toMillis() > now) return null;
    } else if (!["approved", "scheduled"].includes(post.status)) {
      return null;
    }
    tx.update(ref, { status: "publishing", publishingSince: admin.firestore.Timestamp.fromMillis(now), scheduledAt: del() });
    return post;
  });
}

async function publish(db, bucket, ref, post, { fetchImpl, deadline, now = Date.now(), pause }) {
  const ts = admin.firestore.Timestamp.fromMillis;
  try {
    const found = problems(post);
    if (found.length) throw refused(found.join("; "));
    const { token, userId } = await loadToken(db);
    const urls = [];
    for (const m of post.media) urls.push(await publicUrl(bucket, m.path));
    const { children, parent } = containerRequests(post, urls);
    const childIds = [];
    for (const c of children) {
      const made = await graph(fetchImpl, token, "POST", `${userId}/media`, c);
      await waitReady(fetchImpl, token, made.id, deadline, pause);
      childIds.push(made.id);
    }
    const body = childIds.length ? { ...parent, children: childIds.join(",") } : parent;
    const container = await graph(fetchImpl, token, "POST", `${userId}/media`, body);
    await waitReady(fetchImpl, token, container.id, deadline, pause);
    const done = await graph(fetchImpl, token, "POST", `${userId}/media_publish`, { creation_id: container.id });
    let permalink = "";
    try { permalink = (await graph(fetchImpl, token, "GET", done.id, { fields: "permalink" })).permalink || ""; } catch (_) {}
    const published = { mediaId: String(done.id), permalink, at: ts(Date.now()) };
    await ref.update({ status: "published", published, error: del(), publishingSince: del(), updatedAt: ts(Date.now()) });
    return { status: "published", permalink, mediaId: String(done.id) };
  } catch (err) {
    await ref.update({ status: "failed", error: String(err.message || err).slice(0, 500), publishingSince: del(), updatedAt: ts(now) });
    throw err;
  }
}

async function publishNow(db, bucket, id, { fetchImpl, deadline, now = Date.now() }) {
  const ref = db.collection(POSTS).doc(id);
  const post = await claim(db, ref, { now, scheduledOnly: false });
  if (!post) throw refused("only an approved or scheduled post can be published (is it already going out?)", "conflict", 409);
  return publish(db, bucket, ref, post, { fetchImpl, deadline, now });
}

// ---------------------------------------------------------------------------
// Insights and comments.
// ---------------------------------------------------------------------------

async function mediaInsights(fetchImpl, token, mediaId, type) {
  const out = {};
  const basic = await graph(fetchImpl, token, "GET", mediaId, { fields: "like_count,comments_count,permalink" });
  out.likes = Number(basic.like_count) || 0;
  out.comments = Number(basic.comments_count) || 0;
  // The metrics Instagram offers differ by media type; ask for the wide set
  // and fall back to the one every type has.
  const sets = type === "story" ? ["reach,replies,views", "reach"] : ["reach,saved,shares,views", "reach,saved", "reach"];
  for (const metric of sets) {
    try {
      const res = await graph(fetchImpl, token, "GET", `${mediaId}/insights`, { metric });
      for (const row of res.data || []) {
        const v = row.values && row.values[0] ? row.values[0].value : row.total_value && row.total_value.value;
        if (Number.isFinite(Number(v))) out[row.name] = Number(v);
      }
      break;
    } catch (err) {
      if (err.code === "ig_token") throw err;
    }
  }
  return out;
}

async function refreshInsights(db, fetchImpl, { id, now = Date.now() } = {}) {
  const { token } = await loadToken(db);
  const ts = admin.firestore.Timestamp.fromMillis;
  let docs;
  if (id) {
    const snap = await db.collection(POSTS).doc(id).get();
    docs = snap.exists ? [snap] : [];
  } else {
    const snap = await db.collection(POSTS).where("published.at", ">=", ts(now - INSIGHTS_WINDOW_MS)).limit(100).get();
    docs = snap.docs;
  }
  let count = 0;
  for (const doc of docs) {
    const post = doc.data();
    if (post.status !== "published" || !post.published || !post.published.mediaId) continue;
    try {
      const insights = await mediaInsights(fetchImpl, token, post.published.mediaId, post.type);
      await doc.ref.update({ insights: { ...insights, at: ts(now) } });
      count++;
    } catch (err) {
      if (err.code === "ig_token") throw err;
      logger.warn("instagram insights failed", { id: doc.id, reason: err.message });
    }
  }
  if (!id) await db.doc(ACCOUNT_DOC).set({ insightsAt: ts(now) }, { merge: true });
  return { refreshed: count };
}

async function listComments(db, fetchImpl, id) {
  const { post } = await getPost(db, id);
  if (!post.published || !post.published.mediaId) throw refused("the post is not published", "conflict", 409);
  const { token } = await loadToken(db);
  const res = await graph(fetchImpl, token, "GET", `${post.published.mediaId}/comments`, {
    fields: "id,text,username,timestamp,like_count,hidden,replies{id,text,username,timestamp,hidden}",
    limit: "50",
  });
  const shape = (c) => ({ id: c.id, text: c.text || "", username: c.username || "", at: c.timestamp || null, likes: Number(c.like_count) || 0, hidden: !!c.hidden });
  return { comments: (res.data || []).map((c) => ({ ...shape(c), replies: ((c.replies && c.replies.data) || []).map(shape) })) };
}

async function replyComment(db, fetchImpl, commentId, text) {
  const message = String(text || "").trim();
  if (!message) throw refused("write a reply first");
  if (CREATIVE_RULE.test(message)) throw refused("the reply mentions a price, a plan or Premium (creative rule)");
  const { token } = await loadToken(db);
  const res = await graph(fetchImpl, token, "POST", `${commentId}/replies`, { message: message.slice(0, MAX_CAPTION) });
  return { id: res.id };
}

async function hideComment(db, fetchImpl, commentId, hide) {
  const { token } = await loadToken(db);
  await graph(fetchImpl, token, "POST", commentId, { hide: hide ? "true" : "false" });
  return { hidden: !!hide };
}

// ---------------------------------------------------------------------------
// The runner.
// ---------------------------------------------------------------------------

async function runDue(db, bucket, { fetchImpl = fetch, now = Date.now(), budgetMs = 480000 } = {}) {
  const ts = admin.firestore.Timestamp.fromMillis;
  const deadline = now + budgetMs;
  const result = { published: 0, failed: 0, stuck: 0, insights: false, refreshed: false };

  // A post left in publishing (a crash mid-way) may or may not be on
  // Instagram; it is marked failed and the operator checks before retrying.
  const stuck = await db.collection(POSTS).where("publishingSince", "<=", ts(now - STUCK_MS)).limit(20).get();
  for (const doc of stuck.docs) {
    if (doc.get("status") !== "publishing") continue;
    await doc.ref.update({ status: "failed", error: "Publishing was interrupted. Check the Instagram profile before trying again.", publishingSince: del(), updatedAt: ts(now) });
    result.stuck++;
  }

  const due = await db.collection(POSTS).where("scheduledAt", "<=", ts(now)).limit(10).get();
  for (const doc of due.docs) {
    if (Date.now() > deadline - 60000) break;
    let post;
    try { post = await claim(db, doc.ref, { now, scheduledOnly: true }); } catch (err) {
      logger.warn("instagram claim failed", { id: doc.id, reason: err.message });
      continue;
    }
    if (!post) continue;
    try {
      await publish(db, bucket, doc.ref, post, { fetchImpl, deadline, now });
      result.published++;
    } catch (err) {
      result.failed++;
      logger.warn("scheduled instagram post failed", { id: doc.id, reason: err.message });
    }
  }

  const account = await db.doc(ACCOUNT_DOC).get();
  if (account.exists && account.get("connected")) {
    const millis = (k) => { const v = account.get(k); return v && typeof v.toMillis === "function" ? v.toMillis() : 0; };
    if (now - millis("refreshedAt") >= REFRESH_EVERY_MS) {
      try { await refreshToken(db, fetchImpl, now); result.refreshed = true; } catch (err) { logger.warn("instagram token refresh failed", { reason: err.message }); }
    }
    if (now - millis("insightsAt") >= INSIGHTS_EVERY_MS) {
      try {
        await refreshInsights(db, fetchImpl, { now });
        const { token } = await loadToken(db);
        const profile = await profileSummary(fetchImpl, token);
        await db.doc(ACCOUNT_DOC).set({ ...profile, profileAt: ts(now) }, { merge: true });
        result.insights = true;
      } catch (err) { logger.warn("instagram daily refresh failed", { reason: err.message }); }
    }
  }
  return result;
}

const runInstagram = onSchedule(
  { schedule: "every 5 minutes", timeZone: TZ, region: "europe-west1", retryCount: 0, timeoutSeconds: 540, memory: "256MiB" },
  async () => {
    const result = await runDue(admin.firestore(), admin.storage().bucket());
    if (result.published || result.failed || result.stuck) logger.info("instagram runner", result);
  },
);

// ---------------------------------------------------------------------------
// adminPanel actions.
// ---------------------------------------------------------------------------

async function handle(request, { caller, db, bucket, fetchImpl = fetch, deadline }) {
  const now = Date.now();
  switch (request.action) {
    case "ig.account.get": return accountInfo(db, fetchImpl, now);
    case "ig.account.connect": return connect(db, fetchImpl, request.token, now);
    case "ig.account.disconnect": return disconnect(db);
    case "ig.account.refresh": return refreshToken(db, fetchImpl, now);
    case "ig.post.save": return savePost(db, bucket, request, caller, now);
    case "ig.post.approve": return approve(db, request.id, caller, now);
    case "ig.post.unapprove": return unapprove(db, request.id, caller, now);
    case "ig.post.schedule": return schedule(db, request.id, request.at, caller, now);
    case "ig.post.unschedule": return unschedule(db, request.id, caller, now);
    case "ig.post.publish": return publishNow(db, bucket, request.id, { fetchImpl, deadline: deadline || now + 240000, now });
    case "ig.post.delete": return removePost(db, bucket, request.id);
    case "ig.insights.refresh": return refreshInsights(db, fetchImpl, { id: request.id, now });
    case "ig.comments.list": return listComments(db, fetchImpl, request.id);
    case "ig.comment.reply": return replyComment(db, fetchImpl, request.commentId, request.text);
    case "ig.comment.hide": return hideComment(db, fetchImpl, request.commentId, request.hide === true);
    default: throw refused("unknown action");
  }
}

module.exports = {
  POSTS, ACCOUNT_DOC, TOKEN_DOC, MEDIA_PREFIX,
  handle, runDue, runInstagram,
  internals: {
    problems, cleanPost, cleanMedia, containerRequests, hashtags, mentions, claim, publish, publishNow, savePost, approve, unapprove,
    schedule, unschedule, removePost, connect, accountInfo, refreshToken, refreshInsights, mediaInsights, listComments, replyComment,
    hideComment, waitReady, publicUrl, CREATIVE_RULE, STATUSES, TYPES, STUCK_MS,
  },
};
