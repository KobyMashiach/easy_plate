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
    (err) => err.status === 429 && err.code === "quota",
  );
  await assert.rejects(
    search(request, { key: "k", fetchImpl: refused(403, "Unauthorized"), db: fakeDb() }),
    (err) => err.status === 502 && err.code === "upstream",
  );
  assert.equal(seen.url, "https://google.serper.dev/images");
  assert.equal(seen.init.method, "POST");
  assert.equal(seen.init.headers["X-API-KEY"], "k");
  assert.equal(JSON.parse(seen.init.body).q, "pizza");
});
