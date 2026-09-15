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
