// The slice of the Firestore and Storage SDKs the web app uses, in one module
// that firebase.ts imports dynamically. Importing the SDK packages themselves
// with import() would keep their whole namespaces (no tree-shaking); this
// re-export list is what decides what ships in the firebase-data chunk.
// Feature code never imports "firebase/firestore" directly: it goes through
// lib/cloud.ts, which loads this module on first use.
import { getFirestore as sdkGetFirestore, connectFirestoreEmulator, type Firestore } from "firebase/firestore";
import { getStorage as sdkGetStorage, connectStorageEmulator, type FirebaseStorage } from "firebase/storage";
import type { FirebaseApp } from "firebase/app";

// getFirestore / getStorage, attached to the local emulators in the preview
// harness's emulator mode (see EMULATORS in firebase.ts). Every caller goes
// through these, so no instance can reach production in that mode. The guard
// is compile-time: in a production build these are the plain SDK calls.
const connected = new WeakSet<object>();
export function getFirestore(app: FirebaseApp): Firestore {
  const db = sdkGetFirestore(app);
  if (import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1" && !connected.has(db)) {
    connected.add(db);
    connectFirestoreEmulator(db, "127.0.0.1", Number(import.meta.env.VITE_EMU_FIRESTORE_PORT || 8288));
  }
  return db;
}
export function getStorage(app: FirebaseApp): FirebaseStorage {
  const storage = sdkGetStorage(app);
  if (import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1" && !connected.has(storage)) {
    connected.add(storage);
    connectStorageEmulator(storage, "127.0.0.1", Number(import.meta.env.VITE_EMU_STORAGE_PORT || 9399));
  }
  return storage;
}

export {
  collection,
  collectionGroup,
  doc,
  limit,
  onSnapshot,
  orderBy,
  query,
  where,
  startAfter,
  documentId,
  getDoc,
  getDocFromCache,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  addDoc,
  writeBatch,
  runTransaction,
  serverTimestamp,
  increment,
  arrayUnion,
  arrayRemove,
  deleteField,
  Timestamp,
} from "firebase/firestore";
export { ref, getDownloadURL, uploadBytes, deleteObject } from "firebase/storage";
