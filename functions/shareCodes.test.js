const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { normalizeCode, rejectReason, recipeCollabIdsIn, redeem } = require("./shareCodes").internals;

test("codes are normalised from what people type", () => {
  assert.equal(normalizeCode("ep-7k3m 9qx2"), "7K3M9QX2");
  assert.equal(normalizeCode("7K3M9QX2"), "7K3M9QX2");
  assert.equal(normalizeCode("EP7K3M9QX2"), "7K3M9QX2");
  // A bare code that happens to start with E and P is the code itself.
  assert.equal(normalizeCode("EPXK3M9Q"), "EPXK3M9Q");
  assert.equal(normalizeCode("ep-xk3m-9q"), "EPXK3M9Q");
  assert.equal(normalizeCode("EP-EPXK-3M9Q"), "EPXK3M9Q");
  assert.equal(normalizeCode("abc"), null);
  assert.equal(normalizeCode("7K3M9QX0"), null); // 0 and 1 are not in the alphabet
  assert.equal(normalizeCode(42), null);
});

test("a code is refused when revoked, expired, used up, missing or the owner's own", () => {
  const ts = (ms) => ({ toMillis: () => ms });
  const now = 1_000_000;
  const base = { kind: "recipe", ownerUid: "owner", targetId: "c1", uses: 0 };
  assert.equal(rejectReason(null, "u", now), "not_found");
  assert.equal(rejectReason({ ...base, revoked: true }, "u", now), "revoked");
  assert.equal(rejectReason({ ...base, expiresAt: ts(now - 1) }, "u", now), "expired");
  assert.equal(rejectReason({ ...base, expiresAt: ts(now + 1) }, "u", now), null);
  assert.equal(rejectReason({ ...base, maxUses: 1, uses: 1 }, "u", now), "used_up");
  assert.equal(rejectReason({ ...base, maxUses: 2, uses: 1 }, "u", now), null);
  assert.equal(rejectReason(base, "owner", now), "self");
  assert.equal(rejectReason({ ...base, kind: "pizza" }, "u", now), "not_found");
});

test("recipe ids are read from both container shapes", () => {
  assert.deepEqual(recipeCollabIdsIn({ recipes: [{ collabId: "a" }, { collabId: "b" }, {}] }), ["a", "b"]);
  assert.deepEqual(recipeCollabIdsIn({ meals: [{ items: [{ recipeCollabId: "x" }, { freeText: "soup" }] }, { items: [{ recipeCollabId: "x" }] }] }), ["x"]);
  assert.deepEqual(recipeCollabIdsIn(null), []);
});

// A Firestore stand-in with what redeem uses: documents by path, one
// array-contains query, and a transaction whose reads and writes land on the
// same map. The transaction body runs once; the ordering rule (reads before
// writes) is Firestore's, so the fake fails a read after a write the same way.
function fakeDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  let wrote = false;
  const snapOf = (path) => {
    const data = store.get(path);
    return { exists: store.has(path), id: path.split("/").pop(), data: () => data, get: (f) => (data || {})[f] };
  };
  const docRef = (path) => ({
    path,
    id: path.split("/").pop(),
    get: async () => snapOf(path),
    collection: (name) => collection(`${path}/${name}`),
  });
  const collection = (name) => ({
    doc: (id) => docRef(`${name}/${id}`),
    where: (field, op, value) => ({
      limit: () => ({
        get: async () => {
          const docs = [...store.entries()]
            .filter(([path, data]) => path.startsWith(`${name}/`) && path.split("/").length === name.split("/").length + 1 && Array.isArray(data[field]) && data[field].includes(value))
            .map(([path]) => snapOf(path));
          return { empty: docs.length === 0, docs };
        },
      }),
    }),
  });
  const guardRead = () => {
    if (wrote) throw new Error("Firestore transactions require all reads to be executed before all writes");
  };
  const write = (ref, data, merge) => {
    wrote = true;
    store.set(ref.path, merge ? { ...(store.get(ref.path) || {}), ...data } : data);
  };
  const tx = {
    get: (target) => { guardRead(); return target.get(); },
    getAll: (...refs) => { guardRead(); return Promise.all(refs.map((r) => r.get())); },
    set: (ref, data, opts) => write(ref, data, !!(opts && opts.merge)),
    update: (ref, data) => {
      if (!store.has(ref.path)) throw new Error(`no document to update at ${ref.path}`);
      write(ref, data, true);
    },
  };
  return { store, collection, runTransaction: async (fn) => { wrote = false; return fn(tx); } };
}

