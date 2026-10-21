const test = require("node:test");
const assert = require("node:assert/strict");
const { parseRequest, parseResults, cacheId, searchBody, pageFor, configured, search, MAX_START } = require("./imageSearch").internals;

test("the request is normalised: whitespace folded, start clamped, language trimmed", () => {
  assert.deepEqual(parseRequest({ query: "  קובה   סלק ", start: 11, lang: "HE" }), { query: "קובה סלק", start: 11, lang: "he" });
  assert.deepEqual(parseRequest({ query: "pizza" }), { query: "pizza", start: 1, lang: "" });
  assert.deepEqual(parseRequest({ query: "pizza", start: "21" }), { query: "pizza", start: 21, lang: "" });
  assert.deepEqual(parseRequest({ query: "pizza", start: -4 }), { query: "pizza", start: 1, lang: "" });
  assert.equal(parseRequest({ query: "   " }).error, "empty_query");
  assert.equal(parseRequest(null).error, "empty_query");
  assert.equal(parseRequest({ query: "pizza", start: MAX_START + 10 }).error, "end_of_results");
});

const tenImages = () => Array.from({ length: 10 }, (_, i) => ({ imageUrl: `https://x/${i}.jpg` }));

test("results keep only http links and report where the next page begins", () => {
  const json = {
    images: [
      { imageUrl: "https://a.example/1.jpg", thumbnailUrl: "https://t/1", imageWidth: 800, imageHeight: 600, title: "one", domain: "a.example", source: "A" },
      { imageUrl: "ftp://bad/2.jpg", title: "two" },
      { imageUrl: "https://a.example/3.png", source: "A" },
      ...tenImages().slice(0, 8),
    ],
  };
  const page = parseResults(json, 1);
  assert.equal(page.items.length, 10);
  assert.deepEqual(page.items[0], { url: "https://a.example/1.jpg", thumbnail: "https://t/1", width: 800, height: 600, title: "one", source: "a.example", mime: "" });
  // No thumbnail: the picture itself stands in; no domain: the source name.
  assert.equal(page.items[1].thumbnail, "https://a.example/3.png");
  assert.equal(page.items[1].width, null);
  assert.equal(page.items[1].source, "A");
  assert.equal(page.nextStart, 11);
  assert.equal(page.start, 1);
});

test("a short page is the last one, so is the page at the cap, and so is an empty one", () => {
  assert.equal(parseResults({ images: tenImages().slice(0, 4) }, 1).nextStart, null);
  assert.equal(parseResults({ images: tenImages() }, 81).nextStart, 91);
  assert.equal(parseResults({ images: tenImages() }, 91).nextStart, null);
  assert.equal(parseResults({ images: [] }, 1).nextStart, null);
  assert.deepEqual(parseResults({}, 1).items, []);
});

test("start maps onto Serper's pages of ten", () => {
  assert.equal(pageFor(1), 1);
  assert.equal(pageFor(10), 1);
  assert.equal(pageFor(11), 2);
  assert.equal(pageFor(91), 10);
});

test("the cache key ignores case but not the page or language", () => {
  const a = cacheId({ query: "Pizza", start: 1, lang: "he" });
  assert.equal(a, cacheId({ query: "pizza", start: 1, lang: "he" }));
  assert.notEqual(a, cacheId({ query: "pizza", start: 11, lang: "he" }));
  assert.notEqual(a, cacheId({ query: "pizza", start: 1, lang: "en" }));
});

test("the request asks for ten safe results on the right page, in the UI's language when it can", () => {
  assert.deepEqual(searchBody({ query: "קובה סלק", start: 11, lang: "he" }), { q: "קובה סלק", num: 10, page: 2, safe: "active", hl: "he" });
  assert.deepEqual(searchBody({ query: "x", start: 1, lang: "" }), { q: "x", num: 10, page: 1, safe: "active" });
});

test("a placeholder secret counts as not configured", () => {
  assert.equal(configured("unset"), false);
  assert.equal(configured(""), false);
  assert.equal(configured("key"), true);
});

function fakeDb(store = new Map()) {
  return {
    store,
    collection: () => ({
      doc: (id) => ({
        get: async () => ({ exists: store.has(id), data: () => store.get(id) }),
        set: async (data) => store.set(id, data),
      }),
    }),
  };
}

