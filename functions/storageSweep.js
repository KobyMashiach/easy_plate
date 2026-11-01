// Weekly sweep of recipe photos nothing points at any more.
//
// `recipe_images/{uid}/…` only ever grows: an upload is a file, and a photo
// replaced in the editor, a recipe deleted on a device that never got to
// remove its picture, or a share that failed half-way all leave one behind,
// up to 5MB each and billed forever. Deleting a picture is deleting user
// data, so this is built to keep anything it is not sure about:
//
//   - Mode from Remote Config `storage_sweep_mode`: 0 off, 1 report only
//     (the in-code fallback, also what an unreadable template means),
//     2 delete. Report mode writes admin_reports/storage_sweep and logs.
//   - Nothing younger than GRACE_DAYS is looked at: the app uploads the
//     photo first and the record that names it syncs afterwards (offline,
//     that can be days).
//   - The files are listed BEFORE the references are read, so a reference
//     written while the run is going is still seen.
//   - Every cap (documents read, files listed, time spent) and every failed
//     read makes the run "incomplete", and an incomplete run deletes
//     nothing whatever the mode: a file not seen referenced in half the
//     database is not an orphan.
//
// What counts as a reference. A photo travels as its Storage *path* (see
// lib/core/sync/recipe_image_store.dart) and is reached by other accounts
// through copies of that path, never of the file. Those copies can sit in:
//
//   users/{uid}/recipes, books, meal_plans,    the cloud mirror of every
//     grocery_lists                           account (CloudSyncService) —
//                                             a recipe saved from the
//                                             community or shared in keeps
//                                             the AUTHOR's path
//   households/{hid}/recipes, books, …         the household root (same
//                                             collection names)
//   shared_recipes                            community posts, incl. the
//                                             console personas' posts
//                                             (adminPanel recipe.create)
//   collab_recipes                            a shared recipe's live doc
//   collab_containers                         shared books/plans/lists —
//                                             content.coverImageStoragePath
//   share_invites                             pending invites
//   forum_posts, replies                      threads that attach a recipe
//   items                                     notifications/{uid}/items,
//                                             the in-app inbox
//   whats_new_releases                        console "what's new" (imageUrl)
//   feedback                                  support threads
//   users                                     the account docs themselves
//
// Each is read as a collection group, so the same name under any parent
// counts. Documents are scanned field-agnostically: any string anywhere in
// a document that contains `recipe_images/…` (or its URL-encoded form, as
// in a download URL the console writes) is a reference, and so is the
// value of any field whose name ends in `FileName` (imageFileName,
// coverImageFileName): the app uploads under the record's own file name,
// and a record whose path write-back was lost still names its file that
// way. A new field that carries a photo is therefore covered without
// touching this file; a new COLLECTION is not — add it to SOURCES.
//
// Not seen, and why it is acceptable: a record that lives only in a
// device's Hive box because its mirror never reached Firestore. The grace
// period covers ordinary delays; mode 2 is a deliberate console switch.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const remoteFlags = require("./remoteFlags");

const PREFIX = "recipe_images/";
const MODE_PARAM = "storage_sweep_mode";
const MODE_FALLBACK = 1;
const MODES = { off: 0, report: 1, delete: 2 };

const GRACE_DAYS = 14;
const DAY_MS = 24 * 60 * 60 * 1000;

// Hard ceilings, so a grown database cannot run the function (or the bill)
// away. Reaching any of them leaves the run incomplete: report only.
const LIMITS = {
  maxDocs: 400000,
  maxFiles: 200000,
  // Within the scheduled function's own timeout, with room to write the
  // report.
  maxMillis: 25 * 60 * 1000,
  // Deletes per run. Not an "incomplete" cap: what is left is deleted next
  // week, with the same checks.
  maxDeletes: 5000,
  // More than this share of the old files unreferenced reads as a scan
  // that missed something (a renamed collection, the wrong project), not as
  // a clean-up: reported, not deleted.
  maxOrphanShare: 0.5,
};
const PAGE = 500;
const FILE_PAGE = 1000;
const SAMPLE = 50;

