// collab_containers/{id}: a shared book, meal plan or grocery list. Same
// roster and invite flow as a shared recipe; the body points at shared
// recipes by their collab ids. Ports CollabContainersFirestoreDataSource,
// ContainerAdapter (encode/decode), RecipeLinker and ContainerCollab.
import { firestore, getRecord, listRecords, newId } from "../../../lib/cloud";
import { saveRecipe } from "../../../lib/recipesStore";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";
import { anyResolves, findUidByContact, normalizeContact } from "./contact";
import {
  acceptAndJoin,
  collabRecipeFrom,
  createCollabRecipe,
  getCollabRecipe,
  localCopy,
  membersFrom,
  removeCollabMember,
  roleOf,
  acceptRecipeInvite,
} from "./collabRecipes";
import {
  getContainerRecord,
  listContainerRecords,
  normalizeContainerRecord,
  saveContainerRecord,
  titleOf,
  DEFAULT_GROCERY_CATEGORY,
  type Book,
  type ContainerRecord,
  type GroceryList,
  type MealPlan,
} from "./containerRecords";
import { inviteFields, inviteFrom, inviteIsDead, readInvite } from "./invites";
import { inviteIdFor, ItemGone, kindFrom, ShareFailure, tsMs, type CollabRole, type ContainerKind, type ShareInvite } from "./types";

export interface CollabContainer {
  id: string;
  kind: ContainerKind;
  ownerUid: string;
  members: Record<string, CollabRole>;
  title: string;
  content: Record<string, unknown>;
  updatedAtMs: number;
}

type Fs = Awaited<ReturnType<typeof firestore>>["fs"];
type Db = Awaited<ReturnType<typeof firestore>>["db"];

function containerFrom(id: string, data: Record<string, unknown>): CollabContainer {
  const kind = kindFrom(data.kind);
  return {
    id,
    kind: kind === "book" || kind === "mealPlan" || kind === "groceryList" ? kind : "book",
    ownerUid: typeof data.ownerUid === "string" ? data.ownerUid : "",
    members: membersFrom(data.members),
    title: typeof data.title === "string" ? data.title : "",
    content: data.content && typeof data.content === "object" ? (data.content as Record<string, unknown>) : {},
    updatedAtMs: tsMs(data.updatedAt) ?? tsMs(data.createdAt) ?? Date.now(),
  };
}

/** Owner first, then everyone else with their role. */
export function participants(c: CollabContainer): Record<string, CollabRole> {
  return { [c.ownerUid]: "owner", ...c.members };
}

/** CollabContainerEntity.collabIdsIn */
export function collabIdsIn(content: Record<string, unknown>): Set<string> {
  const ids = new Set<string>();
  for (const raw of Array.isArray(content.recipes) ? content.recipes : []) {
    if (raw && typeof raw === "object" && typeof (raw as { collabId?: unknown }).collabId === "string") ids.add((raw as { collabId: string }).collabId);
  }
  for (const meal of Array.isArray(content.meals) ? content.meals : []) {
    const items = meal && typeof meal === "object" ? (meal as { items?: unknown }).items : null;
    for (const item of Array.isArray(items) ? items : []) {
      if (item && typeof item === "object" && typeof (item as { recipeCollabId?: unknown }).recipeCollabId === "string") {
        ids.add((item as { recipeCollabId: string }).recipeCollabId);
      }
    }
  }
  return ids;
}

export async function getContainer(id: string): Promise<CollabContainer | null> {
  const { fs, db } = await firestore();
  const snap = await fs.getDoc(fs.doc(db, "collab_containers", id));
  return snap.exists() ? containerFrom(snap.id, snap.data()) : null;
}

export async function containersOwnedBy(uid: string): Promise<CollabContainer[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "collab_containers"), fs.where("ownerUid", "==", uid)));
  return snap.docs.map((d) => containerFrom(d.id, d.data()));
}

export async function containersSharedWith(uid: string): Promise<CollabContainer[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "collab_containers"), fs.where("memberUids", "array-contains", uid)));
  return snap.docs.map((d) => containerFrom(d.id, d.data()));
}

// ── Encoding (owner → document) ───────────────────────────────────────────

function recipeIdsOf(kind: ContainerKind, item: ContainerRecord): string[] {
  if (kind === "book") return [...(item as Book).recipeRefs].sort((a, b) => a.order - b.order).map((r) => r.recipeId);
  if (kind === "mealPlan") return (item as MealPlan).meals.flatMap((m) => m.items.map((i) => i.recipeId).filter((x): x is string => x !== null));
  return [];
}

