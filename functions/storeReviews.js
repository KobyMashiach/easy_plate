// Store reviews and ratings, both stores in one inbox, with replies sent
// back to the store from the console.
//
//   Google Play   Two sources, merged by review id:
//                 · the Play Developer API (androidpublisher v3 reviews) —
//                   only reviews written or edited in the last 7 days, but
//                   live, and the only way to reply. Needs the function's
//                   service account invited in Play Console with the app
//                   permission "Reply to reviews" and the Google Play
//                   Android Developer API enabled on the project.
//                 · the monthly reviews CSV the Play Console exports to the
//                   same bucket the Downloads page reads
//                   (reviews/reviews_<package>_<YYYYMM>.csv) — the whole
//                   history, star-only ratings included.
//                 The average comes from stats/ratings/…_overview.csv.
//   App Store     App Store Connect API customerReviews (rating, title,
//                 body, nickname, territory, response) — the same key as
//                 the Downloads page, which must then carry the Admin or
//                 Customer Support role. Apple has no API for star-only
//                 ratings; the average and count per storefront come from
//                 the public iTunes lookup.
//
//   store_reviews/{android|ios}_{id}   one review, newest state
//   store_reviews_meta/summary         averages, counts, last sync, errors
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const crypto = require("node:crypto");
const { GoogleAuth } = require("google-auth-library");
const stats = require("./storeStats");

const { decodeReport, parseCsv, normalizePem, isPem, appleJwt } = stats.internals;
const COLLECTION = "store_reviews";
const META = "store_reviews_meta/summary";
const PLAY_API = "https://androidpublisher.googleapis.com/androidpublisher/v3";
const ASC_HOST = "https://api.appstoreconnect.apple.com";
// Store limits on a reply.
const MAX_REPLY = { android: 350, ios: 5970 };
// Storefronts asked for the App Store average; the lookup answers one at a time.
const IOS_STOREFRONTS = ["il", "us", "gb", "ca", "au", "fr", "de", "ru", "ae", "sa"];
const HTTP_TIMEOUT_MS = 30000;

const norm = (s) => String(s || "").trim().toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
const int = (v) => {
  const n = parseInt(String(v === undefined || v === null ? "" : v).replace(/[^-\d]/g, ""), 10);
  return Number.isFinite(n) ? n : 0;
};
const clip = (v, max) => String(v === undefined || v === null ? "" : v).slice(0, max);
const safeId = (raw) => String(raw || "").replace(/[/\s]+/g, "_").slice(0, 300);

function objects(rows) {
  if (!rows.length) return [];
  const header = rows[0].map(norm);
  return rows.slice(1).map((r) => Object.fromEntries(header.map((k, i) => [k, r[i] === undefined ? "" : String(r[i]).trim()])));
}

// ---------------------------------------------------------------------------
// Pure: one shape for a review from any source.
//   { platform, storeId, author, rating, title, text, lang, country, device,
//     appVersion, createdAt, updatedAt, reply: {text, at, state} | null,
//     link }
// ---------------------------------------------------------------------------

