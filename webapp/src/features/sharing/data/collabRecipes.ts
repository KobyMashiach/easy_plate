// collab_recipes/{id}: a recipe shared between accounts — the source of truth
// every member's local copy (users/{uid}/recipes or the household's) caches.
// Field for field RecipeSharingFirestoreDataSource; the flows are
// ShareRecipeUseCase, RespondToShareInviteUseCase and SyncCollabRecipeUseCase.
import { firestore, getRecord, listRecords, newId } from "../../../lib/cloud";
import { auth } from "../../../lib/firebase";
import { RecipeGoneError, saveRecipe } from "../../../lib/recipesStore";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";
import { anyResolves, findUidByContact, normalizeContact } from "./contact";
import { inviteFields, inviteIsDead, readInvite, setInviteStatus } from "./invites";
import { CollabMissing, fsCode, inviteIdFor, ItemGone, roleFrom, ShareFailure, tsMs, type CollabRole, type ShareInvite } from "./types";

export interface CollabRecipe {
  id: string;
  ownerUid: string;
  /** Everyone besides the owner, with what they may do. */
  members: Record<string, CollabRole>;
  recipe: Recipe;
  updatedAtMs: number;
}

export type CollabCollection = "collab_recipes" | "collab_containers";

/** A recipe this account wrote: not saved from the community, not someone else's share. */
export function isMine(r: Recipe): boolean {
  return r.savedFromSharedId === null && (r.collabRole === null || r.collabRole === "owner");
}

/** The recipe body every shared copy carries (_recipeFields; also a community post's body). */
export function recipeFields(r: Recipe): Record<string, unknown> {
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
    nutrition: r.nutrition
      ? { calories: Math.trunc(r.nutrition.calories), proteinGrams: r.nutrition.proteinGrams, carbsGrams: r.nutrition.carbsGrams, fatGrams: r.nutrition.fatGrams }
      : null,
  };
}

export function membersFrom(raw: unknown): Record<string, CollabRole> {
  const out: Record<string, CollabRole> = {};
  if (raw && typeof raw === "object") {
    for (const [uid, role] of Object.entries(raw as Record<string, unknown>)) {
      const r = roleFrom(role);
      if (r) out[uid] = r;
    }
  }
  return out;
}

export function collabRecipeFrom(id: string, data: Record<string, unknown>): CollabRecipe {
  const createdMs = tsMs(data.createdAt) ?? Date.now();
  return {
    id,
    ownerUid: typeof data.ownerUid === "string" ? data.ownerUid : "",
    members: membersFrom(data.members),
    recipe: normalizeRecipe({ ...data, id, createdAt: new Date(createdMs).toISOString() }),
    updatedAtMs: tsMs(data.updatedAt) ?? createdMs,
  };
}

export function roleOf(c: { ownerUid: string; members: Record<string, CollabRole> }, uid: string): CollabRole {
  return uid === c.ownerUid ? "owner" : c.members[uid] ?? "viewer";
}

export async function getCollabRecipe(id: string): Promise<CollabRecipe | null> {
  const { fs, db } = await firestore();
  const snap = await fs.getDoc(fs.doc(db, "collab_recipes", id));
  return snap.exists() ? collabRecipeFrom(snap.id, snap.data()) : null;
}

export async function createCollabRecipe(recipe: Recipe, ownerUid: string): Promise<string> {
  const { fs, db } = await firestore();
  const id = newId();
  await fs.setDoc(fs.doc(db, "collab_recipes", id), {
    ...recipeFields(recipe),
    ownerUid,
    members: {},
    // memberUids mirrors the keys of members: a map key cannot be queried.
    memberUids: [],
    createdAt: fs.Timestamp.now(),
    updatedAt: fs.Timestamp.now(),
    updatedBy: ownerUid,
  });
  return id;
}

/** Adds exactly this account with the role it was offered (the accept rule). */
export async function joinCollab(collection: CollabCollection, id: string, uid: string, role: CollabRole): Promise<void> {
  const { fs, db } = await firestore();
  await fs.updateDoc(fs.doc(db, collection, id), {
    [`members.${uid}`]: role,
    memberUids: fs.arrayUnion(uid),
    updatedAt: fs.serverTimestamp(),
  });
}