function encode(kind: ContainerKind, item: ContainerRecord, collabIdByRecipeId: Map<string, string>, titles: Map<string, string>): Record<string, unknown> {
  if (kind === "book") {
    const b = item as Book;
    const refs = [...b.recipeRefs].sort((a, c) => a.order - c.order);
    return {
      coverImageFileName: b.coverImageFileName,
      coverImageStoragePath: b.coverImageStoragePath,
      spine: b.spine,
      recipes: refs.filter((r) => collabIdByRecipeId.has(r.recipeId)).map((r) => ({ collabId: collabIdByRecipeId.get(r.recipeId), order: r.order })),
    };
  }
  if (kind === "mealPlan") {
    const p = item as MealPlan;
    return {
      meals: p.meals.map((m) => ({
        id: m.id,
        weekday: m.weekday,
        name: m.name,
        order: m.order,
        items: m.items.map((i) => ({
          id: i.id,
          recipeCollabId: i.recipeId === null ? null : collabIdByRecipeId.get(i.recipeId) ?? null,
          label: i.recipeId === null ? i.freeText : titles.get(i.recipeId) ?? i.freeText,
          freeText: i.freeText,
          ingredients: i.ingredients.map((g) => ({ name: g.name, amount: g.amount, unit: g.unit })),
        })),
      })),
    };
  }
  const l = item as GroceryList;
  return {
    items: l.items.map((line) => ({
      id: line.id,
      name: line.name,
      unit: line.unit,
      category: line.category,
      isChecked: line.isChecked,
      isAdHoc: line.isAdHoc,
      sources: line.sources.map((s) => ({ label: s.label, amount: s.amount })),
    })),
  };
}

// ── Decoding (document → this account's copy) ─────────────────────────────

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === "object" ? (v as Record<string, unknown>) : {});
const arr = (v: unknown): unknown[] => (Array.isArray(v) ? v : []);
const intOr = (v: unknown, d: number) => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : d);
const UNITS = ["gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch", "unspecified"] as const;
const unitOf = (v: unknown) => ((UNITS as readonly string[]).includes(v as string) ? (v as (typeof UNITS)[number]) : "unspecified");

