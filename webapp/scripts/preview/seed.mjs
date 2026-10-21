// Seeds the Firebase emulators (project demo-easyplate) with one signed-in
// test account and the Hebrew sample data the native store screenshots show
// (sample-data.json). Admin SDK, emulators only: the script refuses to run
// unless every *_EMULATOR_HOST it uses points at this machine.
//
//   npm run preview:seed            (emulators already running: npm run preview:emulators)
//   node scripts/preview/seed.mjs --household   also puts the account in a Pro Family household
//
// Every collection record is the sample's Dart-shaped JSON, written as is to
// users/{uid}/{collection}/{id} (or households/{hid}/… with --household) —
// the same documents the app and the web app write (lib/cloud.ts).
import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
export const PROJECT = "demo-easyplate";
export const PORTS = { auth: 9299, firestore: 8288, storage: 9399, functions: 5299 };
export const BUCKET = `${PROJECT}.appspot.com`;

export function loadSample() {
  return JSON.parse(readFileSync(join(here, "sample-data.json"), "utf8"));
}

function emulatorEnv() {
  process.env.GCLOUD_PROJECT = PROJECT;
  process.env.FIRESTORE_EMULATOR_HOST ||= `127.0.0.1:${PORTS.firestore}`;
  process.env.FIREBASE_AUTH_EMULATOR_HOST ||= `127.0.0.1:${PORTS.auth}`;
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ||= `127.0.0.1:${PORTS.storage}`;
  for (const k of ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST", "FIREBASE_STORAGE_EMULATOR_HOST"]) {
    if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env[k])) throw new Error(`${k}=${process.env[k]} is not a local emulator — refusing to seed`);
  }
}

// firebase-admin is the functions' dependency; the web app adds none.
function admin() {
  const require = createRequire(join(here, "../../../functions/package.json"));
  return require("firebase-admin");
}

