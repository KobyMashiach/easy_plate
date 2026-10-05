const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { collectStrings, applyTranslations, parseRequest, cacheKey } =
  require("./translateContent").internals;

const recipe = (id, title, ingredients, steps) => ({
  id, type: "recipe", fields: { title, ingredients, steps },
});

test("collects every text field, once, in order", () => {
  const strings = collectStrings([
    recipe("1", "שקשוקה", ["2 ביצים", "1 עגבנייה"], ["מטגנים"]),
    recipe("2", "חביתה", ["2 ביצים"], []),
  ]);
  assert.deepEqual(strings, ["שקשוקה", "2 ביצים", "1 עגבנייה", "מטגנים", "חביתה"]);
});

test("numbers, ids and unknown types never reach the model", () => {
  const strings = collectStrings([
    { id: "1", type: "recipe", fields: { title: "עוגה", servings: 4, imageFileName: "a.png" } },
    { id: "2", type: "receipt", fields: { title: "לא נתמך" } },
  ]);
  assert.deepEqual(strings, ["עוגה"]);
});

test("blank and over-long lines are skipped", () => {
  const strings = collectStrings([
    recipe("1", "   ", ["x".repeat(2001), "מלח"], []),
  ]);
  assert.deepEqual(strings, ["מלח"]);
});

test("every kind of record has its own fields translated", () => {
  const items = [
    recipe("r", "שקשוקה", ["2 ביצים"], ["מטגנים"]),
    { id: "b", type: "book", fields: { title: "ספר" } },
    { id: "p", type: "mealPlan", fields: { name: "תפריט", meals: ["בוקר"], items: ["חביתה"] } },
    { id: "g", type: "groceryList", fields: { name: "קניות", items: ["חלב"] } },
  ];
  const table = {
    "שקשוקה": "Shakshuka", "2 ביצים": "2 eggs", "מטגנים": "Fry",
    "ספר": "Book", "תפריט": "Menu", "בוקר": "Breakfast", "חביתה": "Omelette",
    "קניות": "Groceries", "חלב": "Milk",
  };
  const out = applyTranslations(items, table);
  assert.deepEqual(out.r.fields, { title: "Shakshuka", ingredients: ["2 eggs"], steps: ["Fry"] });
  assert.deepEqual(out.b.fields, { title: "Book" });
  assert.deepEqual(out.p.fields, { name: "Menu", meals: ["Breakfast"], items: ["Omelette"] });
  assert.deepEqual(out.g.fields, { name: "Groceries", items: ["Milk"] });
});

test("a line the model did not return keeps its original", () => {
  const out = applyTranslations([recipe("1", "שקשוקה", ["2 ביצים"], [])], { "שקשוקה": "Shakshuka" });
  assert.deepEqual(out["1"].fields, { title: "Shakshuka", ingredients: ["2 ביצים"], steps: [] });
});

test("the cache key separates languages and texts", () => {
  assert.notEqual(cacheKey("en", "מלח"), cacheKey("fr", "מלח"));
  assert.equal(cacheKey("en", "מלח"), cacheKey("en", "מלח"));
});

test("requests are checked before anything is spent", () => {
  assert.match(parseRequest({ targetLang: "xx", items: [recipe("1", "a", [], [])] }).error, /targetLang/);
  assert.match(parseRequest({ targetLang: "en" }).error, /items is required/);
  assert.match(parseRequest({ targetLang: "en", items: [{ id: "1", type: "receipt" }] }).error, /known type/);
  const ok = parseRequest({ targetLang: "en", items: [recipe("1", "a", [], [])] });
  assert.equal(ok.lang, "en");
  assert.equal(ok.items.length, 1);
});
