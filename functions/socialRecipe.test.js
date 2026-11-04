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
  assert.match(sr.YT_DLP_URL, /^https:\/\/github\.com\/yt-dlp\/yt-dlp\/releases\/download\/\d{4}\.\d{2}\.\d{2}\/yt-dlp_linux$/);
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
  assert.equal(sr.refusalStatus({ status: 503, code: "auth_unavailable" }), "UNAVAILABLE");
});

// ── The recipe's pictures ─────────────────────────────────────────────────

test("a YouTube id is read from every link shape the app accepts", () => {
  assert.equal(sr.youtubeId("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10"), "dQw4w9WgXcQ");
  assert.equal(sr.youtubeId("https://youtu.be/dQw4w9WgXcQ?si=abc"), "dQw4w9WgXcQ");
  assert.equal(sr.youtubeId("https://m.youtube.com/shorts/dQw4w9WgXcQ"), "dQw4w9WgXcQ");
  assert.equal(sr.youtubeId("https://www.youtube.com/embed/dQw4w9WgXcQ"), "dQw4w9WgXcQ");
  assert.equal(sr.youtubeId("https://www.youtube.com/@channel/videos"), null);
  assert.equal(sr.youtubeId("https://www.tiktok.com/@a/video/1"), null);
  assert.equal(sr.youtubeId("garbage"), null);
  assert.deepEqual(sr.youtubeThumbnails("dQw4w9WgXcQ"), [
    "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
    "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
  ]);
});

test("the cover is yt-dlp's pick, else the preferred / largest thumbnail, never a non-http one", () => {
  assert.equal(sr.coverFromProbe(null), null);
  assert.equal(sr.coverFromProbe({ thumbnail: "https://p16.tiktokcdn.com/c.jpeg" }), "https://p16.tiktokcdn.com/c.jpeg");
  assert.equal(
    sr.coverFromProbe({
      thumbnails: [
        { url: "https://x/a.jpg", width: 100, height: 100, preference: -1 },
        { url: "https://x/b.jpg", width: 1000, height: 1000, preference: -1 },
        { url: "file:///etc/passwd", width: 5000, height: 5000, preference: 9 },
      ],
    }),
    "https://x/b.jpg",
  );
  assert.equal(
    sr.coverFromProbe({ thumbnails: [{ url: "https://x/small.jpg", width: 10, height: 10, preference: 1 }, { url: "https://x/big.jpg", width: 999, height: 999, preference: 0 }] }),
    "https://x/small.jpg",
  );
  assert.equal(sr.coverFromProbe({ thumbnail: 42, thumbnails: "no" }), null);
});

test("the Instagram embed picture is found whichever way the tag is written", () => {
  assert.equal(
    sr.instagramEmbedImage('<div><img class="EmbeddedMediaImage" src="https://scontent.cdninstagram.com/a.jpg?x=1&amp;y=2"></div>'),
    "https://scontent.cdninstagram.com/a.jpg?x=1&y=2",
  );
  assert.equal(
    sr.instagramEmbedImage("<img src='https://i/b.jpg' alt='' class='EmbeddedMediaImage' />"),
    "https://i/b.jpg",
  );
  assert.equal(sr.instagramEmbedImage('<img src="https://i/avatar.jpg" class="Avatar">'), null);
});

test("the frame field is added to the caller's schema and taken out of the answer", () => {
  const schema = { type: "object", properties: { title: { type: "string" } }, required: ["title"] };
  const wide = sr.withFrameField(schema);
  assert.deepEqual(Object.keys(wide.properties), ["title", sr.FRAME_FIELD]);
  assert.deepEqual(wide.required, ["title"]);
  assert.deepEqual(schema.properties, { title: { type: "string" } }, "the caller's object is not touched");
  assert.equal(sr.withFrameField(null), null);

  const answer = `{"title":"x","ingredients":[],"steps":["a"],"${sr.FRAME_FIELD}":[1,2]}`;
  assert.deepEqual(JSON.parse(sr.stripFrameField(answer)), { title: "x", ingredients: [], steps: ["a"] });
  assert.equal(sr.stripFrameField('{"title":"x"}'), '{"title":"x"}');
  assert.equal(sr.stripFrameField("not json"), "not json");
  assert.equal(sr.isUsableRecipe(answer), true, "the extra field does not confuse the usability check");
});