const CODE = "7K3M9QX2";
const codeDoc = (over = {}) => ({ kind: "recipe", ownerUid: "owner", targetId: "c1", role: "editor", title: "Soup", uses: 0, revoked: false, ...over });

test("a member the owner removed is re-invited, not told 'already', even though the old invite says accepted", async () => {
  const db = fakeDb({
    [`share_codes/${CODE}`]: codeDoc(),
    "collab_recipes/c1": { ownerUid: "owner", title: "Soup", memberUids: ["owner"], members: { owner: "owner" } },
    "share_invites/c1_bob": { collabId: "c1", ownerUid: "owner", targetUid: "bob", status: "accepted", role: "viewer" },
  });
  const out = await redeem(db, CODE, "bob");
  assert.equal(out.already, undefined);
  assert.equal(out.invite.id, "c1_bob");
  assert.equal(out.invite.role, "editor");
  const invite = db.store.get("share_invites/c1_bob");
  assert.equal(invite.status, "pending", "the dead invite is written afresh");
  assert.equal(invite.role, "editor", "with the role the code offers");
  assert.equal(invite.kind, "recipe");
  const item = db.store.get("notifications/bob/items/c1_bob");
  assert.equal(item.type, "shareInvite");
  assert.equal(item.fromUid, "owner");
  assert.ok("uses" in db.store.get(`share_codes/${CODE}`), "the use is counted in the same transaction");
});

test("someone on the roster is 'already', and nothing is written for them", async () => {
  const db = fakeDb({
    [`share_codes/${CODE}`]: codeDoc(),
    "collab_recipes/c1": { ownerUid: "owner", title: "Soup", memberUids: ["owner", "bob"], members: { owner: "owner", bob: "viewer" } },
    "share_invites/c1_bob": { collabId: "c1", ownerUid: "owner", targetUid: "bob", status: "accepted", role: "viewer" },
  });
  assert.deepEqual(await redeem(db, CODE, "bob"), { already: true });
  assert.equal(db.store.get("share_invites/c1_bob").status, "accepted");
  assert.equal(db.store.has("notifications/bob/items/c1_bob"), false);
  assert.equal(db.store.get(`share_codes/${CODE}`).uses, 0);
});

test("the use count is checked and moved inside the transaction; a used-up code is refused before any read of the target", async () => {
  const db = fakeDb({
    [`share_codes/${CODE}`]: codeDoc({ maxUses: 1, uses: 1 }),
    "collab_recipes/c1": { ownerUid: "owner", title: "Soup", memberUids: ["owner"] },
  });
  assert.deepEqual(await redeem(db, CODE, "bob"), { error: "used_up" });
  assert.equal(db.store.has("share_invites/c1_bob"), false);
});

test("a code written by someone who does not own the document is refused as not found", async () => {
  const db = fakeDb({
    [`share_codes/${CODE}`]: codeDoc({ ownerUid: "viewer_mallory" }),
    "collab_recipes/c1": { ownerUid: "owner", title: "Soup", memberUids: ["owner", "viewer_mallory"] },
  });
  assert.deepEqual(await redeem(db, CODE, "bob"), { error: "gone" });
  assert.equal(db.store.has("share_invites/c1_bob"), false);
});

test("a container invite carries silent invites for the owner's recipes inside, re-sending only dead ones", async () => {
  const db = fakeDb({
    [`share_codes/${CODE}`]: codeDoc({ kind: "book", targetId: "b1", title: "Book" }),
    "collab_containers/b1": { ownerUid: "owner", title: "Book", memberUids: ["owner"], content: { recipes: [{ collabId: "r1" }, { collabId: "r2" }, { collabId: "r3" }, { collabId: "r4" }] } },
    "collab_recipes/r1": { ownerUid: "owner", title: "One", memberUids: ["owner"] },
    "collab_recipes/r2": { ownerUid: "owner", title: "Two", memberUids: ["owner"] },
    "collab_recipes/r3": { ownerUid: "someone_else", title: "Three", memberUids: ["someone_else"] },
    "collab_recipes/r4": { ownerUid: "owner", title: "Four", memberUids: ["owner"] },
    // r2: removed from the recipe after accepting → re-sent. r4: still pending → left alone.
    "share_invites/r2_bob": { collabId: "r2", ownerUid: "owner", targetUid: "bob", status: "accepted", role: "viewer" },
    "share_invites/r4_bob": { collabId: "r4", ownerUid: "owner", targetUid: "bob", status: "pending", role: "viewer" },
  });
  const out = await redeem(db, CODE, "bob");
  assert.equal(out.invite.kind, "book");
  assert.equal(db.store.get("share_invites/b1_bob").status, "pending");
  assert.equal(db.store.get("share_invites/r1_bob").via, "b1");
  assert.equal(db.store.get("share_invites/r2_bob").status, "pending");
  assert.equal(db.store.get("share_invites/r2_bob").role, "editor");
  assert.equal(db.store.has("share_invites/r3_bob"), false, "another owner's recipe is not the code owner's to share");
  assert.equal(db.store.get("share_invites/r4_bob").role, "viewer", "a pending invite stands as it was");
  assert.equal(db.store.has("notifications/bob/items/r1_bob"), false, "recipe invites inside a container are silent");
});

