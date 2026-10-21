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
const budget = require("./dailyBudget");
const safeFetch = require("./safeFetch");
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");

const serperApiKey = defineSecret("SERPER_API_KEY");

const ENDPOINT = "https://google.serper.dev/images";
const PAGE_SIZE = 10;
// Google Images gives about a hundred results; `start` is 1-based like
// Google's own API, so the last page begins at 91.
const MAX_START = 91;
const CACHE_COLLECTION = "image_search_cache";
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_QUERY_LENGTH = 120;
// One Serper call; it answers in about a second.
const SEARCH_TIMEOUT_MS = 15000;

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
  // Onto the first result of its Serper page: start 1 and start 7 fetch the
  // same page, so they share one cache entry instead of each buying it.
  start = (pageFor(start) - 1) * PAGE_SIZE + 1;
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

// `onMiss` runs between the cache and Serper: the app's handler spends the
// caller's daily budget there (a cached page costs nothing and counts for
// nothing); the console's calls pass none.
async function search(request, { key, fetchImpl = fetch, db = admin.firestore(), now = Date.now(), onMiss = null }) {
  const id = cacheId(request);
  const cached = await fromCache(db, id, now);
  if (cached) return { ...cached, cached: true };
  if (onMiss) await onMiss();

  // Serper's side failing (a network error, a timeout, a 5xx) is marked
  // `refundable`: the caller's search is given back, as aiProxy does.
  const upstreamDown = (message) => Object.assign(new Error(message), { status: 502, code: "upstream", refundable: true });
  let response;
  let text;
  try {
    response = await fetchImpl(ENDPOINT, {
      method: "POST",
      headers: { "X-API-KEY": key, "Content-Type": "application/json" },
      body: JSON.stringify(searchBody(request)),
      signal: AbortSignal.timeout(SEARCH_TIMEOUT_MS),
    });
    text = await response.text();
  } catch (err) {
    throw upstreamDown(`upstream unreachable: ${err.message}`);
  }
  if (response.status >= 500) throw upstreamDown(`upstream HTTP ${response.status}`);
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
    // Our Serper account out of credits, over its rate, or its key refused
    // (401/402/403): our side, not the caller's — the search is given back,
    // as for a Serper outage. Only a refusal of the request itself (another
    // 4xx) stays charged.
    error.refundable = quota || response.status === 401 || response.status === 402 || response.status === 403;
    throw error;
  }
  const page = parseResults(json, request.start);
  await toCache(db, id, page, request.query);
  return page;
}

// ---------------------------------------------------------------------------
// action "download": the web app cannot read most picked results itself
// (their hosts send no CORS headers), so it asks for the bytes here and
// uploads them with its own uploadRecipeImage. The fetch goes through the
// same SSRF guard as the admin console (safeFetch.js): http(s) only, every
// address the host resolves to must be public, redirects followed by hand
// (at most 5) with each hop re-checked, the body read no further than 8 MB.
// Every attempt that gets past the URL syntax check costs one unit of the
// caller's `imageSearch` daily budget (the same allowance as a search), and
// is not refunded on failure, so the endpoint cannot be used as a free
// prober of other hosts.
// ---------------------------------------------------------------------------
const MAX_DOWNLOAD_URL_LENGTH = 2048;
const DOWNLOAD_USER_AGENT = "Mozilla/5.0 (compatible; EasyPlate/1.0; +https://aieasyplate.app)";

// HTTP status per stable error code of the download action.
const DOWNLOAD_STATUS = Object.freeze({
  invalid_url: 400,
  blocked_address: 400,
  not_image: 415,
  too_large: 413,
  fetch_failed: 502,
});

