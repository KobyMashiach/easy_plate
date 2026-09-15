const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { normalizeName, keyFor, fold, median, validRecord } = require("./priceStats").internals;

test("names normalise to one key however they were typed", () => {
  assert.equal(normalizeName("  חָלָב 3%, תנובה "), "חלב 3% תנובה");
  assert.equal(normalizeName("Milk 3%"), "milk 3%");
  assert.equal(keyFor(normalizeName("חלב 3%")), keyFor(normalizeName("חלב  3% ")));
});

test("the fold keeps a mean, a median and a bounded window", () => {
  let doc = null;
  for (const p of [10, 10, 11, 1000]) doc = fold(doc, p, 1);
  assert.equal(doc.count, 4);
  assert.equal(doc.avg, 257.75, "the mean is dragged by the typo");
  assert.equal(doc.median, 10.5, "the median is not");
  for (let i = 0; i < 40; i++) doc = fold(doc, 12, 1);
  assert.equal(doc.recent.length, 25);
});

test("median of odd and even windows", () => {
  assert.equal(median([3, 1, 2]), 2);
  assert.equal(median([4, 1, 3, 2]), 2.5);
});

test("only sane records are accepted", () => {
  assert.equal(validRecord({ name: "חלב", price: "6.90" }).price, 6.9);
  assert.equal(validRecord({ name: "", price: 5 }), null);
  assert.equal(validRecord({ name: "x", price: -1 }), null);
  assert.equal(validRecord({ name: "x", price: 99999 }), null);
  assert.equal(validRecord("nope"), null);
});
