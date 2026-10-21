// The web app's data layer: the same Firestore records the phone app
// mirrors (lib/core/sync/user_cloud_collection.dart). Every record lives at
//   users/{uid}/{collection}/{id}          (personal root)
//   households/{hid}/{collection}/{id}     (shared root, while in a household)
// and its document data IS the Dart model's toJson() — field for field. The
// phone parses these with strict generated fromJson code, so a record written
// here must have exactly the Dart shape: every key present (nullable fields as
// null, never missing), dates as ISO-8601 strings, enums as their Dart names,
// nested models as plain objects. See src/models/ for the typed shapes and
// webapp/contract-fixtures/ for the samples the Dart contract test parses.
//
// Shared collections follow the household root; personal ones (preferences,
// usage) never do — the same `shared` flag the app uses.
import { useEffect, useMemo, useState } from "react";
import { auth, firestore, withFirestore } from "./firebase";

export type CollectionName =
  | "recipes"
  | "books"
  | "meal_plans"
  | "grocery_lists"
  | "price_records"
  | "receipts"
  | "product_pricing"
  | "preferences"
  | "usage";

const PERSONAL = new Set<CollectionName>(["preferences", "usage"]);

export function isShared(name: CollectionName): boolean {
  return !PERSONAL.has(name);
}

// ---------------------------------------------------------------------------
// The shared root: the household the account belongs to, else its own doc.
// One live listener per uid, shared by every subscriber.

type RootPath = string; // "users/{uid}" | "households/{hid}"
interface RootWatch {
  root: RootPath | null;
  householdId: string | null;
  listeners: Set<(root: RootPath, householdId: string | null) => void>;
  stop: () => void;
}
const roots = new Map<string, RootWatch>();

export function watchSharedRoot(uid: string, onRoot: (root: RootPath, householdId: string | null) => void): () => void {
  let w = roots.get(uid);
  if (!w) {
    const watch: RootWatch = { root: null, householdId: null, listeners: new Set(), stop: () => {} };
    const apply = (root: RootPath, hid: string | null) => {
      if (watch.root === root) return;
      watch.root = root;
      watch.householdId = hid;
      for (const l of watch.listeners) l(root, hid);
    };
    // A listener that errored is dead. Its subscribers keep the known root
    // and the watch starts a new listener after a pause (longer each time),
    // so joining or leaving a household later still re-roots them.
    let stopped = false;
    let stopListener: () => void = () => {};
    let retry: ReturnType<typeof setTimeout> | null = null;
    let delay = 5_000;
    const start = () => {
      retry = null;
      if (stopped) return;
      stopListener();
      stopListener = withFirestore(
        (fs, db) =>
          fs.onSnapshot(
            fs.query(fs.collection(db, "households"), fs.where("memberUids", "array-contains", uid), fs.limit(1)),
            { includeMetadataChanges: true },
            (snap) => {
              // Offline at start, the SDK answers with an empty snapshot from
              // its (empty) cache. That is "don't know", not "no household":
              // taking it would send a member's first writes to the personal
              // root. The root is decided by the server, or by a cached hit.
              if (snap.empty && snap.metadata.fromCache && !watch.root) return;
              if (!snap.metadata.fromCache) delay = 5_000;
              if (snap.empty) apply(`users/${uid}`, null);
              else apply(`households/${snap.docs[0].id}`, snap.docs[0].id);
            },
            () => {
              // A failed read is not "left the household": once a root is known
              // it is kept, so a member's writes never land in their personal
              // root (which would split the data). Only a first read that never
              // answered falls back to the personal root, like the app does
              // before HouseholdService resolves.
              if (!watch.root) apply(`users/${uid}`, null);
              if (stopped || retry) return;
              retry = setTimeout(start, delay);
              delay = Math.min(delay * 2, 300_000);
            },
          ),
        () => {
          if (!watch.root) apply(`users/${uid}`, null);
        },
      );
    };
    start();
    watch.stop = () => {
      stopped = true;
      if (retry) clearTimeout(retry);
      stopListener();
    };
    roots.set(uid, watch);
    w = watch;
  }
  const watch = w;
  watch.listeners.add(onRoot);
  if (watch.root) onRoot(watch.root, watch.householdId);
  return () => {
    watch.listeners.delete(onRoot);
    if (watch.listeners.size === 0) {
      watch.stop();
      if (roots.get(uid) === watch) roots.delete(uid);
    }
  };
}

