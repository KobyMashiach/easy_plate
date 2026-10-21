// Shared books and plans on the web: the app's ContainerCollab (publish,
// sync, retire), RecipeLinker (ensureCollabs, materialize) and the
// collab_containers datasource (write, inviteToRecipes), ported for the two
// kinds this feature owns. Same documents, same fields, same rules:
//
//   collab_containers/{id}   kind, title, content, ownerUid, members,
//                            memberUids, createdAt, updatedAt, updatedBy
//   collab_recipes/{id}      the recipe's fields + the same roster
//   share_invites/{collabId}_{uid}   one per person per shared document
//
// firestore.rules: an owner may rewrite anything but never grow the roster;
// an editor writes title/content/updatedAt/updatedBy only; a member leaves
// by removing exactly themself; only a document's owner sends invites for
// it — which is why only recipes this account owns get the silent `via`
// invites, exactly as on the phone.
import { auth } from "../../../lib/firebase";
import { firestore, getRecord, rootFor } from "../../../lib/cloud";
import { saveRecipe } from "../../../lib/recipesStore";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";

export type Role = "owner" | "editor" | "viewer";

export interface ContainerDoc {
  id: string;
  kind: string;
  ownerUid: string;
  members: Record<string, Role>;
  title: string;
  content: unknown;
}

/**
 * An id that came from a document another account can write (a container's
 * content, its roster, a record's collabId) goes into a Firestore path only
 * when it is one segment: no "/", not empty, not "." / ".." / __reserved__.
 */
export function safeId(id: unknown): id is string {
  return typeof id === "string" && id.length > 0 && id.length <= 1500 && !id.includes("/") && id !== "." && id !== ".." && !/^__.*__$/.test(id);
}

/** CollabContainerEntity.roleOf. */
export function roleIn(doc: { ownerUid: string; members: Record<string, Role> }, uid: string): Role {
  return uid === doc.ownerUid ? "owner" : doc.members[uid] ?? "viewer";
}

/** The owner plus every member (CollabContainerEntity.participants). */
function participants(doc: ContainerDoc): Map<string, Role> {
  const out = new Map<string, Role>(Object.entries(doc.members));
  if (safeId(doc.ownerUid)) out.set(doc.ownerUid, "owner");
  return out;
}

export function containerFrom(id: string, data: Record<string, unknown> | undefined): ContainerDoc {
  const d = data ?? {};
  const members: Record<string, Role> = {};
  if (d.members && typeof d.members === "object") {
    for (const [k, v] of Object.entries(d.members as Record<string, unknown>)) if (safeId(k) && (v === "owner" || v === "editor" || v === "viewer")) members[k] = v;
  }
  return { id, kind: String(d.kind ?? ""), ownerUid: String(d.ownerUid ?? ""), members, title: String(d.title ?? ""), content: d.content ?? {} };
}

export function currentUid(): string | null {
  return auth().currentUser?.uid ?? null;
}

const code = (e: unknown): string | undefined => (e as { code?: string } | null)?.code;

/** How long a write may wait before it is taken as queued (the app's 8 s). */
const REMOTE_TIMEOUT = 8000;
function settled<T>(p: Promise<T>): Promise<T | undefined> {
  return Promise.race([p, new Promise<undefined>((r) => setTimeout(() => r(undefined), REMOTE_TIMEOUT))]);
}

/** The container, or null when it is gone; "denied" when this account was removed. */
export async function readContainer(id: string): Promise<ContainerDoc | null | "denied"> {
  if (!safeId(id)) return null;
  const { fs, db } = await firestore();
  try {
    const snap = await fs.getDoc(fs.doc(db, "collab_containers", id));
    return snap.exists() ? containerFrom(snap.id, snap.data()) : null;
  } catch (e) {
    if (code(e) === "permission-denied") return "denied";
    throw e;
  }
}

// ---------------------------------------------------------------------------
// RecipeLinker.ensureCollabs — outbound.

export interface LinkedRecipes {
  byRecipeId: Map<string, string>;
  /** Recipes this account owns: the only ones it may invite others into. */
  owned: { collabId: string; title: string }[];
  titles: Map<string, string>;
}

