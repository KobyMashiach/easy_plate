const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const w = require("./whatsappBot").internals;

test("toE164 normalises Meta's wa_id and refuses junk", () => {
  assert.equal(w.toE164("972501234567"), "+972501234567");
  assert.equal(w.toE164("+972 50-123-4567"), "+972501234567");
  assert.equal(w.toE164("0501234567"), null);
  assert.equal(w.toE164("123"), null);
  assert.equal(w.toE164(""), null);
});

test("monthKey is Israel time", () => {
  // 2026-11-30 23:30 UTC is already December 1st in Israel.
  assert.equal(w.monthKey(new Date("2026-11-30T23:30:00Z")), "2026-12");
  assert.equal(w.monthKey(new Date("2026-11-15T10:00:00Z")), "2026-11");
});

test("usedThisMonth resets when the month changed", () => {
  assert.equal(w.usedThisMonth({ month: "2026-11", message_count: 7 }, "2026-11"), 7);
  assert.equal(w.usedThisMonth({ month: "2026-10", message_count: 10 }, "2026-11"), 0);
  assert.equal(w.usedThisMonth(null, "2026-11"), 0);
  assert.equal(w.usedThisMonth({ month: "2026-11", message_count: "x" }, "2026-11"), 0);
});

test("extractCode finds a code but not a grocery list with numbers", () => {
  assert.equal(w.extractCode("123456"), "123456");
  assert.equal(w.extractCode("קוד 123 456"), "123456");
  assert.equal(w.extractCode("EasyPlate code: 042917"), "042917");
  assert.equal(w.extractCode("2 חלב ו-3 לחם"), null);
  assert.equal(w.extractCode("1234567"), null);
  assert.equal(w.extractCode("חלב, לחם, ביצים, גבינה צהובה, עגבניות ומלפפונים 123456"), null);
});

test("langOfText guesses from the script", () => {
  assert.equal(w.langOfText("שלום"), "he");
  assert.equal(w.langOfText("مرحبا"), "ar");
  assert.equal(w.langOfText("привет"), "ru");
  assert.equal(w.langOfText("hello"), "en");
  assert.equal(w.langOfText("123456"), "he");
});

test("cleanItems maps known units and keeps package words in the name", () => {
  const out = w.cleanItems([
    { item: "שמן זית", amount: 1, unit: "בקבוק" },
    { item: "קמח", amount: 2, unit: "קילו" },
    { item: "ביצים", amount: 0, unit: "" },
    { item: "  ", amount: 3, unit: "" },
    null,
  ]);
  assert.deepEqual(out.map((i) => [i.name, i.amount, i.unit]), [
    ["שמן זית (בקבוק)", 1, "unit"],
    ["קמח", 2, "kilogram"],
    ["ביצים", 1, "unit"],
  ]);
});

test("mergeItems adds a source to the same line and appends new ones", () => {
  const items = [{ id: "a", name: "חלב", unit: "unit", sources: [{ recipeId: null, label: "חלב", amount: 1 }], isChecked: true, category: "כללי", isAdHoc: true }];
  let n = 0;
  const out = w.mergeItems(items, [
    { name: "חלב", amount: 2, unit: "unit" },
    { name: "לחם", amount: 1, unit: "unit" },
  ], () => `id${++n}`);
  assert.equal(out.length, 2);
  assert.equal(out[0].isChecked, false);
  assert.equal(out[0].sources.length, 2);
  assert.deepEqual(out[1], { id: "id1", name: "לחם", unit: "unit", sources: [{ recipeId: null, label: "לחם", amount: 1 }], isChecked: false, category: "כללי", isAdHoc: true });
  // The stored list is not changed in place.
  assert.equal(items[0].sources.length, 1);
});

