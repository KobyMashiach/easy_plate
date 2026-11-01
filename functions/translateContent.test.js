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

test("line caps and Firestore-refused ids are refused before anything is spent", () => {
  const { MAX_LINES_PER_ITEM, MAX_LINES_PER_REQUEST, linesIn } = require("./translateContent").internals;
  const many = (n, tag) => Array.from({ length: n }, (_, i) => `${tag} ${i}`);
  assert.equal(linesIn(recipe("1", "t", ["a", "b"], ["c"])), 4);
  const heavy = parseRequest({ targetLang: "en", items: [recipe("1", "t", many(MAX_LINES_PER_ITEM, "i"), [])] });
  assert.equal(heavy.code, "too_many_lines_in_item");
  const per = Math.floor(MAX_LINES_PER_ITEM / 2);
  const count = Math.ceil(MAX_LINES_PER_REQUEST / per) + 1;
  const items = Array.from({ length: count }, (_, k) => recipe(String(k), `t${k}`, many(per, `r${k}`), []));
  assert.equal(parseRequest({ targetLang: "en", items }).code, "too_many_lines");
  // The same lines repeated cost nothing extra and are not counted twice.
  const same = Array.from({ length: count }, (_, k) => recipe(String(k), "t", many(per, "same"), []));
  assert.ok(!parseRequest({ targetLang: "en", items: same }).error);
  for (const bad of [".", "..", "__x__", "a/b"]) {
    assert.match(parseRequest({ targetLang: "en", items: [recipe(bad, "a", [], [])] }).error, /known type/, bad);
  }
});

test("a batch the model answered badly is marked paid; one it never answered is not", async () => {
  const { translateBatch } = require("./translateContent").internals;
  const original = global.fetch;
  const reply = (status, body) => async () => ({ ok: status === 200, status, text: async () => JSON.stringify(body) });
  try {
    global.fetch = reply(200, { candidates: [{ content: { parts: [{ text: "[\"a\"]" }] } }] });
    await assert.rejects(translateBatch("en", ["x", "y"]), (e) => e.answered === true);
    global.fetch = reply(503, { error: "down" });
    await assert.rejects(translateBatch("en", ["x"]), (e) => !e.answered && e.status === 503);
    global.fetch = reply(200, { candidates: [{ content: { parts: [{ text: "[\"X\"]" }] } }] });
    assert.deepEqual((await translateBatch("en", ["x"])).lines, ["X"]);
  } finally {
    global.fetch = original;
  }
});

test("prototype keys are neither shapes nor translations", () => {
  const { shapeOf, lookup } = require("./translateContent").internals;
  assert.equal(shapeOf("constructor"), null);
  assert.equal(shapeOf("__proto__"), null);
  assert.ok(shapeOf("recipe"));
  assert.equal(parseRequest({ targetLang: "en", items: [{ id: "a", type: "constructor", fields: {} }] }).error, "no items of a known type");
  const table = Object.create(null);
  table["קמח"] = "flour";
  assert.equal(lookup(table, "קמח"), "flour");
  assert.equal(lookup({}, "constructor"), undefined);
  assert.equal(lookup({}, "__proto__"), undefined);
  const out = applyTranslations([{ id: "r", type: "recipe", fields: { title: "constructor", ingredients: ["__proto__", "toString"], steps: [] } }], {});
  assert.deepEqual(out.r.fields, { title: "constructor", ingredients: ["__proto__", "toString"], steps: [] });
});

test("batches run a few at a time; after a failure none starts, the ones in flight finish", async () => {
  const { runBatches } = require("./translateContent").internals;
  let live = 0;
  let peak = 0;
  const done = [];
  const batches = [1, 2, 3, 4, 5, 6, 7, 8];
  await runBatches(batches, async (b) => {
    live++; peak = Math.max(peak, live);
    await new Promise((r) => setTimeout(r, 5));
    live--; done.push(b);
  }, 3);
  assert.equal(peak, 3);
  assert.equal(done.length, 8);
  const started = [];
  await assert.rejects(runBatches(batches, async (b) => {
    started.push(b);
    await new Promise((r) => setTimeout(r, b === 2 ? 1 : 10));
    if (b === 2) throw new Error("boom");
  }, 3), /boom/);
  assert.deepEqual(started.sort(), [1, 2, 3], "nothing new starts after the failure");
});