// The review id inside a Play Console review link, both the old
// (#ReviewDetailsPlace:…&reviewid=gp:…) and the new (?reviewId=gp:…) form.
function playIdFromLink(link) {
  const m = String(link || "").match(/review_?id=([^&#\s]+)/i);
  if (!m) return "";
  try {
    return decodeURIComponent(m[1]);
  } catch (_) {
    return m[1];
  }
}

// One month's reviews CSV → reviews. A star-only rating has no link (and so
// no id); it gets a stable id from what it does carry.
function parsePlayReviewsCsv(text, pkg = "") {
  const out = [];
  for (const row of objects(parseCsv(text))) {
    if (pkg && row["package name"] && row["package name"] !== pkg) continue;
    const rating = int(row["star rating"]);
    if (rating < 1 || rating > 5) continue;
    const created = int(row["review submit millis since epoch"]) || Date.parse(row["review submit date and time"]) || 0;
    const updated = int(row["review last update millis since epoch"]) || Date.parse(row["review last update date and time"]) || created;
    const replyAt = int(row["developer reply millis since epoch"]) || Date.parse(row["developer reply date and time"]) || 0;
    const link = row["review link"] || "";
    const storeId = playIdFromLink(link) || `csv_${crypto.createHash("sha1").update(`${created}|${row.device || ""}|${row["reviewer language"] || ""}|${rating}`).digest("hex").slice(0, 24)}`;
    const replyText = row["developer reply text"] || "";
    out.push({
      platform: "android",
      storeId,
      author: "",
      rating,
      title: row["review title"] || "",
      text: row["review text"] || "",
      lang: row["reviewer language"] || "",
      country: "",
      device: row.device || "",
      appVersion: row["app version name"] || "",
      createdAt: created || null,
      updatedAt: updated || created || null,
      reply: replyText ? { text: replyText, at: replyAt || null, state: "published" } : null,
      link,
    });
  }
  return out;
}

const seconds = (ts) => (ts && ts.seconds !== undefined ? Number(ts.seconds) * 1000 + Math.floor(Number(ts.nanos || 0) / 1e6) : null);

// One review from androidpublisher reviews.list.
function fromPlayApi(review) {
  const comments = Array.isArray(review && review.comments) ? review.comments : [];
  const user = (comments.find((c) => c.userComment) || {}).userComment || {};
  const dev = (comments.find((c) => c.developerComment) || {}).developerComment || null;
  const updated = seconds(user.lastModified);
  const meta = user.deviceMetadata || {};
  return {
    platform: "android",
    storeId: String(review.reviewId || ""),
    author: review.authorName || "",
    rating: int(user.starRating),
    title: "",
    // A review written in another language comes back translated when a
    // translation language is asked for; we keep the reviewer's own words.
    text: String(user.originalText || user.text || "").trim(),
    lang: user.reviewerLanguage || "",
    country: "",
    device: [meta.manufacturer, meta.productName].filter(Boolean).join(" ") || user.device || "",
    appVersion: user.appVersionName || "",
    createdAt: updated,
    updatedAt: updated,
    reply: dev && dev.text ? { text: dev.text, at: seconds(dev.lastModified), state: "published" } : null,
    link: "",
    thumbsUp: int(user.thumbsUpCount),
  };
}

// One review from App Store Connect customerReviews, with the included
// response (if any).
function fromApple(item, included = []) {
  const a = (item && item.attributes) || {};
  const rel = item && item.relationships && item.relationships.response && item.relationships.response.data;
  const response = rel ? included.find((x) => x.type === "customerReviewResponses" && x.id === rel.id) : null;
  const ra = (response && response.attributes) || {};
  const created = Date.parse(a.createdDate || "") || null;
  return {
    platform: "ios",
    storeId: String(item.id || ""),
    author: a.reviewerNickname || "",
    rating: int(a.rating),
    title: a.title || "",
    text: a.body || "",
    lang: "",
    country: a.territory || "",
    device: "",
    appVersion: "",
    createdAt: created,
    updatedAt: created,
    reply: response && ra.responseBody ? { text: ra.responseBody, at: Date.parse(ra.lastModifiedDate || "") || null, state: String(ra.state || "").toLowerCase() || "published", responseId: response.id } : null,
    link: "",
  };
}

const docId = (r) => `${r.platform}_${safeId(r.storeId)}`;

// Pure: the stored document after `incoming` lands on `existing` (or on
// nothing). The newer review text wins; a reply never disappears because
// an older source lacks it; the read mark is the console's alone. A review
// edited after it was answered asks for attention again.
function mergeReview(existing, incoming, now = Date.now()) {
  const prev = existing || null;
  const newer = !prev || (incoming.updatedAt || 0) >= (prev.updatedAt || 0);
  const base = newer ? { ...(prev || {}), ...stripEmpty(incoming) } : { ...stripEmpty(incoming), ...prev };
  // Fill what the winner lacks from the other (an API review has the
  // author, the CSV the link and the title).
  for (const key of ["author", "title", "lang", "country", "device", "appVersion", "link"]) {
    if (!base[key]) base[key] = (prev && prev[key]) || incoming[key] || "";
  }
  const created = [prev && prev.createdAt, incoming.createdAt].filter((v) => typeof v === "number" && v > 0);
  base.createdAt = created.length ? Math.min(...created) : null;
  const replies = [prev && prev.reply, incoming.reply].filter(Boolean);
  base.reply = replies.sort((a, b) => (b.at || 0) - (a.at || 0))[0] || null;
  base.answered = !!base.reply;
  base.editedAfterReply = !!(base.reply && base.reply.at && base.updatedAt && base.updatedAt > base.reply.at + 60000);
  base.needsReply = !!(base.text || base.title) && (!base.reply || base.editedAfterReply);
  if (!prev) base.read = !!base.reply && !base.editedAfterReply;
  else if (newer && (incoming.updatedAt || 0) > (prev.updatedAt || 0) && (incoming.text !== prev.text || incoming.rating !== prev.rating)) base.read = false;
  else base.read = prev.read === true;
  base.platform = incoming.platform;
  base.storeId = incoming.storeId;
  base.syncedAt = now;
  return base;
}

function stripEmpty(obj) {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== "" && v !== null && v !== undefined));
}

// Pure: counts per star and the mean, from stored reviews.
function distribution(reviews) {
  const stars = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  let total = 0;
  let sum = 0;
  let withText = 0;
  let needsReply = 0;
  for (const r of reviews) {
    if (r.rating >= 1 && r.rating <= 5) {
      stars[r.rating]++;
      total++;
      sum += r.rating;
    }
    if (r.text || r.title) withText++;
    if (r.needsReply) needsReply++;
  }
  return { stars, total, average: total ? Math.round((sum / total) * 100) / 100 : null, withText, needsReply };
}

// The Play ratings overview CSV → the newest "Total Average Rating".
function parsePlayRatings(text, pkg = "") {
  let best = null;
  for (const row of objects(parseCsv(text))) {
    if (pkg && row["package name"] && row["package name"] !== pkg) continue;
    const avg = parseFloat(row["total average rating"]);
    if (!row.date || !Number.isFinite(avg) || avg <= 0) continue;
    if (!best || row.date > best.date) best = { date: row.date, average: Math.round(avg * 100) / 100 };
  }
  return best;
}

// The reviews/ and stats/ratings files of our package; a nightly sync reads
// only this month and last (a backfill all of them).
function recentMonthly(files, now = Date.now()) {
  const d = new Date(now);
  const month = (y, m) => `${y}${String(m + 1).padStart(2, "0")}`;
  const current = month(d.getUTCFullYear(), d.getUTCMonth());
  const previous = d.getUTCMonth() === 0 ? month(d.getUTCFullYear() - 1, 11) : month(d.getUTCFullYear(), d.getUTCMonth() - 1);
  return files.filter((f) => {
    const m = String(f.name).match(/_(\d{6})(?:_overview)?\.csv$/);
    return !m || m[1] === current || m[1] === previous;
  });
}

// ---------------------------------------------------------------------------
// Network.
// ---------------------------------------------------------------------------

let auth = null;
async function playToken() {
  auth = auth || new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/androidpublisher"] });
  const client = await auth.getClient();
  const { token } = await client.getAccessToken();
  return token;
}

function playError(status, json) {
  const message = (json && json.error && json.error.message) || `HTTP ${status}`;
  let hint = "";
  if (/has not been used|is disabled|SERVICE_DISABLED/i.test(message)) hint = "enable the Google Play Android Developer API on the easy-plate Google Cloud project";
  else if (status === 401 || status === 403) hint = 'in Play Console → Users and permissions, give the service account the app permission "Reply to reviews" (it can take up to 24 hours to apply)';
  return Object.assign(new Error(`Google Play ${status}: ${message}${hint ? ` — ${hint}` : ""}`), { status: 502, code: "play_access" });
}

async function playFetch(url, { method = "GET", body, fetchImpl = fetch, token } = {}) {
  const res = await fetchImpl(url, {
    method,
    headers: { Authorization: `Bearer ${token || (await playToken())}`, ...(body ? { "Content-Type": "application/json" } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
  });
  let json = null;
  try {
    json = await res.json();
  } catch (_) {}
  if (!res.ok) throw playError(res.status, json);
  return json || {};
}

async function listPlayApi({ pkg, fetchImpl, token }) {
  const out = [];
  let next = "";
  for (let page = 0; page < 20; page++) {
    const params = new URLSearchParams({ maxResults: "100" });
    if (next) params.set("token", next);
    const json = await playFetch(`${PLAY_API}/applications/${encodeURIComponent(pkg)}/reviews?${params}`, { fetchImpl, token });
    for (const r of json.reviews || []) out.push(fromPlayApi(r));
    next = json.tokenPagination && json.tokenPagination.nextPageToken;
    if (!next) break;
  }
  return out;
}

function appleError(status, json) {
  const e = json && json.errors && json.errors[0];
  const detail = e ? `${e.title || ""} ${e.detail || ""}`.trim() : "";
  const hint = status === 401 ? "the key, key id or issuer id is wrong" : status === 403 ? "the API key needs the Admin or Customer Support role to read and answer reviews (a Sales-only key cannot) — create a key with Admin, it also covers the Downloads page" : "";
  return Object.assign(new Error(`App Store Connect ${status}${detail ? `: ${detail}` : ""}${hint ? ` (${hint})` : ""}`), { status: 502, code: "apple_access" });
}

async function appleFetch(url, { token, method = "GET", body, fetchImpl = fetch }) {
  const res = await fetchImpl(url, {
    method,
    headers: { Authorization: `Bearer ${token}`, ...(body ? { "Content-Type": "application/json" } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
  });
  if (res.status === 204) return {};
  let json = null;
  try {
    json = await res.json();
  } catch (_) {}
  if (!res.ok) throw appleError(res.status, json);
  return json || {};
}

function appleToken(config, privateKey) {
  if (!(config.appleIssuerId && config.appleKeyId && isPem(privateKey))) throw Object.assign(new Error("App Store Connect key not configured (Downloads → settings)"), { status: 400, code: "not_configured" });
  return appleJwt({ issuerId: config.appleIssuerId, keyId: config.appleKeyId, privateKey });
}

// Every review, newest first; the API pages by `links.next`. A nightly run
// stops at the first page that holds nothing newer than what is stored.
async function listApple({ config, privateKey, fetchImpl, stopAt = 0 }) {
  const token = appleToken(config, privateKey);
  const out = [];
  let url = `${ASC_HOST}/v1/apps/${encodeURIComponent(config.appleAppId)}/customerReviews?sort=-createdDate&limit=200&include=response&fields[customerReviewResponses]=responseBody,lastModifiedDate,state`;
  for (let page = 0; url && page < 50; page++) {
    const json = await appleFetch(url, { token, fetchImpl });
    const items = (json.data || []).map((d) => fromApple(d, json.included || []));
    out.push(...items);
    if (stopAt && items.length && items.every((r) => (r.createdAt || 0) < stopAt)) break;
    url = json.links && json.links.next;
  }
  return out;
}

async function appleSummary(appId, fetchImpl = fetch) {
  const countries = {};
  await Promise.all(IOS_STOREFRONTS.map(async (cc) => {
    try {
      const res = await fetchImpl(`https://itunes.apple.com/lookup?id=${encodeURIComponent(appId)}&country=${cc}`, { signal: AbortSignal.timeout(10000) });
      if (!res.ok) return;
      const json = await res.json();
      const app = json && json.results && json.results[0];
      if (app && app.userRatingCount) countries[cc.toUpperCase()] = { average: Math.round(Number(app.averageUserRating || 0) * 100) / 100, count: int(app.userRatingCount) };
    } catch (_) {}
  }));
  let count = 0;
  let sum = 0;
  for (const c of Object.values(countries)) {
    count += c.count;
    sum += c.average * c.count;
  }
  return { countries, count, average: count ? Math.round((sum / count) * 100) / 100 : null };
}

// ---------------------------------------------------------------------------
// Firestore.
// ---------------------------------------------------------------------------

async function store(db, reviews, now = Date.now()) {
  if (!reviews.length) return { added: 0, updated: 0 };
  // The same review can arrive twice in one run (API + CSV): fold first.
  const byId = new Map();
  for (const r of reviews) {
    if (!r.storeId || !r.rating) continue;
    const id = docId(r);
    byId.set(id, byId.has(id) ? mergeReview(byId.get(id), r, now) : r);
  }
  const ids = [...byId.keys()];
  let added = 0;
  let updated = 0;
  for (let i = 0; i < ids.length; i += 300) {
    const chunk = ids.slice(i, i + 300);
    const snaps = await db.getAll(...chunk.map((id) => db.collection(COLLECTION).doc(id)));
    const batch = db.batch();
    snaps.forEach((snap, k) => {
      const incoming = byId.get(chunk[k]);
      const prev = snap.exists ? snap.data() : null;
      const next = mergeReview(prev, incoming, now);
      if (prev && same(prev, next)) return;
      if (prev) updated++;
      else added++;
      batch.set(snap.ref, next);
    });
    await batch.commit();
  }
  return { added, updated };
}

function same(a, b) {
  const keys = ["rating", "text", "title", "updatedAt", "read", "needsReply", "author", "link"];
  return keys.every((k) => (a[k] ?? null) === (b[k] ?? null)) && JSON.stringify(a.reply || null) === JSON.stringify(b.reply || null);
}

async function markMeta(db, patch) {
  await db.doc(META).set({ ...patch, lastSyncAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
}

async function syncAndroid({ db, config, storage = admin.storage(), backfill = false, fetchImpl = fetch, now = Date.now() }) {
  if (!config.playPackage) throw Object.assign(new Error("Play package not configured"), { status: 400, code: "not_configured" });
  const pkg = config.playPackage;
  const reviews = [];
  const errors = [];
  let average = null;
  let csvOk = false;
  // History from the bucket.
  if (config.playBucket) {
    try {
      const bucket = storage.bucket(config.playBucket);
      const [[reviewFiles], [ratingFiles]] = await Promise.all([bucket.getFiles({ prefix: "reviews/" }), bucket.getFiles({ prefix: "stats/ratings/" })]);
      const meta = await db.doc(META).get();
      const full = backfill || !meta.exists || !meta.get("android.csvAt");
      const ours = reviewFiles.filter((f) => f.name.includes(`reviews_${pkg}_`));
      for (const file of full ? ours : recentMonthly(ours, now)) {
        const [buf] = await file.download();
        reviews.push(...parsePlayReviewsCsv(decodeReport(buf), pkg));
      }
      const ratings = recentMonthly(ratingFiles.filter((f) => f.name.includes(`ratings_${pkg}_`) && f.name.endsWith("_overview.csv")), now);
      for (const file of ratings) {
        const [buf] = await file.download();
        const best = parsePlayRatings(decodeReport(buf), pkg);
        if (best && (!average || best.date > average.date)) average = best;
      }
      csvOk = true;
    } catch (err) {
      errors.push(err.code === 403 ? `no access to gs://${config.playBucket} (same permission as the Downloads page)` : err.message);
    }
  }
  // The last week, live, from the API (what lets us answer).
  let apiOk = false;
  try {
    reviews.push(...(await listPlayApi({ pkg, fetchImpl })));
    apiOk = true;
  } catch (err) {
    errors.push(err.message);
  }
  const result = await store(db, reviews, now);
  await markMeta(db, { android: { error: errors.join(" · ") || null, apiOk, ...(csvOk ? { csvAt: now } : {}), storeAverage: average, fetched: reviews.length } });
  logger.info("play reviews synced", { fetched: reviews.length, ...result, errors });
  return { platform: "android", fetched: reviews.length, ...result, errors };
}

async function syncIos({ db, config, privateKey, backfill = false, fetchImpl = fetch, now = Date.now() }) {
  let reviews = [];
  let error = null;
  try {
    const newest = await db.collection(COLLECTION).where("platform", "==", "ios").orderBy("createdAt", "desc").limit(1).get();
    const stopAt = backfill || newest.empty ? 0 : (newest.docs[0].get("createdAt") || 0) - 14 * 86400000;
    reviews = await listApple({ config, privateKey, fetchImpl, stopAt });
  } catch (err) {
    error = err.message;
  }
  const summary = await appleSummary(config.appleAppId, fetchImpl);
  const result = await store(db, reviews, now);
  await markMeta(db, { ios: { error, storeAverage: summary.average, storeCount: summary.count, countries: summary.countries, fetched: reviews.length } });
  logger.info("app store reviews synced", { fetched: reviews.length, ...result, error });
  return { platform: "ios", fetched: reviews.length, ...result, errors: error ? [error] : [] };
}

async function sync({ db, platform = "all", backfill = false, fetchImpl = fetch, storage }) {
  const { config, privateKey } = await stats.loadConfig(db);
  const out = { android: null, ios: null };
  if (platform === "all" || platform === "android") out.android = await syncAndroid({ db, config, storage, backfill, fetchImpl });
  if (platform === "all" || platform === "ios") out.ios = await syncIos({ db, config, privateKey, backfill, fetchImpl });
  const all = await db.collection(COLLECTION).select("platform", "rating", "text", "title", "needsReply").get();
  const rows = all.docs.map((d) => d.data());
  await markMeta(db, {
    counts: {
      all: distribution(rows),
      android: distribution(rows.filter((r) => r.platform === "android")),
      ios: distribution(rows.filter((r) => r.platform === "ios")),
    },
  });
  return out;
}

// Pure: the reply as the store will take it, or why not.
function replyProblem(platform, text) {
  const body = String(text || "").trim();
  if (!body) return "the reply is empty";
  if (body.length > MAX_REPLY[platform]) return `${platform === "android" ? "Google Play" : "The App Store"} takes at most ${MAX_REPLY[platform]} characters (this is ${body.length})`;
  return null;
}

// Sends (or replaces) the developer reply in the store, then stores it.
async function reply({ db, id, text, fetchImpl = fetch, now = Date.now() }) {
  const ref = db.collection(COLLECTION).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw Object.assign(new Error("no such review"), { status: 404, code: "not_found" });
  const review = snap.data();
  const problem = replyProblem(review.platform, text);
  if (problem) throw Object.assign(new Error(problem), { status: 400, code: "invalid" });
  const body = String(text).trim();
  const { config, privateKey } = await stats.loadConfig(db);
  let stored;
  if (review.platform === "android") {
    if (String(review.storeId).startsWith("csv_")) throw Object.assign(new Error("a star-only rating cannot be answered"), { status: 400, code: "invalid" });
    const json = await playFetch(`${PLAY_API}/applications/${encodeURIComponent(config.playPackage)}/reviews/${encodeURIComponent(review.storeId)}:reply`, { method: "POST", body: { replyText: body }, fetchImpl });
    const at = json.result && json.result.lastEdited ? seconds(json.result.lastEdited) : now;
    stored = { text: (json.result && json.result.replyText) || body, at: at || now, state: "published" };
  } else {
    const token = appleToken(config, privateKey);
    const json = await appleFetch(`${ASC_HOST}/v1/customerReviewResponses`, {
      token,
      method: "POST",
      fetchImpl,
      body: { data: { type: "customerReviewResponses", attributes: { responseBody: body }, relationships: { review: { data: { type: "customerReviews", id: review.storeId } } } } },
    });
    const a = (json.data && json.data.attributes) || {};
    stored = { text: a.responseBody || body, at: Date.parse(a.lastModifiedDate || "") || now, state: String(a.state || "pending_publish").toLowerCase(), responseId: json.data && json.data.id };
  }
  await ref.update({ reply: stored, answered: true, editedAfterReply: false, needsReply: false, read: true, repliedAt: now });
  return { reply: stored };
}

// Removes the reply: the App Store only (Google Play has no delete).
async function deleteReply({ db, id, fetchImpl = fetch }) {
  const ref = db.collection(COLLECTION).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw Object.assign(new Error("no such review"), { status: 404, code: "not_found" });
  const review = snap.data();
  if (review.platform !== "ios") throw Object.assign(new Error("Google Play does not allow deleting a reply; send a new one to replace it"), { status: 400, code: "invalid" });
  const responseId = review.reply && review.reply.responseId;
  if (responseId) {
    const { config, privateKey } = await stats.loadConfig(db);
    await appleFetch(`${ASC_HOST}/v1/customerReviewResponses/${encodeURIComponent(responseId)}`, { token: appleToken(config, privateKey), method: "DELETE", fetchImpl });
  }
  await ref.update({ reply: null, answered: false, editedAfterReply: false, needsReply: !!(review.text || review.title) });
  return {};
}

async function markRead({ db, ids, read = true }) {
  const batch = db.batch();
  for (const id of ids) batch.update(db.collection(COLLECTION).doc(id), { read });
  await batch.commit();
  return { count: ids.length };
}

module.exports = {
  sync,
  reply,
  deleteReply,
  markRead,
  internals: {
    playIdFromLink, parsePlayReviewsCsv, fromPlayApi, fromApple, mergeReview, distribution, parsePlayRatings, recentMonthly, replyProblem,
    docId, listApple, listPlayApi, playError, appleError, store, COLLECTION, META, MAX_REPLY, normalizePem,
  },
};
