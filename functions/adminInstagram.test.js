const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const admin = require("firebase-admin");
const ig = require("./adminInstagram");
const { problems, cleanPost, containerRequests, hashtags } = ig.internals;

const { Timestamp, FieldValue } = admin.firestore;
const DELETE = FieldValue.delete();

// ---------------------------------------------------------------- fakes

function getPath(obj, path) {
  return path.split(".").reduce((o, k) => (o == null ? undefined : o[k]), obj);
}
function applyPatch(target, patch) {
  for (const [k, v] of Object.entries(patch)) {
    if (v && typeof v.isEqual === "function" && v.isEqual(DELETE)) delete target[k];
    else target[k] = v;
  }
}
function fakeDb(initial = {}) {
  const store = new Map(Object.entries(initial));
  let auto = 0;
  const ref = (path) => ({
    path,
    id: path.split("/").pop(),
    async get() {
      const data = store.get(path);
      return { exists: !!data, id: path.split("/").pop(), ref: ref(path), data: () => (data ? { ...data } : undefined), get: (f) => (data ? getPath(data, f) : undefined) };
    },
    async set(data, opts = {}) {
      const next = opts.merge && store.has(path) ? { ...store.get(path) } : {};
      applyPatch(next, data);
      store.set(path, next);
    },
    async update(patch) {
      if (!store.has(path)) throw new Error("no document " + path);
      const next = { ...store.get(path) };
      applyPatch(next, patch);
      store.set(path, next);
    },
    async delete() { store.delete(path); },
  });
  const cmp = (a, b) => (a && a.toMillis ? a.toMillis() : a) - (b && b.toMillis ? b.toMillis() : b);
  const coll = (name, filters = [], max = 1000) => ({
    doc: (id) => ref(`${name}/${id || `auto${++auto}`}`),
    where: (f, op, v) => coll(name, [...filters, [f, op, v]], max),
    limit: (n) => coll(name, filters, n),
    async get() {
      const docs = [];
      for (const [path, data] of store) {
        if (!path.startsWith(name + "/") || path.split("/").length !== 2) continue;
        const ok = filters.every(([f, op, v]) => {
          const x = getPath(data, f);
          if (x === undefined || x === null) return false;
          return op === "<=" ? cmp(x, v) <= 0 : op === ">=" ? cmp(x, v) >= 0 : x === v;
        });
        if (ok) docs.push(await ref(path).get());
      }
      return { docs: docs.slice(0, max), size: docs.length };
    },
  });
  return {
    store,
    doc: ref,
    collection: (name) => coll(name),
    async runTransaction(fn) {
      const writes = [];
      const out = await fn({ get: (r) => r.get(), update: (r, p) => writes.push([r, p]) });
      for (const [r, p] of writes) await r.update(p);
      return out;
    },
  };
}
function fakeBucket(paths = []) {
  const files = new Map(paths.map((p) => [p, { metadata: {} }]));
  return {
    name: "easy-plate.firebasestorage.app",
    files,
    file: (p) => ({
      async exists() { return [files.has(p)]; },
      async delete() { files.delete(p); },
      async getMetadata() { return [files.get(p) || {}]; },
      async setMetadata(m) { files.set(p, { ...(files.get(p) || {}), ...m }); },
    }),
  };
}
// Instagram: records every call, answers by path.
function fakeGraph(routes = {}) {
  const calls = [];
  const fetchImpl = async (url, opts = {}) => {
    const u = new URL(url);
    const method = opts.method || "GET";
    const params = Object.fromEntries(method === "GET" ? u.searchParams : new URLSearchParams(opts.body));
    const path = u.pathname.replace(/^\/v[\d.]+\//, "");
    calls.push({ method, path, params });
    const key = `${method} ${path}`;
    const handler = routes[key] || Object.entries(routes).find(([k]) => new RegExp("^" + k + "$").test(key))?.[1];
    const body = typeof handler === "function" ? handler(params) : handler;
    if (!body) return { ok: false, status: 404, json: async () => ({ error: { message: "no route " + key } }) };
    if (body.error) return { ok: false, status: 400, json: async () => body };
    return { ok: true, status: 200, json: async () => body };
  };
  return { calls, fetchImpl };
}

const img = (n, extra = {}) => ({ path: `marketing/instagram/p1/${n}.jpg`, kind: "image", contentType: "image/jpeg", width: 1080, height: 1350, ...extra });
const caller = { uid: "koby" };
const connected = () => ({
  "admin_config/instagram_private": { accessToken: "TOKEN", userId: "17841" },
  "admin_config/instagram": { connected: true, refreshedAt: Timestamp.fromMillis(Date.now()), insightsAt: Timestamp.fromMillis(Date.now()) },
});

// ---------------------------------------------------------------- pure

test("problems: type and media count", () => {
  assert.deepEqual(problems({ type: "image", media: [img(1)], caption: "שלום" }), []);
  assert.match(problems({ type: "image", media: [img(1), img(2)], caption: "x" }).join(), /exactly one image/);
  assert.match(problems({ type: "carousel", media: [img(1)], caption: "x" }).join(), /2 to 10/);
  assert.match(problems({ type: "reel", media: [img(1)], caption: "x" }).join(), /one video/);
  assert.deepEqual(problems({ type: "story", media: [img(1, { width: 1080, height: 1920 })], caption: "" }), []);
});

test("problems: feed aspect ratio, caption limits and the creative rule", () => {
  assert.match(problems({ type: "image", media: [img(1, { height: 2000 })], caption: "x" }).join(), /4:5/);
  assert.match(problems({ type: "image", media: [img(1)], caption: "" }).join(), /empty/);
  assert.match(problems({ type: "image", media: [img(1)], caption: "x".repeat(2201) }).join(), /2201/);
  const tags = Array.from({ length: 31 }, (_, i) => `#t${i}`).join(" ");
  assert.equal(hashtags(tags), 31);
  assert.match(problems({ type: "image", media: [img(1)], caption: tags }).join(), /hashtags/);
  for (const bad of ["עכשיו בפרימיום", "Try EasyPlate Pro", "מנוי חודשי", "רק 9.90 ₪", "free trial", "בחינם לגמרי"]) {
    assert.match(problems({ type: "image", media: [img(1)], caption: bad }).join(), /creative rule/, bad);
  }
  // Grocery prices are a feature, not the app's price.
  assert.deepEqual(problems({ type: "image", media: [img(1)], caption: "סורקים קבלה ורואים מחיר לכל מוצר" }), []);
});

test("cleanPost refuses media outside the marketing folder or of the wrong type", () => {
  assert.ok(cleanPost({ type: "image", media: [{ path: "recipe_images/u/x.jpg", contentType: "image/jpeg" }] }).error);
  assert.ok(cleanPost({ type: "image", media: [{ path: "marketing/instagram/p/x.png", contentType: "image/png" }] }).error);
  assert.ok(cleanPost({ type: "image", media: [{ path: "marketing/instagram/../x.jpg", contentType: "image/jpeg" }] }).error);
  assert.ok(cleanPost({ type: "weird", media: [img(1)] }).error);
  const { post } = cleanPost({ type: "image", media: [img(1)], caption: " hi \r\n", source: "claude" });
  assert.equal(post.caption, "hi");
  assert.equal(post.source, "claude");
  assert.equal(post.media[0].kind, "image");
});

test("containerRequests builds a carousel's children and parent", () => {
  const { children, parent } = containerRequests({ type: "carousel", caption: "c", media: [img(1), { kind: "video" }] }, ["u1", "u2"]);
  assert.deepEqual(children, [{ image_url: "u1", is_carousel_item: "true" }, { media_type: "VIDEO", video_url: "u2", is_carousel_item: "true" }]);
  assert.deepEqual(parent, { media_type: "CAROUSEL", caption: "c" });
  assert.equal(containerRequests({ type: "reel", caption: "r", media: [{ kind: "video" }] }, ["v"]).parent.media_type, "REELS");
  assert.equal(containerRequests({ type: "story", media: [img(1)] }, ["s"]).parent.caption, undefined);
});

// ---------------------------------------------------------------- flow

test("save → approve → publish a carousel, never twice", async () => {
  const db = fakeDb(connected());
  const bucket = fakeBucket([img(1).path, img(2).path]);
  let n = 0;
  const { calls, fetchImpl } = fakeGraph({
    "POST 17841/media": () => ({ id: `c${++n}` }),
    "GET c\\d+": { status_code: "FINISHED" },
    "POST 17841/media_publish": { id: "m1" },
    "GET m1": { permalink: "https://www.instagram.com/p/abc/" },
  });
  const saved = await ig.internals.savePost(db, bucket, { type: "carousel", caption: "שלום #מתכונים", media: [img(1), img(2)] }, caller);
  assert.equal(saved.status, "draft");
  await assert.rejects(ig.internals.publishNow(db, bucket, saved.id, { fetchImpl, deadline: Date.now() + 10000 }), /approved/);
  await ig.internals.approve(db, saved.id, caller);
  const out = await ig.internals.publishNow(db, bucket, saved.id, { fetchImpl, deadline: Date.now() + 10000 });
  assert.equal(out.permalink, "https://www.instagram.com/p/abc/");
  const doc = db.store.get(`instagram_posts/${saved.id}`);
  assert.equal(doc.status, "published");
  assert.equal(doc.published.mediaId, "m1");
  const parent = calls.find((c) => c.path === "17841/media" && c.params.media_type === "CAROUSEL");
  assert.equal(parent.params.children, "c1,c2");
  assert.match(calls.find((c) => c.params.is_carousel_item).params.image_url, /^https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/easy-plate\.firebasestorage\.app\/o\/marketing%2Finstagram%2Fp1%2F1\.jpg\?alt=media&token=/);
  assert.ok(calls.every((c) => c.params.access_token === "TOKEN"));
  await assert.rejects(ig.internals.publishNow(db, bucket, saved.id, { fetchImpl, deadline: Date.now() + 10000 }), /already/);
});

test("editing an approved or scheduled post sends it back to draft and drops the schedule", async () => {
  const db = fakeDb(connected());
  const bucket = fakeBucket([img(1).path, img(2).path]);
  const { id } = await ig.internals.savePost(db, bucket, { type: "image", caption: "a", media: [img(1)] }, caller);
  await ig.internals.approve(db, id, caller);
  await ig.internals.schedule(db, id, Date.now() + 3600000, caller);
  assert.equal(db.store.get(`instagram_posts/${id}`).status, "scheduled");
  await ig.internals.savePost(db, bucket, { id, type: "image", caption: "b", media: [img(2)] }, caller);
  const doc = db.store.get(`instagram_posts/${id}`);
  assert.equal(doc.status, "draft");
  assert.equal(doc.scheduledAt, undefined);
  // The replaced image is removed from the bucket.
  assert.equal(bucket.files.has(img(1).path), false);
});

test("approve refuses a post that breaks a rule; schedule needs approval and a future time", async () => {
  const db = fakeDb(connected());
  const bucket = fakeBucket([img(1).path]);
  const { id } = await ig.internals.savePost(db, bucket, { type: "image", caption: "עכשיו בפרימיום", media: [img(1)] }, caller);
  await assert.rejects(ig.internals.approve(db, id, caller), /creative rule/);
  await assert.rejects(ig.internals.schedule(db, id, Date.now() + 3600000, caller), /approve/);
  await ig.internals.savePost(db, bucket, { id, type: "image", caption: "מתכון חדש", media: [img(1)] }, caller);
  await ig.internals.approve(db, id, caller);
  await assert.rejects(ig.internals.schedule(db, id, Date.now() + 1000, caller), /minute/);
});

test("save refuses a file that is not in the bucket", async () => {
  const db = fakeDb();
  await assert.rejects(ig.internals.savePost(db, fakeBucket([]), { type: "image", caption: "a", media: [img(1)] }, caller), /missing file/);
});

test("runner publishes only due scheduled posts and marks a stuck one failed", async () => {
  const now = Date.now();
  const ts = Timestamp.fromMillis;
  const base = { type: "image", caption: "x", media: [img(1)] };
  const db = fakeDb({
    ...connected(),
    "instagram_posts/due": { ...base, status: "scheduled", scheduledAt: ts(now - 1000) },
    "instagram_posts/later": { ...base, status: "scheduled", scheduledAt: ts(now + 3600000) },
    "instagram_posts/stuck": { ...base, status: "publishing", publishingSince: ts(now - ig.internals.STUCK_MS - 1000) },
  });
  const bucket = fakeBucket([img(1).path]);
  const { fetchImpl } = fakeGraph({
    "POST 17841/media": { id: "c1" },
    "GET c1": { status_code: "FINISHED" },
    "POST 17841/media_publish": { id: "m9" },
    "GET m9": { permalink: "https://www.instagram.com/p/z/" },
  });
  const result = await ig.runDue(db, bucket, { fetchImpl, now });
  assert.equal(result.published, 1);
  assert.equal(result.stuck, 1);
  assert.equal(db.store.get("instagram_posts/due").status, "published");
  assert.equal(db.store.get("instagram_posts/later").status, "scheduled");
  assert.equal(db.store.get("instagram_posts/stuck").status, "failed");
});

test("a failed publish records the reason and frees the post", async () => {
  const db = fakeDb({ ...connected(), "instagram_posts/p": { type: "image", caption: "x", media: [img(1)], status: "approved" } });
  const { fetchImpl } = fakeGraph({ "POST 17841/media": { error: { message: "Invalid image", code: 9004 } } });
  await assert.rejects(ig.internals.publishNow(db, fakeBucket([img(1).path]), "p", { fetchImpl, deadline: Date.now() + 5000 }), /Invalid image/);
  const doc = db.store.get("instagram_posts/p");
  assert.equal(doc.status, "failed");
  assert.match(doc.error, /Invalid image/);
  assert.equal(doc.publishingSince, undefined);
});

test("connect stores the token apart from what the console reads", async () => {
  const db = fakeDb();
  const { fetchImpl } = fakeGraph({ "GET me": { user_id: "17841", username: "easyplate.app", followers_count: 12 } });
  const out = await ig.internals.connect(db, fetchImpl, "IGAAx".padEnd(40, "z"));
  assert.equal(out.account.username, "easyplate.app");
  assert.equal(db.store.get("admin_config/instagram_private").accessToken, "IGAAx".padEnd(40, "z"));
  assert.equal(JSON.stringify(db.store.get("admin_config/instagram")).includes("IGAAx"), false);
  await assert.rejects(ig.internals.connect(db, fetchImpl, "short"), /token/);
});

test("an expired token surfaces as ig_token, not a server error", async () => {
  const db = fakeDb(connected());
  const { fetchImpl } = fakeGraph({ "GET me": { error: { message: "Error validating access token", code: 190 } } });
  const out = await ig.internals.accountInfo(db, fetchImpl);
  assert.equal(out.tokenExpired, true);
});

test("comment replies obey the creative rule", async () => {
  const db = fakeDb(connected());
  const { calls, fetchImpl } = fakeGraph({ "POST 555/replies": { id: "r1" } });
  await assert.rejects(ig.internals.replyComment(db, fetchImpl, "555", "יש גרסת פרימיום"), /creative rule/);
  assert.deepEqual(await ig.internals.replyComment(db, fetchImpl, "555", "תודה! 🙏"), { id: "r1" });
  assert.equal(calls[0].params.message, "תודה! 🙏");
});