test("a household code seats the member in the same transaction as the use count, and only the owner's code does", async () => {
  const seed = () => ({
    [`share_codes/${CODE}`]: codeDoc({ kind: "household", targetId: "h1", title: "" }),
    "households/h1": { ownerUid: "owner", tier: "duo", seats: 2, title: "Home", memberUids: ["owner"], members: { owner: { role: "owner" } } },
    "entitlements/owner": { premium: true, productId: "easy_plate_ai_pro_duo_monthly", source: "stripe" },
  });
  const db = fakeDb(seed());
  const out = await redeem(db, CODE, "bob");
  assert.equal(out.household.id, "h1");
  assert.deepEqual(out.household.memberUids, ["owner", "bob"]);
  assert.ok("uses" in db.store.get(`share_codes/${CODE}`));
  assert.equal(db.store.get("entitlements/bob").source, "household");
  assert.equal(db.store.get("entitlements/bob").premium, true);

  // The last seat is taken: the next one is refused with nothing written.
  const full = fakeDb({ ...seed(), "households/h1": { ...seed()["households/h1"], memberUids: ["owner", "carol"] } });
  assert.deepEqual(await redeem(full, CODE, "bob"), { error: "full" });
  assert.equal(full.store.get(`share_codes/${CODE}`).uses, 0);

  // A member's own code for the owner's household is not honoured.
  const forged = fakeDb({ ...seed(), [`share_codes/${CODE}`]: codeDoc({ kind: "household", targetId: "h1", ownerUid: "carol" }) });
  assert.deepEqual(await redeem(forged, CODE, "bob"), { error: "gone" });
});

test("container recipe ids that would be a path are skipped; an oversized container is refused", async () => {
  const { recipeCollabIdsIn, redeem, MAX_CONTAINER_RECIPES } = require("./shareCodes").internals;
  assert.deepEqual(recipeCollabIdsIn({ recipes: [{ collabId: "a" }, { collabId: "x/y" }, { collabId: ".." }, { collabId: "" }], meals: "nope" }), ["a"]);
  const recipes = Array.from({ length: MAX_CONTAINER_RECIPES + 1 }, (_, i) => ({ collabId: `r${i}` }));
  const writes = [];
  const db = {
    collection: (name) => ({ doc: (id) => ({ path: `${name}/${id}` }) }),
    runTransaction: async (fn) => fn({
      get: async (ref) => (ref.path.startsWith("share_codes/")
        ? { exists: true, data: () => ({ kind: "book", targetId: "b1", ownerUid: "owner", role: "viewer" }) }
        : { exists: true, get: (f) => ({ ownerUid: "owner", memberUids: [], content: { recipes } })[f] }),
      getAll: async () => { throw new Error("not reached"); },
      set: (ref) => writes.push(ref.path),
      update: (ref) => writes.push(ref.path),
    }),
  };
  assert.deepEqual(await redeem(db, "ABCDEFGH", "member"), { error: "too_many_recipes" });
  assert.deepEqual(writes, []);
});

test("an invite's title is a short string whatever the owner stored", () => {
  const { titleOf } = require("./shareCodes").internals;
  assert.equal(titleOf({ a: 1 }, "Book"), "Book");
  assert.equal(titleOf(undefined, 7), "");
  assert.equal(titleOf("x".repeat(5000)).length, 200);
  assert.equal(titleOf("  ", "Plan"), "Plan");
});