function decode(c: CollabContainer, local: ContainerRecord | null, recipeIdByCollabId: Map<string, string>, uid: string): ContainerRecord {
  const myRole = roleOf(c, uid);
  if (c.kind === "book") {
    const l = local as Book | null;
    const remotePath = typeof c.content.coverImageStoragePath === "string" ? c.content.coverImageStoragePath : null;
    const linked = new Set(recipeIdByCollabId.values());
    const refs = (l?.recipeRefs ?? []).filter((r) => !linked.has(r.recipeId));
    for (const raw of arr(c.content.recipes)) {
      const r = obj(raw);
      const localId = recipeIdByCollabId.get(r.collabId as string);
      if (!localId) continue;
      refs.push({ recipeId: localId, order: intOr(r.order, refs.length) });
    }
    const spine = typeof c.content.spine === "string" ? c.content.spine : null;
    const book = {
      id: l?.id ?? newId(),
      title: c.title,
      recipeRefs: refs,
      collaborators: l?.collaborators ?? {},
      createdAt: l?.createdAt ?? new Date().toISOString(),
      coverImageFileName: remotePath !== null ? (typeof c.content.coverImageFileName === "string" ? c.content.coverImageFileName : null) : l?.coverImageFileName ?? null,
      coverImageStoragePath: remotePath ?? l?.coverImageStoragePath ?? null,
      spine: spine ?? l?.spine ?? null,
      collabId: c.id,
      collabRole: myRole,
      contentLang: l?.contentLang ?? null,
      contentVersion: l?.contentVersion ?? 0,
    };
    return normalizeContainerRecord("book", book);
  }
  if (c.kind === "mealPlan") {
    const l = local as MealPlan | null;
    const linked = new Set(recipeIdByCollabId.values());
    const unlinked = new Map<string, MealPlan["meals"][number]["items"][number]>();
    for (const meal of l?.meals ?? []) for (const item of meal.items) if (item.recipeId && !linked.has(item.recipeId)) unlinked.set(item.id, item);
    const meals: MealPlan["meals"] = [];
    for (const rawMeal of arr(c.content.meals)) {
      const m = obj(rawMeal);
      const items: MealPlan["meals"][number]["items"] = [];
      for (const rawItem of arr(m.items)) {
        const it = obj(rawItem);
        const own = unlinked.get(it.id as string);
        if (own && (it.recipeCollabId === null || it.recipeCollabId === undefined)) {
          items.push(own);
          continue;
        }
        const localId = recipeIdByCollabId.get(it.recipeCollabId as string);
        const id = typeof it.id === "string" ? it.id : newId();
        items.push(
          localId
            ? { id, recipeId: localId, freeText: null, ingredients: [] }
            : {
                id,
                recipeId: null,
                freeText: typeof it.freeText === "string" ? it.freeText : typeof it.label === "string" ? it.label : "",
                ingredients: arr(it.ingredients).map((g) => {
                  const ing = obj(g);
                  return { name: String(ing.name ?? ""), amount: typeof ing.amount === "number" ? ing.amount : null, unit: unitOf(ing.unit) };
                }),
              },
        );
      }
      meals.push({ id: typeof m.id === "string" ? m.id : newId(), weekday: intOr(m.weekday, 0), name: typeof m.name === "string" ? m.name : "", order: intOr(m.order, meals.length), items });
    }
    const plan = {
      id: l?.id ?? newId(),
      name: c.title,
      meals,
      createdAt: l?.createdAt ?? new Date().toISOString(),
      collabId: c.id,
      collabRole: myRole,
      contentLang: l?.contentLang ?? null,
      contentVersion: l?.contentVersion ?? 0,
    };
    return normalizeContainerRecord("mealPlan", plan);
  }
  const l = local as GroceryList | null;
  const mine = myRole === "owner";
  const list = {
    id: l?.id ?? newId(),
    name: c.title,
    items: arr(c.content.items).map((raw) => {
      const it = obj(raw);
      return {
        id: typeof it.id === "string" ? it.id : newId(),
        name: typeof it.name === "string" ? it.name : "",
        unit: unitOf(it.unit),
        sources: arr(it.sources).map((s) => {
          const src = obj(s);
          return { recipeId: null, label: typeof src.label === "string" ? src.label : "", amount: typeof src.amount === "number" ? src.amount : 0 };
        }),
        category: typeof it.category === "string" ? it.category : DEFAULT_GROCERY_CATEGORY,
        isChecked: it.isChecked === true,
        isAdHoc: it.isAdHoc === true,
      };
    }),
    collaborators: l?.collaborators ?? {},
    selectedPlanIds: mine ? l?.selectedPlanIds ?? [] : [],
    createdAt: l?.createdAt ?? new Date().toISOString(),
    contentLang: l?.contentLang ?? null,
    contentVersion: l?.contentVersion ?? 0,
    source: mine ? l?.source ?? "manual" : "manual",
    recipeId: mine ? l?.recipeId ?? null : null,
    recipeScale: mine ? l?.recipeScale ?? 1 : 1,
    recipeServings: mine ? l?.recipeServings ?? null : null,
    recipeTitle: mine ? l?.recipeTitle ?? null : null,
    collabId: c.id,
    collabRole: myRole,
  };
  return normalizeContainerRecord("groceryList", list);
}

// ── RecipeLinker ──────────────────────────────────────────────────────────

interface LinkedRecipes {
  byRecipeId: Map<string, string>;
  /** Shared recipes this account owns: the only ones it may invite others into. */
  owned: { collabId: string; title: string }[];
  titles: Map<string, string>;
}

/** Every recipe in the item becomes (or already is) a shared recipe. */
async function ensureCollabs(recipeIds: string[], uid: string, lang: string): Promise<LinkedRecipes> {
  const all = new Map((await listRecords<unknown>("recipes")).map((raw) => normalizeRecipe(raw)).map((r) => [r.id, r] as const));
  const byRecipeId = new Map<string, string>();
  const owned: LinkedRecipes["owned"] = [];
  const titles = new Map<string, string>();
  for (const id of new Set(recipeIds)) {
    const recipe = all.get(id);
    if (!recipe) continue;
    titles.set(id, recipe.title);
    if (recipe.collabId) {
      byRecipeId.set(id, recipe.collabId);
      if (recipe.collabRole === "owner") owned.push({ collabId: recipe.collabId, title: recipe.title });
      continue;
    }
    try {
      // Read again right before the write: a long book takes a round trip
      // per recipe, and an edit (or a delete) in between must not be undone.
      const raw = await getRecord<unknown>("recipes", id);
      if (!raw) continue;
      const fresh = normalizeRecipe(raw);
      if (fresh.collabId) {
        byRecipeId.set(id, fresh.collabId);
        if (fresh.collabRole === "owner") owned.push({ collabId: fresh.collabId, title: fresh.title });
        continue;
      }
      const collabId = await createCollabRecipe(fresh, uid);
      await saveRecipe({ ...fresh, collabId, collabRole: "owner" }, lang, { mustExist: true });
      byRecipeId.set(id, collabId);
      owned.push({ collabId, title: fresh.title });
    } catch (_) {
      // Refused or offline: this recipe stays out of the document this time.
    }
  }
  return { byRecipeId, owned, titles };
}

