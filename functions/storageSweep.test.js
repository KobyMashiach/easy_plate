const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");

const { sweep, internals } = require("./storageSweep");

const DAY = 24 * 60 * 60 * 1000;
const NOW = Date.UTC(2026, 10, 1, 4, 0, 0);
const iso = (daysAgo) => new Date(NOW - daysAgo * DAY).toISOString();

// A bucket of { name, daysAgo, size }, paged like getFiles with
// autoPaginate off.
function fakeBucket(entries, pageSize = 2) {
  const deleted = [];
  const files = entries.map((e) => ({
    name: e.name,
    metadata: { timeCreated: iso(e.daysAgo), size: String(e.size ?? 100) },
    delete: async () => deleted.push(e.name),
  }));
  return {
    deleted,
    getFiles: async ({ prefix, pageToken }) => {
      const matching = files.filter((f) => f.name.startsWith(prefix));
      const start = pageToken ? Number(pageToken) : 0;
      const page = matching.slice(start, start + pageSize);
      const next = start + pageSize < matching.length ? { prefix, pageToken: String(start + pageSize) } : null;
      return [page, next];
    },
  };
}

// Collection groups by name: { recipes: [data, …], … }, paged by
// limit/startAfter. Writes land in `written`.
function fakeDb(groups, { failOn } = {}) {
  const written = {};
  const query = (name, limit = Infinity, after = -1) => ({
    orderBy: () => query(name, limit, after),
    limit: (n) => query(name, n, after),
    startAfter: (doc) => query(name, limit, doc.index),
    get: async () => {
      if (name === failOn) throw new Error("permission denied");
      const all = (groups[name] || []).map((data, index) => ({ index, data: () => data }));
      return { docs: all.slice(after + 1, after + 1 + limit) };
    },
  });
  return {
    written,
    collectionGroup: (name) => query(name),
    collection: (c) => ({ doc: (d) => ({ set: async (v) => { written[`${c}/${d}`] = v; } }) }),
  };
}

const run = (opts) => sweep({
  params: async () => ({ storage_sweep_mode: { defaultValue: { value: String(opts.mode ?? 1) } } }),
  now: NOW,
  documentId: null,
  serverTimestamp: () => "ts",
  limits: { ...internals.LIMITS, ...(opts.limits || {}) },
  db: opts.db,
  bucket: opts.bucket,
});

const library = () => ({
  recipes: [
    { title: "Soup", imageFileName: "kept.jpg", imageStoragePath: "recipe_images/u1/kept.jpg" },
    // A saved community copy: the author's path, in another account.
    { title: "Saved", imageStoragePath: "recipe_images/u2/author.jpg" },
    { title: "Filler", imageStoragePath: "recipe_images/u1/filler.jpg" },
  ],
  collab_containers: [{ content: { coverImageStoragePath: "recipe_images/u1/cover.jpg" } }],
  whats_new_releases: [{ imageUrl: "https://firebasestorage.googleapis.com/v0/b/x/o/recipe_images%2Fadmin%2Fnews.jpg?alt=media&token=t" }],
});

const files = () => [
  { name: "recipe_images/u1/kept.jpg", daysAgo: 60 },
  { name: "recipe_images/u2/author.jpg", daysAgo: 60 },
  { name: "recipe_images/u1/filler.jpg", daysAgo: 60 },
  { name: "recipe_images/u1/cover.jpg", daysAgo: 60 },
  { name: "recipe_images/admin/news.jpg", daysAgo: 60 },
  { name: "recipe_images/u1/orphan.jpg", daysAgo: 30, size: 5000 },
  { name: "recipe_images/u1/young.jpg", daysAgo: 3 },
];

test("references are found in any field, encoded URLs and file names included", () => {
  const paths = new Set();
  const names = new Set();
  internals.collectRefs({
    a: { deep: [{ x: "recipe_images/u1/a.jpg" }] },
    url: "https://h/o/recipe_images%2Fu2%2Fb.jpg?alt=media",
    imageFileName: "c.jpg",
    title: "no photo here",
  }, paths, names);
  assert.deepEqual([...paths].sort(), ["recipe_images/u1/a.jpg", "recipe_images/u2/b.jpg"]);
  assert.deepEqual([...names], ["c.jpg"]);
  // A file whose record lost its path write-back is still known by name.
  assert.equal(internals.isReferenced("recipe_images/u1/c.jpg", { paths, names }), true);
  assert.equal(internals.isReferenced("recipe_images/u1/d.jpg", { paths, names }), false);
});