/** collab_recipes fields (RecipeSharingFirestoreDataSource._recipeFields). */
function recipeFields(r: Recipe): Record<string, unknown> {
  return {
    title: r.title,
    prepTimeMinutes: r.prepTimeMinutes,
    cookTimeMinutes: r.cookTimeMinutes,
    ingredients: r.ingredients.map((i) => ({ name: i.name, amount: i.amount, unit: i.unit })),
    steps: r.steps,
    dietaryTags: r.dietaryTags,
    allergens: r.allergens,
    mayContain: r.mayContain,
    imageFileName: r.imageFileName,
    imageStoragePath: r.imageStoragePath,
    servings: r.servings,
    nutrition: r.nutrition ? { calories: Math.trunc(r.nutrition.calories), proteinGrams: r.nutrition.proteinGrams, carbsGrams: r.nutrition.carbsGrams, fatGrams: r.nutrition.fatGrams } : null,
  };
}

/**
 * Local id → collab id for every recipe that is, or can be made, shared. A
 * recipe never shared becomes this account's own collab_recipes document
 * (created with an empty roster, as the rules require) and the local record
 * is tagged with it. A failure leaves that recipe out until the next save.
 */
export async function ensureRecipeCollabs(recipeIds: string[], uid: string, lang: string): Promise<LinkedRecipes> {
  const byRecipeId = new Map<string, string>();
  const owned: { collabId: string; title: string }[] = [];
  const titles = new Map<string, string>();
  if (recipeIds.length === 0) return { byRecipeId, owned, titles };
  // Only the recipes asked for (a few per book or plan), not the whole
  // library: this runs on every save of a shared book or plan.
  const wanted = [...new Set(recipeIds)].filter((id) => safeId(id));
  const all = (await Promise.all(wanted.map((id) => getRecord<unknown>("recipes", id).catch(() => null))))
    .filter((r): r is NonNullable<typeof r> => !!r)
    .map(normalizeRecipe);
  const { fs, db } = await firestore();
  for (const recipe of all) {
    titles.set(recipe.id, recipe.title);
    if (recipe.collabId) {
      // A tag that is not one path segment is left out, never re-shared over.
      if (!safeId(recipe.collabId)) continue;
      byRecipeId.set(recipe.id, recipe.collabId);
      if (recipe.collabRole === "owner") owned.push({ collabId: recipe.collabId, title: recipe.title });
      continue;
    }
    try {
      const collabId = crypto.randomUUID();
      await settled(
        fs.setDoc(fs.doc(db, "collab_recipes", collabId), {
          ...recipeFields(recipe),
          ownerUid: uid,
          members: {},
          memberUids: [],
          createdAt: fs.Timestamp.now(),
          updatedAt: fs.Timestamp.now(),
          updatedBy: uid,
        }),
      );
      await saveRecipe({ ...recipe, collabId, collabRole: "owner" }, lang);
      byRecipeId.set(recipe.id, collabId);
      owned.push({ collabId, title: recipe.title });
    } catch {
      // Refused or offline: left out this time, picked up by the next save.
    }
  }
  return { byRecipeId, owned, titles };
}

// ---------------------------------------------------------------------------
// Silent recipe invites (CollabContainersFirestoreDataSource.inviteToRecipes).

const known = new Set<string>();
const BATCH_LIMIT = 450;

/** An invite by its deterministic id, or null; the rules answer a missing one with "no invite". */
async function readInvite(id: string): Promise<Record<string, unknown> | null> {
  const { fs, db } = await firestore();
  try {
    const snap = await fs.getDoc(fs.doc(db, "share_invites", id));
    return snap.exists() ? (snap.data() as Record<string, unknown>) : null;
  } catch (e) {
    if (code(e) === "permission-denied") return null;
    throw e;
  }
}

