const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const {
  ACTIONS, parseRequest, isPersona, personaUid, backdated, normalizeRecipe, portraitUrl, summarize, decodeDataUrl, sniffImage, textPrompt, dishesPrompt, threadPrompt, peoplePrompt, ORIGINS,
} = require("./adminPanel").internals;

test("an unknown action, and a missing required field, are refused before any work", () => {
  assert.equal(parseRequest({ action: "nope" }).error, "unknown action");
  assert.equal(parseRequest({}).error, "unknown action");
  assert.equal(parseRequest({ action: "user.disable" }).error, "uid is required");
  assert.equal(parseRequest({ action: "user.disable", uid: "   " }).error, "uid is required");
  assert.equal(parseRequest({ action: "forum.post.create", as: "me", title: "t" }).error, "body is required");
});

test("fields are trimmed, capped and typed; strangers are dropped", () => {
  const r = parseRequest({ action: "user.notify", uid: " u1 ", title: "x".repeat(200), body: "hello", extra: "no" });
  assert.equal(r.uid, "u1");
  assert.equal(r.title.length, 80);
  assert.equal(r.extra, undefined);
  assert.equal(parseRequest({ action: "community.seedLikes", kind: "post", postId: "p", count: "12" }).count, 12);
  assert.equal(parseRequest({ action: "community.seedLikes", kind: "post", postId: "p", count: "lots" }).error, "count must be a number");
  assert.equal(parseRequest({ action: "community.like", as: "me", kind: "thread" }).error, "kind is not one of post, reply, recipe");
  assert.equal(parseRequest({ action: "user.entitlement", uid: "u", premium: "true" }).premium, true);
  assert.equal(parseRequest({ action: "user.content.set", root: "users", rootId: "u", collection: "recipes", id: "r", data: [] }).error, "data must be an object");
  assert.equal(parseRequest({ action: "user.content.set", root: "secrets", rootId: "u", collection: "recipes", id: "r", data: {} }).error, "root is not one of users, households");
});

test("every action has a spec, and none reads the request body blindly", () => {
  for (const [name, spec] of Object.entries(ACTIONS)) {
    assert.ok(/^[a-z]+(\.[a-zA-Z]+)*$/.test(name), name);
    for (const rule of Object.values(spec)) assert.ok(["string", "number", "boolean", "object", "enum"].includes(rule.kind), name);
  }
});

test("persona uids are marked and random", () => {
  const a = personaUid();
  const b = personaUid();
  assert.ok(isPersona(a));
  assert.ok(!isPersona("TMUEhPfI5VcYpiluym1aT23daZc2"));
  assert.notEqual(a, b);
  assert.ok(/^seed_[A-Za-z0-9]{16,20}$/.test(a), a);
});

test("a backdate stays within the last year and never in the future", () => {
  const now = 1_800_000_000_000;
  assert.equal(backdated(undefined, now), now);
  assert.equal(backdated(now + 5000, now), now);
  assert.equal(backdated(now - 1000, now), now - 1000);
  assert.equal(backdated(0, now), now - 365 * 24 * 3600 * 1000);
});

test("a recipe is reduced to the app's shape", () => {
  const { recipe, error } = normalizeRecipe({
    title: "  Shakshuka ",
    prepTimeMinutes: "10",
    cookTimeMinutes: 25.6,
    servings: 0,
    ingredients: [
      { name: "eggs", amount: 4, unit: "unit" },
      { name: "tomatoes", amount: "2.5", unit: "cups" },
      { name: "", amount: 1, unit: "cup" },
      { name: "salt" },
    ],
    steps: ["Fry", "", "  Crack eggs  ", 42],
    dietaryTags: ["vegetarian", "paleo", "vegetarian"],
    allergens: ["eggs", "nothing"],
    mayContain: [],
    nutrition: { calories: 320.4, proteinGrams: "14", carbsGrams: 9.123, fatGrams: null },
    somethingElse: true,
  });
  assert.equal(error, undefined);
  assert.equal(recipe.title, "Shakshuka");
  assert.equal(recipe.prepTimeMinutes, 10);
  assert.equal(recipe.cookTimeMinutes, 26);
  assert.equal(recipe.servings, 1);
  assert.deepEqual(recipe.ingredients, [
    { name: "eggs", amount: 4, unit: "unit" },
    { name: "tomatoes", amount: 2.5, unit: "unspecified" },
    { name: "salt", amount: null, unit: "unspecified" },
  ]);
  assert.deepEqual(recipe.steps, ["Fry", "Crack eggs"]);
  assert.deepEqual(recipe.dietaryTags, ["vegetarian"]);
  assert.deepEqual(recipe.allergens, ["eggs"]);
  assert.deepEqual(recipe.nutrition, { calories: 320, proteinGrams: 14, carbsGrams: 9.12, fatGrams: 0 });
  assert.equal(recipe.somethingElse, undefined);
  assert.equal(normalizeRecipe({ title: "x" }).error, "recipe needs ingredients or steps");
  assert.equal(normalizeRecipe({ steps: ["a"] }).error, "recipe.title is required");
  assert.equal(normalizeRecipe({ title: "x", steps: ["a"], nutrition: { proteinGrams: 3 } }).recipe.nutrition, null);
});

