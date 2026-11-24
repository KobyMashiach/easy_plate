// The server's backstop for the community swear filter. The app and the
// website refuse to post a listed word (profanity.js has the lists); an
// older build, or a write that skipped them, still lands — so every
// written thread, reply and community recipe is read here and any listed
// word is replaced by asterisks in place. Switched off by
// ff_profanity_filter = 0 (hidden), like the clients.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { maskProfanity } = require("./profanity");
const remoteFlags = require("./remoteFlags");

const FLAG = "ff_profanity_filter";

// Pure: the update that masks [data]'s text fields, or null when clean.
// `fields` are top-level strings; `lists` are arrays of strings; `objects`
// are arrays of objects whose named string keys are checked (ingredients).
function maskPatch(data, { fields = [], lists = [], objects = {} } = {}) {
  if (!data || typeof data !== "object") return null;
  const patch = {};
  for (const f of fields) {
    if (typeof data[f] !== "string") continue;
    const masked = maskProfanity(data[f]);
    if (masked !== data[f]) patch[f] = masked;
  }
  for (const f of lists) {
    if (!Array.isArray(data[f])) continue;
    const masked = data[f].map((v) => (typeof v === "string" ? maskProfanity(v) : v));
    if (masked.some((v, i) => v !== data[f][i])) patch[f] = masked;
  }
  for (const [f, keys] of Object.entries(objects)) {
    if (!Array.isArray(data[f])) continue;
    let changed = false;
    const masked = data[f].map((item) => {
      if (!item || typeof item !== "object") return item;
      const next = { ...item };
      for (const k of keys) {
        if (typeof item[k] !== "string") continue;
        const m = maskProfanity(item[k]);
        if (m !== item[k]) { next[k] = m; changed = true; }
      }
      return next;
    });
    if (changed) patch[f] = masked;
  }
  return Object.keys(patch).length ? patch : null;
}

async function filterOn() {
  const params = await remoteFlags.params();
  return remoteFlags.intFrom(params, FLAG, 2) !== 0;
}

// The masking write does not change anything it reads, so its own trigger
// finds the text clean and stops.
function moderate(path, shape) {
  return onDocumentWritten(path, async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;
    const patch = maskPatch(after.data(), shape);
    if (!patch) return;
    if (!(await filterOn())) return;
    await after.ref.update({ ...patch, moderatedAt: admin.firestore.FieldValue.serverTimestamp() });
    logger.info("community text masked", { path: after.ref.path, fields: Object.keys(patch) });
  });
}

const POST = { fields: ["title", "body"] };
const REPLY = { fields: ["body"] };
const RECIPE = { fields: ["title"], lists: ["steps"], objects: { ingredients: ["name", "section"] } };

module.exports = {
  moderateForumPost: moderate("forum_posts/{postId}", POST),
  moderateForumReply: moderate("forum_posts/{postId}/replies/{replyId}", REPLY),
  moderateSharedRecipe: moderate("shared_recipes/{sharedId}", RECIPE),
  internals: { maskPatch, POST, REPLY, RECIPE },
};
