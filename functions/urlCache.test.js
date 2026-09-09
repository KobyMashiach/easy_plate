// Run with: npm test  (node's built-in runner, no extra dependency)
const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const {
  normalizeSourceUrl,
  cacheKeyFor,
  cacheRequestFor,
  extractedRecipe,
  isFresh,
  CACHE_TTL_MS,
  SOURCE_URL_HEADER,
  SOURCE_KIND_HEADER,
} = require("./aiProxy").internals;

// A Gemini Interactions response carrying [recipe] as its model output.
function geminiResponse(recipe) {
  return JSON.stringify({
    steps: [
      { type: "thought", content: [{ text: "thinking" }] },
      { type: "model_output", content: [{ text: JSON.stringify(recipe) }] },
    ],
  });
}

test("the same page shared with different tracking tails is one key", () => {
  const a = normalizeSourceUrl(
    "https://www.tiktok.com/@cook/video/123?_t=8abc&_r=1&is_from_webapp=1&utm_source=share",
  );
  const b = normalizeSourceUrl("https://tiktok.com/@cook/video/123/?fbclid=zzz#top");
  assert.equal(a, "https://tiktok.com/@cook/video/123");
  assert.equal(a, b);
});

test("parameters that pick the content are kept, in a stable order", () => {
  const a = normalizeSourceUrl("https://youtube.com/watch?v=abc&list=xyz&si=tracking");
  const b = normalizeSourceUrl("https://www.YouTube.com/watch?list=xyz&v=abc");
  assert.equal(a, "https://youtube.com/watch?list=xyz&v=abc");
  assert.equal(a, b);
});

test("the root path keeps its slash and non-http links are refused", () => {
  assert.equal(normalizeSourceUrl("https://example.com/"), "https://example.com/");
  assert.equal(normalizeSourceUrl("ftp://example.com/recipe"), null);
  assert.equal(normalizeSourceUrl("not a url"), null);
  assert.equal(normalizeSourceUrl(undefined), null);
});

test("web and social prompts for one link are different entries", () => {
  const url = "https://example.com/r";
  assert.notEqual(cacheKeyFor("url", url), cacheKeyFor("social", url));
  assert.equal(cacheKeyFor("url", url), cacheKeyFor("url", url));
});

test("a request names its link in the headers and the body", () => {
  const url = "https://www.example.com/recipes/shakshuka/?utm_source=x";
  const body = JSON.stringify({ input: `extract\n${url}` });
  const entry = cacheRequestFor(
    { [SOURCE_URL_HEADER]: url, [SOURCE_KIND_HEADER]: "url" },
    body,
  );
  assert.equal(entry.normalizedUrl, "https://example.com/recipes/shakshuka");
  assert.equal(entry.kind, "url");
  assert.equal(entry.key, cacheKeyFor("url", "https://example.com/recipes/shakshuka"));
});

test("a header link that is not in the body cannot poison another page's entry", () => {
  const body = JSON.stringify({ input: "extract\nhttps://example.com/a" });
  const entry = cacheRequestFor(
    { [SOURCE_URL_HEADER]: "https://example.com/b", [SOURCE_KIND_HEADER]: "url" },
    body,
  );
  assert.equal(entry, null);
});

test("requests without the headers, or with an unknown kind, are not cached", () => {
  const body = JSON.stringify({ input: "https://example.com/a" });
  assert.equal(cacheRequestFor({}, body), null);
  assert.equal(
    cacheRequestFor(
      { [SOURCE_URL_HEADER]: "https://example.com/a", [SOURCE_KIND_HEADER]: "refine" },
      body,
    ),
    null,
  );
});

test("a response holding a recipe is worth remembering", () => {
  const recipe = extractedRecipe(
    geminiResponse({ title: "שקשוקה", ingredients: [{ name: "ביצים", unit: "unit" }], steps: [] }),
  );
  assert.equal(recipe.title, "שקשוקה");
});

test("a response with no recipe in it is not", () => {
  assert.equal(extractedRecipe(geminiResponse({ title: "", ingredients: [], steps: [] })), null);
  assert.equal(extractedRecipe(geminiResponse({ title: "x", ingredients: [], steps: [] })), null);
  assert.equal(extractedRecipe(JSON.stringify({ steps: [] })), null);
  assert.equal(extractedRecipe("not json"), null);
  assert.equal(extractedRecipe(JSON.stringify({ error: { message: "nope" } })), null);
});

test("an entry expires after the TTL", () => {
  const now = Date.now();
  const stamp = (ms) => ({ toMillis: () => ms });
  assert.equal(isFresh(stamp(now - 1000), now), true);
  assert.equal(isFresh(stamp(now - CACHE_TTL_MS - 1), now), false);
  assert.equal(isFresh(undefined, now), false);
});