async function inviteToRecipes(container: ContainerDoc, recipes: { collabId: string; title: string }[], byUid: string): Promise<void> {
  const people = participants(container);
  const targets = [...people.keys()].filter((p) => p !== byUid);
  const wanted = targets.flatMap((target) => recipes.map((r) => ({ ...r, target, id: `${r.collabId}_${target}` }))).filter((w) => !known.has(w.id));
  if (wanted.length === 0) return;
  const existing = await Promise.all(wanted.map((w) => readInvite(w.id)));
  const missing = wanted.filter((w, i) => {
    if (existing[i]) known.add(w.id);
    return !existing[i];
  });
  if (missing.length === 0) return;
  const { fs, db } = await firestore();
  for (let i = 0; i < missing.length; i += BATCH_LIMIT) {
    const batch = fs.writeBatch(db);
    for (const m of missing.slice(i, i + BATCH_LIMIT)) {
      // The container's owner gets to edit a recipe an editor brought in;
      // everyone else gets the role they hold on the container.
      const role: Role = people.get(m.target) === "viewer" ? "viewer" : "editor";
      batch.set(fs.doc(db, "share_invites", m.id), {
        collabId: m.collabId,
        recipeTitle: m.title,
        ownerUid: byUid,
        targetUid: m.target,
        role,
        status: "pending",
        kind: "recipe",
        via: container.id,
        createdAt: fs.Timestamp.now(),
      });
    }
    await batch.commit();
  }
  for (const m of missing) known.add(m.id);
}

// ---------------------------------------------------------------------------
// ContainerCollab.publish / retire.

/**
 * A save by the owner or an editor: every recipe in it made shareable, the
 * document's title and content rewritten, and every participant let into
 * the recipes this account owns that are new to them. Nothing for an
 * unshared item; a viewer is refused. A deleted document is left alone —
 * the open page's follower turns the copy private.
 */
export async function publishContainer(opts: {
  collabId: string | null;
  role: Role | null;
  title: string;
  recipeIds: string[];
  encode: (linked: LinkedRecipes) => Record<string, unknown>;
  lang: string;
}): Promise<void> {
  const uid = currentUid();
  if (!safeId(opts.collabId) || !uid) return;
  if (opts.role === "viewer") throw new Error("viewer-cannot-edit");
  const linked = await ensureRecipeCollabs(opts.recipeIds, uid, opts.lang);
  const content = opts.encode(linked);
  let remote: ContainerDoc | null | "denied";
  try {
    remote = await readContainer(opts.collabId);
  } catch {
    return; // unreachable: the local copy is saved, the next save carries it
  }
  if (remote === null || remote === "denied") return;
  const { fs, db } = await firestore();
  await settled(fs.updateDoc(fs.doc(db, "collab_containers", opts.collabId), { title: opts.title, content, updatedAt: fs.serverTimestamp(), updatedBy: uid }));
  const others = [...participants(remote).keys()].filter((p) => p !== uid);
  if (linked.owned.length === 0 || others.length === 0) return;
  try {
    await inviteToRecipes(remote, linked.owned, uid);
  } catch {
    /* the app logs and moves on */
  }
}

/** Before a local copy is deleted: the owner takes the document down, a member leaves it. */
export async function retireContainer(collabId: string | null, mine: boolean): Promise<void> {
  const uid = currentUid();
  if (!safeId(collabId) || !uid) return;
  try {
    const { fs, db } = await firestore();
    const ref = fs.doc(db, "collab_containers", collabId);
    if (mine) await settled(fs.deleteDoc(ref));
    else await settled(fs.updateDoc(ref, { [`members.${uid}`]: fs.deleteField(), memberUids: fs.arrayRemove(uid), updatedAt: fs.serverTimestamp() }));
  } catch {
    /* best effort, as the app */
  }
}

// ---------------------------------------------------------------------------
// RecipeLinker.materialize — inbound.

/**
 * Collab id → local id for every local recipe with a collab id, plus every
 * shared recipe in `collabIds` this account can be let into: a pending
 * `via` invite is accepted (invite marked, roster joined, local copy saved),
 * an accepted one whose recipe is not cached here is fetched. One it was
 * never invited to is left out.
 */
// Invite ids just read as missing, so a container's every snapshot does not
// probe them again (forgotten after a few minutes: an invite can still come).
const noInvite = new Map<string, number>();
const NO_INVITE_TTL = 5 * 60_000;

