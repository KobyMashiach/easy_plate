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
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const YTDlpWrap = require("yt-dlp-wrap").default;
const proxy = require("./aiProxy").internals;

const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Past this the video is not sent; the caption alone is used. A recipe reel
// is 30–90 seconds; a ten-minute video is a cooking show, and its bytes
// would blow the request.
const MAX_VIDEO_BYTES = 30 * 1024 * 1024;
const MAX_VIDEO_SECONDS = 10 * 60;
const CAPTION_LIMIT = 4000;
const CACHE_KIND = "video";

const BROWSER_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " +
  "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

// The yt-dlp binary is fetched once per instance into /tmp (the only
// writable place) — a few seconds on a cold start, nothing after.
const BINARY_PATH = "/tmp/yt-dlp";
let binaryPromise = null;
function ytDlp() {
  if (!binaryPromise) {
    binaryPromise = (async () => {
      if (!fs.existsSync(BINARY_PATH)) {
        await YTDlpWrap.downloadFromGithub(BINARY_PATH);
        fs.chmodSync(BINARY_PATH, 0o755);
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
  if (host === "youtu.be" || host.endsWith("youtube.com")) return "youtube";
  if (host.endsWith("tiktok.com")) return "tiktok";
  if (host.endsWith("instagram.com")) return "instagram";
  if (host.endsWith("facebook.com") || host === "fb.watch") return "facebook";
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

async function fetchText(url, headers = {}) {
  const res = await fetch(url, { headers: { "User-Agent": BROWSER_UA, ...headers } });
  if (!res.ok) throw new Error(`${url} -> ${res.status}`);
  return res.text();
}

// What yt-dlp knows about the link, without downloading anything.
async function probe(url) {
  const bin = await ytDlp();
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
  ]);
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

async function download(mediaUrl, headers) {
  const res = await fetch(mediaUrl, { headers: { "User-Agent": BROWSER_UA, ...headers } });
  if (!res.ok) throw new Error(`media -> ${res.status}`);
  const declared = Number(res.headers.get("content-length")) || 0;
  if (declared > MAX_VIDEO_BYTES) throw new Error(`media too large: ${declared}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length > MAX_VIDEO_BYTES) throw new Error(`media too large: ${buf.length}`);
  return buf;
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
async function askGemini({ model, systemInstruction, prompt, schema, video, youtubeUrl, caption }) {
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
  let res = await callModel(model, body);
  // An older endpoint may not know response_json_schema; the prompt already
  // describes the shape, so the second try goes without it.
  if (res.status === 400) {
    delete body.generation_config.response_json_schema;
    res = await callModel(model, body);
  }
  const text = await res.text();
  if (!res.ok) {
    const err = new Error(`gemini ${res.status}: ${text.slice(0, 300)}`);
    err.status = res.status;
    throw err;
  }
  const data = JSON.parse(text);
  const answer = ((((data.candidates || [])[0] || {}).content || {}).parts || [])
    .map((p) => p.text || "")
    .join("");
  if (!answer.trim()) throw new Error("gemini returned no text");
  return answer;
}

function callModel(model, body) {
  return fetch(`${proxy.GOOGLE_ORIGIN}/v1beta/models/${model}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": geminiApiKey.value() },
    body: JSON.stringify(body),
  });
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

// The Interactions envelope the app already parses, so the client has one
// reader for both proxies.
function envelope(text, extra) {
  return JSON.stringify({ steps: [{ content: [{ type: "text", text }] }], easyplate: extra });
}

function refuse(res, status, code, message) {
  return res.status(status).json({ error: { status: code, message } });
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
    timeoutSeconds: 180,
    // Each request may hold a 30 MB video and its base64 copy; the default
    // 80 in flight per instance would exhaust the memory on the first busy
    // evening. Four is plenty — more traffic scales out to more instances.
    concurrency: 4,
    cors: false,
  },
  async (req, res) => {
    if (req.method !== "POST") return refuse(res, 405, "METHOD", "POST only");
    const caller = await proxy.verifyCaller(req);
    if (!caller) return refuse(res, 401, "UNAUTHENTICATED", "A valid Firebase ID token is required");

    const { url, model, system_instruction: systemInstruction, prompt, schema } = req.body || {};
    const platform = typeof url === "string" ? platformOf(url) : null;
    if (!platform || typeof model !== "string" || typeof prompt !== "string" || !schema) {
      return refuse(res, 400, "BAD_REQUEST", "url, model, prompt and schema are required");
    }

    const normalizedUrl = proxy.normalizeSourceUrl(url);
    const cacheEntry = normalizedUrl
      ? { kind: CACHE_KIND, url, normalizedUrl, key: proxy.cacheKeyFor(CACHE_KIND, normalizedUrl) }
      : null;
    if (cacheEntry) {
      const cached = await proxy.readCache(cacheEntry);
      if (cached) {
        proxy.countHit(cacheEntry);
        return res.status(200).set("x-easyplate-cache", "hit").send(cached.body);
      }
    }

    const uid = caller.uid;
    const limit = proxy.dailyLimitForUser(uid);
    const slot = await proxy.claimQuotaSlot(uid, limit);
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
    let mode = "video";
    try {
      let answer;
      if (platform === "youtube") {
        answer = await askGemini({ model, systemInstruction, prompt, schema, youtubeUrl: url });
      } else {
        let info = null;
        let video = null;
        try {
          info = await probe(url);
          if (info.mediaUrl && (!info.durationSec || info.durationSec <= MAX_VIDEO_SECONDS)) {
            video = await download(info.mediaUrl, info.headers);
          }
        } catch (err) {
          logger.info("video fetch failed, trying the caption", { platform, reason: err.message });
        }
        let caption = captionText(info);
        if (!video) {
          mode = "caption";
          if (!caption) caption = captionText(await captionFallback(url, platform));
          if (!caption) {
            await proxy.refundQuotaSlot(uid);
            return refuse(
              res,
              422,
              "SOCIAL_UNREADABLE",
              "The video and its caption could not be fetched (private account, or the platform blocked the request)",
            );
          }
        }
        answer = await askGemini({ model, systemInstruction, prompt, schema, video, caption });
      }

      if (!isUsableRecipe(answer)) {
        await proxy.refundQuotaSlot(uid);
        return refuse(res, 422, "SOCIAL_EMPTY", "No recipe could be read from this video");
      }

      const body = envelope(answer, { mode, platform });
      if (cacheEntry) await proxy.writeCache(cacheEntry, body, "application/json", model);
      logger.info("social recipe", { uid, platform, mode, ms: Date.now() - started });
      return res.status(200).set("Content-Type", "application/json").send(body);
    } catch (err) {
      logger.error("social recipe failed", { platform, mode, reason: err.message });
      await proxy.refundQuotaSlot(uid);
      const status = err.status === 429 ? 429 : 502;
      return refuse(res, status, "UPSTREAM", err.message);
    }
  },
);

exports.internals = { platformOf, textFromHtml, metaContent, isUsableRecipe, captionText };
