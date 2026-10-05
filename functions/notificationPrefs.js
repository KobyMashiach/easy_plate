// The account's notification choices, as the app mirrors them to
// users/{uid}/preferences/current (see UserPreferencesModel in the app).
// Everything is on unless the account switched it off, which is also what
// an account that never opened the settings screen gets.
const DEFAULTS = Object.freeze({
  pushEnabled: true,
  notifyRepliesOnMyPosts: true,
  notifyRepliesOnThreads: true,
  notifyShareInvites: true,
  notifySharedRecipeUpdates: true,
  notifyAdminReplies: true,
  notifyAnnouncements: true,
});

// Which switch governs an inbox item of a given type. A forum reply has
// two, depending on whether the thread is the recipient's own.
function flagFor(data) {
  switch (String(data.type || "")) {
    case "shareInvite": return "notifyShareInvites";
    case "sharedRecipeUpdated": return "notifySharedRecipeUpdates";
    case "adminReply": return "notifyAdminReplies";
    case "adminMessage": return "notifyAnnouncements";
    case "forumReply": return data.onMyPost === true ? "notifyRepliesOnMyPosts" : "notifyRepliesOnThreads";
    default: return null;
  }
}

// Folds a stored preferences document (possibly missing, possibly older
// than these fields) over the defaults. Only booleans are taken; anything
// else in the document is not this module's business.
function fromDocument(data) {
  const prefs = { ...DEFAULTS };
  if (!data || typeof data !== "object") return prefs;
  for (const key of Object.keys(DEFAULTS)) {
    if (typeof data[key] === "boolean") prefs[key] = data[key];
  }
  return prefs;
}

async function load(db, uid) {
  try {
    const doc = await db.doc(`users/${uid}/preferences/current`).get();
    return fromDocument(doc.exists ? doc.data() : null);
  } catch (err) {
    // A read that fails should not silence the account: defaults are "on".
    return { ...DEFAULTS };
  }
}

// Whether a push for this item may reach the account's phone: the master
// switch first, then the item's own category. Items of a type this module
// does not know are pushed, as they always were.
function wantsPush(prefs, data) {
  if (!prefs.pushEnabled) return false;
  const flag = flagFor(data);
  return flag === null ? true : prefs[flag] !== false;
}

// Whether an item of this type should be written into the inbox at all.
// Only the two "nothing to act on" kinds are dropped outright; an invite
// has to be answerable and a word from the administrator has to be
// readable, whatever the phone does about them.
function wantsInboxItem(prefs, data) {
  const type = String(data.type || "");
  if (type !== "forumReply" && type !== "sharedRecipeUpdated") return true;
  const flag = flagFor(data);
  return flag === null ? true : prefs[flag] !== false;
}

module.exports = { DEFAULTS, flagFor, fromDocument, load, wantsPush, wantsInboxItem };
