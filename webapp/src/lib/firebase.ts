// Firebase for the web app: project easy-plate, the same Auth users and
// Firestore the phone app uses. The web config is public by design (the
// rules and ID-token checks guard the data) but is not kept in the repo:
// Firebase Hosting serves it at the reserved /__/firebase/init.json URL, like
// the admin console does. Locally (vite dev) set VITE_FIREBASE_CONFIG to the
// config JSON in webapp/.env.local.
import { initializeApp, type FirebaseApp, type FirebaseOptions } from "firebase/app";
import { getAuth, browserLocalPersistence, setPersistence, connectAuthEmulator, signInWithCustomToken, type Auth } from "firebase/auth";
// Firestore and Storage are loaded on first use (dynamic import), so the
// pages a signed-out visitor sees (/login, /link, /upgrade/:token) never
// download them: only auth.tsx (after a user exists), recipes.ts and
// storageUrl ask for them.
import type { Firestore } from "firebase/firestore";
import type { FirebaseStorage } from "firebase/storage";

type FirestoreModule = typeof import("./firestoreSdk");
type StorageModule = typeof import("./firestoreSdk");

// Preview harness only (webapp/scripts/preview): `VITE_EMULATORS=1 vite`
// points Auth, Firestore, Storage and the functions at local emulators of
// the demo-easyplate project. Both halves of the guard are compile-time
// constants, so a production build (DEV = false) drops every emulator branch
// and host string; `npm run preview:check-build` proves it.

export const FUNCTIONS_ORIGIN =
  import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1"
    ? `http://127.0.0.1:${import.meta.env.VITE_EMU_FUNCTIONS_PORT || "5299"}/demo-easyplate/europe-west1`
    : "https://europe-west1-easy-plate.cloudfunctions.net";
export const SITE_ORIGIN = "https://aieasyplate.app";

let app: FirebaseApp | null = null;
let authInstance: Auth | null = null;
let fsPromise: Promise<{ fs: FirestoreModule; db: Firestore }> | null = null;
let storagePromise: Promise<{ st: StorageModule; storage: FirebaseStorage }> | null = null;

async function loadConfig(): Promise<FirebaseOptions> {
  // Emulator mode never reads the real config: a demo-* project id cannot
  // reach production even if an emulator is missing.
  if (import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1") {
    return { apiKey: "demo-key", authDomain: "demo-easyplate.firebaseapp.com", projectId: "demo-easyplate", storageBucket: "demo-easyplate.appspot.com", appId: "1:000000000000:web:0000000000000000000000" };
  }
  const inline = import.meta.env.VITE_FIREBASE_CONFIG as string | undefined;
  if (inline) return JSON.parse(inline) as FirebaseOptions;
  const res = await fetch("/__/firebase/init.json", { cache: "no-store" });
  if (!res.ok) {
    throw new Error(
      `Firebase config missing at /__/firebase/init.json (${res.status}). Serve through Firebase Hosting ` +
        "or its emulator, or set VITE_FIREBASE_CONFIG for local development.",
    );
  }
  return (await res.json()) as FirebaseOptions;
}

export async function initFirebase(): Promise<void> {
  if (app) return;
  app = initializeApp(await loadConfig());
  authInstance = getAuth(app);
  if (import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1") {
    connectAuthEmulator(authInstance, `http://127.0.0.1:${import.meta.env.VITE_EMU_AUTH_PORT || "9299"}`, { disableWarnings: true });
    // The screenshot runner signs the seeded test account in with this.
    const a = authInstance;
    (window as unknown as { __easyplatePreview?: unknown }).__easyplatePreview = {
      signIn: (customToken: string) => signInWithCustomToken(a, customToken).then((c) => c.user.uid),
    };
  }
  await setPersistence(authInstance, browserLocalPersistence);
}

export function auth(): Auth {
  if (!authInstance) throw new Error("Firebase not initialised");
  return authInstance;
}
/// The Firestore SDK and instance, imported on first call. A failed import
/// (offline) is not cached, so the next caller tries again.
export function firestore(): Promise<{ fs: FirestoreModule; db: Firestore }> {
  if (!app) return Promise.reject(new Error("Firebase not initialised"));
  if (!fsPromise) {
    const a = app;
    const p = import("./firestoreSdk").then((fs) => ({ fs, db: fs.getFirestore(a) }));
    fsPromise = p;
    p.catch(() => {
      if (fsPromise === p) fsPromise = null;
    });
  }
  return fsPromise;
}

/// Starts a Firestore subscription once the SDK is loaded and returns its
/// stop function synchronously, the shape React effects want. Stopping before
/// the import resolves cancels the start.
export function withFirestore(start: (fs: FirestoreModule, db: Firestore) => () => void, onError?: (e: Error) => void): () => void {
  let stop: (() => void) | null = null;
  let cancelled = false;
  firestore().then(
    ({ fs, db: d }) => {
      if (!cancelled) stop = start(fs, d);
    },
    (e: Error) => {
      if (!cancelled && onError) onError(e);
    },
  );
  return () => {
    cancelled = true;
    if (stop) stop();
  };
}

function storageSdk(): Promise<{ st: StorageModule; storage: FirebaseStorage }> {
  if (!app) return Promise.reject(new Error("Firebase not initialised"));
  if (!storagePromise) {
    const a = app;
    const p = import("./firestoreSdk").then((st) => ({ st, storage: st.getStorage(a) }));
    storagePromise = p;
    p.catch(() => {
      if (storagePromise === p) storagePromise = null;
    });
  }
  return storagePromise;
}

// A Storage path (the way recipes carry their picture) → something an <img>
// can load. Cached per path; a missing object resolves to null (not cached).
const urlCache = new Map<string, Promise<string | null>>();
export function storageUrl(path: string | null | undefined): Promise<string | null> {
  if (!path || !app) return Promise.resolve(null);
  const cached = urlCache.get(path);
  if (cached) return cached;
  const promise = storageSdk().then(
    ({ st, storage }) =>
      st.getDownloadURL(st.ref(storage, path)).catch(() => {
        // A miss is not kept: the phone writes the record before its photo
        // upload ends, and a passing 403/network error must not stick for
        // the session. The next render asks again.
        if (urlCache.get(path) === promise) urlCache.delete(path);
        return null;
      }),
    () => {
      // The SDK did not load (offline): forget it so a later render retries.
      urlCache.delete(path);
      return null;
    },
  );
  urlCache.set(path, promise);
  return promise;
}
