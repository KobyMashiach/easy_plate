// One-off: accepted share invites whose target is no longer on the shared
// document's roster. The accept rule (firestore.rules, collab_recipes /
// collab_containers) only asks for an invite marked "accepted" that the
// owner sent to the caller — so a member the owner removed could add
// themselves straight back with the invite they accepted the first time.
// The clients now delete the invite in the same batch as the removal; this
// clears the ones left from before. An invite whose document is gone is
// stale too.
//
//   node scripts/cleanupStaleInvites.js            # dry run: counts + a sample
//   node scripts/cleanupStaleInvites.js --apply    # deletes them
//
// Needs application-default credentials (gcloud auth application-default login).
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore, FieldPath } = require("firebase-admin/firestore");

const PAGE = 300;

/// Pure: why an accepted invite no longer stands, or null when it does.
/// [collab] is the shared document's data (null when it is gone).
function staleReason(invite, collab) {
  if (!collab) return "collab_gone";
  const members = Array.isArray(collab.memberUids) ? collab.memberUids : [];
  if (!members.includes(invite.targetUid)) return "not_a_member";
  if (collab.ownerUid !== invite.ownerUid) return "owner_changed";
  return null;
}

async function run(db, { apply = false, log = console.log } = {}) {
  const counts = { accepted: 0, stale: 0, collab_gone: 0, not_a_member: 0, owner_changed: 0, deleted: 0 };
  const sample = [];
  let cursor = null;
  for (;;) {
    let query = db.collection("share_invites").where("status", "==", "accepted").orderBy(FieldPath.documentId()).limit(PAGE);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    const invites = page.docs.filter((d) => typeof d.get("collabId") === "string" && d.get("collabId") && !d.get("collabId").includes("/"));
    const ids = [...new Set(invites.map((d) => d.get("collabId")))];
    const refs = ids.flatMap((id) => [db.doc(`collab_recipes/${id}`), db.doc(`collab_containers/${id}`)]);
    const snaps = refs.length ? await db.getAll(...refs) : [];
    const collabs = new Map();
    for (const snap of snaps) if (snap.exists && !collabs.has(snap.id)) collabs.set(snap.id, snap.data());
    const batch = db.batch();
    let pending = 0;
    for (const doc of invites) {
      counts.accepted++;
      const reason = staleReason(doc.data(), collabs.get(doc.get("collabId")) || null);
      if (!reason) continue;
      counts.stale++;
      counts[reason]++;
      if (sample.length < 20) sample.push({ id: doc.id, reason });
      if (apply) {
        batch.delete(doc.ref);
        pending++;
      }
    }
    if (pending) {
      await batch.commit();
      counts.deleted += pending;
    }
    if (page.size < PAGE) break;
    cursor = page.docs[page.docs.length - 1].id;
  }
  log(JSON.stringify({ apply, ...counts, sample }, null, 2));
  return { counts, sample };
}

module.exports = { staleReason, run };

if (require.main === module) {
  initializeApp({ credential: applicationDefault(), projectId: process.env.GCLOUD_PROJECT || "easy-plate" });
  run(getFirestore(), { apply: process.argv.includes("--apply") }).catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