/** Collab id → local id for every shared recipe the container points at that this account holds or can be let into. */
async function materialize(collabIds: Set<string>, uid: string, lang: string): Promise<Map<string, string>> {
  const recipes = (await listRecords<unknown>("recipes")).map(normalizeRecipe);
  const byCollabId = new Map<string, string>();
  for (const r of recipes) if (r.collabId) byCollabId.set(r.collabId, r.id);
  for (const collabId of collabIds) {
    if (byCollabId.has(collabId)) continue;
    try {
      const invite = await readInvite(inviteIdFor(collabId, uid));
      if (!invite) continue;
      let local: Recipe;
      if (invite.status === "accepted") {
        const collab = await getCollabRecipe(collabId);
        if (!collab) continue;
        local = await saveRecipe(localCopy(collab, roleOf(collab, uid)), lang);
      } else {
        local = await acceptRecipeInvite(invite, lang, recipes);
        recipes.push(local);
      }
      byCollabId.set(collabId, local.id);
    } catch (_) {
      // Not reachable now: the recipe is left out of this copy.
    }
  }
  return byCollabId;
}

// ── Invites ───────────────────────────────────────────────────────────────

async function commitChunked(fs: Fs, db: Db, writes: ((b: ReturnType<Fs["writeBatch"]>) => void)[]): Promise<void> {
  for (let i = 0; i < writes.length; i += 450) {
    const batch = fs.writeBatch(db);
    for (const w of writes.slice(i, i + 450)) w(batch);
    await batch.commit();
  }
}

/** The container invite (with its inbox item) plus a silent invite into each owned recipe the target lacks. */
async function inviteToContainer(c: CollabContainer, targetUid: string, role: CollabRole, recipes: LinkedRecipes["owned"]): Promise<void> {
  const { fs, db } = await firestore();
  const missing: { collabId: string; title: string }[] = [];
  // Read together (Future.wait in the app): a long book is one round trip, not one per recipe.
  const existingInvites = await Promise.all(recipes.map((r) => readInvite(inviteIdFor(r.collabId, targetUid))));
  for (let i = 0; i < recipes.length; i++) {
    const r = recipes[i];
    const existing = existingInvites[i];
    if (!existing) {
      missing.push(r);
      continue;
    }
    if (await inviteIsDead(existing, "collab_recipes")) {
      await fs.deleteDoc(fs.doc(db, "share_invites", existing.id));
      missing.push(r);
    }
  }
  const inviteId = inviteIdFor(c.id, targetUid);
  let notificationId = inviteId;
  const existing = await readInvite(inviteId);
  let already = existing !== null;
  if (existing && (await inviteIsDead(existing, "collab_containers"))) {
    await fs.deleteDoc(fs.doc(db, "share_invites", inviteId));
    already = false;
    notificationId = `${inviteId}_${Date.now()}`;
  }
  if (already && missing.length === 0) return;
  const writes: ((b: ReturnType<Fs["writeBatch"]>) => void)[] = [];
  if (!already) {
    // First, so they share the first commit (the inbox rule reads the invite with getAfter).
    writes.push((b) => b.set(fs.doc(db, "share_invites", inviteId), inviteFields(fs, { collabId: c.id, title: c.title, ownerUid: c.ownerUid, targetUid, role, kind: c.kind })));
    writes.push((b) =>
      b.set(fs.doc(db, "notifications", targetUid, "items", notificationId), {
        type: "shareInvite",
        kind: c.kind,
        fromUid: c.ownerUid,
        inviteId,
        collabId: c.id,
        recipeTitle: c.title,
        role,
        read: false,
        createdAt: fs.Timestamp.now(),
      }),
    );
  }
  for (const m of missing) {
    writes.push((b) =>
      b.set(
        fs.doc(db, "share_invites", inviteIdFor(m.collabId, targetUid)),
        inviteFields(fs, { collabId: m.collabId, title: m.title, ownerUid: c.ownerUid, targetUid, role, kind: "recipe", via: c.id }),
      ),
    );
  }
  await commitChunked(fs, db, writes);
}

// ── ContainerCollab ───────────────────────────────────────────────────────

function isMineItem(item: ContainerRecord): boolean {
  return item.collabRole === null || item.collabRole === "owner";
}

