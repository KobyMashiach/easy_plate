// Picture search for a recipe: the app sends the dish name, this asks
// Serper (google.serper.dev, Google Images results as JSON) for one page of
// ten and hands it back. Google's own Custom Search JSON API is closed to
// new customers since 2025, which is why a reseller. The API key lives in
// Secret Manager; the caller is identified by their Firebase ID token, like
// the AI proxy.
//
// Serper bills per query, and the same dish is asked for again and again,
// so a page is kept in Firestore for a week and served from there the
// second time.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");
const proxy = require("./aiProxy").internals;

const serperApiKey = defineSecret("SERPER_API_KEY");

const ENDPOINT = "https://google.serper.dev/images";
const PAGE_SIZE = 10;
// Google Images gives about a hundred results; `start` is 1-based like
// Google's own API, so the last page begins at 91.
const MAX_START = 91;
const CACHE_COLLECTION = "image_search_cache";
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_QUERY_LENGTH = 120;

// A placeholder secret (set so the function can deploy before the real
// value exists) reads as "not configured", not as a key to send out.
function configured(key) {
  return typeof key === "string" && key.trim() !== "" && key.trim().toLowerCase() !== "unset";
}

// Pure: what the app sent, normalised. `start` is 1-based like the API's.
function parseRequest(body) {
  const rawQuery = body && typeof body.query === "string" ? body.query : "";
  const query = rawQuery.replace(/\s+/g, " ").trim().slice(0, MAX_QUERY_LENGTH);
  if (!query) return { error: "empty_query" };
  const rawStart = body && body.start;
  let start = Number.isInteger(rawStart) ? rawStart : parseInt(rawStart, 10);
  if (!Number.isInteger(start) || start < 1) start = 1;
  if (start > MAX_START) return { error: "end_of_results" };
  const lang = body && typeof body.lang === "string" ? body.lang.trim().toLowerCase().slice(0, 5) : "";
  return { query, start, lang };
}

// Pure: Serper's `images`, cut down to what the picker shows, plus where
// the next page begins (null once a page came back short, or at the cap).
function parseResults(json, start) {
  const items = [];
  for (const item of (json && json.images) || []) {
    if (!item || typeof item.imageUrl !== "string" || !/^https?:\/\//i.test(item.imageUrl)) continue;
    const thumbnail = typeof item.thumbnailUrl === "string" && item.thumbnailUrl ? item.thumbnailUrl : item.imageUrl;
    items.push({
      url: item.imageUrl,
      thumbnail,
      width: Number.isInteger(item.imageWidth) ? item.imageWidth : null,
      height: Number.isInteger(item.imageHeight) ? item.imageHeight : null,
      title: typeof item.title === "string" ? item.title.slice(0, 200) : "",
      source: typeof item.domain === "string" ? item.domain : typeof item.source === "string" ? item.source : "",
      mime: "",
    });
  }
  const after = start + PAGE_SIZE;
  const nextStart = items.length >= PAGE_SIZE && after <= MAX_START ? after : null;
  return { items, nextStart, start };
}

function cacheId({ query, start, lang }) {
  return crypto.createHash("sha1").update(`${lang}|${start}|${query.toLowerCase()}`).digest("hex");
}

// Serper pages are 1-based and ten wide; `start` maps onto them.
function pageFor(start) {
  return Math.floor((start - 1) / PAGE_SIZE) + 1;
}

// The request body Serper takes. The UI's language is what the dish name
// is written in, so results in it rank first.
function searchBody({ query, start, lang }) {
  const body = { q: query, num: PAGE_SIZE, page: pageFor(start), safe: "active" };
  if (/^[a-z]{2}$/.test(lang)) body.hl = lang;
  return body;
}

async function fromCache(db, id, now) {
  try {
    const snap = await db.collection(CACHE_COLLECTION).doc(id).get();
    if (!snap.exists) return null;
    const data = snap.data();
    const at = data.cachedAt && typeof data.cachedAt.toMillis === "function" ? data.cachedAt.toMillis() : 0;
    if (now - at > CACHE_TTL_MS) {
      // Passed over, so gone: the collection must not keep every dish name
      // ever typed. Not awaited; the refetch below rewrites the document.
      snap.ref.delete().catch((err) => logger.warn("stale cache delete failed", { reason: err.message }));
      return null;
    }
    return data.page || null;
  } catch (err) {
    logger.warn("image search cache read failed", { reason: err.message });
    return null;
  }
}

async function toCache(db, id, page, query) {
  try {
    await db.collection(CACHE_COLLECTION).doc(id).set({
      query,
      page,
      cachedAt: admin.firestore.Timestamp.now(),
    });
  } catch (err) {
    logger.warn("image search cache write failed", { reason: err.message });
  }
}

async function search(request, { key, fetchImpl = fetch, db = admin.firestore(), now = Date.now() }) {
  const id = cacheId(request);
  const cached = await fromCache(db, id, now);
  if (cached) return { ...cached, cached: true };

  const response = await fetchImpl(ENDPOINT, {
    method: "POST",
    headers: { "X-API-KEY": key, "Content-Type": "application/json" },
    body: JSON.stringify(searchBody(request)),
  });
  const text = await response.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch (err) {
    throw new Error(`upstream returned non-JSON (${response.status})`);
  }
  if (!response.ok) {
    const reason = json && (json.message || (json.error && json.error.message)) ? String(json.message || json.error.message) : `HTTP ${response.status}`;
    const quota = response.status === 429 || /quota|limit|credits/i.test(reason);
    const error = new Error(reason);
    error.status = quota ? 429 : 502;
    error.code = quota ? "quota" : "upstream";
    throw error;
  }
  const page = parseResults(json, request.start);
  await toCache(db, id, page, request.query);
  return page;
}

exports.imageSearch = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 5, secrets: [serperApiKey] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });

    const key = serperApiKey.value();
    if (!configured(key)) {
      logger.error("image search is not configured: set SERPER_API_KEY");
      return res.status(503).json({ error: { code: "not_configured", message: "Image search is not configured" } });
    }

    const request = parseRequest(req.body);
    if (request.error === "end_of_results") return res.status(200).json({ items: [], nextStart: null, start: MAX_START });
    if (request.error) return res.status(400).json({ error: { code: request.error, message: request.error } });

    try {
      const page = await search(request, { key });
      logger.info("image search", { uid: caller.uid, start: request.start, count: page.items.length, cached: page.cached === true });
      return res.status(200).json(page);
    } catch (err) {
      logger.error("image search failed", { uid: caller.uid, reason: err.message });
      const status = err.status || 502;
      return res.status(status).json({ error: { code: err.code || "upstream", message: "Image search failed" } });
    }
  },
);

exports.internals = { parseRequest, parseResults, cacheId, searchBody, pageFor, configured, search, PAGE_SIZE, MAX_START };