test("moments come from the model's list, inside the video, a second apart, at most five", () => {
  const F = sr.FRAME_FIELD;
  assert.deepEqual(sr.frameTimes(`{"${F}":[12.04, 12.5, 3, "1:05", 99, -1, "x", 40, 41.5, 50, 60]}`, 70), [12, 3, 65, 40, 41.5]);
  // A plain string of seconds, and hours:minutes:seconds.
  assert.deepEqual(sr.frameTimes(`{"${F}":["7", "0:01:30"]}`, 100), [7, 90]);
  // Nothing listed, length known: evenly through the video.
  assert.deepEqual(sr.frameTimes(`{"${F}":[]}`, 60), [10, 20, 30, 40, 50]);
  assert.deepEqual(sr.frameTimes('{"title":"x"}', 12), [2, 4, 6, 8, 10]);
  // Nothing listed and no length: nothing to cut.
  assert.deepEqual(sr.frameTimes('{"title":"x"}', null), []);
  assert.deepEqual(sr.frameTimes("garbage", 0), []);
  // No length but a list: every non-negative moment is trusted.
  assert.deepEqual(sr.frameTimes(`{"${F}":[5, 500]}`, null), [5, 500]);
});

test("pictures are trimmed to the envelope's budget, an oversized one skipped rather than ending the list", () => {
  const big = { kind: "cover", jpeg: "x".repeat(700) };
  const a = { kind: "frame", jpeg: "a".repeat(300) };
  const b = { kind: "frame", jpeg: "b".repeat(300) };
  const c = { kind: "frame", jpeg: "c".repeat(300) };
  assert.deepEqual(sr.fitImages([big, a, b, c], 650), [a, b]);
  assert.deepEqual(sr.fitImages([a, big], 900), [a]);
  assert.deepEqual(sr.fitImages([a, big], 1000), [a, big], "exactly the budget still fits");
  assert.deepEqual(sr.fitImages([{ kind: "frame" }], 1000), []);
  assert.deepEqual(sr.fitImages([], 10), []);
});

// The width and height a JPEG declares in its frame header.
function jpegSize(buf) {
  let i = 2;
  while (i < buf.length) {
    if (buf[i] !== 0xff) {
      i++;
      continue;
    }
    const marker = buf[i + 1];
    if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) {
      return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
    }
    i += 2 + buf.readUInt16BE(i + 2);
  }
  return null;
}

const { execFileSync } = require("node:child_process");

test("ffmpeg cuts stills at the moments asked, sized for a card, and resizes a cover", async () => {
  await sr.withScratch(async (dir) => {
    const mp4 = pathT.join(dir, "src.mp4");
    execFileSync(sr.ffmpegPath, [
      "-hide_banner", "-loglevel", "error", "-y",
      "-f", "lavfi", "-i", "testsrc=duration=3:size=1280x720:rate=10", "-pix_fmt", "yuv420p", mp4,
    ]);
    const video = fsT.readFileSync(mp4);
    const frames = await sr.extractFrames(video, [0.5, 1.5, 2.5], dir, Date.now() + 60000);
    assert.equal(frames.length, 3);
    for (const [i, frame] of frames.entries()) {
      assert.equal(frame.kind, "frame");
      assert.equal(frame.at, [0.5, 1.5, 2.5][i]);
      const jpeg = Buffer.from(frame.jpeg, "base64");
      assert.deepEqual([jpeg[0], jpeg[1]], [0xff, 0xd8], "a JPEG");
      // 1280x720 into a 720 box: 720x405, rounded to an even height.
      const size = jpegSize(jpeg);
      assert.equal(size.width, 720);
      assert.ok(size.height === 404 || size.height === 406, `height ${size.height}`);
    }
    // A moment past the end is not an error (ffmpeg hands over its last
    // frame or nothing); frameTimes keeps moments inside the video anyway.
    assert.ok((await sr.extractFrames(video, [100], dir, Date.now() + 60000)).length <= 1);

    const png = pathT.join(dir, "cover.png");
    execFileSync(sr.ffmpegPath, ["-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=red:s=2000x1000", "-frames:v", "1", png]);
    const cover = await sr.toJpeg(fsT.readFileSync(png), 1024, dir, "cover");
    assert.deepEqual(jpegSize(cover), { width: 1024, height: 512 });
    // Never upscaled.
    const small = await sr.toJpeg(cover, 4096, dir, "again");
    assert.deepEqual(jpegSize(small), { width: 1024, height: 512 });
  });
});

