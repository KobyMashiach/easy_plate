// Grocery lists on the web: the live list (one device's tick reaches every
// other at once), every write the app's GroceryListsRepositoryImpl makes
// (language stamp included), and — for a shared list — the shared document
// in collab_containers, as the app's ContainerCollab publishes, syncs and
// retires it.
import { useEffect, useRef, useState } from "react";
import { auth } from "../../lib/firebase";
import { deleteRecord, firestore, getRecord, listRecords, newId, putRecord, updateRecord, watchSharedRoot, withFirestore } from "../../lib/cloud";
import { normalizeRecipe, type CollabRole } from "../../models/recipe";
import {
  canEditList,
  groceryContainerContent,
  groceryItemsForPlans,
  groceryItemsForRecipe,
  groceryListFromContainer,
  groceryListToDart,
  groceryShareKey,
  includesAllPlans,
  isMyList,
  mergeRebuilt,
  newGroceryList,
  normalizeGroceryList,
  planLikeOf,
  stampGroceryList,
  type GroceryItem,
  type GroceryList,
  type PlanLike,
  type RecipeLike,
} from "../../models/groceryList";

// ---------------------------------------------------------------------------
// The open list on this device (active_grocery_list_store.dart): local on
// purpose — two people on one account shop from different lists.

const ACTIVE_KEY = "ep-active-grocery-list";
export function readActiveList(uid: string): string | null {
  try {
    return localStorage.getItem(`${ACTIVE_KEY}:${uid}`);
  } catch {
    return null;
  }
}
export function writeActiveList(uid: string, id: string): void {
  try {
    localStorage.setItem(`${ACTIVE_KEY}:${uid}`, id);
  } catch {
    /* private window: nothing to remember */
  }
}

// ---------------------------------------------------------------------------
// Writing

// Offline, a Firestore write applies locally at once but its promise only
// settles when the server answers. Past a few seconds the write is taken as
// queued (Firestore sends it on reconnect) so a busy state never sticks;
// a refusal that arrives in time still throws.
const WRITE_WAIT_MS = 8_000;
function queuedAfter<T>(p: Promise<T>): Promise<T | undefined> {
  return Promise.race([p, new Promise<undefined>((r) => setTimeout(() => r(undefined), WRITE_WAIT_MS))]);
}

/** Saves the whole record (stamped like the app) and, for a shared list, the shared document. */
export async function saveList(next: GroceryList, previous: GroceryList | null, lang: string, { stamp = true } = {}): Promise<GroceryList> {
  const list = stamp ? stampGroceryList(next, previous, lang) : next;
  await queuedAfter(putRecord("grocery_lists", list.id, groceryListToDart(list)));
  await queuedAfter(publishShared(list));
  return list;
}

/**
 * CreateRecipeGroceryListUseCase: a new list holding one recipe's lines,
 * scaled, with its title and servings copied, made this device's open list.
 * Built from the recipe in hand, not re-read by id: a community recipe that
 * was never saved is not among this account's recipes and is still
 * shoppable. Shared by the groceries page and the community recipe page.
 */
export async function createRecipeList(recipe: RecipeLike, name: string, scale: number, lang: string): Promise<GroceryList> {
  const list: GroceryList = {
    ...newGroceryList(newId(), name.trim() || recipe.title, "recipe"),
    items: groceryItemsForRecipe(recipe, scale),
    recipeId: recipe.id,
    recipeScale: scale,
    recipeServings: recipe.servings ?? null,
    recipeTitle: recipe.title,
  };
  const saved = await saveList(list, null, lang);
  const uid = auth().currentUser?.uid;
  if (uid) writeActiveList(uid, saved.id);
  return saved;
}

/** A record id that is safe in a Firestore path (cloud.ts keeps its own check private). */
export const validListId = (id: string | null | undefined): id is string => !!id && !id.includes("/") && id !== "." && id !== "..";

/** The list a change was meant for is gone — deleted on another device. */
export class ListGoneError extends Error {
  constructor() {
    super("grocery-list-gone");
  }
}

/**
 * Read-modify-write of one stored list (GroceryListBloc's write rule): the
 * change is applied to the record as it is stored now, never to a copy held
 * on screen, so a tick or rename made on another device meanwhile survives.
 * A list deleted elsewhere is not written back — ListGoneError instead.
 * Resolves the saved list, or null when there was nothing to write.
 */
export async function updateList(id: string, change: (l: GroceryList) => GroceryList | null, lang: string, { stamp = true } = {}): Promise<GroceryList | null> {
  let gone = false as boolean;
  let saved = null as GroceryList | null;
  await updateRecord("grocery_lists", id, (raw) => {
    gone = raw === null;
    saved = null;
    if (raw === null) return null;
    const stored = normalizeGroceryList(raw);
    if (!canEditList(stored)) return null;
    const next = change(stored);
    if (next === null || next === stored) return null;
    saved = stamp ? stampGroceryList(next, stored, lang) : next;
    return groceryListToDart(saved);
  });
  if (gone) throw new ListGoneError();
  if (saved) await queuedAfter(publishShared(saved));
  return saved;
}

