// A recipe from a short-form video. The app used to hand the video's page
// URL to Gemini's url_context tool, which reads HTML — and TikTok, Instagram
// and Facebook answer a bot with a login wall, so the model saw "log in to
// continue" and returned an empty recipe (or, memorably, one titled
// "account blocked"). This function fetches the video itself:
//
//   1. yt-dlp resolves the link to a direct media URL plus the caption (it
//      knows every platform's page layout, and is updated when they change);
//   2. the video bytes and the caption go to Gemini as one multimodal
//      request — the model reads the on-screen text, watches the steps and
//      listens to the narration;
//   3. when the video cannot be fetched (private account, a platform that
//      blocked the datacenter), the caption alone is tried through the
//      platform's public embed/oEmbed endpoint;
//   4. and when there is not even a caption, a typed 422 tells the app so it
//      can say "we could not read this video" instead of showing nothing.
//
// YouTube skips the download: Gemini reads YouTube links natively.
//
// Auth, the daily quota and the URL cache are aiProxy's, reused as-is.
const fs = require("node:fs");
const crypto = require("node:crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const YTDlpWrap = require("yt-dlp-wrap").default;
const proxy = require("./aiProxy").internals;

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const aiUsage = require("./aiUsage");
// The website (aieasyplate.app/app) calls this from the browser too.
const { ORIGINS } = require("./origins");
const safeFetch = require("./safeFetch");
const budget = require("./dailyBudget");

// Past this the video is not sent; the caption alone is used. A recipe reel
// is 30–90 seconds; a ten-minute video is a cooking show, and its bytes
// would blow the request.
const MAX_VIDEO_BYTES = 30 * 1024 * 1024;
const MAX_VIDEO_SECONDS = 10 * 60;
const CAPTION_LIMIT = 4000;
const CACHE_KIND = "video";

// A model id as Google names them ("gemini-3.8-flash", "gemini-2.5-flash-lite"):
// no slash, no colon, no dot-dot, so it cannot leave /v1beta/models/.
const MODEL_ID = /^[a-z0-9](?:[a-z0-9-]|\.(?!\.)){0,63}$/i;

const BROWSER_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " +
  "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

// The yt-dlp binary is fetched once per instance into /tmp (the only
// writable place) — a few seconds on a cold start, nothing after.
//
// Pinned to one release and checked against its published SHA-256: it used
// to be "whatever GitHub calls latest", unverified, so a compromised or
// broken release ran on our servers (with the Gemini key in the
// environment) the moment an instance started. A failed download used to
// stay behind too — the library writes the body whatever the status, and
// the next call found a file and trusted it. Now the body goes to a temp
// file, is hashed, and only a match is renamed into place; a file already
// in /tmp is hashed before it is used.
//
// To move to a newer yt-dlp: take the tag from github.com/yt-dlp/yt-dlp/
// releases and the `yt-dlp` line of that release's SHA2-256SUMS.
const YT_DLP_VERSION = "2026.08.19";
const YT_DLP_SHA256 = "1fa6733c37ea6fb51c99ad8fe785e7b7e5f3246c9b980230329d4fb72ed8d4d6";
const YT_DLP_URL = `https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp`;
const YT_DLP_MAX_BYTES = 50 * 1024 * 1024;
const YT_DLP_DOWNLOAD_MS = 60 * 1000;
const BINARY_PATH = "/tmp/yt-dlp";

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function fileMatches(path, expected = YT_DLP_SHA256) {
  try {
    return sha256(fs.readFileSync(path)) === expected;
  } catch (_) {
    return false;
  }
}

/// Downloads the pinned release to [path], verified. Throws on a bad
/// status, an oversized body or a hash mismatch; nothing is left at [path]
/// unless it matched.
async function installYtDlp(path = BINARY_PATH, { fetchImpl = fetch, url = YT_DLP_URL, expected = YT_DLP_SHA256 } = {}) {
  const res = await fetchImpl(url, { redirect: "follow", signal: AbortSignal.timeout(YT_DLP_DOWNLOAD_MS) });
  if (!res.ok) throw new Error(`yt-dlp download -> ${res.status}`);
  const bytes = await safeFetch.readCapped(res, YT_DLP_MAX_BYTES);
  const got = sha256(bytes);
  if (got !== expected) throw new Error(`yt-dlp checksum mismatch (${got})`);
  const temp = `${path}.${process.pid}.${Date.now()}.part`;
  fs.writeFileSync(temp, bytes, { mode: 0o755 });
  fs.renameSync(temp, path);
}

let binaryPromise = null;
function ytDlp() {
  if (!binaryPromise) {
    binaryPromise = (async () => {
      if (!fileMatches(BINARY_PATH)) {
        try {
          fs.rmSync(BINARY_PATH, { force: true });
        } catch (_) {
          // Not there, or not ours to remove: the rename below replaces it.
        }
        await installYtDlp(BINARY_PATH);
      }
      return new YTDlpWrap(BINARY_PATH);
    })().catch((err) => {
      binaryPromise = null;
      throw err;
    });
  }
  return binaryPromise;
}

function platformOf(url) {
  let host;
  try {
    host = new URL(url).hostname.toLowerCase().replace(/^(www|m|vm|vt)\./, "");
  } catch (_) {
    return null;
  }
  // A bare endsWith("tiktok.com") let "eviltiktok.com" through, and anything
  // that passes here is fetched by yt-dlp on the server: match the domain or
  // a real subdomain of it, nothing else.
  const on = (domain) => host === domain || host.endsWith(`.${domain}`);
  if (host === "youtu.be" || on("youtube.com")) return "youtube";
  if (on("tiktok.com")) return "tiktok";
  if (on("instagram.com")) return "instagram";
  if (on("facebook.com") || host === "fb.watch") return "facebook";
  return "other";
}

// Pure, so the caption path is testable without a network: the readable text
// of an embed page, tags and scripts stripped.
function textFromHtml(html) {
  return String(html)
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|li|h\d)>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/[ \t]*\n[ \t]*/g, "\n")
    .replace(/\n+/g, "\n")
    .trim();
}