// A record id is one path segment. Ids reach here from the address bar
// (/recipes/:id, decoded by the router), so "a/b" or ".." must never turn
// into a different document path.
export function validId(id: string): boolean {
  return id.length > 0 && id.length <= 1500 && !id.includes("/") && id !== "." && id !== ".." && !/^__.*__$/.test(id);
}
function assertId(id: string): void {
  if (!validId(id)) throw new Error("Invalid record id");
}

function currentUid(): string {
  const uid = auth().currentUser?.uid;
  if (!uid) throw new Error("Not signed in");
  return uid;
}

/** The root path a collection lives under right now (resolves the household once). */
export function rootFor(name: CollectionName): Promise<RootPath> {
  const uid = currentUid();
  if (!isShared(name)) return Promise.resolve(`users/${uid}`);
  return new Promise((resolve) => {
    let stop: (() => void) | null = null;
    let done = false;
    stop = watchSharedRoot(uid, (root) => {
      if (done) return;
      done = true;
      resolve(root);
      queueMicrotask(() => stop && stop());
    });
  });
}

// ---------------------------------------------------------------------------
// Reading

export interface LiveList<T> {
  items: T[] | null;
  error: Error | null;
}

/**
 * Every record of a collection, live. `items` is null until the first
 * snapshot. Re-roots by itself when the account joins or leaves a household.
 */
export function useCollection<T>(name: CollectionName, uid: string | null | undefined): LiveList<T> {
  const [state, setState] = useState<LiveList<T>>({ items: null, error: null });
  useEffect(() => {
    // Signed out: drop the previous account's records rather than keep them.
    if (!uid) {
      setState((s) => (s.items === null && !s.error ? s : { items: null, error: null }));
      return;
    }
    setState({ items: null, error: null });
    let stopInner: (() => void) | null = null;
    const listen = (root: RootPath) => {
      if (stopInner) stopInner();
      stopInner = withFirestore(
        (fs, db) =>
          fs.onSnapshot(
            fs.collection(db, `${root}/${name}`),
            (snap) => setState({ items: snap.docs.map((d) => d.data() as T), error: null }),
            (e) => setState((s) => ({ items: s.items, error: e as Error })),
          ),
        (e) => setState((s) => ({ items: s.items, error: e })),
      );
    };
    const stopRoot = isShared(name) ? watchSharedRoot(uid, listen) : (listen(`users/${uid}`), () => {});
    return () => {
      stopRoot();
      if (stopInner) stopInner();
    };
  }, [name, uid]);
  return state;
}

/** One record, live. `undefined` while loading, `null` when it does not exist. */
export function useRecord<T>(name: CollectionName, uid: string | null | undefined, id: string | null | undefined): { item: T | null | undefined; error: Error | null } {
  const [state, setState] = useState<{ item: T | null | undefined; error: Error | null }>({ item: undefined, error: null });
  useEffect(() => {
    if (!uid || !id) {
      setState((s) => (s.item === undefined && !s.error ? s : { item: undefined, error: null }));
      return;
    }
    if (!validId(id)) {
      setState({ item: null, error: null });
      return;
    }
    setState({ item: undefined, error: null });
    let stopInner: (() => void) | null = null;
    const listen = (root: RootPath) => {
      if (stopInner) stopInner();
      stopInner = withFirestore(
        (fs, db) =>
          fs.onSnapshot(
            fs.doc(db, `${root}/${name}/${id}`),
            (snap) => setState({ item: snap.exists() ? (snap.data() as T) : null, error: null }),
            (e) => setState({ item: null, error: e as Error }),
          ),
        (e) => setState({ item: null, error: e }),
      );
    };
    const stopRoot = isShared(name) ? watchSharedRoot(uid, listen) : (listen(`users/${uid}`), () => {});
    return () => {
      stopRoot();
      if (stopInner) stopInner();
    };
  }, [name, uid, id]);
  return state;
}

/** Sorts a live list without re-sorting on every render. */
export function useSorted<T>(items: T[] | null, compare: (a: T, b: T) => number): T[] | null {
  return useMemo(() => (items ? [...items].sort(compare) : null), [items, compare]);
}

// ---------------------------------------------------------------------------
// Writing — whole records, exactly as the app writes them (set, not merge).

/** Writes one record (replacing it). `data` must be the full Dart-shaped JSON. */
export async function putRecord(name: CollectionName, id: string, data: object): Promise<void> {
  assertId(id);
  assertDartShape(data);
  const [{ fs, db }, root] = await Promise.all([firestore(), rootFor(name)]);
  await fs.setDoc(fs.doc(db, `${root}/${name}/${id}`), data as Record<string, unknown>);
}