test("stamp bumps the version only when words changed", () => {
  const prev = { name: "L", items: [{ name: "a" }], contentLang: "he", contentVersion: 3 };
  assert.equal(w.stamp({ ...prev, items: [{ name: "a" }, { name: "b" }] }, prev, "he").contentVersion, 4);
  assert.equal(w.stamp({ ...prev }, prev, "he").contentVersion, 3);
  assert.equal(w.stamp(w.newList("x", "n", "he"), null, "he").contentVersion, 0);
});

test("a new list has every GroceryListModel key", () => {
  const l = w.newList("id1", "From WhatsApp", "en", new Date("2026-11-11T00:00:00Z"));
  assert.deepEqual(Object.keys(l).sort(), [
    "collabId", "collabRole", "collaborators", "contentLang", "contentVersion", "createdAt", "id", "items",
    "name", "recipeId", "recipeScale", "recipeServings", "recipeTitle", "selectedPlanIds", "source",
  ]);
  assert.equal(l.createdAt, "2026-11-11T00:00:00.000Z");
});

test("writable refuses shared copies and read-only lists", () => {
  assert.equal(w.writable({ items: [], collabId: null, collabRole: null }), true);
  assert.equal(w.writable({ items: [], collabId: "c1", collabRole: "owner" }), false);
  assert.equal(w.writable({ items: [], collabId: null, collabRole: "viewer" }), false);
  assert.equal(w.writable(null), false);
});

test("Hebrew and Arabic replies are marked right to left, line by line", () => {
  const he = w.directional("שורה\n• 1 חלב", "he");
  assert.ok(he.split("\n").every((l) => l.startsWith(w.RLM)));
  assert.equal(w.directional("line", "en"), "line");
  assert.equal(w.lineFor({ amount: 1, word: "בקבוק", item: "שמן זית" }, "he"), `${w.RLM}• 1 בקבוק שמן זית`);
  assert.equal(w.lineFor({ amount: 2, word: "", item: "milk" }, "en"), "• 2 milk");
});

test("every language carries every reply", () => {
  const keys = Object.keys(w.TEXT.he).sort();
  for (const lang of ["en", "ar", "fr", "ru"]) assert.deepEqual(Object.keys(w.TEXT[lang]).sort(), keys, lang);
  assert.match(w.TEXT.he.quota(10), /10 ההודעות/);
  assert.match(w.TEXT.he.quota(10), /aieasyplate\.app\/upgrade/);
  assert.match(w.TEXT.he.added("• x"), /aieasyplate\.app\/list/);
});

test("signatureValid checks Meta's HMAC", () => {
  const body = Buffer.from('{"a":1}');
  const sig = "sha256=" + crypto.createHmac("sha256", "s3cret").update(body).digest("hex");
  assert.equal(w.signatureValid(body, sig, "s3cret"), true);
  assert.equal(w.signatureValid(body, sig, "other"), false);
  assert.equal(w.signatureValid(body, "sha256=00", "s3cret"), false);
  assert.equal(w.signatureValid(body, undefined, "s3cret"), false);
  assert.equal(w.signatureValid(body, sig, ""), false);
});

test("messagesIn reads only message changes", () => {
  const body = { entry: [{ changes: [
    { field: "messages", value: { messages: [{ id: "m1" }], statuses: [{ id: "s" }] } },
    { field: "messages", value: { statuses: [{ id: "s2" }] } },
    { field: "other", value: { messages: [{ id: "x" }] } },
  ] }] };
  assert.deepEqual(w.messagesIn(body).map((m) => m.id), ["m1"]);
  assert.deepEqual(w.messagesIn(null), []);
});

test("accessFor: hidden is open only to superuser / admin", () => {
  assert.equal(w.accessFor({ flag: 0 }), "closed");
  assert.equal(w.accessFor({ flag: 0, allFeatures: true }), "open");
  assert.equal(w.accessFor({ flag: 4 }), "closed");
  assert.equal(w.accessFor({ flag: 2 }), "open");
  assert.equal(w.accessFor({ flag: 3, premium: false }), "premium_only");
  assert.equal(w.accessFor({ flag: 3, premium: true }), "open");
});