function metaContent(html, property) {
  const re = new RegExp(
    `<meta[^>]+(?:property|name)=["']${property}["'][^>]+content=["']([^"']*)["']`,
    "i",
  );
  const m = String(html).match(re);
  return m ? m[1] : null;
}

// Pages and media are fetched through the SSRF guard: the host allow-list
// only vouches for the first hop, and a redirect from an allowed host (or a
// media URL yt-dlp reports) could otherwise point anywhere, the metadata
// server included. Bodies are read no further than a cap — a chunked
// response carries no length to refuse up front.
const MAX_PAGE_BYTES = 2 * 1024 * 1024;

// The request's time, shared out so the slowest path (probe, download,
// model, the schema-less retry) ends inside the function's 180 s instead of
// being cut off mid-call with the slot neither used nor given back.
const FUNCTION_TIMEOUT_S = 180;
const DEADLINE_MS = 170 * 1000;
const PROBE_MS = 40 * 1000;
const DOWNLOAD_MS = 60 * 1000;
const MODEL_MS = 90 * 1000;
const MIN_STEP_MS = 5 * 1000;

/// Pure: how long the next step may take — its own cap, or what is left
/// before [deadline], whichever is shorter (never under MIN_STEP_MS, so a
/// step is not started with no time at all; the caller checks `left` first).
function stepBudget(deadline, cap, now = Date.now()) {
  return Math.max(MIN_STEP_MS, Math.min(cap, deadline - now));
}

async function fetchText(url, headers = {}) {
  const res = await safeFetch.fetchPublic(url, fetch, { headers: { "User-Agent": BROWSER_UA, ...headers } });
  if (!res.ok) throw new Error(`page -> ${res.status}`);
  return (await safeFetch.readCapped(res, MAX_PAGE_BYTES)).toString("utf8");
}