const SOURCES = [
  "recipes",
  "books",
  "meal_plans",
  "grocery_lists",
  "shared_recipes",
  "collab_recipes",
  "collab_containers",
  "share_invites",
  "forum_posts",
  "replies",
  "items",
  "whats_new_releases",
  "feedback",
  "users",
];

const PATH_RE = /recipe_images\/[^\s"'?#&<>]+/g;

// Pure: collects every photo path and file name one document carries.
// Depth-capped so a pathological document cannot recurse forever.
function collectRefs(value, paths, names, key = "", depth = 0) {
  if (depth > 12 || value === null || value === undefined) return;
  if (typeof value === "string") {
    if (/filename$/i.test(key) && value) names.add(value.split("/").pop());
    if (value.includes("recipe_images")) {
      for (const text of [value, safeDecode(value)]) {
        for (const match of text.matchAll(PATH_RE)) paths.add(match[0]);
      }
    }
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value) collectRefs(item, paths, names, key, depth + 1);
    return;
  }
  // Plain maps only: Timestamps, GeoPoints and references carry no path.
  if (typeof value === "object" && Object.getPrototypeOf(value) === Object.prototype) {
    for (const [k, v] of Object.entries(value)) collectRefs(v, paths, names, k, depth + 1);
  }
}

function safeDecode(text) {
  if (!text.includes("%2F") && !text.includes("%2f")) return text;
  try {
    return decodeURIComponent(text);
  } catch (_) {
    return text;
  }
}

// Pure: whether a listed object is referenced.
function isReferenced(path, refs) {
  return refs.paths.has(path) || refs.names.has(path.split("/").pop());
}

function modeFrom(parameters) {
  const mode = remoteFlags.intFrom(parameters, MODE_PARAM, MODE_FALLBACK);
  return Object.values(MODES).includes(mode) ? mode : MODE_FALLBACK;
}

// Lists recipe_images/ page by page. Returns the old-enough files, plus
// counts of the rest; `incomplete` when a cap or an error stopped it.
async function listFiles(bucket, { now, limits, deadline }) {
  const cutoff = now - GRACE_DAYS * DAY_MS;
  const old = [];
  let listed = 0;
  let young = 0;
  let query = { prefix: PREFIX, maxResults: FILE_PAGE, autoPaginate: false };
  while (query) {
    if (Date.now() > deadline) return { old, listed, young, incomplete: "time" };
    const [files, next] = await bucket.getFiles(query);
    for (const file of files) {
      if (file.name.endsWith("/")) continue;
      listed++;
      if (listed > limits.maxFiles) return { old, listed, young, incomplete: "maxFiles" };
      const created = Date.parse(file.metadata?.timeCreated || "");
      // A file whose age cannot be read is treated as new: kept.
      if (!Number.isFinite(created) || created > cutoff) {
        young++;
        continue;
      }
      old.push({ file, path: file.name, bytes: Number(file.metadata?.size) || 0 });
    }
    query = next && next.pageToken ? { ...query, pageToken: next.pageToken } : null;
  }
  return { old, listed, young, incomplete: null };
}

// Reads every source collection group page by page into one reference set.
async function readRefs(db, { limits, deadline, documentId }) {
  const refs = { paths: new Set(), names: new Set() };
  const perSource = {};
  let docs = 0;
  for (const group of SOURCES) {
    let count = 0;
    let last = null;
    for (;;) {
      if (Date.now() > deadline) return { refs, docs, perSource, incomplete: "time" };
      let query = db.collectionGroup(group);
      if (documentId) query = query.orderBy(documentId);
      query = query.limit(PAGE);
      if (last) query = query.startAfter(last);
      const snap = await query.get();
      for (const doc of snap.docs) {
        collectRefs(doc.data(), refs.paths, refs.names);
      }
      count += snap.docs.length;
      docs += snap.docs.length;
      if (docs > limits.maxDocs) {
        perSource[group] = count;
        return { refs, docs, perSource, incomplete: "maxDocs" };
      }
      if (snap.docs.length < PAGE) break;
      last = snap.docs[snap.docs.length - 1];
    }
    perSource[group] = count;
  }
  return { refs, docs, perSource, incomplete: null };
}