/** The owner taking someone out, or a member leaving. */
export async function removeCollabMember(collection: CollabCollection, id: string, memberUid: string): Promise<void> {
  const { fs, db } = await firestore();
  const ref = fs.doc(db, collection, id);
  const roster = { [`members.${memberUid}`]: fs.deleteField(), memberUids: fs.arrayRemove(memberUid), updatedAt: fs.serverTimestamp() };
  const me = auth().currentUser?.uid;
  if (!me || memberUid === me) {
    // Leaving: the invite stays (it is the owner's to retire).
    await fs.updateDoc(ref, roster);
    return;
  }
  // The owner taking someone out: their accepted invite goes in the same
  // transaction, or it would let them accept their way back in.
  const inviteRef = fs.doc(db, "share_invites", inviteIdFor(id, memberUid));
  await fs.runTransaction(db, async (tx) => {
    const invite = await tx.get(inviteRef);
    tx.update(ref, roster);
    if (invite.exists() && invite.get("ownerUid") === me) tx.delete(inviteRef);
  });
}

export async function collabRecipesOwnedBy(uid: string): Promise<CollabRecipe[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "collab_recipes"), fs.where("ownerUid", "==", uid)));
  return snap.docs.map((d) => collabRecipeFrom(d.id, d.data()));
}

export async function collabRecipesSharedWith(uid: string): Promise<CollabRecipe[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "collab_recipes"), fs.where("memberUids", "array-contains", uid)));
  return snap.docs.map((d) => collabRecipeFrom(d.id, d.data()));
}

/**
 * Invite and inbox item in one batch. An invite that still stands (pending,
 * or accepted by someone still on the roster) is left alone; a dead one is
 * deleted and written afresh, with a new inbox item id.
 */
export async function inviteToRecipe(p: { collabId: string; recipeTitle: string; ownerUid: string; targetUid: string; role: CollabRole }): Promise<void> {
  const { fs, db } = await firestore();
  const inviteId = inviteIdFor(p.collabId, p.targetUid);
  let notificationId = inviteId;
  const existing = await readInvite(inviteId);
  if (existing) {
    if (!(await inviteIsDead(existing, "collab_recipes"))) return;
    await fs.deleteDoc(fs.doc(db, "share_invites", inviteId));
    notificationId = `${inviteId}_${Date.now()}`;
  }
  const batch = fs.writeBatch(db);
  batch.set(
    fs.doc(db, "share_invites", inviteId),
    inviteFields(fs, { collabId: p.collabId, title: p.recipeTitle, ownerUid: p.ownerUid, targetUid: p.targetUid, role: p.role, kind: null }),
  );
  batch.set(fs.doc(db, "notifications", p.targetUid, "items", notificationId), {
    type: "shareInvite",
    fromUid: p.ownerUid,
    inviteId,
    collabId: p.collabId,
    recipeTitle: p.recipeTitle,
    role: p.role,
    read: false,
    createdAt: fs.Timestamp.now(),
  });
  await batch.commit();
}

/**
 * Makes the recipe shareable without inviting anyone (prepare): the collab
 * document exists and the local copy carries its id as owner. The contact
 * flow, share codes and the book/plan linker all start here.
 */
export async function prepareRecipe(recipe: Recipe, ownerUid: string, lang: string): Promise<{ owned: Recipe; collabId: string }> {
  if (!isMine(recipe)) throw new Error("Only recipes this account wrote can be shared");
  let current = recipe;
  if (current.collabId === null) {
    // The page may hold the recipe as it was before a code made it shared,
    // or before an edit elsewhere: the stored copy is the one written back
    // (and published), so a stale page never undoes that edit.
    const storedRaw = await getRecord<unknown>("recipes", recipe.id);
    // Deleted since the page loaded it (here or on the phone): writing the
    // held copy back would bring it back to life.
    if (!storedRaw) throw new ItemGone();
    const stored = normalizeRecipe(storedRaw);
    if (isMine(stored)) current = stored.collabId ? { ...stored, collabRole: stored.collabRole ?? "owner" } : stored;
  }
  if (current.collabId) return { owned: current, collabId: current.collabId };
  const collabId = await createCollabRecipe(current, ownerUid);
  let owned: Recipe;
  try {
    // Deleted while the collab document was being made: not brought back.
    owned = await saveRecipe({ ...current, collabId, collabRole: "owner" }, lang, { mustExist: true });
  } catch (e) {
    if (e instanceof RecipeGoneError) throw new ItemGone();
    throw e;
  }
  return { owned, collabId };
}