test("collectImages puts the cover first, then the stills the model asked for, and never throws", async () => {
  const dir = fsT.mkdtempSync(pathT.join(osT.tmpdir(), "social-test-"));
  try {
    const mp4 = pathT.join(dir, "src.mp4");
    execFileSync(sr.ffmpegPath, [
      "-hide_banner", "-loglevel", "error", "-y",
      "-f", "lavfi", "-i", "testsrc=duration=3:size=640x360:rate=10", "-pix_fmt", "yuv420p", mp4,
    ]);
    const png = pathT.join(dir, "cover.png");
    execFileSync(sr.ffmpegPath, ["-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=blue:s=300x200", "-frames:v", "1", png]);
    const video = fsT.readFileSync(mp4);
    const coverBytes = fsT.readFileSync(png);
    const deadline = Date.now() + 60000;

    const both = await sr.collectImages({
      cover: Promise.resolve(coverBytes),
      video,
      answer: `{"title":"x","${sr.FRAME_FIELD}":[0.5, 2]}`,
      durationSec: 3,
      deadline,
    });
    assert.deepEqual(both.map((i) => i.kind), ["cover", "frame", "frame"]);
    assert.deepEqual(both.slice(1).map((i) => i.at), [0.5, 2]);

    const coverOnly = await sr.collectImages({ cover: Promise.resolve(coverBytes), video: null, answer: "{}", durationSec: null, deadline });
    assert.deepEqual(coverOnly.map((i) => i.kind), ["cover"]);

    // No cover, no video: nothing, quietly.
    assert.deepEqual(await sr.collectImages({ cover: Promise.resolve(null), video: null, answer: "{}", durationSec: null, deadline }), []);
    // A cover that is not a picture at all is dropped, not thrown.
    assert.deepEqual(await sr.collectImages({ cover: Promise.resolve(Buffer.from("not an image")), video: null, answer: "{}", durationSec: null, deadline }), []);
    // Out of time: the cover is still handed over when it is in hand, the stills are not cut.
    const late = await sr.collectImages({ cover: Promise.resolve(coverBytes), video, answer: `{"${sr.FRAME_FIELD}":[1]}`, durationSec: 3, deadline: Date.now() + 1000 });
    assert.deepEqual(late.map((i) => i.kind), ["cover"]);
  } finally {
    fsT.rmSync(dir, { recursive: true, force: true });
  }
});

test("the caption fallback's shape carries a thumbnail slot the handler reads", () => {
  // captionText ignores it; only the cover fetch reads it.
  assert.equal(sr.captionText({ title: "T", description: null, thumbnail: "https://x/t.jpg" }), "כותרת: T");
});