test("a search is served from the cache the second time, and the upstream is asked once", async () => {
  let calls = 0;
  const fetchImpl = async () => {
    calls++;
    return { ok: true, status: 200, text: async () => JSON.stringify({ images: [{ imageUrl: "https://x/1.jpg" }] }) };
  };
  const db = fakeDb();
  const request = { query: "pizza", start: 1, lang: "en" };
  const first = await search(request, { key: "k", fetchImpl, db, now: 1000 });
  assert.equal(first.items.length, 1);
  assert.equal(first.cached, undefined);
  const second = await search(request, { key: "k", fetchImpl, db, now: 2000 });
  assert.equal(second.cached, true);
  assert.equal(second.items[0].url, "https://x/1.jpg");
  assert.equal(calls, 1);
});

test("the cache-miss hook runs only before an upstream call, and its refusal stops the search", async () => {
  let calls = 0;
  let misses = 0;
  const fetchImpl = async () => {
    calls++;
    return { ok: true, status: 200, text: async () => JSON.stringify({ images: [{ imageUrl: "https://x/1.jpg" }] }) };
  };
  const db = fakeDb();
  const request = { query: "pizza", start: 1, lang: "en" };
  const onMiss = async () => { misses++; };
  await search(request, { key: "k", fetchImpl, db, now: 1000, onMiss });
  await search(request, { key: "k", fetchImpl, db, now: 2000, onMiss });
  assert.equal(misses, 1, "a cached page spends nothing");
  assert.equal(calls, 1);
  const refused = Object.assign(new Error("budget"), { status: 429, body: { error: { code: "quota" } } });
  await assert.rejects(
    search({ ...request, query: "sushi" }, { key: "k", fetchImpl, db, now: 3000, onMiss: async () => { throw refused; } }),
    (err) => err === refused,
  );
  assert.equal(calls, 1, "a refused search never reaches Serper");
});

test("a stale cache entry is refetched", async () => {
  let calls = 0;
  const fetchImpl = async () => {
    calls++;
    return { ok: true, status: 200, text: async () => JSON.stringify({ images: [{ imageUrl: "https://x/2.jpg" }] }) };
  };
  const request = { query: "pizza", start: 1, lang: "en" };
  const db = fakeDb(new Map([[cacheId(request), { page: { items: [{ url: "old" }], nextStart: null }, cachedAt: { toMillis: () => 0 } }]]));
  const page = await search(request, { key: "k", fetchImpl, db, now: 8 * 24 * 60 * 60 * 1000 });
  assert.equal(page.items[0].url, "https://x/2.jpg");
  assert.equal(calls, 1);
});

test("spent credits surface as 429, any other refusal as 502, and the key goes in the header", async () => {
  let seen;
  const refused = (status, message) => async (url, init) => {
    seen = { url, init };
    return { ok: false, status, text: async () => JSON.stringify({ message }) };
  };
  const request = { query: "pizza", start: 1, lang: "" };
  await assert.rejects(
    search(request, { key: "k", fetchImpl: refused(400, "Not enough credits"), db: fakeDb() }),
    (err) => err.status === 429 && err.code === "quota" && err.refundable === true,
  );
  await assert.rejects(
    search(request, { key: "k", fetchImpl: refused(403, "Unauthorized"), db: fakeDb() }),
    (err) => err.status === 502 && err.code === "upstream" && err.refundable === true,
  );
  await assert.rejects(
    search(request, { key: "k", fetchImpl: refused(402, "Payment required"), db: fakeDb() }),
    (err) => err.refundable === true,
  );
  await assert.rejects(
    search(request, { key: "k", fetchImpl: refused(400, "Bad query"), db: fakeDb() }),
    (err) => err.status === 502 && !err.refundable,
  );
  assert.equal(seen.url, "https://google.serper.dev/images");
  assert.equal(seen.init.method, "POST");
  assert.equal(seen.init.headers["X-API-KEY"], "k");
  assert.equal(JSON.parse(seen.init.body).q, "pizza");
});

// ---------------------------------------------------------------------------
// action "download"
// ---------------------------------------------------------------------------
const { parseDownload, acceptImageType, looksLikeMarkup, download, DOWNLOAD_STATUS, MAX_DOWNLOAD_URL_LENGTH } = require("./imageSearch").internals;