/** ShareRecipeUseCase.call: look the contact up, make the recipe shared, invite. */
export async function shareRecipeWithContact(
  recipe: Recipe,
  p: { contact: string; role: CollabRole; ownerUid: string; senderContacts: string[]; lang: string },
): Promise<Recipe> {
  if (!normalizeContact(p.contact)) throw new ShareFailure("invalid");
  const targetUid = await findUidByContact(p.contact);
  if (!targetUid) {
    const anySender = await anyResolves(p.senderContacts);
    throw new ShareFailure(anySender || p.senderContacts.length === 0 ? "notFound" : "directoryUnavailable");
  }
  if (targetUid === p.ownerUid) throw new ShareFailure("self");
  const { owned, collabId } = await prepareRecipe(recipe, p.ownerUid, p.lang);
  await inviteToRecipe({ collabId, recipeTitle: owned.title, ownerUid: p.ownerUid, targetUid, role: p.role });
  return owned;
}

/** A failed join that means the document is gone (not-found, or the rules found nothing to check). */
function isCollabGone(e: unknown): boolean {
  const code = fsCode(e);
  return code === "not-found" || code === "permission-denied";
}

/**
 * Accepts: the invite is marked, this account joins the roster, and the
 * document is read back (acceptInvite in both repositories). A document
 * the owner deleted meanwhile closes the invite as declined.
 */
export async function acceptAndJoin(invite: ShareInvite, collection: CollabCollection): Promise<Record<string, unknown> & { __id: string }> {
  const { fs, db } = await firestore();
  await setInviteStatus(invite.id, "accepted");
  try {
    await joinCollab(collection, invite.collabId, invite.targetUid, invite.role);
  } catch (e) {
    if (!isCollabGone(e)) throw e;
    try {
      await setInviteStatus(invite.id, "declined");
    } catch (_) {
      /* the dead invite stays; nothing else to do */
    }
    throw new CollabMissing();
  }
  const snap = await fs.getDoc(fs.doc(db, collection, invite.collabId));
  if (!snap.exists()) throw new CollabMissing();
  return { ...snap.data(), __id: snap.id };
}

/** RespondToShareInviteUseCase.localCopy: this account's cache of the shared recipe, under a fresh id. */
export function localCopy(collab: CollabRecipe, role: CollabRole): Recipe {
  const r = collab.recipe;
  return normalizeRecipe({
    id: newId(),
    title: r.title,
    prepTimeMinutes: r.prepTimeMinutes,
    cookTimeMinutes: r.cookTimeMinutes,
    ingredients: r.ingredients,
    steps: r.steps,
    dietaryTags: r.dietaryTags,
    allergens: r.allergens,
    mayContain: r.mayContain,
    imageFileName: r.imageFileName,
    imageStoragePath: r.imageStoragePath,
    servings: r.servings,
    nutrition: r.nutrition,
    collabId: collab.id,
    collabRole: role,
    createdAt: new Date().toISOString(),
  });
}

/** SyncCollabRecipeUseCase.merged: the shared document laid over the local copy. */
export function mergedCopy(local: Recipe, collab: CollabRecipe, uid: string): Recipe {
  const r = collab.recipe;
  return {
    ...local,
    title: r.title,
    prepTimeMinutes: r.prepTimeMinutes,
    cookTimeMinutes: r.cookTimeMinutes,
    ingredients: r.ingredients,
    steps: r.steps,
    dietaryTags: r.dietaryTags,
    allergens: r.allergens,
    mayContain: r.mayContain,
    imageFileName: r.imageStoragePath !== null ? r.imageFileName : local.imageFileName,
    imageStoragePath: r.imageStoragePath ?? local.imageStoragePath,
    servings: r.servings,
    nutrition: r.nutrition,
    collabId: collab.id,
    collabRole: roleOf(collab, uid),
  };
}

/** RespondToShareInviteUseCase.accept: join, then cache the recipe locally (once). */
export async function acceptRecipeInvite(invite: ShareInvite, lang: string, allRecipes?: Recipe[]): Promise<Recipe> {
  const raw = await acceptAndJoin(invite, "collab_recipes");
  const { __id, ...data } = raw;
  const collab = collabRecipeFrom(__id, data);
  const recipes = allRecipes ?? (await listRecords<unknown>("recipes")).map(normalizeRecipe);
  const existing = recipes.find((r) => r.collabId === collab.id) ?? null;
  // The role comes from the invite: the roster read back may lag the join.
  const local = existing ? { ...mergedCopy(existing, collab, invite.targetUid), collabRole: invite.role } : localCopy(collab, invite.role);
  // Updating a copy already held: deleted on another device meanwhile, it is
  // not brought back (RecipeGoneError → "accept failed"; a retry finds no
  // copy and makes a fresh one).
  return saveRecipe(local, lang, { mustExist: existing !== null });
}

export async function declineInvite(invite: ShareInvite): Promise<void> {
  await setInviteStatus(invite.id, "declined");
}