// Publishes run one after another per shared document: two quick ticks each
// read-then-write the document, and the older one landing last would leave
// the shared copy a tick behind.
const publishQueues = new Map<string, Promise<void>>();

/** ContainerCollab.publish for a grocery list: title + content, by an owner or editor. */
function publishShared(list: GroceryList): Promise<void> {
  const collabId = list.collabId;
  if (!collabId || !validListId(collabId)) return Promise.resolve();
  const run = publishQueues.get(collabId) ?? Promise.resolve();
  const next = run.then(() => publishNow(list));
  publishQueues.set(collabId, next);
  void next.finally(() => {
    if (publishQueues.get(collabId) === next) publishQueues.delete(collabId);
  });
  return next;
}

async function publishNow(list: GroceryList): Promise<void> {
  const uid = auth().currentUser?.uid;
  if (!list.collabId || !uid || !canEditList(list)) return;
  try {
    const { fs, db } = await firestore();
    const ref = fs.doc(db, "collab_containers", list.collabId);
    const snap = await fs.getDoc(ref);
    if (!snap.exists()) return; // deleted by the owner: the next open orphans the copy
    await queuedAfter(fs.updateDoc(ref, { title: list.name, content: groceryContainerContent(list), updatedAt: fs.serverTimestamp(), updatedBy: uid }));
  } catch {
    /* best effort, as the app: the local copy is saved */
  }
}

/** Deleting: the owner takes the shared document down, a member leaves it; then the record goes. */
export async function deleteList(list: GroceryList): Promise<void> {
  const uid = auth().currentUser?.uid;
  if (list.collabId && validListId(list.collabId) && uid) {
    try {
      const { fs, db } = await firestore();
      const ref = fs.doc(db, "collab_containers", list.collabId);
      if (isMyList(list)) await queuedAfter(fs.deleteDoc(ref));
      else await queuedAfter(fs.updateDoc(ref, { [`members.${uid}`]: fs.deleteField(), memberUids: fs.arrayRemove(uid), updatedAt: fs.serverTimestamp() }));
    } catch {
      /* best effort */
    }
  }
  await queuedAfter(deleteRecord("grocery_lists", list.id));
}

// ---------------------------------------------------------------------------
// Building

export async function loadPlans(): Promise<PlanLike[]> {
  return (await listRecords<unknown>("meal_plans")).map(planLikeOf);
}

async function recipeIndex(): Promise<Map<string, RecipeLike>> {
  const all = (await listRecords<unknown>("recipes")).map(normalizeRecipe);
  return new Map(all.map((r) => [r.id, r]));
}

export async function loadRecipe(id: string): Promise<RecipeLike | null> {
  const raw = await getRecord<unknown>("recipes", id);
  return raw ? normalizeRecipe(raw) : null;
}

/**
 * What a rebuild produces for this list (GroceryListBloc._regenerate), or
 * null when there is nothing to rebuild from (a hand-made list, a recipe that
 * is gone) — the caller then keeps the list as it is.
 */
export async function rebuiltItems(list: GroceryList): Promise<GroceryItem[] | null> {
  if (list.source === "manual") return null;
  if (list.source === "recipe") {
    if (!list.recipeId) return null;
    const recipe = await loadRecipe(list.recipeId);
    return recipe ? groceryItemsForRecipe(recipe, list.recipeScale) : null;
  }
  const [plans, recipes] = await Promise.all([loadPlans(), recipeIndex()]);
  // An empty selection means every plan — also what a list whose plans were all deleted falls back to.
  const chosen = includesAllPlans(list) ? plans : plans.filter((p) => list.selectedPlanIds.includes(p.id));
  return groceryItemsForPlans(chosen, (id) => recipes.get(id));
}

export { mergeRebuilt };

// ---------------------------------------------------------------------------
// Reading, live

export type MutateResult = "ok" | "failed" | "gone";

export interface LiveList {
  /** undefined while loading, null when the record does not exist. */
  list: GroceryList | null | undefined;
  error: boolean;
  /**
   * Applies a change on screen at once and writes it onto the stored record;
   * "gone" when the list was deleted elsewhere, "failed" when the write failed.
   */
  mutate: (fn: (l: GroceryList) => GroceryList, opts?: { stamp?: boolean }) => Promise<MutateResult>;
}

/**
 * One list, live. Snapshots that carry this tab's own pending writes are
 * skipped — the screen is already ahead of them, and taking one would undo a
 * tick made a moment later (the bloc's in-flight rule). Everything else —
 * another device, another member — is taken as it comes.
 */
