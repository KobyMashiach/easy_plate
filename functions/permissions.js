// Who may do what: `users/{uid}.permission`, "admin", "superuser" or "user".
//
// "superuser" (2026-10-15) is an account the administrator marked from the
// console: every feature flag reads as on for it (Premium ones included)
// and it has no device limit, but it has none of the administrator's
// powers — the rules and the functions keep asking for "admin".
//
// The field is the only source of who the administrator is. The app cannot
// write it (firestore.rules allows a client to create it only as "user" and
// never to change it), so it is set from the Firebase console or by a
// server; onUserCreated stamps "user" on every new profile. A missing or
// unknown value counts as "user".
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const PERMISSIONS = Object.freeze({ ADMIN: "admin", SUPERUSER: "superuser", USER: "user" });

// What the administrator may set from the console: never "admin" itself,
// which stays a Firebase-console edit.
const GRANTABLE = Object.freeze([PERMISSIONS.USER, PERMISSIONS.SUPERUSER]);

// Pure: the permission a users document grants.
function permissionOf(data) {
  const value = data && data.permission;
  if (value === PERMISSIONS.ADMIN) return PERMISSIONS.ADMIN;
  if (value === PERMISSIONS.SUPERUSER) return PERMISSIONS.SUPERUSER;
  return PERMISSIONS.USER;
}

// Pure: whether a permission is exempt from the device limit (and, in the
// app, from every feature flag).
function hasAllFeatures(permission) {
  return permission === PERMISSIONS.ADMIN || permission === PERMISSIONS.SUPERUSER;
}

// The administrator grants or removes "superuser" on another account.
async function setPermission(uid, permission) {
  if (!GRANTABLE.includes(permission)) throw new Error("permission must be user or superuser");
  const ref = admin.firestore().doc(`users/${uid}`);
  const snapshot = await ref.get();
  if (!snapshot.exists) throw new Error("no such account");
  if (permissionOf(snapshot.data()) === PERMISSIONS.ADMIN) throw new Error("an administrator's permission is changed in the Firebase console only");
  await ref.set({ permission, permissionUpdatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  return permission;
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

module.exports = { PERMISSIONS, GRANTABLE, permissionOf, permissionFor, hasAllFeatures, isAdmin, setPermission, onUserCreated };