test("a downloaded 'video' that is an HLS playlist is not opened: no local file reaches a still", async () => {
  await sr.withScratch(async (dir) => {
    // The secret ffmpeg would read through the playlist: a real clip, so an
    // unguarded run cuts a still from it.
    const secret = pathT.join(dir, "secret.ts");
    execFileSync(sr.ffmpegPath, [
      "-hide_banner", "-loglevel", "error", "-y",
      "-f", "lavfi", "-i", "testsrc=duration=2:size=64x64:rate=10", "-c:v", "mpeg2video", "-f", "mpegts", secret,
    ]);
    const playlist = Buffer.from(`#EXTM3U\n#EXT-X-MEDIA-SEQUENCE:0\n#EXTINF:2.0,\nfile://${secret}\n#EXT-X-ENDLIST\n`);
    assert.equal(sr.videoDemuxer(playlist), null);
    assert.deepEqual(await sr.extractFrames(playlist, [0.5], dir, Date.now() + 60000), []);
    // Even with its reader forced the playlist is refused (ffmpeg reads it as mp4 and fails).
    await assert.rejects(
      execFileAsyncT(sr.ffmpegPath, ["-hide_banner", "-loglevel", "error", "-y",
        ...sr.inputArgs("mov", writeT(dir, "p.mp4", playlist), sr.MAX_VIDEO_PIXELS), "-frames:v", "1", pathT.join(dir, "p.jpg")]),
    );
    // A cover that only claims to be a picture never reaches ffmpeg.
    await assert.rejects(sr.toJpeg(playlist, 1024, dir, "cover"), /not a picture/);
  });
});

test("videoDemuxer names the reader from the container's magic", () => {
  const box = (type) => Buffer.concat([Buffer.from([0, 0, 0, 0x20]), Buffer.from(type, "latin1"), Buffer.alloc(8)]);
  assert.equal(sr.videoDemuxer(box("ftyp")), "mov");
  assert.equal(sr.videoDemuxer(box("moov")), "mov");
  assert.equal(sr.videoDemuxer(Buffer.concat([Buffer.from([0x1a, 0x45, 0xdf, 0xa3]), Buffer.alloc(12)])), "matroska");
  assert.equal(sr.videoDemuxer(Buffer.from("<?xml version='1.0'?><MPD>")), null, "DASH manifest");
  assert.equal(sr.videoDemuxer(Buffer.from("ffconcat version 1.0\nfile /etc/passwd")), null);
  assert.equal(sr.videoDemuxer(Buffer.alloc(4)), null);
  assert.equal(sr.videoDemuxer(null), null);
});

const execFileAsyncT = require("node:util").promisify(require("node:child_process").execFile);
function writeT(dir, name, bytes) {
  const file = pathT.join(dir, name);
  fsT.writeFileSync(file, bytes);
  return file;
}

test("a cover that decodes to a huge bitmap is refused before ffmpeg allocates it", async () => {
  await sr.withScratch(async (dir) => {
    // 12000x12000 is a few hundred KB as a flat PNG and ~540 MB decoded.
    const png = pathT.join(dir, "bomb.png");
    execFileSync(sr.ffmpegPath, ["-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "color=c=red:s=12000x12000", "-frames:v", "1", png]);
    const bomb = fsT.readFileSync(png);
    assert.ok(12000 * 12000 > sr.MAX_COVER_PIXELS);
    await assert.rejects(sr.toJpeg(bomb, 1024, dir, "cover"));
    // collectImages drops it (not a small JPEG to pass on as fetched) and does not throw.
    assert.deepEqual(await sr.collectImages({ cover: Promise.resolve(bomb), video: null, answer: "{}", durationSec: null, deadline: Date.now() + 60000 }), []);
  });
});

test("fetchFirstCover skips inside addresses, failures and non-pictures, and never throws", async () => {
  const jpeg = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(32)]);
  const asked = [];
  const realFetch = global.fetch;
  global.fetch = async (url) => {
    asked.push(url);
    if (url.includes("/missing")) return new Response("no", { status: 404 });
    if (url.includes("/html")) return new Response("<html>not a picture</html>", { status: 200 });
    if (url.includes("/boom")) throw new Error("socket hang up");
    if (url.includes("/hop")) return new Response(null, { status: 302, headers: { location: "http://169.254.169.254/computeMetadata/v1/" } });
    return new Response(jpeg, { status: 200, headers: { "content-type": "image/jpeg" } });
  };
  try {
    const got = await sr.fetchFirstCover([
      "http://169.254.169.254/latest/meta-data",
      "http://127.0.0.1/x.jpg",
      "file:///etc/passwd",
      "https://93.184.216.34/hop",
      "https://93.184.216.34/missing",
      "https://93.184.216.34/html",
      "https://93.184.216.34/boom",
      "https://93.184.216.34/cover.jpg",
    ], {}, Date.now() + 60000);
    assert.deepEqual(got, jpeg);
    // The inside addresses were refused before any request; the redirect into
    // the metadata server was not followed.
    assert.ok(!asked.some((u) => /169\.254|127\.0\.0\.1|^file:/.test(u)), asked.join(" "));
    assert.equal(await sr.fetchFirstCover(["https://93.184.216.34/missing", "https://93.184.216.34/html"], {}, Date.now() + 60000), null);
    // Out of time: nothing is fetched.
    asked.length = 0;
    assert.equal(await sr.fetchFirstCover(["https://93.184.216.34/cover.jpg"], {}, Date.now() + 1000), null);
    assert.equal(asked.length, 0);
  } finally {
    global.fetch = realFetch;
  }
});