test("download: only an http(s) URL without credentials passes the syntax check", () => {
  assert.deepEqual(parseDownload({ action: "download", url: "  https://a.example/x.jpg " }), { url: "https://a.example/x.jpg" });
  assert.deepEqual(parseDownload({ url: "http://a.example/x.jpg?w=1" }), { url: "http://a.example/x.jpg?w=1" });
  for (const bad of [undefined, "", "   ", "not a url", "ftp://a.example/x.jpg", "file:///etc/passwd", "javascript:alert(1)", "data:image/png;base64,AAAA", "https://u:p@a.example/x.jpg", 42]) {
    assert.equal(parseDownload({ url: bad }).error, "invalid_url", String(bad));
  }
  assert.equal(parseDownload(null).error, "invalid_url");
  assert.equal(parseDownload({ url: `https://a.example/${"x".repeat(MAX_DOWNLOAD_URL_LENGTH)}` }).error, "invalid_url");
});

test("download: raster image types pass, SVG / XML / non-images do not", () => {
  assert.equal(acceptImageType("image/jpeg"), "image/jpeg");
  assert.equal(acceptImageType("IMAGE/PNG; charset=binary"), "image/png");
  assert.equal(acceptImageType("image/webp"), "image/webp");
  for (const bad of ["image/svg+xml", "image/svg", "image/x-xml", "text/html", "application/octet-stream", "", null, "image/"]) {
    assert.equal(acceptImageType(bad), null, String(bad));
  }
  assert.equal(looksLikeMarkup(Buffer.from("  <svg xmlns='http://www.w3.org/2000/svg'/>")), true);
  assert.equal(looksLikeMarkup(Buffer.from("﻿<html>")), true);
  assert.equal(looksLikeMarkup(Buffer.from([0xff, 0xd8, 0xff, 0xe0])), false);
});

test("download: stable error codes map to fixed statuses", () => {
  assert.deepEqual(DOWNLOAD_STATUS, { invalid_url: 400, blocked_address: 400, not_image: 415, too_large: 413, fetch_failed: 502 });
});

const publicLookup = async () => [{ address: "93.184.216.34", family: 4 }];
const reply = (status, headers = {}, body = Buffer.alloc(0)) => ({
  status, ok: status >= 200 && status < 300, headers: new Headers(headers), arrayBuffer: async () => body,
});
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0x10, 0x4a, 0x46, 0x49, 0x46, 0, 1, 2, 3]);

test("download: a picture comes back as base64 with its type", async () => {
  const seen = [];
  const fetchImpl = async (url, options) => {
    seen.push(options);
    return reply(200, { "content-type": "image/jpeg" }, jpeg);
  };
  const image = await download("https://images.example/a.jpg", { fetchImpl, lookup: publicLookup });
  assert.deepEqual(image, { contentType: "image/jpeg", dataBase64: jpeg.toString("base64"), size: jpeg.length });
  assert.equal(seen[0].redirect, "manual");
  assert.match(seen[0].headers["User-Agent"], /EasyPlate\/1\.0/);
});

test("download: each refusal carries its stable reason", async () => {
  const reason = (p) => p.then(() => "resolved", (e) => e.reason);
  const ok = async () => reply(200, { "content-type": "image/jpeg" }, jpeg);
  // the metadata server, loopback, internal names, a host resolving inside
  assert.equal(await reason(download("http://169.254.169.254/computeMetadata/v1/", { fetchImpl: ok })), "blocked_address");
  assert.equal(await reason(download("http://[::1]/x.png", { fetchImpl: ok })), "blocked_address");
  assert.equal(await reason(download("http://metadata.google.internal/x", { fetchImpl: ok })), "blocked_address");
  assert.equal(await reason(download("https://evil.example/x", { fetchImpl: ok, lookup: async () => [{ address: "10.0.0.2" }] })), "blocked_address");
  // a public page redirecting inside
  const toMeta = async () => reply(302, { location: "http://127.0.0.1/admin" });
  assert.equal(await reason(download("https://images.example/r", { fetchImpl: toMeta, lookup: publicLookup })), "blocked_address");
  // too many redirects, an upstream error, a network failure, no DNS
  const loop = async (url) => reply(302, { location: url });
  assert.equal(await reason(download("https://images.example/loop", { fetchImpl: loop, lookup: publicLookup })), "fetch_failed");
  assert.equal(await reason(download("https://images.example/404", { fetchImpl: async () => reply(404), lookup: publicLookup })), "fetch_failed");
  assert.equal(await reason(download("https://images.example/x", { fetchImpl: async () => { throw new TypeError("fetch failed"); }, lookup: publicLookup })), "fetch_failed");
  assert.equal(await reason(download("https://nowhere.example/x", { fetchImpl: ok, lookup: async () => { throw new Error("ENOTFOUND"); } })), "fetch_failed");
  // not a picture: SVG, HTML, markup sent as image/png, an empty body
  const svg = async () => reply(200, { "content-type": "image/svg+xml" }, Buffer.from("<svg/>"));
  assert.equal(await reason(download("https://images.example/x.svg", { fetchImpl: svg, lookup: publicLookup })), "not_image");
  const html = async () => reply(200, { "content-type": "text/html" }, Buffer.from("<!doctype html><html></html>"));
  assert.equal(await reason(download("https://images.example/page", { fetchImpl: html, lookup: publicLookup })), "not_image");
  const disguised = async () => reply(200, { "content-type": "image/png" }, Buffer.from("<svg onload='x'/>"));
  assert.equal(await reason(download("https://images.example/x.png", { fetchImpl: disguised, lookup: publicLookup })), "not_image");
  const empty = async () => reply(200, { "content-type": "image/jpeg" }, Buffer.alloc(0));
  assert.equal(await reason(download("https://images.example/e.jpg", { fetchImpl: empty, lookup: publicLookup })), "not_image");
  // over 8 MB, declared or streamed
  const declared = async () => reply(200, { "content-type": "image/jpeg", "content-length": String(8 * 1024 * 1024 + 1) }, jpeg);
  assert.equal(await reason(download("https://images.example/big.jpg", { fetchImpl: declared, lookup: publicLookup })), "too_large");
  const streamed = async () => ({
    status: 200, ok: true, headers: new Headers({ "content-type": "image/jpeg" }),
    body: { async *[Symbol.asyncIterator]() { for (;;) yield new Uint8Array(1024 * 1024); }, cancel: async () => {} },
  });
  assert.equal(await reason(download("https://images.example/endless.jpg", { fetchImpl: streamed, lookup: publicLookup })), "too_large");
});