async function clearEmulators() {
  const fsHost = process.env.FIRESTORE_EMULATOR_HOST;
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const del = (url) => fetch(url, { method: "DELETE", headers: { Authorization: "Bearer owner" } }).then((r) => {
    if (!r.ok) throw new Error(`DELETE ${url} → ${r.status}`);
  });
  await del(`http://${fsHost}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  await del(`http://${authHost}/emulator/v1/projects/${PROJECT}/accounts`);
}

const ago = (days, Timestamp) => Timestamp.fromMillis(Date.now() - Math.round(days * 86_400_000));

export async function seed({ household = false, quiet = false } = {}) {
  emulatorEnv();
  const sample = loadSample();
  const a = admin();
  const app = a.apps.length ? a.app() : a.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
  const { Timestamp } = a.firestore;
  const db = app.firestore();
  const bucket = app.storage().bucket(BUCKET);
  const log = (...m) => quiet || console.log(...m);

  await clearEmulators();
  try {
    const [files] = await bucket.getFiles();
    await Promise.all(files.map((f) => f.delete()));
  } catch (_) {
    // Empty bucket.
  }

  // ── The account: phone verified (the gate), email/password for convenience.
  const u = sample.user;
  await app.auth().createUser({ uid: u.uid, email: u.email, emailVerified: true, password: u.password, phoneNumber: u.phoneNumber, displayName: u.fullName });
  for (const p of sample.people) await app.auth().createUser({ uid: p.uid, displayName: p.fullName });
  log(`auth: ${u.uid} (${u.phoneNumber}) + ${sample.people.length} other cooks`);

  // ── Photos: the account's own under recipe_images/{uid}/, the community
  // authors' under theirs (the storage paths the records carry).
  const upload = (key, owner) =>
    bucket.file(`recipe_images/${owner}/${key}.jpg`).save(readFileSync(join(here, sample.images[key])), { contentType: "image/jpeg", resumable: false });
  await Promise.all(Object.keys(sample.images).map((k) => upload(k, u.uid)));
  const authored = sample.shared_recipes.filter((s) => s.imageKey);
  await Promise.all(authored.map((s) => upload(s.imageKey, s.authorUid)));
  log(`storage: ${Object.keys(sample.images).length + authored.length} photos`);

  const batch = db.batch();
  const set = (path, data) => batch.set(db.doc(path), data);
  const now = Timestamp.now();

  set(`users/${u.uid}`, { fullName: u.fullName, email: u.email, photoUrl: null, createdAt: ago(40, Timestamp) });
  set(`public_profiles/${u.uid}`, { fullName: u.fullName, photoUrl: null });
  for (const p of sample.people) set(`public_profiles/${p.uid}`, { fullName: p.fullName, photoUrl: null });
  // Premium, the way the RevenueCat webhook writes it.
  set(`entitlements/${u.uid}`, {
    premium: true,
    premiumFrom: ago(20, Timestamp),
    premiumUntil: Timestamp.fromMillis(Date.now() + 345 * 86_400_000),
    source: "revenuecat",
    productId: u.productId,
    store: u.store,
    cancelAtPeriodEnd: false,
    updatedAt: now,
  });

  // ── The account's records (Dart toJson shapes).
  const hh = sample.household;
  const sharedRoot = household ? `households/${hh.id}` : `users/${u.uid}`;
  if (household) {
    set(`households/${hh.id}`, { ownerUid: u.uid, tier: hh.tier, seats: hh.seats, title: hh.title, memberUids: [u.uid, "cook-rachel"], createdAt: ago(10, Timestamp) });
  }
  const shared = ["recipes", "books", "meal_plans", "grocery_lists", "receipts", "price_records", "product_pricing"];
  for (const name of shared) {
    for (const rec of sample[name]) set(`${sharedRoot}/${name}/${name === "product_pricing" ? rec.key : rec.id}`, rec);
  }
  set(`users/${u.uid}/preferences/current`, sample.preferences);
  set(`users/${u.uid}/usage/current`, sample.usage);

  // ── Community feed (copies of recipes, with likes).
  const authorName = (uid) => (uid === u.uid ? u.fullName : sample.people.find((p) => p.uid === uid)?.fullName ?? "");
  for (const s of sample.shared_recipes) {
    set(`shared_recipes/${s.id}`, {
      sourceRecipeId: s.id,
      title: s.title,
      prepTimeMinutes: s.prepTimeMinutes,
      cookTimeMinutes: s.cookTimeMinutes,
      ingredients: s.ingredients,
      steps: s.steps,
      dietaryTags: s.dietaryTags,
      allergens: [],
      mayContain: [],
      imageFileName: s.imageKey ? `${s.imageKey}.jpg` : null,
      imageStoragePath: s.imageKey ? `recipe_images/${s.authorUid}/${s.imageKey}.jpg` : null,
      servings: s.servings,
      nutrition: s.nutrition,
      authorUid: s.authorUid,
      authorName: authorName(s.authorUid),
      authorPhotoUrl: null,
      likeCount: s.likeCount,
      createdAt: ago(s.daysAgo, Timestamp),
    });
    if (s.likedByMe) set(`shared_recipes/${s.id}/likes/${u.uid}`, { createdAt: now });
  }

  // ── Forum threads and replies.
  for (const p of sample.forum_posts) {
    set(`forum_posts/${p.id}`, {
      title: p.title,
      body: p.body,
      authorUid: p.authorUid,
      authorName: authorName(p.authorUid),
      authorPhotoUrl: null,
      createdAt: ago(p.daysAgo, Timestamp),
      replyCount: p.replies.length,
      likeCount: p.likeCount,
    });
    if (p.likedByMe) set(`forum_posts/${p.id}/likes/${u.uid}`, { createdAt: now });
    for (const r of p.replies) {
      set(`forum_posts/${p.id}/replies/${r.id}`, {
        body: r.body,
        authorUid: r.authorUid,
        authorName: authorName(r.authorUid),
        authorPhotoUrl: null,
        createdAt: ago(r.daysAgo, Timestamp),
        sharedRecipeId: r.sharedRecipeId,
        sharedRecipeTitle: r.sharedRecipeTitle,
        likeCount: r.likeCount,
      });
    }
  }

  // ── Sharing: one recipe this account shares (two members), one invite to it.
  for (const c of sample.collab_recipes) {
    const body = c.recipeId ? sample.recipes.find((r) => r.id === c.recipeId) : { ...c.inline, prepTimeMinutes: null, cookTimeMinutes: null, allergens: [], mayContain: [], imageFileName: null, imageStoragePath: null, servings: null, nutrition: null };
    set(`collab_recipes/${c.id}`, {
      title: body.title,
      prepTimeMinutes: body.prepTimeMinutes,
      cookTimeMinutes: body.cookTimeMinutes,
      ingredients: body.ingredients,
      steps: body.steps,
      dietaryTags: body.dietaryTags,
      allergens: body.allergens,
      mayContain: body.mayContain,
      imageFileName: body.imageFileName,
      imageStoragePath: body.imageStoragePath,
      servings: body.servings,
      nutrition: body.nutrition,
      ownerUid: c.ownerUid,
      members: c.members,
      memberUids: Object.keys(c.members),
      createdAt: ago(c.daysAgo, Timestamp),
      updatedAt: ago(c.daysAgo, Timestamp),
      updatedBy: c.ownerUid,
    });
  }
  for (const i of sample.share_invites) {
    set(`share_invites/${i.collabId}_${i.targetUid}`, {
      collabId: i.collabId,
      recipeTitle: i.title,
      ownerUid: i.ownerUid,
      targetUid: i.targetUid,
      role: i.role,
      status: i.status,
      ...(i.kind ? { kind: i.kind } : {}),
      createdAt: ago(i.daysAgo, Timestamp),
    });
  }

  // ── Inbox.
  for (const n of sample.notifications) {
    const { id, daysAgo, ...fields } = n;
    set(`notifications/${u.uid}/items/${id}`, { ...fields, createdAt: ago(daysAgo, Timestamp) });
  }

  // ── Support conversation.
  for (const f of sample.feedback) {
    set(`feedback/${f.id}`, {
      authorUid: u.uid,
      type: f.type,
      message: f.message,
      createdAt: ago(f.daysAgo, Timestamp),
      updatedAt: ago(Math.min(...f.replies.map((r) => r.daysAgo), f.daysAgo), Timestamp),
      followUps: f.followUps.map((l) => ({ text: l.text, at: ago(l.daysAgo, Timestamp) })),
      replies: f.replies.map((l) => ({ text: l.text, at: ago(l.daysAgo, Timestamp) })),
      userUnread: f.userUnread,
      status: f.status,
      source: f.source,
    });
  }

  await batch.commit();
  log(
    `firestore: ${sample.recipes.length} recipes, ${sample.books.length} books, ${sample.meal_plans.length} plans, ${sample.grocery_lists.length} lists, ` +
      `${sample.receipts.length} receipts, ${sample.price_records.length} prices, ${sample.shared_recipes.length} feed posts, ${sample.forum_posts.length} threads, ` +
      `${sample.notifications.length} inbox items${household ? `, household ${hh.id}` : ""} (root ${sharedRoot})`,
  );
  return { uid: u.uid, sample };
}

/** A custom token for the test account (unsigned: the Auth emulator accepts it). */
export async function customToken(uid) {
  emulatorEnv();
  const a = admin();
  const app = a.apps.length ? a.app() : a.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
  return app.auth().createCustomToken(uid);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  seed({ household: process.argv.includes("--household") }).then(
    () => process.exit(0),
    (e) => {
      console.error(e);
      process.exit(1);
    },
  );
}
