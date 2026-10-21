// Pure checks of the content-translation rules the website shares with the
// app (src/lib/translationCore.ts ↔ lib/core/translation/*.dart): batching
// by records and lines, the over-long record left out, the quota cut, the
// language guess and the display overlay. Runs in the build; needs a Node
// that strips TypeScript types (22.18+ / 23.6+). An older Node skips it.
import assert from "node:assert/strict";

let core;
try {
  core = await import("../src/lib/translationCore.ts");
} catch (e) {
  console.warn(`test-translation: skipped (${e.code || e.message})`);
  process.exit(0);
}
const { batchesOf, fitting, linesIn, unitsOf, unitsIn, guessLanguage, needsTranslation, applyRecipe, applyPlan, planItem, recipeItem, variantVersion } = core;

const item = (id, lines) => ({ type: "recipe", id, version: 0, fields: { title: "t", ingredients: Array(lines - 1).fill("x"), steps: [] } });

// linesIn: one per string, one per list entry.
assert.equal(linesIn(item("a", 5)), 5);

// ≤120 records per call.
let b = batchesOf(Array.from({ length: 250 }, (_, i) => item(`r${i}`, 1)));
assert.deepEqual(b.map((x) => x.length), [120, 120, 10]);

// ≤2500 lines per call (13 × 200 = 2600 → 12 + 1).
b = batchesOf(Array.from({ length: 13 }, (_, i) => item(`r${i}`, 200)));
assert.deepEqual(b.map((x) => x.length), [12, 1]);

// A record over 200 lines is left out; the rest still go.
b = batchesOf([item("big", 201), item("ok", 3)]);
assert.deepEqual(b.flat().map((x) => x.id), ["ok"]);
assert.deepEqual(batchesOf([]), []);

// Quota cut: only a sized refusal shrinks; strictly smaller; never empty.
const slice = [item("a", 10), item("b", 10), item("c", 10)];
assert.deepEqual(fitting(slice, { used: 80, limit: 100, requested: 30 }).map((x) => x.id), ["a", "b"]);
assert.equal(fitting(slice, { used: 80, limit: 100 }), null);
assert.equal(fitting(slice, { used: 95, limit: 100, requested: 30 }), null);
assert.equal(fitting(slice, { used: 0, limit: 100, requested: 30 }), null);
assert.equal(fitting(slice, null), null);

// Units, as the server counts them: 1 per started 300 characters of the
// trimmed line; an ordinary line is still 1.
assert.equal(unitsOf(""), 1);
assert.equal(unitsOf("x".repeat(300)), 1);
assert.equal(unitsOf("x".repeat(301)), 2);
assert.equal(unitsOf(" ".repeat(10) + "x".repeat(600) + " "), 2);
assert.equal(unitsIn(item("a", 5)), 5);
const long = { type: "recipe", id: "L", version: 0, fields: { title: "t", ingredients: ["y".repeat(650)], steps: ["z".repeat(301), "short"] } };
assert.equal(linesIn(long), 4);
assert.equal(unitsIn(long), 1 + 3 + 2 + 1);
// The cut is by units: 4 lines but 7 units, so with 8 left only the first
// long record goes, not the first two.
assert.deepEqual(fitting([long, { ...long, id: "M" }, item("c", 1)], { used: 92, limit: 100, requested: 15 }).map((x) => x.id), ["L"]);
assert.equal(fitting([long, item("c", 1)], { used: 94, limit: 100, requested: 8 }), null);

// Language guess and the needs rule.
assert.equal(guessLanguage("שקשוקה", "en"), "he");
assert.equal(guessLanguage("Шакшука", "en"), "ru");
assert.equal(guessLanguage("شكشوكة", "en"), "ar");
assert.equal(guessLanguage("Omelette", "fr"), "fr");
assert.equal(guessLanguage("Omelette", "he"), "en");
assert.equal(guessLanguage("123", "ru"), "ru");
assert.equal(needsTranslation("he", "Shakshuka", "he"), false);
assert.equal(needsTranslation(null, "שקשוקה", "en"), true);
assert.equal(needsTranslation(null, "123", "en"), false);
assert.equal(needsTranslation("xx", "Omelette", "en"), false);

// Variant version: absent or non-number matches nothing.
assert.equal(variantVersion({}), -1);
assert.equal(variantVersion({ version: 3 }), 3);

// Overlay: lists only when the length matches; amounts/units kept.
const recipe = { id: "r", title: "שקשוקה", ingredients: [{ name: "ביצים", amount: 4, unit: "piece" }], steps: ["לבשל"], contentLang: "he", contentVersion: 2 };
assert.deepEqual(recipeItem(recipe).fields, { title: "שקשוקה", ingredients: ["ביצים"], steps: ["לבשל"] });
const shown = applyRecipe(recipe, { title: "Shakshuka", ingredients: ["Eggs"], steps: ["Cook", "extra"], version: 2 });
assert.equal(shown.title, "Shakshuka");
assert.deepEqual(shown.ingredients, [{ name: "Eggs", amount: 4, unit: "piece" }]);
assert.deepEqual(shown.steps, ["לבשל"]);
assert.equal(recipe.title, "שקשוקה");

// Plans: free text laid back by position, recipe items untouched.
const plan = { id: "p", name: "שבוע", contentLang: "he", contentVersion: 0, meals: [
  { name: "בוקר", items: [{ freeText: "טוסט" }, { freeText: null, recipeId: "r" }, { freeText: " " }] },
  { name: "ערב", items: [{ freeText: "סלט" }] },
] };
assert.deepEqual(planItem(plan).fields, { name: "שבוע", meals: ["בוקר", "ערב"], items: ["טוסט", "סלט"] });
const p2 = applyPlan(plan, { name: "Week", meals: ["Breakfast", "Dinner"], items: ["Toast", "Salad"] });
assert.deepEqual(p2.meals.map((m) => m.name), ["Breakfast", "Dinner"]);
assert.deepEqual(p2.meals.flatMap((m) => m.items.map((i) => i.freeText)), ["Toast", null, " ", "Salad"]);

console.log("test-translation: ok");