test("adminPanel still exposes the same guard, now from safeFetch", () => {
  const admin = require("./adminPanel").internals;
  const safe = require("./safeFetch");
  for (const name of ["isPrivateAddress", "isInternalHostname", "assertPublicUrl", "fetchImage", "readCapped", "sniffImage"]) {
    assert.equal(admin[name], safe[name], name);
  }
});

test("the SSRF guard refuses the IPv4-compatible IPv6 form of an inside address", () => {
  const { isPrivateAddress } = require("./safeFetch");
  assert.equal(isPrivateAddress("::127.0.0.1"), true);
  assert.equal(isPrivateAddress("::169.254.169.254"), true);
  assert.equal(isPrivateAddress("::7f00:1"), true);
  assert.equal(isPrivateAddress("2606:4700::1111"), false);
});

test("fetchPublic re-checks every redirect hop", async () => {
  const { fetchPublic } = require("./safeFetch");
  const lookup = async (host) => [{ address: host === "inside.example" ? "10.0.0.5" : "93.184.216.34" }];
  const calls = [];
  const fetchImpl = async (url) => {
    calls.push(url);
    return { status: 302, ok: false, headers: new Map([["location", "http://inside.example/secret"]]) };
  };
  await assert.rejects(fetchPublic("https://www.facebook.com/x", fetchImpl, { lookup }), (err) => err.reason === "blocked_address");
  assert.equal(calls.length, 1);
});

test("start is rounded onto its page, so one page is one cache entry", () => {
  assert.equal(parseRequest({ query: "pizza", start: 7 }).start, 1);
  assert.equal(parseRequest({ query: "pizza", start: 15 }).start, 11);
  assert.equal(cacheId(parseRequest({ query: "pizza", start: 3 })), cacheId(parseRequest({ query: "pizza", start: 1 })));
});

test("Serper down (5xx, network, timeout) is refundable; a 4xx is not", async () => {
  const db = { collection: () => ({ doc: () => ({ get: async () => ({ exists: false }), set: async () => {} }) }) };
  const request = parseRequest({ query: "pizza" });
  const run = (fetchImpl) => search(request, { key: "k", db, fetchImpl }).then(() => null, (e) => e);
  const e500 = await run(async () => ({ status: 503, ok: false, text: async () => "oops" }));
  assert.equal(e500.refundable, true);
  const net = await run(async (_u, opts) => { assert.ok(opts.signal, "the call carries a timeout"); throw new Error("ECONNRESET"); });
  assert.equal(net.refundable, true);
  const e400 = await run(async () => ({ status: 400, ok: false, text: async () => JSON.stringify({ message: "bad" }) }));
  assert.ok(!e400.refundable);
});
