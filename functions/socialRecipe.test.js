const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { platformOf, textFromHtml, metaContent, isUsableRecipe, captionText } =
  require("./socialRecipe").internals;

test("every short-form platform is recognised, with or without www/m", () => {
  assert.equal(platformOf("https://www.tiktok.com/@a/video/1"), "tiktok");
  assert.equal(platformOf("https://vm.tiktok.com/ZM1/"), "tiktok");
  assert.equal(platformOf("https://www.instagram.com/reel/abc/"), "instagram");
  assert.equal(platformOf("https://youtu.be/xyz"), "youtube");
  assert.equal(platformOf("https://m.youtube.com/shorts/xyz"), "youtube");
  assert.equal(platformOf("https://fb.watch/abc/"), "facebook");
  // Lookalike hosts must not pass: yt-dlp fetches whatever passes here.
  assert.equal(platformOf("https://eviltiktok.com/x"), "other");
  assert.equal(platformOf("https://tiktok.com.evil.io/x"), "other");
  assert.equal(platformOf("https://notyoutube.com/x"), "other");
  assert.equal(platformOf("https://evilfacebook.com/x"), "other");
  assert.equal(platformOf("https://www.facebook.com/reel/1"), "facebook");
  assert.equal(platformOf("https://example.com/video"), "other");
  assert.equal(platformOf("not a url"), null);
});

test("embed html reduces to its readable caption", () => {
  const html =
    "<html><head><style>.x{}</style><script>var a=1;</script></head><body>" +
    "<div>Ingredients:<br>2 eggs<br>1 cup flour</div><p>Mix &amp; bake</p></body></html>";
  assert.equal(textFromHtml(html), "Ingredients:\n2 eggs\n1 cup flour\nMix & bake");
});

test("og tags are read whichever attribute order the page uses", () => {
  const html = '<meta property="og:description" content="Best pasta" /><meta name="description" content="x">';
  assert.equal(metaContent(html, "og:description"), "Best pasta");
  assert.equal(metaContent(html, "og:title"), null);
});

test("a recipe with nothing in it is not usable", () => {
  assert.equal(isUsableRecipe('{"title":"החשבון חסום","ingredients":[],"steps":[]}'), false);
  assert.equal(isUsableRecipe('{"title":"x","ingredients":[{"name":"egg"}],"steps":[]}'), true);
  assert.equal(isUsableRecipe("garbage"), false);
});

test("caption text names what it has and skips what it lacks", () => {
  assert.equal(captionText(null), "");
  assert.equal(captionText({ title: "T", description: null }), "כותרת: T");
  assert.match(captionText({ title: "T", description: "D" }), /כותרת: T\nתיאור: D/);
});

test("the slot comes back only when Google failed (5xx) or the network did, never on a 4xx", () => {
  const { refundable } = require("./socialRecipe").internals;
  assert.equal(refundable(Object.assign(new Error("x"), { status: 503 })), true);
  assert.equal(refundable(new Error("fetch failed")), true);
  assert.equal(refundable(Object.assign(new Error("x"), { status: 400 })), false);
  assert.equal(refundable(Object.assign(new Error("x"), { status: 404 })), false);
  assert.equal(refundable(Object.assign(new Error("x"), { status: 429 })), false);
  assert.equal(refundable(Object.assign(new Error("x"), { answered: true })), false);
});

const sr = require("./socialRecipe").internals;
const fsT = require("node:fs");
const osT = require("node:os");
const pathT = require("node:path");
const cryptoT = require("node:crypto");

function fakeResponse(status, bytes) {
  return {
    ok: status >= 200 && status < 300,
    status,
    headers: new Map([["content-length", String(bytes.length)]]),
    body: (async function* () { yield bytes; })(),
    arrayBuffer: async () => bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.length),
  };
}

test("yt-dlp is pinned to one release URL with a SHA-256", () => {
  assert.match(sr.YT_DLP_URL, /^https:\/\/github\.com\/yt-dlp\/yt-dlp\/releases\/download\/\d{4}\.\d{2}\.\d{2}\/yt-dlp$/);
  assert.match(sr.YT_DLP_SHA256, /^[0-9a-f]{64}$/);
  assert.ok(!sr.YT_DLP_URL.includes("latest"));
});

test("a yt-dlp download is installed only when its hash matches; a failure leaves nothing behind", async () => {
  const dir = fsT.mkdtempSync(pathT.join(osT.tmpdir(), "ytdlp-"));
  const target = pathT.join(dir, "yt-dlp");
  const good = Buffer.from("#!/usr/bin/env python3\nprint('ok')\n");
  const hash = cryptoT.createHash("sha256").update(good).digest("hex");

  await assert.rejects(sr.installYtDlp(target, { fetchImpl: async () => fakeResponse(404, Buffer.from("Not Found")), expected: hash }), /404/);
  assert.equal(fsT.existsSync(target), false);

  await assert.rejects(sr.installYtDlp(target, { fetchImpl: async () => fakeResponse(200, Buffer.from("evil")), expected: hash }), /checksum/);
  assert.equal(fsT.existsSync(target), false);
  assert.deepEqual(fsT.readdirSync(dir), []);

  await sr.installYtDlp(target, { fetchImpl: async () => fakeResponse(200, good), expected: hash });
  assert.ok(sr.fileMatches(target, hash));
  assert.ok(!sr.fileMatches(target, "0".repeat(64)));
  fsT.rmSync(dir, { recursive: true, force: true });
});

test("every step's time fits the function's limit", () => {
  assert.ok(sr.DEADLINE_MS < sr.FUNCTION_TIMEOUT_S * 1000);
  const now = 1_000_000;
  assert.equal(sr.stepBudget(now + 200_000, sr.MODEL_MS, now), sr.MODEL_MS);
  assert.equal(sr.stepBudget(now + 30_000, sr.MODEL_MS, now), 30_000);
  assert.equal(sr.stepBudget(now - 1, sr.MODEL_MS, now), sr.MIN_STEP_MS);
});

test("a timed-out model call is not refunded (Google most likely billed it)", async () => {
  const realFetch = global.fetch;
  global.fetch = (_u, opts) => new Promise((_, reject) => {
    opts.signal.addEventListener("abort", () => reject(opts.signal.reason));
  });
  process.env.GEMINI_API_KEY = process.env.GEMINI_API_KEY || "test";
  try {
    const err = await sr.callModel("gemini-x", {}, 10).then(() => null, (e) => e);
    assert.ok(err);
    assert.equal(sr.refundable(err), false);
  } finally {
    global.fetch = realFetch;
  }
  assert.equal(sr.refundable(Object.assign(new Error("x"), { status: 503 })), true);
});

test("an unreadable link refunds only while the probe budget lasts, and keeps the slot when it cannot be read", async () => {
  assert.equal(await sr.probeRefundAllowed("u", async ({ kind }) => ({ allowed: kind === "socialProbe" })), true);
  assert.equal(await sr.probeRefundAllowed("u", async () => ({ allowed: false })), false);
  assert.equal(await sr.probeRefundAllowed("u", async () => { throw new Error("down"); }), false);
});

test("a caller refusal keeps its own word: a disabled account is not told to verify a phone", () => {
  assert.equal(sr.refusalStatus({ status: 401, code: "unauthenticated" }), "UNAUTHENTICATED");
  assert.equal(sr.refusalStatus({ status: 403, code: "phone_required" }), "PHONE_REQUIRED");
  assert.equal(sr.refusalStatus({ status: 403, code: "account_disabled" }), "ACCOUNT_DISABLED");
});
