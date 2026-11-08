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
// The recipe comes back with pictures to choose from (2026-10-27, Koby:
// "take the picture from the video"): the post's own cover first — yt-dlp's
// thumbnail, the oEmbed thumbnail, og:image, YouTube's i.ytimg.com — and,
// when the video itself was fetched, up to five stills of the food cut with
// ffmpeg at moments the model names in the same call (no people, no hands,
// the finished dish first). The app shows the cover as the recipe photo and
// the stills as the alternatives.
//
// Auth, the daily quota and the URL cache are aiProxy's, reused as-is.
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const crypto = require("node:crypto");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const YTDlpWrap = require("yt-dlp-wrap").default;
// A static ffmpeg, installed with the package (no download on a cold start,
// unlike yt-dlp, which has to track the platforms). Only stills and a
// resize are asked of it.
const ffmpegPath = require("ffmpeg-static");

// ffmpeg-static fetches that binary at `npm install` — in Cloud Build, on
// every deploy — from a GitHub release, with no checksum: a replaced release
// asset would run here on strangers' media, on the instance that holds the
// Gemini key. So it is hashed before its first run on an instance and
// compared with the binary of the pinned release (ffmpeg-static 5.2.0 →
// tag b6.0, ffmpeg 6.0; the package is pinned exactly in package.json). A
// mismatch means no ffmpeg on this instance at all — no cover re-encode, no
// stills, an error in the log — and the recipe still goes out.
//
// linux-x64 is what Cloud Functions runs; darwin-arm64 is the Mac the tests
// and the emulator run on. Any other platform has no pinned hash and gets no
// ffmpeg. To move ffmpeg-static: gunzip that release's
// ffmpeg-<platform>-<arch>.gz and take the SHA-256 of the binary inside (the
// release publishes no sums of its own).
const FFMPEG_SHA256 = {
  "linux-x64": "ed652b2f32e0851d1946894fb8333f5b677c1b2ce6b9d187910a67f8b99da028",
  "darwin-arm64": "a90e3db6a3fd35f6074b013f948b1aa45b31c6375489d39e572bea3f18336584",
};
const FFMPEG_EXPECTED = FFMPEG_SHA256[`${process.platform}-${process.arch}`] || null;
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

// The pictures offered with the recipe. JPEG, sized for a phone card,
// base64 inside the envelope — the app stores the chosen one like a photo
// it took. The envelope is cached in a Firestore document (1 MiB), so the
// pictures are trimmed to a budget that leaves room for the recipe.
const COVER_MAX_SIDE = 1024;
const FRAME_MAX_SIDE = 720;
const MAX_FRAMES = 5;
const MAX_COVER_BYTES = 8 * 1024 * 1024;
// A cover that ffmpeg could not re-encode is passed on as fetched only when
// it is already a JPEG this small.
const MAX_RAW_COVER_BYTES = 400 * 1024;
const MAX_IMAGES_BASE64 = 600 * 1024;
const COVER_MS = 15 * 1000;
const FFMPEG_MS = 15 * 1000;
const FRAME_FIELD = "food_frame_seconds";
// Part of the cache key: an answer cached before the pictures existed is
// a recipe alone, and must not be served as the whole answer now.
const ENVELOPE_VERSION = "images:1";

// A model id as Google names them ("gemini-3.8-flash", "gemini-2.5-flash-lite"):
// no slash, no colon, no dot-dot, so it cannot leave /v1beta/models/.
const MODEL_ID = /^[a-z0-9](?:[a-z0-9-]|\.(?!\.)){0,63}$/i;

const BROWSER_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " +
  "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

// TikTok answers yt-dlp's own webpage request with a page it cannot read
// ("Unexpected response from webpage request", yt-dlp issue #17604, every
// TikTok link from 2026-09 on); a desktop browser's user agent gets the real
// page. Only for TikTok: the other platforms read fine with yt-dlp's default.
const TIKTOK_UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36";

// Pure: the flags a platform needs on top of the probe's own.
function probeExtraArgs(url) {
  return platformOf(url) === "tiktok" ? ["--user-agent", TIKTOK_UA] : [];
}

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
// The standalone Linux build, not the `yt-dlp` zipapp: the zipapp runs on
// the instance's own python3, which is 3.10 on the Cloud Functions image,
// and yt-dlp dropped 3.10 in 2026.10.26. The standalone build carries its
// own Python (and curl_cffi for browser impersonation), so the runtime's
// Python no longer decides which yt-dlp can run.
//
// To move to a newer yt-dlp: take the tag from github.com/yt-dlp/yt-dlp/
// releases and the `yt-dlp_linux` line of that release's SHA2-256SUMS.
const YT_DLP_VERSION = "2026.10.26";
const YT_DLP_SHA256 = "767ba9dce7052aa196f8b12652f433d76de128ba168966fa84b6394d5e6c6795";
const YT_DLP_URL = `https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp_linux`;
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