test("portraits come from the hundred per gender", () => {
  assert.equal(portraitUrl("male", 7), "https://randomuser.me/api/portraits/men/7.jpg");
  assert.equal(portraitUrl("female", 107), "https://randomuser.me/api/portraits/women/7.jpg");
  assert.equal(portraitUrl("female", "x"), "https://randomuser.me/api/portraits/women/0.jpg");
});

test("the audit summary keeps ids and drops pictures and bodies", () => {
  const s = summarize({ action: "persona.create", name: "Dana", photoDataUrl: "data:image/jpeg;base64,AAAA", recipe: { title: "Soup", steps: ["x"] }, image: { dataUrl: "data:..." }, body: "y".repeat(400), data: { a: 1 } });
  assert.equal(s.action, undefined);
  assert.equal(s.name, "Dana");
  assert.equal(s.photoDataUrl, "<27 chars>");
  assert.deepEqual(s.recipe, { title: "Soup" });
  assert.deepEqual(s.image, { dataUrl: "<8 chars>" });
  assert.equal(s.body.length, 301);
  assert.equal(s.data, "<object>");
});

test("data urls and magic bytes are recognised", () => {
  const png = decodeDataUrl("data:image/png;base64,iVBORw0KGgo=");
  assert.equal(png.contentType, "image/png");
  assert.equal(decodeDataUrl("data:text/plain;base64,aGk="), null);
  assert.equal(sniffImage(Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0, 0, 0, 0, 0])), "image/jpeg");
  assert.equal(sniffImage(Buffer.from("RIFF....WEBPVP8 ")), "image/webp");
  assert.equal(sniffImage(Buffer.from("hello world!")), null);
});

test("prompts carry the language and the persona", () => {
  const p = textPrompt({ kind: "reply", lang: "he", context: "How long do I boil eggs?", persona: "Dana Levi" });
  assert.match(p, /Hebrew/);
  assert.match(p, /Dana Levi/);
  assert.match(p, /boil eggs/);
  assert.match(textPrompt({ kind: "thread", lang: "xx" }), /Hebrew/);
});

test("only our own origins may call", () => {
  assert.ok(ORIGINS.includes("https://aieasyplate.app"));
  assert.ok(!ORIGINS.some((o) => o === "*"));
});

test("the seed actions take their fields and the dish prompt carries the theme", () => {
  const r = parseRequest({ action: "recipe.seedOne", title: "Shakshuka", lang: "he", as: "random", likes: "4", createdAt: 1 });
  assert.equal(r.likes, 4);
  assert.equal(r.as, "random");
  assert.equal(parseRequest({ action: "recipe.seedOne" }).error, "title is required");
  assert.equal(parseRequest({ action: "dish.suggest", count: 12, lang: "fr", theme: "vegan" }).theme, "vegan");
  assert.match(dishesPrompt({ count: 5, lang: "ru", theme: "soups" }), /Russian[\s\S]*soups/);
});

test("names come in the language's own script, and a thread names its cast", () => {
  assert.match(peoplePrompt({ count: 3, lang: "he" }), /Hebrew letters/);
  assert.match(peoplePrompt({ count: 3, lang: "ru" }), /Cyrillic/);
  const p = threadPrompt({ lang: "he", topic: "leftovers", replies: 2, names: ["דנה", "יוסי", "מיכל"] });
  assert.match(p, /by דנה/);
  assert.match(p, /יוסי, מיכל/);
  assert.equal(parseRequest({ action: "forum.seedThread", lang: "he", replies: "3", days: 20, likes: 4 }).replies, 3);
});