test("report mode keeps everything and reports the orphan", async () => {
  const db = fakeDb(library());
  const bucket = fakeBucket(files());
  const summary = await run({ mode: 1, db, bucket });
  assert.equal(summary.complete, true);
  assert.equal(summary.orphans, 1);
  assert.deepEqual(summary.sample, ["recipe_images/u1/orphan.jpg"]);
  assert.equal(summary.orphanBytes, 5000);
  assert.equal(summary.young, 1);
  assert.equal(summary.referenced, 5);
  assert.deepEqual(bucket.deleted, []);
  assert.equal(db.written["admin_reports/storage_sweep"].orphans, 1);
});

test("delete mode removes only the old orphan", async () => {
  const bucket = fakeBucket(files());
  const summary = await run({ mode: 2, db: fakeDb(library()), bucket });
  assert.deepEqual(bucket.deleted, ["recipe_images/u1/orphan.jpg"]);
  assert.equal(summary.deleted, 1);
  assert.equal(summary.deletedBytes, 5000);
});

test("a young orphan is never touched", async () => {
  const bucket = fakeBucket(files());
  await run({ mode: 2, db: fakeDb(library()), bucket });
  assert.ok(!bucket.deleted.includes("recipe_images/u1/young.jpg"));
});

test("a document cap reached means nothing is deleted", async () => {
  const bucket = fakeBucket(files());
  const summary = await run({ mode: 2, db: fakeDb(library()), bucket, limits: { maxDocs: 2 } });
  assert.equal(summary.complete, false);
  assert.equal(summary.incomplete, "maxDocs");
  assert.deepEqual(bucket.deleted, []);
});

test("a file cap reached means nothing is deleted", async () => {
  const bucket = fakeBucket(files());
  const summary = await run({ mode: 2, db: fakeDb(library()), bucket, limits: { maxFiles: 3 } });
  assert.equal(summary.incomplete, "maxFiles");
  assert.deepEqual(bucket.deleted, []);
});

test("a source that cannot be read means nothing is deleted", async () => {
  const bucket = fakeBucket(files());
  const summary = await run({ mode: 2, db: fakeDb(library(), { failOn: "shared_recipes" }), bucket });
  assert.match(summary.incomplete, /^error/);
  assert.deepEqual(bucket.deleted, []);
});

test("no references at all next to old files reads as a broken scan", async () => {
  const bucket = fakeBucket(files());
  const summary = await run({ mode: 2, db: fakeDb({}), bucket });
  assert.equal(summary.incomplete, "no references found");
  assert.deepEqual(bucket.deleted, []);
});

test("mostly orphans is reported, not deleted", async () => {
  const bucket = fakeBucket([
    { name: "recipe_images/u1/kept.jpg", daysAgo: 60 },
    { name: "recipe_images/u1/x.jpg", daysAgo: 60 },
    { name: "recipe_images/u1/y.jpg", daysAgo: 60 },
  ]);
  const summary = await run({ mode: 2, db: fakeDb({ recipes: [{ imageStoragePath: "recipe_images/u1/kept.jpg" }] }), bucket });
  assert.equal(summary.complete, true);
  assert.ok(summary.blocked);
  assert.deepEqual(bucket.deleted, []);
});

test("mode 0 reads and writes nothing", async () => {
  let touched = false;
  const db = { collectionGroup: () => { touched = true; }, collection: () => { touched = true; } };
  const bucket = { getFiles: async () => { touched = true; return [[], null]; } };
  const summary = await run({ mode: 0, db, bucket });
  assert.equal(summary.skipped, true);
  assert.equal(touched, false);
});

test("an unknown or unreadable mode falls back to report only", () => {
  assert.equal(internals.modeFrom({}), 1);
  assert.equal(internals.modeFrom({ storage_sweep_mode: { defaultValue: { value: "7" } } }), 1);
  assert.equal(internals.modeFrom({ storage_sweep_mode: { defaultValue: { value: "2" } } }), 2);
});

test("the template ships the mode at report only", () => {
  const template = require(path.join(__dirname, "..", "remoteconfig.template.json"));
  const param = template.parameters[internals.MODE_PARAM];
  assert.equal(param.valueType, "NUMBER");
  assert.equal(param.defaultValue.value, String(internals.MODE_FALLBACK));
});