// One run. Everything injectable for the tests; the summary is returned
// and, unless the mode is off, written to admin_reports/storage_sweep.
async function sweep({
  db = admin.firestore(),
  bucket = admin.storage().bucket(),
  params = () => remoteFlags.params(),
  now = Date.now(),
  limits = LIMITS,
  documentId = admin.firestore.FieldPath.documentId(),
  serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp(),
} = {}) {
  const mode = modeFrom(await params());
  if (mode === MODES.off) {
    logger.info("storage sweep off");
    return { mode, skipped: true };
  }
  const deadline = Date.now() + limits.maxMillis;
  const summary = {
    mode,
    graceDays: GRACE_DAYS,
    complete: false,
    incomplete: null,
    files: 0,
    young: 0,
    referenced: 0,
    orphans: 0,
    orphanBytes: 0,
    deleted: 0,
    deletedBytes: 0,
    blocked: null,
    docsScanned: 0,
    perSource: {},
    sample: [],
  };

  let listing;
  let scan;
  try {
    // Files first, references second: see the header.
    listing = await listFiles(bucket, { now, limits, deadline });
    summary.files = listing.listed;
    summary.young = listing.young;
    scan = await readRefs(db, { limits, deadline, documentId });
    summary.docsScanned = scan.docs;
    summary.perSource = scan.perSource;
    summary.incomplete = listing.incomplete || scan.incomplete;
  } catch (err) {
    summary.incomplete = `error: ${String(err?.message || err).slice(0, 200)}`;
  }

  const orphans = [];
  if (listing && scan) {
    for (const entry of listing.old) {
      if (isReferenced(entry.path, scan.refs)) {
        summary.referenced++;
      } else {
        orphans.push(entry);
        summary.orphanBytes += entry.bytes;
      }
    }
  }
  summary.orphans = orphans.length;
  summary.sample = orphans.slice(0, SAMPLE).map((o) => o.path);
  // No reference at all next to old files means the read went wrong.
  if (summary.incomplete === null && listing.old.length > 0 && scan.refs.paths.size === 0 && scan.refs.names.size === 0) {
    summary.incomplete = "no references found";
  }
  summary.complete = summary.incomplete === null;
  const share = listing && listing.old.length ? orphans.length / listing.old.length : 0;
  summary.blocked = share > limits.maxOrphanShare ? `orphan share ${share.toFixed(2)} over ${limits.maxOrphanShare}` : null;

  // Deleting needs both the switch and a full picture of the references.
  if (mode === MODES.delete && summary.complete && !summary.blocked) {
    for (const entry of orphans.slice(0, limits.maxDeletes)) {
      try {
        await entry.file.delete({ ignoreNotFound: true });
        summary.deleted++;
        summary.deletedBytes += entry.bytes;
      } catch (err) {
        logger.warn("storage sweep delete failed", { path: entry.path, reason: err.message });
      }
    }
  }

  const log = summary.complete ? logger.info : logger.warn;
  log("storage sweep", { ...summary, sample: summary.sample.slice(0, 10) });
  try {
    await db.collection("admin_reports").doc("storage_sweep").set({ ...summary, at: serverTimestamp() });
  } catch (err) {
    logger.warn("storage sweep report not written", { reason: err.message });
  }
  return summary;
}

module.exports = {
  sweep,
  internals: { collectRefs, isReferenced, modeFrom, SOURCES, LIMITS, GRACE_DAYS, MODE_PARAM, MODE_FALLBACK, MODES },
};