/**
 * Makes the item shareable without inviting anyone (ensureContainer): every
 * owned recipe in it becomes a collab document, and the container document
 * is created or brought up to date.
 */
export async function ensureContainer(kind: ContainerKind, item: ContainerRecord, ownerUid: string, lang: string): Promise<{ owned: ContainerRecord; container: CollabContainer; linked: LinkedRecipes }> {
  if (!isMineItem(item)) throw new Error("Only what this account owns can be shared");
  // The page may hold the item as it was when it opened: before its first
  // share, or before a co-editor's change was pulled in. The stored copy is
  // the current one; encoding the held one would put old content back over
  // theirs (ContainerCollab.ensureContainer).
  const stored = await getContainerRecord(kind, item.id);
  // Deleted since the page loaded it: the held copy is not written back.
  if (!stored) throw new ItemGone();
  const current =
    stored.collabId !== null || item.collabId === null
      ? stored
      : ({ ...stored, collabId: item.collabId, collabRole: item.collabRole ?? "owner" } as ContainerRecord);
  if (!isMineItem(current)) throw new Error("Only what this account owns can be shared");
  const linked = await ensureCollabs(recipeIdsOf(kind, current), ownerUid, lang);
  const content = encode(kind, current, linked.byRecipeId, linked.titles);
  const title = titleOf(kind, current);
  const { fs, db } = await firestore();
  let owned = current;
  let collabId = current.collabId;
  if (collabId === null) {
    collabId = newId();
    await fs.setDoc(fs.doc(db, "collab_containers", collabId), {
      kind,
      title,
      content,
      ownerUid,
      members: {},
      memberUids: [],
      createdAt: fs.Timestamp.now(),
      updatedAt: fs.Timestamp.now(),
      updatedBy: ownerUid,
    });
    owned = await saveContainerRecord(kind, { ...current, collabId, collabRole: "owner" } as ContainerRecord, lang);
  } else {
    await fs.updateDoc(fs.doc(db, "collab_containers", collabId), { title, content, updatedAt: fs.serverTimestamp(), updatedBy: ownerUid });
  }
  return { owned, linked, container: { id: collabId, kind, ownerUid, members: {}, title, content, updatedAtMs: Date.now() } };
}

/** ContainerCollab.share: look the contact up, make the item shared, invite into it and its recipes. */
export async function shareContainerWithContact(
  kind: ContainerKind,
  item: ContainerRecord,
  p: { contact: string; role: CollabRole; ownerUid: string; senderContacts: string[]; lang: string },
): Promise<ContainerRecord> {
  if (!normalizeContact(p.contact)) throw new ShareFailure("invalid");
  const targetUid = await findUidByContact(p.contact);
  if (!targetUid) {
    const anySender = await anyResolves(p.senderContacts);
    throw new ShareFailure(anySender || p.senderContacts.length === 0 ? "notFound" : "directoryUnavailable");
  }
  if (targetUid === p.ownerUid) throw new ShareFailure("self");
  const prepared = await ensureContainer(kind, item, p.ownerUid, p.lang);
  await inviteToContainer(prepared.container, targetUid, p.role, prepared.linked.owned);
  return prepared.owned;
}

/** ContainerCollab.accept: join, cache every reachable recipe, then lay the document over this account's copy. */
export async function acceptContainerInvite(invite: ShareInvite, uid: string, lang: string): Promise<ContainerRecord> {
  const raw = await acceptAndJoin(invite, "collab_containers");
  const { __id, ...data } = raw;
  const container = containerFrom(__id, data);
  const byCollabId = await materialize(collabIdsIn(container.content), uid, lang);
  const existing = (await listContainerRecords(container.kind)).find((i) => i.collabId === container.id) ?? null;
  const decoded = decode(container, existing, byCollabId, uid);
  return saveContainerRecord(container.kind, decoded, lang);
}

/**
 * The owner revoking someone, or a member leaving — from the container and,
 * best effort, from each shared recipe in it (ContainerSharingService.removeMember).
 */
export async function removeContainerMember(containerId: string, memberUid: string): Promise<void> {
  const container = await getContainer(containerId).catch(() => null);
  await removeCollabMember("collab_containers", containerId, memberUid);
  if (!container) return;
  for (const recipeCollabId of collabIdsIn(container.content)) {
    try {
      await removeCollabMember("collab_recipes", recipeCollabId, memberUid);
    } catch (_) {
      // Owned by another editor: only they may change its roster.
    }
  }
}

export { inviteFrom, collabRecipeFrom };