test("a platform's outbound redirector is not a post: refused before yt-dlp follows it anywhere", () => {
  for (const url of [
    "https://l.facebook.com/l.php?u=https%3A%2F%2Fevil.example%2Fx.mp4",
    "https://lm.facebook.com/l.php?u=https%3A%2F%2Fevil.example%2F",
    "https://www.facebook.com/l.php?u=https%3A%2F%2Fevil.example%2F",
    "https://m.facebook.com/flx/warn/?u=https%3A%2F%2Fevil.example%2F",
    "https://l.instagram.com/?u=https%3A%2F%2Fevil.example%2F",
    "https://www.tiktok.com/link/v2?target=https%3A%2F%2Fevil.example",
    "https://www.youtube.com/redirect?q=https%3A%2F%2Fevil.example",
  ]) {
    assert.equal(sr.isLinkShim(url), true, url);
  }
  // Real posts pass, whichever host form the share sheet gives.
  for (const url of [
    "https://www.facebook.com/share/r/1AbCdEf/",
    "https://www.facebook.com/reel/123456789",
    "https://fb.watch/abc/",
    "https://www.instagram.com/reel/abc/",
    "https://www.tiktok.com/@cook/video/123",
    "https://vm.tiktok.com/ZM1/",
    "https://youtu.be/dQw4w9WgXcQ",
    "https://www.youtube.com/shorts/dQw4w9WgXcQ",
    "https://www.facebook.com/lasagna.page/videos/1",
  ]) {
    assert.equal(sr.isLinkShim(url), false, url);
  }
  assert.equal(sr.isLinkShim("not a url"), false);
});

test("a post wrapped in a redirector is read as the post; a redirector to anywhere else stays refused", () => {
  const inner = "https://www.tiktok.com/@cook/video/123";
  assert.equal(sr.unwrapLinkShim(`https://l.facebook.com/l.php?u=${encodeURIComponent(inner)}&h=AT0x`), inner);
  assert.equal(sr.unwrapLinkShim(`https://l.instagram.com/?u=${encodeURIComponent("https://www.instagram.com/reel/abc/")}`), "https://www.instagram.com/reel/abc/");
  for (const url of [
    "https://l.facebook.com/l.php?u=https%3A%2F%2Fevil.example%2Fx.mp4",
    // http, a lookalike, a shim inside a shim: not unwrapped.
    `https://l.facebook.com/l.php?u=${encodeURIComponent("http://www.tiktok.com/@a/video/1")}`,
    `https://l.facebook.com/l.php?u=${encodeURIComponent("https://eviltiktok.com/x")}`,
    `https://l.facebook.com/l.php?u=${encodeURIComponent("https://l.facebook.com/l.php?u=https%3A%2F%2Fevil.example")}`,
  ]) {
    const out = sr.unwrapLinkShim(url);
    assert.equal(out, url, url);
    assert.equal(sr.isLinkShim(out), true, "still refused");
  }
  // Not a redirector: unchanged.
  assert.equal(sr.unwrapLinkShim(inner), inner);
});

