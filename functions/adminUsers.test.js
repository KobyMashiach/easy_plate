const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { parseRequest } = require("./adminUsers").internals;
const { permissionOf, isAdmin, PERMISSIONS } = require("./permissions");

test("only permission \"admin\" on the users document makes an administrator", async () => {
  assert.equal(permissionOf({ permission: "admin" }), PERMISSIONS.ADMIN);
  assert.equal(permissionOf({ permission: "user" }), PERMISSIONS.USER);
  assert.equal(permissionOf({ permission: "Admin" }), PERMISSIONS.USER);
  assert.equal(permissionOf({ email: "koby9779@gmail.com" }), PERMISSIONS.USER);
  assert.equal(permissionOf(null), PERMISSIONS.USER);
  assert.equal(await isAdmin(null), false);
  assert.equal(await isAdmin({ email: "koby9779@gmail.com" }), false);
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

test("a broadcast reaches exactly its audience", () => {
  const { inAudience } = require("./adminUsers").internals;
  const picked = new Set(["a", "b"]);
  assert.equal(inAudience({ audience: "all", uid: "x" }), true);
  assert.equal(inAudience({ audience: "premium", uid: "x", premium: true }), true);
  assert.equal(inAudience({ audience: "premium", uid: "x", premium: false }), false);
  assert.equal(inAudience({ audience: "free", uid: "x", premium: false }), true);
  assert.equal(inAudience({ audience: "free", uid: "x", premium: true }), false);
  assert.equal(inAudience({ audience: "users", uid: "a", uidSet: picked }), true);
  assert.equal(inAudience({ audience: "users", uid: "c", uidSet: picked }), false);
});

test("setPermission takes user or superuser, never admin", () => {
  assert.deepEqual(parseRequest({ action: "setPermission", uid: "u1", permission: "superuser" }), { action: "setPermission", uid: "u1", permission: "superuser" });
  assert.equal(parseRequest({ action: "setPermission", uid: "u1", permission: "admin" }).error, "permission must be user or superuser");
  assert.equal(parseRequest({ action: "setPermission", permission: "user" }).error, "uid is required");
});

test("a superuser is read as such and is exempt like the administrator", () => {
  const { permissionOf, hasAllFeatures } = require("./permissions");
  assert.equal(permissionOf({ permission: "superuser" }), "superuser");
  assert.equal(permissionOf({ permission: "boss" }), "user");
  assert.ok(hasAllFeatures("superuser"));
  assert.ok(hasAllFeatures("admin"));
  assert.ok(!hasAllFeatures("user"));
});