// What yt-dlp knows about the link, without downloading anything.
async function probe(url, timeoutMs = PROBE_MS) {
  const bin = await ytDlp();
  // --socket-timeout bounds each read, not the run: an extractor that keeps
  // following pages could hold the request until the function's own limit.
  const out = await bin.execPromise([
    "--dump-single-json",
    "--no-playlist",
    "--no-warnings",
    "--skip-download",
    "--socket-timeout",
    "20",
    "-f",
    // One self-contained mp4, smallest that is still the best; no merging,
    // so no ffmpeg needed. Falls back to whatever exists.
    `best[ext=mp4][vcodec!=none][filesize<${MAX_VIDEO_BYTES}]/best[ext=mp4]/best`,
    url,
  ], {}, AbortSignal.timeout(timeoutMs));
  const info = JSON.parse(out);
  const chosen = (info.requested_downloads && info.requested_downloads[0]) || info;
  return {
    title: info.title || null,
    description: info.description || null,
    mediaUrl: chosen.url || null,
    headers: chosen.http_headers || info.http_headers || {},
    durationSec: Number(info.duration) || null,
  };
}

async function download(mediaUrl, headers, timeoutMs = DOWNLOAD_MS) {
  const res = await safeFetch.fetchPublic(mediaUrl, fetch, { headers: { "User-Agent": BROWSER_UA, ...headers }, timeoutMs });
  if (!res.ok) throw new Error(`media -> ${res.status}`);
  return safeFetch.readCapped(res, MAX_VIDEO_BYTES);
}

// The caption without the video, through whatever public door the platform
// leaves open. Null when there is none.
async function captionFallback(url, platform) {
  try {
    switch (platform) {
      case "tiktok":
      case "youtube": {
        const base =
          platform === "tiktok" ? "https://www.tiktok.com/oembed" : "https://www.youtube.com/oembed";
        const json = JSON.parse(await fetchText(`${base}?url=${encodeURIComponent(url)}`));
        return json.title ? { title: json.title, description: null } : null;
      }
      case "instagram": {
        const m = url.match(/\/(reel|reels|p|tv)\/([A-Za-z0-9_-]+)/);
        if (!m) return null;
        const html = await fetchText(
          `https://www.instagram.com/${m[1] === "reels" ? "reel" : m[1]}/${m[2]}/embed/captioned/`,
        );
        const text = textFromHtml(html);
        // The embed page for a private or removed post carries only chrome.
        if (text.length < 40 || /Sorry, this page isn.t available/i.test(text)) return null;
        return { title: null, description: text.slice(0, CAPTION_LIMIT) };
      }
      default: {
        const html = await fetchText(url);
        const description = metaContent(html, "og:description") || metaContent(html, "description");
        const title = metaContent(html, "og:title");
        return description || title ? { title, description } : null;
      }
    }
  } catch (err) {
    logger.info("caption fallback failed", { platform, reason: err.message });
    return null;
  }
}

function captionText(source) {
  const parts = [];
  if (source && source.title) parts.push(`כותרת: ${source.title}`);
  if (source && source.description) parts.push(`תיאור: ${source.description.slice(0, CAPTION_LIMIT)}`);
  return parts.join("\n");
}