test("the handler refuses a redirector before any cache read or fetch, and reads a wrapped post as the post", async () => {
  const proxyInternals = require("./aiProxy").internals;
  const saved = {};
  const stub = (name, fn) => {
    saved[name] = proxyInternals[name];
    proxyInternals[name] = fn;
  };
  const reads = [];
  stub("verifyPaidCaller", async () => ({ caller: { uid: "u1", phone_number: "+972500000000" }, refusal: null }));
  stub("readCache", async (entry) => {
    reads.push(entry);
    return { body: '{"cached":true}' };
  });
  stub("cacheHitRefusal", async () => null);
  stub("countHit", () => {});
  // The console's limits, without reaching Remote Config.
  stub("sizeLimits", async () => proxyInternals.sizeLimitsFrom({}));
  const call = async (body) => {
    const res = {
      statusCode: 0,
      sent: null,
      status(code) { this.statusCode = code; return this; },
      json(b) { this.sent = b; return this; },
      send(b) { this.sent = b; return this; },
      set() { return this; },
      setHeader() {},
      getHeader() {},
      on() {},
      end() {},
    };
    const req = { method: "POST", headers: { authorization: "Bearer t" }, get(n) { return this.headers[n.toLowerCase()]; }, body };
    await require("./socialRecipe").socialRecipe(req, res);
    return res;
  };
  const base = { model: "gemini-3.8-flash", prompt: "p", schema: { type: "object" } };
  try {
    for (const url of [
      "https://l.facebook.com/l.php?u=https%3A%2F%2Fevil.example%2Fx.mp4",
      "https://www.youtube.com/redirect?q=https%3A%2F%2Fevil.example",
      "https://evil.example/video.mp4",
    ]) {
      const res = await call({ ...base, url });
      assert.equal(res.statusCode, 400, url);
      assert.equal(res.sent.error.status, "BAD_REQUEST");
    }
    assert.equal((await call({ ...base, url: "https://www.tiktok.com/@a/video/1", model: "../files" })).statusCode, 400);
    assert.equal(reads.length, 0, "nothing was read or fetched for a refused link");

    const inner = "https://www.tiktok.com/@cook/video/123";
    const res = await call({ ...base, url: `https://l.facebook.com/l.php?u=${encodeURIComponent(inner)}` });
    assert.equal(res.statusCode, 200);
    assert.equal(reads.length, 1);
    assert.equal(reads[0].url, inner, "the cache (and yt-dlp) see the post, not the redirector");

    // A prompt or schema past aiProxy's limits: refused before the cache,
    // the quota or any fetch.
    const link = "https://www.tiktok.com/@cook/video/456";
    const longPrompt = await call({ ...base, url: link, prompt: "x".repeat(proxyInternals.MAX_PROMPT_CHARS + 1) });
    assert.equal(longPrompt.statusCode, 413);
    assert.equal(longPrompt.sent.error.status, "TOO_LARGE");
    const bigSchema = { type: "object", description: "y".repeat(proxyInternals.MAX_SCHEMA_CHARS) };
    assert.equal((await call({ ...base, url: link, schema: bigSchema })).statusCode, 413);
    assert.equal(reads.length, 1, "nothing was read for an oversized request");
  } finally {
    Object.assign(proxyInternals, saved);
  }
});

test("yt-dlp and ffmpeg run without the Gemini key in their environment", async () => {
  const env = sr.childEnv({ PATH: "/usr/bin", GEMINI_API_KEY: "AIza-secret", HOME: "/tmp" });
  assert.deepEqual(env, { PATH: "/usr/bin", HOME: "/tmp" });
  await sr.withScratch(async (dir) => {
    // A stand-in binary that writes down the environment it was given.
    const dump = pathT.join(dir, "env.txt");
    const fake = writeT(dir, "fake-ffmpeg", Buffer.from(`#!/bin/sh\nenv > "${dump}"\n`));
    fsT.chmodSync(fake, 0o755);
    const before = process.env.GEMINI_API_KEY;
    process.env.GEMINI_API_KEY = "AIza-must-not-leak";
    try {
      // Its own hash pinned: only a binary that matches is run.
      await sr.runFfmpeg([], 5000, fake, await sr.hashFile(fake));
    } finally {
      if (before === undefined) delete process.env.GEMINI_API_KEY;
      else process.env.GEMINI_API_KEY = before;
    }
    const seen = fsT.readFileSync(dump, "utf8");
    assert.ok(!seen.includes("AIza-must-not-leak"), "the key reached the child");
    assert.ok(/^PATH=/m.test(seen), "the rest of the environment is kept");
  });
});