export async function materializeRecipes(collabIds: Iterable<string>, uid: string, lang: string): Promise<Map<string, string>> {
  const ids = [...new Set(collabIds)].filter((id) => safeId(id));
  const byCollabId = new Map<string, string>();
  const { fs, db } = await firestore();
  // The local copies of just these shared recipes (by collabId, 30 per
  // query), not a read of the whole library on every container snapshot.
  const root = await rootFor("recipes");
  for (let i = 0; i < ids.length; i += 30) {
    const snap = await fs.getDocs(fs.query(fs.collection(db, `${root}/recipes`), fs.where("collabId", "in", ids.slice(i, i + 30))));
    for (const d of snap.docs) {
      const r = normalizeRecipe(d.data());
      if (r.collabId && r.id && !byCollabId.has(r.collabId)) byCollabId.set(r.collabId, r.id);
    }
  }
  for (const collabId of ids) {
    if (byCollabId.has(collabId)) continue;
    try {
      const inviteId = `${collabId}_${uid}`;
      const missedAt = noInvite.get(inviteId);
      if (missedAt !== undefined && Date.now() - missedAt < NO_INVITE_TTL) continue;
      const invite = await readInvite(inviteId);
      if (!invite) {
        noInvite.set(inviteId, Date.now());
        continue;
      }
      noInvite.delete(inviteId);
      const role: Role = invite.role === "editor" ? "editor" : invite.role === "owner" ? "owner" : "viewer";
      let grantedRole = role;
      if (invite.status === "pending") {
        await fs.updateDoc(fs.doc(db, "share_invites", inviteId), { status: "accepted", respondedAt: fs.serverTimestamp() });
        try {
          await fs.updateDoc(fs.doc(db, "collab_recipes", collabId), { [`members.${uid}`]: role, memberUids: fs.arrayUnion(uid), updatedAt: fs.serverTimestamp() });
        } catch (e) {
          // The owner deleted the recipe meanwhile: close the invite as declined.
          if (code(e) === "not-found" || code(e) === "permission-denied") {
            await fs.updateDoc(fs.doc(db, "share_invites", inviteId), { status: "declined", respondedAt: fs.serverTimestamp() }).catch(() => {});
            continue;
          }
          throw e;
        }
      } else if (invite.status !== "accepted") continue;
      const snap = await fs.getDoc(fs.doc(db, "collab_recipes", collabId));
      if (!snap.exists()) continue;
      const data = snap.data() as Record<string, unknown>;
      if (invite.status === "accepted") {
        const doc = containerFrom(collabId, data);
        grantedRole = roleIn(doc, uid);
      }
      // RespondToShareInviteUseCase.localCopy: a fresh local id, tagged.
      const copy = normalizeRecipe({
        ...data,
        id: crypto.randomUUID(),
        createdAt: new Date().toISOString(),
        collabId,
        collabRole: grantedRole,
        sourceChannel: null,
        sourceUrl: null,
        savedFromSharedId: null,
        pendingAnalysis: false,
        sharedRecipeId: null,
        contentLang: null,
        contentVersion: 0,
      });
      const saved = await saveRecipe(copy, lang);
      byCollabId.set(collabId, saved.id);
    } catch {
      // Unreachable or refused: left out; the next sync tries again.
    }
  }
  return byCollabId;
}

/** The collab ids of the recipes a container's content points at. */
export function containerRecipeCollabIds(content: unknown): string[] {
  const c = (content && typeof content === "object" ? content : {}) as Record<string, unknown>;
  const out: string[] = [];
  for (const r of Array.isArray(c.recipes) ? c.recipes : []) {
    const id = (r as Record<string, unknown> | null)?.collabId;
    if (safeId(id)) out.push(id);
  }
  for (const m of Array.isArray(c.meals) ? c.meals : []) {
    for (const it of Array.isArray((m as Record<string, unknown> | null)?.items) ? ((m as Record<string, unknown>).items as unknown[]) : []) {
      const id = (it as Record<string, unknown> | null)?.recipeCollabId;
      if (safeId(id)) out.push(id);
    }
  }
  return out;
}