export function useLiveGroceryList(uid: string | null | undefined, id: string, lang: string): LiveList {
  const [list, setList] = useState<GroceryList | null | undefined>(undefined);
  const [error, setError] = useState(false);
  const current = useRef<GroceryList | null | undefined>(undefined);
  // This tab's own writes not yet landed (the bloc's _inflight): while one is
  // in flight, the shared document may echo an older publish of ours, and
  // taking it would undo a tick made meanwhile. Its newest snapshot is held
  // and laid over once nothing is in flight.
  const inflight = useRef(0);
  const heldShared = useRef<(() => void) | null>(null);
  const set = (l: GroceryList | null | undefined) => {
    current.current = l;
    setList(l);
  };

  useEffect(() => {
    if (!uid || !id) return;
    setError(false);
    heldShared.current = null;
    if (!validListId(id)) {
      set(null);
      return;
    }
    set(undefined);
    let stopInner: (() => void) | null = null;
    const stopRoot = watchSharedRoot(uid, (root) => {
      stopInner?.();
      stopInner = withFirestore(
        (fs, db) =>
          fs.onSnapshot(
            fs.doc(db, `${root}/grocery_lists/${id}`),
            (snap) => {
              if (snap.metadata.hasPendingWrites && current.current) return;
              // While a write of ours is in flight the list's own snapshots
              // are passed over: a transaction leaves no local pending write,
              // so one would flick a tick back for a moment. Once nothing is
              // in flight the record is read afresh (mutate).
              if (inflight.current > 0 && current.current) return;
              set(snap.exists() ? normalizeGroceryList(snap.data()) : null);
            },
            () => setError(true),
          ),
        () => setError(true),
      );
    });
    return () => {
      stopRoot();
      stopInner?.();
    };
  }, [uid, id]);

  // A shared list: the shared document laid over this copy whenever it moves
  // (ContainerCollab.sync). Gone or no longer readable → a private list again.
  const collabId = list?.collabId ?? null;
  useEffect(() => {
    if (!uid || !collabId || !validListId(collabId)) return;
    // The shared copy laid over the stored record (not the one on screen);
    // a list deleted meanwhile is not written back.
    const rewrite = (id: string, fn: (stored: GroceryList) => GroceryList) =>
      void updateRecord("grocery_lists", id, (raw) => {
        if (raw === null) return null;
        const stored = normalizeGroceryList(raw);
        if (stored.collabId !== collabId) return null;
        const next = fn(stored);
        return groceryShareKey(next) === groceryShareKey(stored) && next.collabId === stored.collabId ? null : groceryListToDart(next);
      }).catch(() => {});
    return withFirestore((fs, db) =>
      fs.onSnapshot(
        fs.doc(db, "collab_containers", collabId),
        (snap) => {
          if (snap.metadata.hasPendingWrites) return;
          const exists = snap.exists();
          // Offline at start the SDK answers "no document" from its empty
          // cache. That proves nothing: taking it would strip the list's
          // collabId (and write that back), ending the share for this copy.
          // Only the server may say the document is gone (as the book and
          // plan followers already require).
          if (!exists && snap.metadata.fromCache) return;
          const data = (exists ? snap.data() : {}) as { ownerUid?: string; members?: Record<string, string>; title?: string; content?: unknown };
          const apply = () => {
            const local = current.current;
            if (!local || local.collabId !== collabId) return;
            const role: CollabRole = data.ownerUid === uid ? "owner" : data.members?.[uid] === "editor" ? "editor" : "viewer";
            const overlay = (l: GroceryList): GroceryList =>
              exists ? groceryListFromContainer({ id: collabId, title: data.title ?? "", content: data.content }, l, role) : { ...l, collabId: null, collabRole: null };
            const next = overlay(local);
            if (groceryShareKey(next) === groceryShareKey(local) && next.collabId === local.collabId) return;
            set(next);
            rewrite(next.id, overlay);
          };
          if (inflight.current > 0) heldShared.current = apply;
          else apply();
        },
        (e) => {
          const local = current.current;
          if (!local || local.collabId !== collabId || (e as { code?: string }).code !== "permission-denied") return;
          set({ ...local, collabId: null, collabRole: null });
          rewrite(local.id, (l) => ({ ...l, collabId: null, collabRole: null }));
        },
      ),
    );
  }, [uid, collabId]);

  const mutate = async (fn: (l: GroceryList) => GroceryList, opts: { stamp?: boolean } = {}): Promise<MutateResult> => {
    const before = current.current;
    if (!before || !canEditList(before)) return "failed";
    const next = fn(before);
    if (next === before) return "ok";
    set(next);
    inflight.current += 1;
    let result: MutateResult = "ok";
    try {
      // The change itself is replayed on the stored record, not `next`.
      await updateList(before.id, fn, lang, opts);
    } catch (e) {
      result = e instanceof ListGoneError ? "gone" : "failed";
    } finally {
      inflight.current -= 1;
    }
    if (inflight.current === 0) {
      const listId = before.id;
      // What is stored now (this write, and anything another device wrote
      // meanwhile) — also what undoes the on-screen change of a failed write.
      try {
        const raw = await getRecord<unknown>("grocery_lists", listId);
        if (inflight.current === 0 && current.current?.id === listId) set(raw ? normalizeGroceryList(raw) : null);
      } catch {
        /* the listener carries on */
      }
      const held = inflight.current === 0 ? heldShared.current : null;
      if (held) {
        heldShared.current = null;
        held();
      }
    }
    return result;
  };

  return { list, error, mutate };
}