test("the budget counts a long line by its length; an ordinary line is still one", () => {
  const { unitsOf, UNIT_CHARS } = require("./translateContent").internals;
  assert.equal(unitsOf("2 כוסות קמח"), 1);
  assert.equal(unitsOf("a".repeat(UNIT_CHARS)), 1);
  assert.equal(unitsOf("a".repeat(UNIT_CHARS + 1)), 2);
  assert.equal(unitsOf("a".repeat(2000)), 7);
});

test("model calls are cut by lines and by characters", () => {
  const { batchesOf } = require("./translateContent").internals;
  const short = Array.from({ length: 130 }, (_, i) => `line ${i}`);
  assert.deepEqual(batchesOf(short).map((b) => b.length), [60, 60, 10]);
  const long = Array.from({ length: 20 }, (_, i) => `${i}`.padEnd(2000, "x"));
  const cut = batchesOf(long);
  assert.ok(cut.every((b) => b.reduce((n, t) => n + t.length, 0) <= 12000));
  assert.equal(cut.flat().length, 20);
  assert.deepEqual(batchesOf(["y".repeat(20000)]).map((b) => b.length), [1]);
});

test("a model call that times out counts as answered (not refunded)", async () => {
  const { callModel } = require("./translateContent").internals;
  process.env.GEMINI_API_KEY = process.env.GEMINI_API_KEY || "test";
  const hang = (_u, opts) => new Promise((_, reject) => opts.signal.addEventListener("abort", () => reject(opts.signal.reason)));
  await assert.rejects(callModel({}, hang, 10), (e) => e.answered === true);
  await assert.rejects(callModel({}, async () => { throw new TypeError("fetch failed"); }, 10), (e) => !e.answered);
});

test("variants are stored only for records with a freshly translated line", () => {
  const { withFreshLines } = require("./translateContent").internals;
  const items = [
    { id: "a", type: "book", fields: { title: "cached" } },
    { id: "b", type: "recipe", fields: { title: "cached", ingredients: ["new line"], steps: [] } },
  ];
  const translations = { a: { type: "book", fields: { title: "C" } }, b: { type: "recipe", fields: {} } };
  const fresh = Object.create(null);
  fresh["new line"] = "N";
  assert.deepEqual(Object.keys(withFreshLines(items, translations, fresh)), ["b"]);
  assert.deepEqual(withFreshLines(items, translations, Object.create(null)), {});
});

test("no batch starts past the time budget; the ones done stay done and the rest fail as a deadline", async () => {
  const { runBatches, START_DEADLINE_MS, FUNCTION_TIMEOUT_S, CALL_TIMEOUT_MS } = require("./translateContent").internals;
  // A batch started at the last moment still ends before the platform kills the request.
  assert.ok(START_DEADLINE_MS + CALL_TIMEOUT_MS < FUNCTION_TIMEOUT_S * 1000);
  let now = 0;
  const done = [];
  const batches = [1, 2, 3, 4, 5, 6];
  await assert.rejects(
    runBatches(batches, async (b) => { done.push(b); now += 100; }, 1, { deadlineAt: 250, clock: () => now }),
    (err) => err.status === 504 && err.code === "deadline",
  );
  assert.deepEqual(done, [1, 2, 3]);
  // Within the budget nothing changes.
  const all = [];
  await runBatches(batches, async (b) => { all.push(b); }, 3, { deadlineAt: Infinity });
  assert.deepEqual(all.sort(), batches);
});