test("ffmpeg runs only when the binary matches its pinned SHA-256", async () => {
  // The package that fetched it is the one the hashes were taken from.
  const pkg = require("ffmpeg-static/package.json");
  assert.equal(pkg.version, "5.2.0");
  assert.equal(pkg["ffmpeg-static"]["binary-release-tag"], "b6.0");
  assert.equal(require("./package.json").dependencies["ffmpeg-static"], "5.2.0", "pinned exactly, not a range");
  // Cloud Functions' platform has a hash; this machine's binary passes.
  assert.match(sr.FFMPEG_SHA256["linux-x64"], /^[0-9a-f]{64}$/);
  if (sr.FFMPEG_EXPECTED) {
    assert.equal(await sr.hashFile(sr.ffmpegPath), sr.FFMPEG_EXPECTED);
    assert.equal(await sr.ffmpegTrusted(), true);
  }
  await sr.withScratch(async (dir) => {
    // A stand-in that leaves a mark if it is ever run.
    const mark = pathT.join(dir, "ran.txt");
    const fake = writeT(dir, "fake-ffmpeg", Buffer.from(`#!/bin/sh\ntouch "${mark}"\n`));
    fsT.chmodSync(fake, 0o755);
    const wrong = "0".repeat(64);
    assert.equal(await sr.ffmpegTrusted(fake, wrong), false);
    await assert.rejects(sr.runFfmpeg([], 5000, fake, wrong), /checksum/);
    // No pinned hash for the platform: refused too.
    await assert.rejects(sr.runFfmpeg([], 5000, fake, null), /checksum/);
    // The stills come back empty (the recipe goes on without them), and the
    // video is not even copied to /tmp.
    const mp4 = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from("ftypmp42"), Buffer.alloc(16)]);
    assert.deepEqual(await sr.extractFrames(mp4, [0.5, 1], dir, Date.now() + 60000, fake, wrong), []);
    assert.ok(!fsT.existsSync(pathT.join(dir, "video.mp4")));
    assert.ok(!fsT.existsSync(mark), "a binary that failed its checksum was run");
  });
});

test("only a TikTok probe carries the desktop user agent", () => {
  const { probeExtraArgs } = require("./socialRecipe").internals;
  const args = probeExtraArgs("https://vt.tiktok.com/ZSpRYDYmv/");
  assert.equal(args[0], "--user-agent");
  assert.match(args[1], /Windows NT/);
  assert.deepEqual(probeExtraArgs("https://www.instagram.com/reel/abc/"), []);
  assert.deepEqual(probeExtraArgs("https://youtu.be/abc"), []);
});

test("yt-dlp's cookies field becomes the media fetch's Cookie header", () => {
  const { cookieHeader, withCookies } = require("./socialRecipe").internals;
  const raw =
    "tt_chain_token=abc; Domain=.tiktok.com; Path=/; Secure; Expires=1793000000; " +
    "ttwid=x=y; Domain=.tiktok.com; Path=/; HttpOnly";
  assert.equal(cookieHeader(raw), "tt_chain_token=abc; ttwid=x=y");
  assert.equal(cookieHeader(undefined), "");
  assert.deepEqual(withCookies({ Referer: "r" }, raw), { Referer: "r", Cookie: "tt_chain_token=abc; ttwid=x=y" });
  // A Cookie yt-dlp already put in the headers is left alone.
  assert.deepEqual(withCookies({ cookie: "a=1" }, raw), { cookie: "a=1" });
  assert.deepEqual(withCookies({}, null), {});
});
