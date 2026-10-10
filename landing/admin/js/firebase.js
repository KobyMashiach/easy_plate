// Firebase for the console: the EasyPlate Admin web app of project
// easy-plate. The web config is public by design (it names the project; the
// rules and the ID-token checks are what guard the data), but it is not kept
// in the repo: Firebase Hosting serves it at the reserved /__/firebase/init.json
// URL, so the page loads it from there. Locally that URL only exists behind the
// Hosting emulator (`npm run serve:hosting`), not a plain static server.
import { initializeApp } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-app.js";
import { getAuth, GoogleAuthProvider, signInWithPopup, signOut as fbSignOut, onAuthStateChanged, setPersistence, browserLocalPersistence } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-firestore.js";
import { getStorage, ref as storageRef, getDownloadURL } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-storage.js";

export * from "https://www.gstatic.com/firebasejs/12.4.0/firebase-firestore.js";

export const ADMIN_EMAIL = "koby9779@gmail.com";
export const PANEL_URL = "https://europe-west1-easy-plate.cloudfunctions.net/adminPanel";
export const PERSONA_PREFIX = "seed_";

async function loadConfig() {
  const url = "/__/firebase/init.json";
  let res;
  try {
    res = await fetch(url, { cache: "no-store" });
  } catch (err) {
    throw new Error(`Firebase config unreachable at ${url}: ${err.message}`);
  }
  if (!res.ok) {
    throw new Error(
      `Firebase config missing at ${url} (${res.status}). The admin console must be served by ` +
      `Firebase Hosting or its emulator (cd landing && npm run serve:hosting).`,
    );
  }
  return res.json();
}

const app = initializeApp(await loadConfig());

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export function watchAuth(onChange) {
  return onAuthStateChanged(auth, onChange);
}

export async function signInWithGoogle() {
  await setPersistence(auth, browserLocalPersistence);
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: "select_account", login_hint: ADMIN_EMAIL });
  const result = await signInWithPopup(auth, provider);
  return result.user;
}

export function signOut() {
  return fbSignOut(auth);
}

export function isAdminUser(user) {
  return !!user && String(user.email || "").trim().toLowerCase() === ADMIN_EMAIL;
}

// A Storage path (the way recipes carry their picture) to something an
// <img> can load. Cached per path; a missing object resolves to null.
const urlCache = new Map();
export async function storageUrl(path) {
  if (!path) return null;
  if (urlCache.has(path)) return urlCache.get(path);
  const promise = getDownloadURL(storageRef(storage, path)).catch(() => null);
  urlCache.set(path, promise);
  return promise;
}
