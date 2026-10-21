// Who may do what: `users/{uid}.permission`, "admin", "superuser" or "user".
//
// "superuser" (2026-10-15) is an account the administrator marked from the
// console: every feature flag reads as on for it (Premium ones included)
// and it has no device limit, but it has none of the administrator's
// powers — the rules and the functions keep asking for "admin". (An
// administrator gets the same through `admin_all_features`.)
//
// The field is the only source of who the administrator is. The app cannot
// write it (firestore.rules allows a client to create it only as "user" and
// never to change it), so it is set by a server — an administrator grants
// any of the three from the console (2026-10-18, "admin" included), never
// on their own account, so there is always at least the caller left — or
// in the Firebase console; onUserCreated stamps "user" on every new
// profile. A missing or unknown value counts as "user".
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

const PERMISSIONS = Object.freeze({ ADMIN: "admin", SUPERUSER: "superuser", USER: "user" });

// What an administrator may set from the console, on any account but their
// own (the callers refuse that), so an admin can never demote the last one.
const GRANTABLE = Object.freeze([PERMISSIONS.USER, PERMISSIONS.SUPERUSER, PERMISSIONS.ADMIN]);

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

// An administrator sets another account's permission.
async function setPermission(uid, permission) {
  if (!GRANTABLE.includes(permission)) throw new Error("permission must be user, superuser or admin");
  const ref = admin.firestore().doc(`users/${uid}`);
  const snapshot = await ref.get();
  if (!snapshot.exists) throw new Error("no such account");
  await ref.set({ permission, permissionUpdatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  return permission;
}

// The caller's permission, read from their users document.
async function permissionFor(uid) {
  if (!uid) return PERMISSIONS.USER;
  const snapshot = await admin.firestore().doc(`users/${uid}`).get();
  return permissionOf(snapshot.exists ? snapshot.data() : null);
}

// An administrator the console switched off (account_status disabled) has
// none of the powers left — otherwise a disabled admin's still-valid token
// could call the console and switch the account back on.
async function isAdmin(caller, db = null) {
  if (!caller || !caller.uid) return false;
  try {
    const store = db || admin.firestore();
    const user = await store.doc(`users/${caller.uid}`).get();
    if (permissionOf(user.exists ? user.data() : null) !== PERMISSIONS.ADMIN) return false;
    const status = await store.doc(`account_status/${caller.uid}`).get();
    return !(status.exists && (status.data() || {}).disabled === true);
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