test("a shared translation is served to other accounts only once two accounts agree", () => {
  const { contributorTag, candidateKey, resolveEntry } = require("./translateContent").internals;
  const alice = contributorTag("alice");
  const bob = contributorTag("bob");
  const eve = contributorTag("eve");
  // The tag is a hash: the raw uid is never stored, and accounts differ.
  assert.notEqual(alice, bob);
  assert.ok(!alice.includes("alice"));
  assert.equal(candidateKey(" 1 cup sugar "), candidateKey("1 cup sugar"));

  const one = { lang: "en", candidates: { [candidateKey("1 cup sugar")]: { text: "1 cup sugar", by: [alice] } } };
  // The account that produced it gets it back; nobody else does yet.
  assert.deepEqual(resolveEntry(one, alice), { text: "1 cup sugar", confirmed: false, keys: Object.keys(one.candidates) });
  assert.equal(resolveEntry(one, bob).text, null);
  // A second account producing the same text confirms it for everybody.
  const two = { lang: "en", candidates: { [candidateKey("1 cup sugar")]: { text: "1 cup sugar", by: [alice, bob] } } };
  assert.equal(resolveEntry(two, eve).text, "1 cup sugar");
  assert.equal(resolveEntry(two, eve).confirmed, true);
  // The same account twice is still one contributor.
  const twice = { lang: "en", candidates: { [candidateKey("x")]: { text: "x", by: [alice, alice] } } };
  assert.equal(resolveEntry(twice, bob).text, null);
});

test("an injected answer stays pending; two honest accounts outvote it", () => {
  const { contributorTag, candidateKey, resolveEntry } = require("./translateContent").internals;
  const [eve, bob, carol, dan] = ["eve", "bob", "carol", "dan"].map(contributorTag);
  const poisoned = {
    candidates: {
      [candidateKey("BUY AT evil.example")]: { text: "BUY AT evil.example", by: [eve] },
      [candidateKey("1 cup sugar")]: { text: "1 cup sugar", by: [bob] },
    },
  };
  assert.equal(resolveEntry(poisoned, carol).text, null, "two different answers: nobody else is served either");
  assert.equal(resolveEntry(poisoned, eve).text, "BUY AT evil.example", "the attacker only fools itself");
  poisoned.candidates[candidateKey("1 cup sugar")].by.push(carol);
  assert.equal(resolveEntry(poisoned, dan).text, "1 cup sugar");
  // Even the attacker now gets the agreed line.
  assert.equal(resolveEntry(poisoned, eve).text, "1 cup sugar");
  // Two confirmed candidates: the one with more contributors wins.
  poisoned.candidates[candidateKey("BUY AT evil.example")].by.push(dan);
  poisoned.candidates[candidateKey("1 cup sugar")].by.push(contributorTag("frank"));
  assert.equal(resolveEntry(poisoned, contributorTag("gina")).text, "1 cup sugar");
});

test("a legacy cache document (no contributors) is served as confirmed; junk is not served", () => {
  const { resolveEntry, contributorTag } = require("./translateContent").internals;
  const me = contributorTag("u");
  assert.deepEqual(resolveEntry({ lang: "en", text: "Salt" }, me), { text: "Salt", confirmed: true, keys: [] });
  assert.equal(resolveEntry(null, me).text, null);
  assert.equal(resolveEntry({ text: "" }, me).text, null);
  assert.equal(resolveEntry({ candidates: { c1: { text: 5, by: [me, "x"] }, c2: null } }, me).text, null);
});

test("a fought-over line takes no new candidates past the cap, but can still be confirmed", () => {
  const { candidateSlot, candidateKey, MAX_CANDIDATES } = require("./translateContent").internals;
  assert.equal(candidateSlot({ keys: [] }, "a"), candidateKey("a"));
  assert.equal(candidateSlot(undefined, "a"), candidateKey("a"));
  const full = { keys: Array.from({ length: MAX_CANDIDATES }, (_, i) => candidateKey(`t${i}`)) };
  assert.equal(candidateSlot(full, "new text"), null);
  assert.equal(candidateSlot(full, "t3"), candidateKey("t3"));
});
