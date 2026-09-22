const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { parseRequest, isAdmin } = require("./adminUsers").internals;

test("only the administrator's email passes", () => {
  assert.equal(isAdmin({ email: "koby9779@gmail.com" }), true);
  assert.equal(isAdmin({ email: "Koby9779@Gmail.com " }), true);
  assert.equal(isAdmin({ email: "someone@gmail.com" }), false);
  assert.equal(isAdmin(null), false);
});

test("disable carries the block message", () => {
  const r = parseRequest({ action: "disable", uid: "u1", message: "  spam  " });
  assert.deepEqual(r, { action: "disable", uid: "u1", message: "spam" });
});

test("account actions need a uid", () => {
  assert.equal(parseRequest({ action: "delete" }).error, "uid is required");
  assert.equal(parseRequest({ action: "enable", uid: "" }).error, "uid is required");
});

test("a push needs a body, and the title is optional", () => {
  assert.equal(parseRequest({ action: "notify", uid: "u1" }).error, "body is required");
  const r = parseRequest({ action: "notify", uid: "u1", body: "hi" });
  assert.deepEqual(r, { action: "notify", uid: "u1", title: "", message: "hi" });
});

test("a broadcast takes no uid", () => {
  const r = parseRequest({ action: "notifyAll", title: "News", body: "Version 2 is out" });
  assert.deepEqual(r, { action: "notifyAll", title: "News", message: "Version 2 is out" });
});

test("long texts are cut, unknown actions refused", () => {
  const r = parseRequest({ action: "notifyAll", body: "x".repeat(5000) });
  assert.equal(r.message.length, 1000);
  assert.equal(parseRequest({ action: "shutdown" }).error, "unknown action");
  assert.equal(parseRequest(null).error, "unknown action");
});

test("a price sync takes nothing", () => {
  assert.deepEqual(parseRequest({ action: "syncPricing" }), { action: "syncPricing" });
});