// Pure: whether a link on an allowed host is the platform's outbound
// redirector rather than a post — Facebook's and Instagram's link shim
// (l./lm. hosts, /l.php), TikTok's /link/ — or a YouTube /redirect.
function isLinkShim(url) {
  let u;
  try {
    u = new URL(url);
  } catch (_) {
    return false;
  }
  const host = u.hostname.toLowerCase().replace(/\.$/, "");
  const path = u.pathname.toLowerCase();
  const on = (domain) => host === domain || host.endsWith(`.${domain}`);
  if (on("facebook.com") || on("instagram.com") || host === "fb.me") {
    if (/^(l|lm)\./.test(host) || host === "fb.me") return true;
    if (path === "/l.php" || path.startsWith("/l/") || path.startsWith("/flx/")) return true;
  }
  if (on("tiktok.com") && path.startsWith("/link")) return true;
  if (on("youtube.com") && path.startsWith("/redirect")) return true;
  return false;
}

// Pure: the post a redirector link wraps, when it names one of the four
// platforms (and is not itself a redirector); otherwise [url] unchanged —
// a redirector to anywhere else stays one, and is refused.
function unwrapLinkShim(url) {
  if (!isLinkShim(url)) return url;
  const params = new URL(url).searchParams;
  for (const key of ["u", "q", "target", "url"]) {
    const inner = params.get(key);
    if (!inner || !/^https:\/\//i.test(inner)) continue;
    const platform = platformOf(inner);
    if (platform && platform !== "other" && !isLinkShim(inner)) return inner;
  }
  return url;
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

// ---------------------------------------------------------------------------
// The post's cover.
// ---------------------------------------------------------------------------

// The video id in any YouTube link the app accepts (watch?v=, youtu.be/,
// /shorts/, /embed/, /live/), or null.
function youtubeId(url) {
  let u;
  try {
    u = new URL(url);
  } catch (_) {
    return null;
  }
  const host = u.hostname.toLowerCase().replace(/^(www|m)\./, "");
  const ok = (id) => (id && /^[A-Za-z0-9_-]{11}$/.test(id) ? id : null);
  if (host === "youtu.be") return ok(u.pathname.split("/")[1]);
  if (host !== "youtube.com" && !host.endsWith(".youtube.com")) return null;
  if (u.searchParams.get("v")) return ok(u.searchParams.get("v"));
  const m = u.pathname.match(/^\/(?:shorts|embed|live|v)\/([A-Za-z0-9_-]{11})/);
  return m ? ok(m[1]) : null;
}

// Best first: maxresdefault exists only for videos uploaded with one (a 404
// otherwise); hqdefault exists for every video.
function youtubeThumbnails(id) {
  return [
    `https://i.ytimg.com/vi/${id}/maxresdefault.jpg`,
    `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
  ];
}

// Pure: the cover as yt-dlp reports it — `thumbnail` is its own pick;
// failing that, the preferred / largest entry of `thumbnails`.
function coverFromProbe(info) {
  if (!info || typeof info !== "object") return null;
  const isHttp = (value) => typeof value === "string" && /^https?:\/\//i.test(value);
  if (isHttp(info.thumbnail)) return info.thumbnail;
  const list = Array.isArray(info.thumbnails) ? info.thumbnails : [];
  const area = (t) => (Number(t.width) || 0) * (Number(t.height) || 0);
  const best = list
    .filter((t) => t && isHttp(t.url))
    .sort((a, b) => (Number(b.preference) || 0) - (Number(a.preference) || 0) || area(b) - area(a))[0];
  return best ? best.url : null;
}

// Pure: the picture on Instagram's captioned embed page (the post's own
// cover; the tag's attributes come in either order).
function instagramEmbedImage(html) {
  for (const tag of String(html).match(/<img\b[^>]*>/gi) || []) {
    if (!/EmbeddedMediaImage/i.test(tag)) continue;
    const m = tag.match(/\bsrc=["']([^"']+)["']/i);
    if (m) return m[1].replace(/&amp;/g, "&");
  }
  return null;
}

// ---------------------------------------------------------------------------
// Stills of the food.
// ---------------------------------------------------------------------------

// Pure: the caller's schema with one more property — the moments the model
// finds worth a still. Taken back out of the answer by stripFrameField, so
// the app's reader gets the shape it sent.
function withFrameField(schema) {
  if (!schema || typeof schema !== "object" || Array.isArray(schema)) return schema;
  const properties = { ...(schema.properties || {}) };
  properties[FRAME_FIELD] = {
    type: "array",
    items: { type: "number" },
    description:
      `Up to ${MAX_FRAMES} moments, as seconds from the start of the video, where the dish or the food ` +
      "fills the frame with no person, hands or face in view and no large text over it; the finished " +
      "dish first. Empty when there is no such moment.",
  };
  return { ...schema, properties };
}

const FRAME_PROMPT =
  `בנוסף, בשדה ${FRAME_FIELD} החזר עד ${MAX_FRAMES} נקודות זמן (שניות מתחילת הסרטון) שבהן המנה או האוכל ` +
  "ממלאים את הפריים, ללא אנשים, ידיים או פנים, ובלי כתוביות גדולות; המנה המוגמרת קודם. " +
  "אם אין רגע כזה, החזר רשימה ריקה.";

function answerObject(text) {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  return JSON.parse(text.slice(start, end + 1));
}

// Pure: the answer without the frame list (unchanged when it has none, or
// is not JSON — isUsableRecipe refuses that one anyway).
function stripFrameField(text) {
  try {
    const obj = answerObject(text);
    if (!(FRAME_FIELD in obj)) return text;
    delete obj[FRAME_FIELD];
    return JSON.stringify(obj);
  } catch (_) {
    return text;
  }
}

// "1:05" as the model sometimes writes a moment, or a plain number of
// seconds. NaN for anything else.
function seconds(value) {
  if (typeof value === "number") return value;
  if (typeof value !== "string") return NaN;
  const m = value.trim().match(/^(?:(\d+):)?(\d+)(?::(\d+))?(?:\.\d+)?$/);
  if (!m) return Number(value);
  if (m[3] !== undefined) return Number(m[1] || 0) * 3600 + Number(m[2]) * 60 + Number(m[3]);
  if (m[1] !== undefined) return Number(m[1]) * 60 + Number(m[2]);
  return Number(m[2]);
}

// Pure: the seconds to cut stills at. The model's own list — inside the
// video, no two within a second of each other, in its order (best first),
// at most [want] — or, when it named none and the length is known, [want]
// moments evenly through the video, so the cook still has something to
// choose from (the picker is theirs; a still with a person in it is one
// they skip).
function frameTimes(text, durationSec, want = MAX_FRAMES) {
  let listed = [];
  try {
    const raw = answerObject(text)[FRAME_FIELD];
    if (Array.isArray(raw)) listed = raw;
  } catch (_) {
    // No list: the fallback below.
  }
  const limit = durationSec > 0 ? durationSec : Infinity;
  const times = [];
  for (const value of listed) {
    const t = seconds(value);
    if (!Number.isFinite(t) || t < 0 || t >= limit) continue;
    if (times.some((seen) => Math.abs(seen - t) < 1)) continue;
    times.push(Math.round(t * 10) / 10);
    if (times.length >= want) break;
  }
  if (times.length || !(durationSec > 0)) return times;
  return Array.from({ length: want }, (_, i) => Math.round(((durationSec * (i + 1)) / (want + 1)) * 10) / 10);
}

// Pure: the pictures that fit the envelope's budget, in order — a picture
// too big for what is left is skipped, the next smaller one still taken.
function fitImages(images, max = MAX_IMAGES_BASE64) {
  const kept = [];
  let total = 0;
  for (const image of images) {
    const size = image && typeof image.jpeg === "string" ? image.jpeg.length : Infinity;
    if (total + size > max) continue;
    kept.push(image);
    total += size;
  }
  return kept;
}

const execFileAsync = promisify(execFile);

// The environment for yt-dlp and ffmpeg: this instance's, minus the secrets
// Firebase mounts into it (GEMINI_API_KEY). Both run on strangers' pages and
// media, and a parser bug in either reads its own environment first.
const SECRET_ENV = ["GEMINI_API_KEY"];
function childEnv(env = process.env) {
  const out = { ...env };
  for (const name of SECRET_ENV) delete out[name];
  return out;
}

// The SHA-256 of a file, streamed — the ffmpeg binary is 78 MB,
// and a Buffer that size is memory the requests on this instance need.
function hashFile(file) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash("sha256");
    fs.createReadStream(file)
      .on("error", reject)
      .on("data", (chunk) => hash.update(chunk))
      .on("end", () => resolve(hash.digest("hex")));
  });
}

// One check per binary per instance: the verdict, a failure included, is
// kept — the file does not change under a running instance, and hashing it
// on every request would cost each one a quarter of a second.
const ffmpegChecks = new Map();
function ffmpegTrusted(binary = ffmpegPath, expected = FFMPEG_EXPECTED) {
  const key = `${binary}\0${expected}`;
  if (!ffmpegChecks.has(key)) {
    ffmpegChecks.set(
      key,
      (async () => {
        if (!binary || !expected) {
          logger.error("ffmpeg has no pinned checksum on this platform; pictures are off", { platform: `${process.platform}-${process.arch}` });
          return false;
        }
        const got = await hashFile(binary).catch((err) => `unreadable: ${err.message}`);
        if (got !== expected) {
          logger.error("ffmpeg binary failed its checksum; pictures are off on this instance", { got, expected });
          return false;
        }
        return true;
      })(),
    );
  }
  return ffmpegChecks.get(key);
}

async function assertFfmpeg(binary, expected) {
  if (!(await ffmpegTrusted(binary, expected))) throw new Error("ffmpeg binary failed its checksum");
}

async function runFfmpeg(args, timeoutMs = FFMPEG_MS, binary = ffmpegPath, expected = FFMPEG_EXPECTED) {
  await assertFfmpeg(binary, expected);
  await execFileAsync(binary, ["-hide_banner", "-loglevel", "error", "-y", ...args], {
    timeout: timeoutMs,
    maxBuffer: 1024 * 1024,
    env: childEnv(),
  });
}

// Longest side at most [maxSide], never upscaled, even dimensions (the
// JPEG encoder wants them).
function scaleFilter(maxSide) {
  return `scale=w='min(${maxSide},iw)':h='min(${maxSide},ih)':force_original_aspect_ratio=decrease:force_divisible_by=2`;
}

// The bytes handed to ffmpeg are a stranger's (the platform's CDN, or
// wherever yt-dlp was redirected), and ffmpeg picks its reader from the
// content, not the file name: a "video" that is an HLS playlist makes it
// open every file:// path listed in it — /proc/self/environ, with the
// Gemini key, included — and cut the stills from those. So the reader is
// named from the sniffed container (a stranger's bytes that are neither
// mp4 nor matroska get no stills), and only the local file itself may be
// opened.
const IMAGE_DEMUXERS = {
  "image/jpeg": "jpeg_pipe",
  "image/png": "png_pipe",
  "image/webp": "webp_pipe",
  "image/gif": "gif",
};

// Pure: ffmpeg's reader for a downloaded video, or null. ISO media (mp4,
// mov) opens with a box whose type is at byte 4; matroska/webm with the
// EBML magic.
function videoDemuxer(bytes) {
  if (!Buffer.isBuffer(bytes) || bytes.length < 12) return null;
  if (["ftyp", "moov", "mdat", "free", "wide"].includes(bytes.toString("latin1", 4, 8))) return "mov";
  if (bytes.readUInt32BE(0) === 0x1a45dfa3) return "matroska";
  return null;
}

// Decoded size, too: a picture is decoded whole before it is scaled, and a
// 450 KB PNG of 12000x12000 took ffmpeg to 540 MB — two such covers, or one
// at the decoder's own ceiling, and the 1 GiB instance dies with the other
// request it holds. Real covers and videos are far below these
// (a 4K thumbnail is 8.3 MP; a phone video 2 MP a frame).
const MAX_COVER_PIXELS = 40 * 1000 * 1000;
const MAX_VIDEO_PIXELS = 4096 * 4096;

// Pure: the input half of an ffmpeg command line — local file only, the
// reader fixed, the decoded size capped.
function inputArgs(demuxer, input, maxPixels) {
  return ["-protocol_whitelist", "file", "-max_pixels", String(maxPixels), "-f", demuxer, "-i", input];
}

// A scratch directory for one request, removed whatever happens: /tmp is
// memory here, and a file left behind is memory the next request lacks.
async function withScratch(fn) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "social-"));
  try {
    return await fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

/// [bytes] (a JPEG, PNG, WebP or GIF, by its magic) as a JPEG no larger
/// than [maxSide]; anything else is refused before ffmpeg sees it.
async function toJpeg(bytes, maxSide, dir, name, timeoutMs = FFMPEG_MS, binary = ffmpegPath) {
  const demuxer = IMAGE_DEMUXERS[safeFetch.sniffImage(bytes)];
  if (!demuxer) throw new Error("not a picture ffmpeg is allowed to read");
  const input = path.join(dir, `${name}.in`);
  const output = path.join(dir, `${name}.jpg`);
  fs.writeFileSync(input, bytes);
  await runFfmpeg([...inputArgs(demuxer, input, MAX_COVER_PIXELS), "-frames:v", "1", "-vf", scaleFilter(maxSide), "-q:v", "4", output], timeoutMs, binary);
  return fs.readFileSync(output);
}

/// One still per entry of [times], as `{kind: "frame", at, jpeg}`; a
/// moment ffmpeg cannot cut is left out, and the run stops when the request
/// is nearly out of time.
async function extractFrames(video, times, dir, deadline, binary = ffmpegPath, expected = FFMPEG_EXPECTED) {
  const demuxer = videoDemuxer(video);
  if (!demuxer) {
    logger.info("frame extraction skipped: not an mp4 or matroska file");
    return [];
  }
  // Before the video is copied to /tmp (memory here): with no trusted
  // ffmpeg every cut would fail anyway.
  if (!(await ffmpegTrusted(binary, expected))) return [];
  const input = path.join(dir, "video.mp4");
  fs.writeFileSync(input, video);
  const frames = [];
  for (const [i, at] of times.entries()) {
    if (deadline - Date.now() < MIN_STEP_MS) break;
    const output = path.join(dir, `frame${i}.jpg`);
    try {
      await runFfmpeg(
        ["-ss", String(at), ...inputArgs(demuxer, input, MAX_VIDEO_PIXELS), "-frames:v", "1", "-vf", scaleFilter(FRAME_MAX_SIDE), "-q:v", "5", output],
        stepBudget(deadline, FFMPEG_MS),
        binary,
        expected,
      );
      frames.push({ kind: "frame", at, jpeg: fs.readFileSync(output).toString("base64") });
    } catch (err) {
      logger.info("frame extraction failed", { at, reason: err.message });
    }
  }
  return frames;
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
const PROBE_MAX_BUFFER = 16 * 1024 * 1024;

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

// Pure: yt-dlp's `cookies` field ("a=1; Domain=.tiktok.com; Path=/; Secure;
// Expires=…; b=2; Domain=…") as the Cookie header the media fetch sends.
// TikTok's CDN answers 403 without its tt_chain_token, which yt-dlp keeps
// here rather than in http_headers.
const COOKIE_ATTRIBUTES = new Set(["domain", "path", "expires", "max-age", "secure", "httponly", "samesite"]);
function cookieHeader(cookies) {
  if (typeof cookies !== "string") return "";
  return cookies
    .split(";")
    .map((part) => part.trim())
    .filter((part) => {
      const eq = part.indexOf("=");
      return eq > 0 && !COOKIE_ATTRIBUTES.has(part.slice(0, eq).trim().toLowerCase());
    })
    .join("; ");
}

function withCookies(headers, cookies) {
  const cookie = cookieHeader(cookies);
  if (!cookie || Object.keys(headers).some((k) => k.toLowerCase() === "cookie")) return headers;
  return { ...headers, Cookie: cookie };
}

// One self-contained mp4, H.264 first (what every model reads), no merging
// so no ffmpeg needed; falls back to whatever exists.
const VIDEO_FORMAT =
  `best[ext=mp4][vcodec^=h264][filesize<${MAX_VIDEO_BYTES}]/` +
  `best[ext=mp4][vcodec!=none][filesize<${MAX_VIDEO_BYTES}]/best[ext=mp4]/best`;

// What yt-dlp knows about the link, without downloading anything.
async function probe(url, timeoutMs = PROBE_MS) {
  const bin = await ytDlp();
  // --socket-timeout bounds each read, not the run: an extractor that keeps
  // following pages could hold the request until the function's own limit.
  // stdout is one JSON document about one post (a few hundred KB at most);
  // the wrapper's own default buffer is 1 GiB.
  const out = await bin.execPromise([
    // No yt-dlp.conf from anywhere (the binary's own /tmp directory, the
    // working directory, $HOME): the flags below are the whole command.
    "--ignore-config",
    "--dump-single-json",
    "--no-playlist",
    "--no-warnings",
    "--skip-download",
    "--socket-timeout",
    "20",
    "-f",
    VIDEO_FORMAT,
    ...probeExtraArgs(url),
    url,
  ], { env: childEnv(), maxBuffer: PROBE_MAX_BUFFER }, AbortSignal.timeout(timeoutMs));
  const info = JSON.parse(out);
  const chosen = (info.requested_downloads && info.requested_downloads[0]) || info;
  return {
    title: info.title || null,
    description: info.description || null,
    mediaUrl: chosen.url || null,
    headers: withCookies(chosen.http_headers || info.http_headers || {}, chosen.cookies || info.cookies),
    durationSec: Number(info.duration) || null,
    thumbnail: coverFromProbe(info),
  };
}

// The first of [urls] that answers with a picture, as fetched (ffmpeg sizes
// it later), or null — a missing cover is not a failed recipe. Through the
// SSRF guard like every other fetch here: a thumbnail URL is the platform's
// (or yt-dlp's reading of it), not ours.
async function fetchFirstCover(urls, headers = {}, deadline = Date.now() + DEADLINE_MS) {
  for (const url of urls) {
    if (deadline - Date.now() < MIN_STEP_MS) return null;
    try {
      const res = await safeFetch.fetchPublic(url, fetch, {
        headers: { "User-Agent": BROWSER_UA, Accept: "image/*,*/*;q=0.5", ...headers },
        timeoutMs: stepBudget(deadline, COVER_MS),
      });
      if (!res.ok) throw new Error(`cover -> ${res.status}`);
      const bytes = await safeFetch.readCapped(res, MAX_COVER_BYTES);
      if (!safeFetch.sniffImage(bytes)) throw new Error("cover is not an image");
      return bytes;
    } catch (err) {
      logger.info("cover fetch failed", { reason: err.message });
    }
  }
  return null;
}

/// The pictures for the envelope: the cover (re-encoded; passed on as
/// fetched only when it is already a small JPEG) and then the stills, cut
/// from [video] at the moments the model listed in [answer]. Never throws —
/// a recipe without pictures is still the recipe.
async function collectImages({ cover, video, answer, durationSec, deadline }) {
  try {
    return await withScratch(async (dir) => {
      const images = [];
      const coverBytes = await cover;
      if (coverBytes) {
        try {
          // Bounded by the request's time like every other step: the model
          // may have used it all, and a 15 s re-encode after that ran past
          // the function's own limit (the slot spent, no answer sent). Past
          // the deadline the function still has FUNCTION_TIMEOUT_S - DEADLINE_MS;
          // the cover may take half of it.
          const coverMs = Math.min(FFMPEG_MS, Math.max(1000, deadline + MIN_STEP_MS - Date.now()));
          images.push({ kind: "cover", jpeg: (await toJpeg(coverBytes, COVER_MAX_SIDE, dir, "cover", coverMs)).toString("base64") });
        } catch (err) {
          logger.info("cover re-encode failed", { reason: err.message });
          if (coverBytes.length <= MAX_RAW_COVER_BYTES && safeFetch.sniffImage(coverBytes) === "image/jpeg") {
            images.push({ kind: "cover", jpeg: coverBytes.toString("base64") });
          }
        }
      }
      if (video && deadline - Date.now() > MIN_STEP_MS) {
        images.push(...(await extractFrames(video, frameTimes(answer, durationSec), dir, deadline)));
      }
      return fitImages(images);
    });
  } catch (err) {
    logger.warn("recipe pictures skipped", { reason: err.message });
    return [];
  }
}

// The video fetched by yt-dlp itself. TikTok's media URL is tied to the
// session that read the page (a plain fetch of it answers 403 even with the
// page's cookies, checked 2026-11-04), so when [download] is refused the
// file comes from the run that can open it. Capped like [download].
async function downloadWithYtDlp(url, timeoutMs = DOWNLOAD_MS) {
  const bin = await ytDlp();
  return withScratch(async (dir) => {
    await bin.execPromise([
      "--ignore-config",
      "--no-playlist",
      "--no-warnings",
      "--no-progress",
      "--socket-timeout",
      "20",
      "--max-filesize",
      String(MAX_VIDEO_BYTES),
      "-f",
      VIDEO_FORMAT,
      ...probeExtraArgs(url),
      "-o",
      path.join(dir, "video.%(ext)s"),
      url,
    ], { env: childEnv(), maxBuffer: PROBE_MAX_BUFFER }, AbortSignal.timeout(timeoutMs));
    const file = fs.readdirSync(dir).find((name) => name.startsWith("video.") && !name.endsWith(".part"));
    // --max-filesize leaves nothing behind for a video over the cap.
    if (!file) throw new Error("yt-dlp wrote no video");
    const bytes = fs.readFileSync(path.join(dir, file));
    if (bytes.length > MAX_VIDEO_BYTES) throw new Error("video over the size cap");
    return bytes;
  });
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
        const thumbnail = typeof json.thumbnail_url === "string" ? json.thumbnail_url : null;
        return json.title ? { title: json.title, description: null, thumbnail } : null;
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
        return { title: null, description: text.slice(0, CAPTION_LIMIT), thumbnail: instagramEmbedImage(html) };
      }
      default: {
        const html = await fetchText(url);
        const description = metaContent(html, "og:description") || metaContent(html, "description");
        const title = metaContent(html, "og:title");
        const thumbnail = metaContent(html, "og:image");
        return description || title ? { title, description, thumbnail } : null;
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
async function askGemini({ model, systemInstruction, prompt, schema, video, youtubeUrl, caption, deadline = Date.now() + DEADLINE_MS, maxOutputTokens = proxy.MAX_OUTPUT_TOKENS }) {
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
      // aiProxy's ceiling: a recipe and five timestamps are a few thousand.
      max_output_tokens: maxOutputTokens,
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
  if (refusal.status === 503) return "UNAVAILABLE";
  return refusal.code === "account_disabled" ? "ACCOUNT_DISABLED" : "PHONE_REQUIRED";
}

exports.socialRecipe = onRequest(
  {
    region: "europe-west1",
    secrets: [geminiApiKey],
    // Cold starts are fine here: the download itself takes longer.
    minInstances: 0,
    // Ten instances of two requests: the same twenty in flight as the five
    // of four this used to be, each with the memory it needs.
    maxInstances: 10,
    // A 30 MB video, its base64 copy and the yt-dlp process at once.
    memory: "1GiB",
    timeoutSeconds: FUNCTION_TIMEOUT_S,
    // One request holds a 30 MB video Buffer, its ~40 MB base64 copy in the
    // model's request body, a 30 MB copy in /tmp (which is memory here) and
    // an ffmpeg process decoding it, next to the Node heap and yt-dlp's
    // Python. Four of those at once (the old setting) left no headroom on
    // 1 GiB, and an instance that runs out takes every request on it down.
    // Two fit; more traffic scales out to more instances.
    concurrency: 2,
    cors: ORIGINS,
  },
  async (req, res) => {
    if (req.method !== "POST") return refuse(res, 405, "METHOD", "POST only");
    const { caller, refusal } = await proxy.verifyPaidCaller(req);
    if (!caller) return refuse(res, refusal.status, refusalStatus(refusal), refusal.message);

    const { url: sentUrl, model, system_instruction: systemInstruction, prompt, schema } = req.body || {};
    // A post link that came wrapped in a platform's redirector (copied from
    // inside Facebook or Instagram) is read as the post it names.
    const url = typeof sentUrl === "string" ? unwrapLinkShim(sentUrl) : sentUrl;
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
    // The same for a platform's own "you are leaving" redirector: it is on
    // an allowed host, but yt-dlp follows it (by itself, unguarded) to
    // whatever site the link names, and the page and media fetched from
    // there are a stranger's.
    if (platform === "other" || isLinkShim(url)) {
      return refuse(res, 400, "BAD_REQUEST", "url must be a TikTok, Instagram, YouTube or Facebook link");
    }
    // aiProxy's limits on what the model is asked: the prompt, system
    // instruction and schema are the caller's here too, and only the call
    // is counted. The caption and the frame prompt are ours (and capped).
    const limits = await proxy.sizeLimits();
    const tooLarge = proxy.sizeRefusal(
      { system_instruction: systemInstruction ?? null, input: prompt, response_format: { schema } },
      limits,
    );
    if (tooLarge) return refuse(res, 413, "TOO_LARGE", tooLarge.message);

    // Keyed on the link and on what the model is asked (see aiProxy's
    // cacheKeyFor): the prompt, system instruction and schema come from the
    // client, so without them in the key one caller's own prompt would fill
    // the entry every later paste of this video is answered from. The link
    // is not in the prompt here (it goes to yt-dlp and the caption fetch),
    // so a tracking tail cannot carry instructions and any request may fill.
    const normalizedUrl = proxy.normalizeSourceUrl(url);
    const shape = proxy.requestShape(JSON.stringify([model, systemInstruction ?? null, prompt, schema, ENVELOPE_VERSION]), null);
    const cacheEntry = normalizedUrl
      ? { kind: CACHE_KIND, url, normalizedUrl, key: proxy.cacheKeyFor(CACHE_KIND, normalizedUrl, shape) }
      : null;
    if (cacheEntry) {
      const cached = await proxy.readCache(cacheEntry);
      if (cached) {
        const overHits = await proxy.cacheHitRefusal(proxy.quotaKeyOf(caller));
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
      slot = await proxy.claimQuotaSlot(proxy.quotaKeyOf(caller), limit);
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
      // The cover is fetched while the model works; the stills are cut once
      // the model has named the moments, from the video already in memory.
      let cover = Promise.resolve(null);
      let video = null;
      let durationSec = null;
      if (platform === "youtube") {
        const id = youtubeId(url);
        if (id) cover = fetchFirstCover(youtubeThumbnails(id), {}, deadline);
        ({ answer, usage } = await askGemini({ model, systemInstruction, prompt, schema, youtubeUrl: url, deadline, maxOutputTokens: limits.outputTokens }));
      } else {
        let info = null;
        try {
          info = await probe(url, stepBudget(deadline, PROBE_MS));
          // The model's share of the time is kept back from the download.
          const forDownload = deadline - Date.now() - MODEL_MS;
          if (info.mediaUrl && (!info.durationSec || info.durationSec <= MAX_VIDEO_SECONDS) && forDownload > MIN_STEP_MS) {
            const budget = Math.min(DOWNLOAD_MS, forDownload);
            const fetchStarted = Date.now();
            try {
              video = await download(info.mediaUrl, info.headers, budget);
            } catch (err) {
              const left = budget - (Date.now() - fetchStarted);
              if (left < MIN_STEP_MS) throw err;
              logger.info("media fetch refused, downloading through yt-dlp", { platform, reason: err.message });
              video = await downloadWithYtDlp(url, left);
            }
          }
        } catch (err) {
          logger.info("video fetch failed, trying the caption", { platform, reason: err.message });
        }
        durationSec = info ? info.durationSec : null;
        let coverUrls = info && info.thumbnail ? [info.thumbnail] : [];
        let caption = captionText(info);
        if (!video) {
          mode = "caption";
          if (!caption) {
            const fallback = await captionFallback(url, platform);
            caption = captionText(fallback);
            if (!coverUrls.length && fallback && fallback.thumbnail) coverUrls = [fallback.thumbnail];
          }
          if (!caption) {
            // The model was never called, so the slot goes back — but only
            // a few times a day (dailyBudget `socialProbe`): each of these
            // still ran yt-dlp and page fetches here, and a private link
            // is easy to paste in a loop.
            if (await probeRefundAllowed(uid)) await proxy.refundQuotaSlot(proxy.quotaKeyOf(caller));
            return refuse(
              res,
              422,
              "SOCIAL_UNREADABLE",
              "The video and its caption could not be fetched (private account, or the platform blocked the request)",
            );
          }
        }
        cover = fetchFirstCover(coverUrls, (info && info.headers) || {}, deadline);
        // With the video in hand the model is also asked where the food is
        // on screen — one more field, one more line, the same call.
        ({ answer, usage } = await askGemini({
          model,
          systemInstruction,
          prompt: video ? `${prompt}\n\n${FRAME_PROMPT}` : prompt,
          schema: video ? withFrameField(schema) : schema,
          video,
          caption,
          deadline,
          maxOutputTokens: limits.outputTokens,
        }));
      }

      if (!isUsableRecipe(answer)) {
        // No refund: the model read the video and was paid for it. The
        // prompt and schema are the caller's, so an empty answer is easy to
        // ask for, and a refund here made every such call free — up to
        // 30 MB of video per call on our key, with no daily cap.
        record(422);
        return refuse(res, 422, "SOCIAL_EMPTY", "No recipe could be read from this video");
      }

      const images = await collectImages({ cover, video, answer, durationSec, deadline });
      const body = envelope(stripFrameField(answer), { mode, platform, images });
      if (cacheEntry) await proxy.writeCache(cacheEntry, body, "application/json", model);
      record(200);
      logger.info("social recipe", { uid, platform, mode, images: images.length, ms: Date.now() - started });
      return res.status(200).set("Content-Type", "application/json").send(body);
    } catch (err) {
      logger.error("social recipe failed", { platform, mode, reason: err.message });
      // Given back only when the model never answered (an upstream error,
      // a fetch that failed): an answer that could not be read was paid for.
      if (refundable(err)) await proxy.refundQuotaSlot(proxy.quotaKeyOf(caller));
      const status = err.status === 429 ? 429 : 502;
      record(status);
      // The upstream's own text (Gemini's error body, a media URL) stays in
      // the log above; the app keys on the status code, not the message.
      return refuse(res, status, "UPSTREAM", status === 429 ? "The model is busy, try again shortly" : "The recipe could not be read right now");
    }
  },
);

exports.internals = {
  platformOf, probeExtraArgs, cookieHeader, withCookies, isLinkShim, unwrapLinkShim, textFromHtml, metaContent, isUsableRecipe, captionText, refundable, refusalStatus, MODEL_ID,
  installYtDlp, fileMatches, stepBudget, probeRefundAllowed, callModel,
  youtubeId, youtubeThumbnails, coverFromProbe, instagramEmbedImage,
  withFrameField, stripFrameField, frameTimes, seconds, fitImages, scaleFilter, videoDemuxer, inputArgs, childEnv, MAX_COVER_PIXELS, MAX_VIDEO_PIXELS,
  toJpeg, extractFrames, withScratch, runFfmpeg, collectImages, fetchFirstCover, probe, download, downloadWithYtDlp, captionFallback,
  FRAME_FIELD, FRAME_PROMPT, MAX_FRAMES, MAX_IMAGES_BASE64, ENVELOPE_VERSION, ffmpegPath,
  FFMPEG_SHA256, FFMPEG_EXPECTED, ffmpegTrusted, hashFile,
  YT_DLP_VERSION, YT_DLP_SHA256, YT_DLP_URL, DEADLINE_MS, MODEL_MS, PROBE_MS, MIN_STEP_MS, FUNCTION_TIMEOUT_S,
};