/**
 * Read-modify-write of one record inside a Firestore transaction, so two
 * writers of the same record (e.g. the daily usage counters, written by the
 * add-recipe page and the community feed) never lose each other's change.
 * `change` gets the stored data (or null) and returns the full Dart-shaped
 * record to write, or null to leave it as it is. Returns what was written.
 */
export async function updateRecord<T extends object>(name: CollectionName, id: string, change: (current: unknown | null) => T | null): Promise<T | null> {
  assertId(id);
  const [{ fs, db }, root] = await Promise.all([firestore(), rootFor(name)]);
  const ref = fs.doc(db, `${root}/${name}/${id}`);
  // Offline fallback. A transaction needs the server and fails at once
  // without one, so ticking a grocery list in a shop with no signal would
  // say "save failed". Offline, the change is applied to the copy this tab
  // already has and written with a plain set, which Firestore queues and
  // sends on reconnect. Trade-off: that queued write is last-writer-wins, so
  // a change another device made to the same record while this one was
  // offline can be overwritten — the same as the app's own offline saves.
  const offlineWrite = async (): Promise<T | null> => {
    let current: unknown | null = null;
    try {
      const snap = await fs.getDocFromCache(ref);
      current = snap.exists() ? snap.data() : null;
    } catch (_) {
      // Not in this tab's cache: the change starts from nothing, as the
      // transaction would for a missing record.
    }
    const next = change(current);
    if (next === null) return null;
    assertDartShape(next);
    // Not awaited past the local apply: offline, the promise only settles
    // when the server answers.
    void fs.setDoc(ref, next as Record<string, unknown>).catch(() => {});
    return next;
  };
  if (typeof navigator !== "undefined" && navigator.onLine === false) return offlineWrite();
  try {
    return await fs.runTransaction(db, async (tx) => {
      const snap = await tx.get(ref);
      const next = change(snap.exists() ? snap.data() : null);
      if (next === null) return null;
      assertDartShape(next);
      tx.set(ref, next as Record<string, unknown>);
      return next;
    });
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code === "unavailable" || (code === "failed-precondition" && typeof navigator !== "undefined" && navigator.onLine === false)) return offlineWrite();
    throw e;
  }
}

export async function deleteRecord(name: CollectionName, id: string): Promise<void> {
  assertId(id);
  const [{ fs, db }, root] = await Promise.all([firestore(), rootFor(name)]);
  await fs.deleteDoc(fs.doc(db, `${root}/${name}/${id}`));
}

export async function getRecord<T>(name: CollectionName, id: string): Promise<T | null> {
  if (!validId(id)) return null;
  const [{ fs, db }, root] = await Promise.all([firestore(), rootFor(name)]);
  const snap = await fs.getDoc(fs.doc(db, `${root}/${name}/${id}`));
  return snap.exists() ? (snap.data() as T) : null;
}

export async function listRecords<T>(name: CollectionName): Promise<T[]> {
  const [{ fs, db }, root] = await Promise.all([firestore(), rootFor(name)]);
  const snap = await fs.getDocs(fs.collection(db, `${root}/${name}`));
  return snap.docs.map((d) => d.data() as T);
}

/** A new record id in the same format the app uses (uuid v4). */
export function newId(): string {
  return crypto.randomUUID();
}

/** Now, as the app stores DateTime (DateTime.toIso8601String()). */
export function nowIso(): string {
  return new Date().toISOString();
}

// Firestore refuses `undefined`, and the Dart side needs nullable fields
// present as null. Catch both mistakes before the write, not on a phone.
function assertDartShape(value: unknown, path = "record"): void {
  if (value === undefined) throw new Error(`${path} is undefined — write null for an empty Dart field`);
  if (Array.isArray(value)) {
    value.forEach((v, i) => assertDartShape(v, `${path}[${i}]`));
    return;
  }
  if (value && typeof value === "object" && !(value instanceof Date)) {
    for (const [k, v] of Object.entries(value)) assertDartShape(v, `${path}.${k}`);
    return;
  }
  if (value instanceof Date) throw new Error(`${path} is a Date — store toISOString() like the app`);
  if (typeof value === "number" && !Number.isFinite(value)) throw new Error(`${path} is not a finite number`);
}

// ---------------------------------------------------------------------------
// Other Firestore paths (community, forum, collab, notifications…): features
// use the raw SDK through this, so nothing imports "firebase/firestore"
// statically and the login page stays light.
export { firestore, withFirestore };