// One generateContent call; the answer's text (JSON per the schema).
async function askGemini({ model, systemInstruction, prompt, schema, video, youtubeUrl, caption, deadline = Date.now() + DEADLINE_MS }) {
  const parts = [];
  if (video) parts.push({ inline_data: { mime_type: "video/mp4", data: video.toString("base64") } });
  if (youtubeUrl) parts.push({ file_data: { file_uri: youtubeUrl } });
  parts.push({ text: [prompt, caption].filter(Boolean).join("\n\n") });

  const body = {
    contents: [{ role: "user", parts }],
    system_instruction: { parts: [{ text: systemInstruction }] },
    generation_config: {
      response_mime_type: "application/json",
      response_json_schema: schema,
      thinking_config: { thinking_level: "low" },
    },
  };
  let res = await callModel(model, body, stepBudget(deadline, MODEL_MS));
  // An older endpoint may not know response_json_schema; the prompt already
  // describes the shape, so the second try goes without it — when there is
  // still time for it.
  if (res.status === 400 && deadline - Date.now() > MIN_STEP_MS) {
    delete body.generation_config.response_json_schema;
    res = await callModel(model, body, stepBudget(deadline, MODEL_MS));
  }
  const text = await res.text();
  if (!res.ok) {
    const err = new Error(`gemini ${res.status}: ${text.slice(0, 300)}`);
    err.status = res.status;
    throw err;
  }
  let data;
  try {
    data = JSON.parse(text);
  } catch (err) {
    err.answered = true;
    throw err;
  }
  const answer = ((((data.candidates || [])[0] || {}).content || {}).parts || [])
    .map((p) => p.text || "")
    .join("");
  if (!answer.trim()) {
    // The model answered (and was paid for): not a slot to give back.
    const err = new Error("gemini returned no text");
    err.answered = true;
    throw err;
  }
  return { answer, usage: aiUsage.extractUsage(data) };
}

// Pure: whether a failed call gives the day's slot back. Only a failure on
// Google's side (5xx) or a network error, as in aiProxy. A 4xx is the
// request's own fault — an unknown model, a schema the API rejects — and
// both are the caller's to choose: refunding them made every such call
// free, each one after a yt-dlp probe and up to 30 MB of video.
//
// A model call that timed out is not refunded either: the request reached
// Google, which most likely went on to bill it, and a timeout is easy to
// provoke with a long video.
function refundable(err) {
  if (!err || err.answered) return false;
  return typeof err.status !== "number" || err.status >= 500;
}

