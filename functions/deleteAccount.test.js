const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { parseRequest, deleteQuery } = require("./deleteAccount").internals;

test("the request has to confirm in as many words", () => {
  assert.equal(parseRequest({ confirm: true }).confirm, true);
  assert.equal(parseRequest({ confirm: "true" }).error, "confirm is required");
  assert.equal(parseRequest({}).error, "confirm is required");
  assert.equal(parseRequest(null).error, "confirm is required");
});

test("a query's documents are deleted in batches, or subtree by subtree", async () => {
  const deleted = [];
  const docs = Array.from({ length: 5 }, (_, i) => ({ ref: `d${i}` }));
  const db = {
    batch: () => ({ delete: (ref) => deleted.push(`batch:${ref}`), commit: async () => {} }),
    recursiveDelete: async (ref) => deleted.push(`tree:${ref}`),
  };
  const query = { get: async () => ({ docs, size: docs.length }) };
  assert.equal(await deleteQuery(db, query), 5);
  assert.equal(await deleteQuery(db, query, { subtrees: true }), 5);
  assert.deepEqual(deleted.slice(0, 5), ["batch:d0", "batch:d1", "batch:d2", "batch:d3", "batch:d4"]);
  assert.deepEqual(deleted.slice(5), ["tree:d0", "tree:d1", "tree:d2", "tree:d3", "tree:d4"]);
});
