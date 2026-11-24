const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { WORDS, PHRASES, findProfanity, maskProfanity } = require("./profanity");

const CLEAN = ["2 כוסות קמח וכוס סוכר", "כוסית יין לבן", "מתכון מזין ובריא", "אני מכין את זה כבר שנים", "5 כפות שמן, 100 גרם חמאה", "this is a cook book", "Cocktail with dick tracy", "מספר 1 בעולם!!"];
const DIRTY = ["כוס אמק מה זה", "יא בן זונה", "what the f u c k!", "fuuuuck this", "sh1t", "putain c’est bon", "enculé", "сука блять", "פאקינג טעים", "זין"];

test("recipe words pass, swear words do not", () => {
  for (const s of CLEAN) assert.equal(findProfanity(s), null, s);
  for (const s of DIRTY) assert.ok(findProfanity(s), s);
});

test("masking hides the words and keeps the rest", () => {
  assert.equal(maskProfanity("וואו כוס אמק, איזה זין של עוגה"), "וואו *** ***, איזה *** של עוגה");
  assert.equal(maskProfanity("what the f u c k!"), "what the * * * *!");
  assert.equal(maskProfanity("2 כוסות קמח"), "2 כוסות קמח");
});

// The app and the website carry copies of the lists.
function listsIn(file, name) {
  const src = fs.readFileSync(path.join(__dirname, "..", file), "utf8");
  const m = src.match(new RegExp(`${name}\\s*(?::[^=]*)?=\\s*\\[([\\s\\S]*?)\\]`));
  assert.ok(m, `${name} in ${file}`);
  return [...m[1].matchAll(/"([^"]*)"/g)].map((x) => x[1]);
}

test("the app's and the website's lists match this one", () => {
  for (const file of ["lib/core/moderation/profanity_filter.dart", "webapp/src/lib/profanity.ts"]) {
    assert.deepEqual(listsIn(file, file.endsWith(".dart") ? "static const words" : "WORDS"), WORDS, file);
    assert.deepEqual(listsIn(file, file.endsWith(".dart") ? "static const phrases" : "PHRASES"), PHRASES, file);
  }
});

test("the moderation trigger masks only what needs it", () => {
  process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
  process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
  const { maskPatch, POST, RECIPE } = require("./communityModeration").internals;
  assert.equal(maskPatch({ title: "עוגת גבינה", body: "2 כוסות קמח" }, POST), null);
  assert.deepEqual(maskPatch({ title: "שלום", body: "יא זונה" }, POST), { body: "** ****" });
  const patch = maskPatch({ title: "ok", steps: ["לערבב", "fuck it"], ingredients: [{ name: "קמח" }, { name: "shit", amount: 1 }] }, RECIPE);
  assert.deepEqual(patch.steps, ["לערבב", "**** it"]);
  assert.deepEqual(patch.ingredients, [{ name: "קמח" }, { name: "****", amount: 1 }]);
  assert.equal(patch.title, undefined);
});
