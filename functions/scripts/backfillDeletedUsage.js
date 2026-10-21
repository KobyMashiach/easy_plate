// One-off: the AI usage traces of accounts that no longer exist. Until pass
// 9 an account's deletion (deleteAccount.js, the console's user.delete) left
// its ai_calls rows, its entry in each day's `users` map, its
// ai_daily/{day}/users/{uid} documents and its ai_usage/{uid} totals behind,
// all naming the uid. Deletions since then clean up as they go
// (aiUsage.deleteUserUsage); this finds what the earlier ones left.
//
//   node scripts/backfillDeletedUsage.js            # dry run: counts per uid
//   node scripts/backfillDeletedUsage.js --apply    # removes them
//
// A uid counts as deleted when Auth has no user for it AND users/{uid} is
// gone — both, so a profile mid-creation or an Auth record mid-import is
// never swept. Persona uids (seed_…, no Auth user by design) are skipped.
// Needs application-default credentials (gcloud auth application-default login).
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

const PAGE = 1000;
const AUTH_LOOKUP = 100;
const PERSONA_PREFIX = "seed_";

/// Pure: of the uids seen in the usage log, the ones with no account behind
/// them. `authMissing` and `profileMissing` are sets of uids each lookup
/// could not find; a uid is deleted only when both say so.
function deletedUids(seen, authMissing, profileMissing) {
  return [...seen]
    .filter((uid) => typeof uid === "string" && uid && !uid.includes("/") && !uid.startsWith(PERSONA_PREFIX))
    .filter((uid) => authMissing.has(uid) && profileMissing.has(uid))
    .sort();
}

/// Pure: one line of the report per deleted uid, and the totals.
function summarize(perUid) {
  const totals = { uids: 0, calls: 0, dayMapEntries: 0, dayUserDocs: 0, usageDocs: 0 };
  const rows = [];
  for (const [uid, c] of Object.entries(perUid).sort()) {
    totals.uids++;
    totals.calls += c.calls;
    totals.dayMapEntries += c.dayMapEntries;
    totals.dayUserDocs += c.dayUserDocs;
    totals.usageDocs += c.usageDoc ? 1 : 0;
    rows.push({ uid, ...c });
  }
  return { totals, rows };
}

// Every uid the usage log names: ai_usage document ids, ai_calls rows (paged,
// uid only), each day's `users` map keys and each day's users subcollection.
async function collectSeen(db) {
  const seen = new Set();
  const dayMap = new Map(); // uid → number of day maps naming it
  const dayDocs = new Map(); // uid → number of ai_daily/*/users/{uid} docs
  const usage = await db.collection("ai_usage").select().get();
  for (const doc of usage.docs) seen.add(doc.id);
  let cursor = null;
  for (;;) {
    let query = db.collection("ai_calls").orderBy("__name__").select("uid").limit(PAGE);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    for (const doc of page.docs) if (typeof doc.get("uid") === "string") seen.add(doc.get("uid"));
    if (page.size < PAGE) break;
    cursor = page.docs[page.docs.length - 1];
  }
  const days = await db.collection("ai_daily").select("users").get();
  for (const day of days.docs) {
    const users = day.get("users");
    if (users && typeof users === "object") {
      for (const uid of Object.keys(users)) {
        seen.add(uid);
        dayMap.set(uid, (dayMap.get(uid) || 0) + 1);
      }
    }
    const subs = await day.ref.collection("users").select().get();
    for (const doc of subs.docs) {
      seen.add(doc.id);
      dayDocs.set(doc.id, (dayDocs.get(doc.id) || 0) + 1);
    }
  }
  return { seen, dayMap, dayDocs, usageIds: new Set(usage.docs.map((d) => d.id)) };
}

async function missingInAuth(auth, uids) {
  const missing = new Set();
  for (let i = 0; i < uids.length; i += AUTH_LOOKUP) {
    const chunk = uids.slice(i, i + AUTH_LOOKUP);
    const result = await auth.getUsers(chunk.map((uid) => ({ uid })));
    for (const id of result.notFound) if (id.uid) missing.add(id.uid);
  }
  return missing;
}

async function missingProfiles(db, uids) {
  const missing = new Set();
  for (let i = 0; i < uids.length; i += 300) {
    const chunk = uids.slice(i, i + 300);
    const snaps = await db.getAll(...chunk.map((uid) => db.doc(`users/${uid}`)), { fieldMask: [] });
    snaps.forEach((snap, j) => {
      if (!snap.exists) missing.add(chunk[j]);
    });
  }
  return missing;
}

async function run(db, auth, { apply = false, log = console.log } = {}) {
  const { seen, dayMap, dayDocs, usageIds } = await collectSeen(db);
  const candidates = [...seen].filter((uid) => typeof uid === "string" && uid && !uid.includes("/") && !uid.startsWith(PERSONA_PREFIX));
  const [authMissing, profileMissing] = await Promise.all([missingInAuth(auth, candidates), missingProfiles(db, candidates)]);
  const deleted = deletedUids(seen, authMissing, profileMissing);
  const perUid = {};
  for (const uid of deleted) {
    const calls = (await db.collection("ai_calls").where("uid", "==", uid).count().get()).data().count;
    perUid[uid] = { calls, dayMapEntries: dayMap.get(uid) || 0, dayUserDocs: dayDocs.get(uid) || 0, usageDoc: usageIds.has(uid) };
  }
  const report = summarize(perUid);
  const result = { apply, seen: seen.size, candidates: candidates.length, authMissingOnly: [...authMissing].filter((u) => !profileMissing.has(u)).length, ...report.totals, rows: report.rows };
  if (apply) {
    const { deleteUserUsage } = require("../aiUsage");
    let removed = 0;
    for (const uid of deleted) {
      await deleteUserUsage(db, uid);
      await db.doc(`ai_usage/${uid}`).delete();
      removed++;
    }
    result.removed = removed;
  }
  log(JSON.stringify(result, null, 2));
  return result;
}

module.exports = { deletedUids, summarize, run, PERSONA_PREFIX };

if (require.main === module) {
  initializeApp({ credential: applicationDefault(), projectId: process.env.GCLOUD_PROJECT || "easy-plate" });
  run(getFirestore(), getAuth(), { apply: process.argv.includes("--apply") }).catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