// Pure: the URL the app sent, or { error: "invalid_url" }. Only syntax is
// checked here; the address check needs DNS and happens in the fetch.
function parseDownload(body) {
  const raw = body && typeof body.url === "string" ? body.url.trim() : "";
  if (!raw || raw.length > MAX_DOWNLOAD_URL_LENGTH) return { error: "invalid_url" };
  let url;
  try {
    url = new URL(raw);
  } catch (_) {
    return { error: "invalid_url" };
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return { error: "invalid_url" };
  if (url.username || url.password) return { error: "invalid_url" };
  return { url: url.toString() };
}

// Pure: the content type to hand back, or null when it is not a raster
// image. SVG (script inside a picture) and anything XML are refused.
function acceptImageType(contentType) {
  const type = String(contentType || "").split(";")[0].trim().toLowerCase();
  if (!/^image\/[a-z0-9.+-]+$/.test(type)) return null;
  if (type.includes("svg") || type.includes("xml")) return null;
  return type;
}

// Pure: bytes that start like markup (an SVG or an HTML error page sent
// with an image type) are not a picture, whatever the header says.
function looksLikeMarkup(bytes) {
  for (let i = 0; i < Math.min(bytes.length, 64); i++) {
    const b = bytes[i];
    if (b === 0x20 || b === 0x09 || b === 0x0a || b === 0x0d || b === 0xef || b === 0xbb || b === 0xbf) continue; // whitespace, UTF-8 BOM
    return b === 0x3c; // "<"
  }
  return false;
}

// The picture at `url` as { contentType, dataBase64, size }. Throws an
// error whose `reason` is one of DOWNLOAD_STATUS's codes.
async function download(url, { fetchImpl = fetch, lookup } = {}) {
  let image;
  try {
    image = await safeFetch.fetchImage(url, fetchImpl, { lookup, userAgent: DOWNLOAD_USER_AGENT, maxBytes: safeFetch.MAX_IMAGE_BYTES });
  } catch (err) {
    // A refusal from the guard carries its reason; anything else (network
    // error, timeout, a body that broke off) is the host failing.
    if (!err.reason) err.reason = "fetch_failed";
    throw err;
  }
  const contentType = acceptImageType(image.contentType);
  if (!contentType || looksLikeMarkup(image.bytes)) throw safeFetch.refused("the url did not return a raster image", "invalid_image", "not_image");
  if (image.bytes.length === 0) throw safeFetch.refused("the url returned an empty body", "invalid_image", "not_image");
  if (image.bytes.length > safeFetch.MAX_IMAGE_BYTES) throw safeFetch.refused("image is larger than 8 MB", "image_too_large", "too_large");
  return { contentType, dataBase64: image.bytes.toString("base64"), size: image.bytes.length };
}

async function handleDownload(req, res, caller) {
  const parsed = parseDownload(req.body);
  if (parsed.error) return res.status(400).json({ error: { code: parsed.error, message: "url must be an http(s) URL" } });

  const decision = await budget.spend({ uid: caller.uid, kind: "imageSearch" });
  if (!decision.allowed) {
    logger.info("image download budget exhausted", { uid: caller.uid, used: decision.used, limit: decision.limit });
    return res.status(429).json(budget.refusalBody(decision, "imageSearch"));
  }

  try {
    const image = await download(parsed.url);
    logger.info("image download", { uid: caller.uid, contentType: image.contentType, size: image.size });
    return res.status(200).json(image);
  } catch (err) {
    const code = DOWNLOAD_STATUS[err.reason] ? err.reason : "fetch_failed";
    logger.warn("image download refused", { uid: caller.uid, code, reason: err.message });
    return res.status(DOWNLOAD_STATUS[code]).json({ error: { code, message: err.reason ? err.message : "Could not download the picture" } });
  }
}

exports.imageSearch = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 5, secrets: [serperApiKey] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const { caller, refusal } = await proxy.verifyPaidCaller(req);
    if (!caller) return res.status(refusal.status).json({ error: { code: refusal.code, message: refusal.message } });

    // { action: "download", url } fetches one picked result for the web
    // app; anything else (no action) is the search the apps have always
    // sent, unchanged.
    if (req.body && req.body.action === "download") {
      try {
        return await handleDownload(req, res, caller);
      } catch (err) {
        logger.error("image download failed", { uid: caller.uid, reason: err.message });
        return res.status(502).json({ error: { code: "fetch_failed", message: "Could not download the picture" } });
      }
    }

    const key = serperApiKey.value();
    if (!configured(key)) {
      logger.error("image search is not configured: set SERPER_API_KEY");
      return res.status(503).json({ error: { code: "not_configured", message: "Image search is not configured" } });
    }

    const request = parseRequest(req.body);
    if (request.error === "end_of_results") return res.status(200).json({ items: [], nextStart: null, start: MAX_START });
    if (request.error) return res.status(400).json({ error: { code: request.error, message: request.error } });

    let spent = false;
    try {
      const page = await search(request, {
        key,
        onMiss: async () => {
          const decision = await budget.spend({ uid: caller.uid, kind: "imageSearch" });
          if (!decision.allowed) throw budget.exhausted(decision, "imageSearch");
          spent = true;
        },
      });
      logger.info("image search", { uid: caller.uid, start: request.start, count: page.items.length, cached: page.cached === true });
      return res.status(200).json(page);
    } catch (err) {
      // The caller's own allowance, spent: the body carries `quota`, which
      // is what tells the app not to retry.
      if (err.body) {
        logger.info("image search budget exhausted", { uid: caller.uid, ...err.body.error.quota });
        return res.status(err.status).json(err.body);
      }
      logger.error("image search failed", { uid: caller.uid, reason: err.message });
      if (spent && err.refundable) await budget.refund(admin.firestore(), { uid: caller.uid, kind: "imageSearch" });
      const status = err.status || 502;
      return res.status(status).json({ error: { code: err.code || "upstream", message: "Image search failed" } });
    }
  },
);

exports.internals = {
  parseRequest, parseResults, cacheId, searchBody, pageFor, configured, search, PAGE_SIZE, MAX_START,
  parseDownload, acceptImageType, looksLikeMarkup, download, DOWNLOAD_STATUS, MAX_DOWNLOAD_URL_LENGTH,
};