async function callModel(model, body, timeoutMs = MODEL_MS) {
  try {
    return await fetch(`${proxy.GOOGLE_ORIGIN}/v1beta/models/${model}:generateContent`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": geminiApiKey.value() },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch (err) {
    if (err && (err.name === "TimeoutError" || err.name === "AbortError")) err.answered = true;
    throw err;
  }
}

// A recipe with neither ingredients nor steps is the model saying "nothing
// here" in the shape it was asked for. Not worth saving, not worth caching.
function isUsableRecipe(text) {
  try {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    const recipe = JSON.parse(text.slice(start, end + 1));
    const ingredients = Array.isArray(recipe.ingredients) ? recipe.ingredients.length : 0;
    const steps = Array.isArray(recipe.steps) ? recipe.steps.length : 0;
    return ingredients > 0 || steps > 0;
  } catch (_) {
    return false;
  }
}

/// Whether an unreadable link's AI slot may be given back: one claim on the
/// day's `socialProbe` budget. A budget that cannot be read keeps the slot.
async function probeRefundAllowed(uid, spend = budget.spend) {
  try {
    return (await spend({ uid, kind: "socialProbe" })).allowed;
  } catch (err) {
    logger.warn("probe budget unavailable", { uid, reason: err.message });
    return false;
  }
}

// The Interactions envelope the app already parses, so the client has one
// reader for both proxies.
function envelope(text, extra) {
  return JSON.stringify({ steps: [{ content: [{ type: "text", text }] }], easyplate: extra });
}

function refuse(res, status, code, message) {
  return res.status(status).json({ error: { status: code, message } });
}

// Pure: this endpoint's `status` word for a caller refusal (aiProxy's
// paidCallerRefusal). The app keys on PHONE_REQUIRED (HttpCalls.isPhoneRequired)
// to offer phone verification — a disabled account used to get that word,
// and so the wrong screen, instead of its own.
function refusalStatus(refusal) {
  if (refusal.status === 401) return "UNAUTHENTICATED";
  return refusal.code === "account_disabled" ? "ACCOUNT_DISABLED" : "PHONE_REQUIRED";
}

exports.socialRecipe = onRequest(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
    // Cold starts are fine here: the download itself takes longer.
    minInstances: 0,
    maxInstances: 5,
    // A 30 MB video, its base64 copy and the yt-dlp process at once.
    memory: "1GiB",
    timeoutSeconds: FUNCTION_TIMEOUT_S,
    // Each request may hold a 30 MB video and its base64 copy; the default
    // 80 in flight per instance would exhaust the memory on the first busy
    // evening. Four is plenty — more traffic scales out to more instances.
    concurrency: 4,
    cors: ORIGINS,
  },
  async (req, res) => {
    if (req.method !== "POST") return refuse(res, 405, "METHOD", "POST only");
    const { caller, refusal } = await proxy.verifyPaidCaller(req);
    if (!caller) return refuse(res, refusal.status, refusalStatus(refusal), refusal.message);

    const { url, model, system_instruction: systemInstruction, prompt, schema } = req.body || {};
    const platform = typeof url === "string" ? platformOf(url) : null;
    if (!platform || typeof model !== "string" || typeof prompt !== "string" || !schema) {
      return refuse(res, 400, "BAD_REQUEST", "url, model, prompt and schema are required");
    }
    // The model id is spliced into the upstream path, which carries this
    // project's key: a "../" in it would reach any other endpoint of the
    // Gemini API (files, cached contents, tuned models) on our account.
    if (!MODEL_ID.test(model)) {
      return refuse(res, 400, "BAD_REQUEST", "model is not a model id");
    }
    // The app sends only the four platforms here (IngestionLaunch.channelForText);
    // anything else would have this server fetch an arbitrary address on the
    // caller's behalf, through yt-dlp and the caption fallback.
    if (platform === "other") {
      return refuse(res, 400, "BAD_REQUEST", "url must be a TikTok, Instagram, YouTube or Facebook link");
    }

    // Keyed on the link and on what the model is asked (see aiProxy's
    // cacheKeyFor): the prompt, system instruction and schema come from the
    // client, so without them in the key one caller's own prompt would fill
    // the entry every later paste of this video is answered from. The link
    // is not in the prompt here (it goes to yt-dlp and the caption fetch),
    // so a tracking tail cannot carry instructions and any request may fill.
    const normalizedUrl = proxy.normalizeSourceUrl(url);
    const shape = proxy.requestShape(JSON.stringify([model, systemInstruction ?? null, prompt, schema]), null);
    const cacheEntry = normalizedUrl
      ? { kind: CACHE_KIND, url, normalizedUrl, key: proxy.cacheKeyFor(CACHE_KIND, normalizedUrl, shape) }
      : null;
    if (cacheEntry) {
      const cached = await proxy.readCache(cacheEntry);
      if (cached) {
        const overHits = await proxy.cacheHitRefusal(caller.uid);
        if (overHits) return res.status(429).json(overHits);
        proxy.countHit(cacheEntry);
        return res.status(200).set("Content-Type", "application/json").set("x-easyplate-cache", "hit").send(cached.body);
      }
    }

    const uid = caller.uid;
    let limit;
    let slot;
    try {
      limit = await proxy.dailyLimitForUser(uid);
      slot = await proxy.claimQuotaSlot(uid, limit);
    } catch (err) {
      // A quota transaction that could not run (contention, Firestore down)
      // is a refusal to retry, not an unhandled rejection.
      logger.error("social recipe quota check failed", { uid, reason: err.message });
      return refuse(res, 503, "UNAVAILABLE", "Try again shortly");
    }
    if (!slot.allowed) {
      return res.status(429).json({
        error: {
          status: "RESOURCE_EXHAUSTED",
          message: `Daily limit of ${limit} AI requests reached`,
          quota: { used: slot.used, limit },
        },
      });
    }

    const started = Date.now();
    const deadline = started + DEADLINE_MS;
    let mode = "video";
    // Tokens were spent the moment the model answered, whether or not a
    // recipe came out of it — so the record is written on every exit below
    // once `usage` is known.
    let usage = null;
    const record = (status) =>
      void aiUsage.recordCall({
        uid,
        fn: "socialRecipe",
        model,
        kind: aiUsage.kindOf({ headers: req.headers, body: req.body, fn: "socialRecipe" }),
        status,
        ms: Date.now() - started,
        usage,
      });
    try {
      let answer;
      if (platform === "youtube") {
        ({ answer, usage } = await askGemini({ model, systemInstruction, prompt, schema, youtubeUrl: url, deadline }));
      } else {
        let info = null;
        let video = null;
        try {
          info = await probe(url, stepBudget(deadline, PROBE_MS));
          // The model's share of the time is kept back from the download.
          const forDownload = deadline - Date.now() - MODEL_MS;
          if (info.mediaUrl && (!info.durationSec || info.durationSec <= MAX_VIDEO_SECONDS) && forDownload > MIN_STEP_MS) {
            video = await download(info.mediaUrl, info.headers, Math.min(DOWNLOAD_MS, forDownload));
          }
        } catch (err) {
          logger.info("video fetch failed, trying the caption", { platform, reason: err.message });
        }
        let caption = captionText(info);
        if (!video) {
          mode = "caption";
          if (!caption) caption = captionText(await captionFallback(url, platform));
          if (!caption) {
            // The model was never called, so the slot goes back — but only
            // a few times a day (dailyBudget `socialProbe`): each of these
            // still ran yt-dlp and page fetches here, and a private link
            // is easy to paste in a loop.
            if (await probeRefundAllowed(uid)) await proxy.refundQuotaSlot(uid);
            return refuse(
              res,
              422,
              "SOCIAL_UNREADABLE",
              "The video and its caption could not be fetched (private account, or the platform blocked the request)",
            );
          }
        }
        ({ answer, usage } = await askGemini({ model, systemInstruction, prompt, schema, video, caption, deadline }));
      }

      if (!isUsableRecipe(answer)) {
        // No refund: the model read the video and was paid for it. The
        // prompt and schema are the caller's, so an empty answer is easy to
        // ask for, and a refund here made every such call free — up to
        // 30 MB of video per call on our key, with no daily cap.
        record(422);
        return refuse(res, 422, "SOCIAL_EMPTY", "No recipe could be read from this video");
      }

      const body = envelope(answer, { mode, platform });
      if (cacheEntry) await proxy.writeCache(cacheEntry, body, "application/json", model);
      record(200);
      logger.info("social recipe", { uid, platform, mode, ms: Date.now() - started });
      return res.status(200).set("Content-Type", "application/json").send(body);
    } catch (err) {
      logger.error("social recipe failed", { platform, mode, reason: err.message });
      // Given back only when the model never answered (an upstream error,
      // a fetch that failed): an answer that could not be read was paid for.
      if (refundable(err)) await proxy.refundQuotaSlot(uid);
      const status = err.status === 429 ? 429 : 502;
      record(status);
      // The upstream's own text (Gemini's error body, a media URL) stays in
      // the log above; the app keys on the status code, not the message.
      return refuse(res, status, "UPSTREAM", status === 429 ? "The model is busy, try again shortly" : "The recipe could not be read right now");
    }
  },
);

exports.internals = {
  platformOf, textFromHtml, metaContent, isUsableRecipe, captionText, refundable, refusalStatus, MODEL_ID,
  installYtDlp, fileMatches, stepBudget, probeRefundAllowed, callModel,
  YT_DLP_VERSION, YT_DLP_SHA256, YT_DLP_URL, DEADLINE_MS, MODEL_MS, PROBE_MS, MIN_STEP_MS, FUNCTION_TIMEOUT_S,
};
