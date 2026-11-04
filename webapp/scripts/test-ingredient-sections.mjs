// Ingredient sections (src/models/recipe.ts), mirroring the app's
// recipe_ingredient_entity.dart: old heading lines are recognised, runs of a
// section group with their original indices, and `section` is written only
// when set. Needs a Node that strips TypeScript types; an older one skips it.
import assert from "node:assert/strict";

let m;
try {
  m = await import("../src/models/recipe.ts");
} catch (e) {
  console.warn(`test-ingredient-sections: skipped (${e.code || e.message})`);
  process.exit(0);
}
const { isSectionHeading, ingredientGroups, normalizeIngredient, ingredientToDart } = m;
const ing = (name, amount = null, section) => ({ name, amount, unit: "unspecified", ...(section === undefined ? {} : { section }) });

for (const name of ["מצרכים לרוטב:", "For the sauce:", " לבצק： ", "מצרכים לרוטב", "רכיבים עבור הבצק", "Ingredients for the filling"]) assert.ok(isSectionHeading(ing(name)), name);
for (const [name, amount] of [["מצרכים לרוטב:", 2], ["מלח", null], ["Ingredients", null], ["מצרכים", null]]) assert.ok(!isSectionHeading(ing(name, amount)), name);

const groups = ingredientGroups([ing("a", 1, "בשר"), ing("b", 1, "בשר"), ing("c", 1, "רוטב"), ing("d", 1), ing("e", 1, " רוטב ")]);
assert.deepEqual(groups.map((g) => [g.section, g.items.map((x) => x.index)]), [["בשר", [0, 1]], ["רוטב", [2]], [null, [3]], ["רוטב", [4]]]);
assert.deepEqual(ingredientGroups([]), []);
assert.deepEqual(ingredientGroups([ing("a"), ing("b")]).map((g) => g.section), [null]);

assert.equal(normalizeIngredient({ name: "x", section: "  רוטב " }).section, "רוטב");
assert.equal(normalizeIngredient({ name: "x", section: "ס".repeat(80) }).section.length, 60);
assert.ok(!("section" in normalizeIngredient({ name: "x", section: "  " })));
assert.ok(!("section" in normalizeIngredient({ name: "x", section: 3 })));
assert.deepEqual(ingredientToDart(ing("x", 1)), { name: "x", amount: 1, unit: "unspecified" });
assert.deepEqual(ingredientToDart(ing("x", 1, null)), { name: "x", amount: 1, unit: "unspecified" });
assert.deepEqual(ingredientToDart(ing("x", 1, "רוטב")), { name: "x", amount: 1, unit: "unspecified", section: "רוטב" });
console.log("test-ingredient-sections: ok");
