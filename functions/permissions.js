// Who may do what: `users/{uid}.permission`, "admin" or "user".
//
// The field is the only source of who the administrator is. The app cannot
// write it (firestore.rules allows a client to create it only as "user" and
// never to change it), so it is set from the Firebase console or by a
// server; onUserCreated stamps "user" on every new profile. A missing or
// unknown value counts as "user".
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const PERMISSIONS = Object.freeze({ ADMIN: "admin", USER: "user" });

// Pure: the permission a users document grants.
function permissionOf(data) {
  return data && data.permission === PERMISSIONS.ADMIN ? PERMISSIONS.ADMIN : PERMISSIONS.USER;
}

// The caller's permission, read from their users document.
async function permissionFor(uid) {
  if (!uid) return PERMISSIONS.USER;
  const snapshot = await admin.firestore().doc(`users/${uid}`).get();
  return permissionOf(snapshot.exists ? snapshot.data() : null);
}

async function isAdmin(caller) {
  if (!caller || !caller.uid) return false;
  try {
    return (await permissionFor(caller.uid)) === PERMISSIONS.ADMIN;
  } catch (err) {
    logger.warn("permission read failed", { uid: caller.uid, reason: err.message });
    return false;
  }
}

// Every new profile starts as a plain user, written by the server so the
// field is there to see and edit in the console.
const onUserCreated = onDocumentCreated(
  { document: "users/{uid}", region: "europe-west1" },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.permission) return;
    await event.data.ref.set({ permission: PERMISSIONS.USER }, { merge: true });
  },
);

module.exports = { PERMISSIONS, permissionOf, permissionFor, isAdmin, onUserCreated };
