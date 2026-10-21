// Where a recipe change goes, the way the app's details page routes it:
//   - a shared (collab) recipe writes the shared document first
//     (SaveCollabRecipeUseCase → writeCollab), then the account's own copy;
//     a viewer is refused here as well as in the UI and the rules;
//   - anything else is saved through recipesStore.saveRecipe (stamped).
// And the refresh the app runs when a shared recipe is opened
// (SyncCollabRecipeUseCase): the shared document is the truth.
import { firestore, getRecord } from "../../../lib/cloud";
import { saveRecipe } from "../../../lib/recipesStore";
import { normalizeIngredient, normalizeRecipe, recipeToDart, ALLERGENS, DIETARY, type Allergen, type CollabRole, type DietaryPreference, type Recipe } from "../../../models/recipe";

export class ViewerCannotEdit extends Error {}

/** _recipeFields in recipe_sharing_remote_datasource.dart. */
function collabFields(r: Recipe): Record<string, unknown> {
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

const timeout = (ms: number) => new Promise<"timeout">((resolve) => setTimeout(() => resolve("timeout"), ms));

export async function persistRecipe(recipe: Recipe, lang: string, uid: string): Promise<Recipe> {
  if (recipe.collabId) {
    if (recipe.collabRole === "viewer") throw new ViewerCannotEdit("viewer-cannot-edit");
    const { fs, db } = await firestore();
    const write = fs.updateDoc(fs.doc(db, "collab_recipes", recipe.collabId), {
      ...collabFields(recipe),
      updatedAt: fs.serverTimestamp(),
      updatedBy: uid,
    });
    // Offline the SDK queues the write and never resolves; after 8 s it is
    // taken as queued (the app's remoteWriteTimeout). A refusal still throws.
    await Promise.race([write, timeout(8000)]);
  }
  return saveRecipe(recipe, lang);
}

/** CollabRecipeEntity.roleOf: anyone not on the roster reads as a viewer. */
function roleOf(data: Record<string, unknown>, uid: string): CollabRole {
  if (data.ownerUid === uid) return "owner";
  const members = (data.members && typeof data.members === "object" ? data.members : {}) as Record<string, unknown>;
  const role = members[uid];
  return role === "owner" || role === "editor" || role === "viewer" ? role : "viewer";
}

/** guessLanguage (core/translation/content_translation.dart): by script; Latin is English unless French is the fallback. */
function guessLanguage(text: string, fallback: string): string {
  let he = 0;
  let ar = 0;
  let ru = 0;
  let latin = 0;
  for (const ch of text) {
    const c = ch.codePointAt(0) ?? 0;
    if (c >= 0x0590 && c <= 0x05ff) he++;
    else if (c >= 0x0600 && c <= 0x06ff) ar++;
    else if (c >= 0x0400 && c <= 0x04ff) ru++;
    else if ((c >= 0x41 && c <= 0x5a) || (c >= 0x61 && c <= 0x7a)) latin++;
  }
  const best = Math.max(he, ar, ru, latin);
  if (best === 0) return fallback;
  if (best === he) return "he";
  if (best === ar) return "ar";
  if (best === ru) return "ru";
  return fallback === "fr" ? "fr" : "en";
}

const CONTENT_LANGS = new Set(["he", "en", "ar", "fr", "ru"]);

/**
 * keepTranslation (core/translation/translated_merge.dart): when this copy
 * holds a translation of the shared words (another language, same shape),
 * its own words and language stamp stay and everything else comes from the
 * share — otherwise every refresh would pour the author's language back over
 * the translation and stamp it with the UI language.
 */
function keepTranslation(local: Recipe, merged: Recipe): Recipe {
  const localLang = local.contentLang;
  if (localLang === null || !CONTENT_LANGS.has(localLang)) return merged;
  if (guessLanguage(merged.title, localLang) === localLang) return merged;
  if (local.ingredients.length !== merged.ingredients.length || local.steps.length !== merged.steps.length) return merged;
  return {
    ...merged,
    title: local.title,
    ingredients: merged.ingredients.map((shared, i) => ({ name: local.ingredients[i].name, amount: shared.amount, unit: shared.unit })),
    steps: local.steps,
    contentLang: local.contentLang,
    contentVersion: local.contentVersion,
  };
}

/**
 * Lays the shared document over the account's copy (merged()), or — when the
 * document is gone or this account was removed — drops every trace of
 * sharing so the copy becomes a private recipe (orphan()). Writes only when
 * something changed. Throws when the read fails for any other reason
 * (offline): the caller keeps showing the copy.
 */
export async function syncCollab(local: Recipe, uid: string, lang: string): Promise<Recipe> {
  if (!local.collabId) return local;
  const { fs, db } = await firestore();
  let data: Record<string, unknown> | null = null;
  try {
    const snap = await fs.getDoc(fs.doc(db, "collab_recipes", local.collabId));
    data = snap.exists() ? (snap.data() as Record<string, unknown>) : null;
  } catch (e) {
    if (!String((e as { code?: string })?.code ?? e).includes("permission-denied")) throw e;
    data = null;
  }
  let next: Recipe;
  if (!data) {
    next = { ...local, collabId: null, collabRole: null };
  } else {
    const names = <X extends string>(v: unknown, all: readonly X[]) =>
      (Array.isArray(v) ? v : []).filter((x): x is X => typeof x === "string" && (all as readonly string[]).includes(x));
    const shared = normalizeRecipe({ ...data, id: local.id, createdAt: local.createdAt });
    const remotePath = typeof data.imageStoragePath === "string" ? data.imageStoragePath : null;
    next = {
      ...local,
      title: typeof data.title === "string" ? data.title : "",
      prepTimeMinutes: shared.prepTimeMinutes,
      cookTimeMinutes: shared.cookTimeMinutes,
      ingredients: (Array.isArray(data.ingredients) ? data.ingredients : []).filter((x) => x && typeof x === "object").map(normalizeIngredient),
      steps: shared.steps,
      dietaryTags: names<DietaryPreference>(data.dietaryTags, DIETARY),
      allergens: names<Allergen>(data.allergens, ALLERGENS),
      mayContain: names<Allergen>(data.mayContain, ALLERGENS),
      imageFileName: remotePath !== null ? (typeof data.imageFileName === "string" ? data.imageFileName : null) : local.imageFileName,
      imageStoragePath: remotePath ?? local.imageStoragePath,
      servings: shared.servings,
      nutrition: shared.nutrition,
      collabRole: roleOf(data, uid),
    };
    // A kept translation has the stored words, so saveRecipe leaves its stamp alone.
    next = keepTranslation(local, next);
  }
  if (JSON.stringify(recipeToDart(next)) === JSON.stringify(recipeToDart(local))) return local;
  return saveRecipe(next, lang);
}

/**
 * A change applied to the record as it is stored now, not to the snapshot a
 * screen showed when a slow call (an AI estimate, an upload) started — so a
 * photo, an edit or a sync that landed meanwhile is not written back over.
 * Null when the recipe is gone.
 */
export async function patchRecipe(id: string, uid: string, lang: string, change: (fresh: Recipe) => Recipe): Promise<Recipe | null> {
  const raw = await getRecord<unknown>("recipes", id);
  if (!raw) return null;
  return persistRecipe(change(normalizeRecipe(raw)), lang, uid);
}

/**
 * mergeEditedRecipe (recipe_details_page.dart), three-way: the editor holds
 * the record as it was when it opened (`before`) with the user's changes
 * (`edited`). Whatever landed meanwhile from elsewhere (`fresh`: the phone's
 * edit of another field, an AI estimate, a photo, a community link, a role
 * change) is taken wherever the user left that field alone, so the save does
 * not put the old values back. A field both sides changed keeps the user's.
 */
export function mergeEdited(edited: Recipe, before: Recipe, fresh: Recipe | null): Recipe {
  if (!fresh) return edited;
  const same = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);
  const pick = <X,>(mine: X, was: X, theirs: X): X => (same(mine, was) && !same(theirs, was) ? theirs : mine);
  const ingKey = (r: Recipe) => r.ingredients.map((i) => ({ n: i.name, a: i.amount, u: i.unit }));
  const photoMoved = fresh.imageFileName !== before.imageFileName || fresh.imageStoragePath !== before.imageStoragePath;
  return {
    ...edited,
    title: pick(edited.title, before.title, fresh.title),
    prepTimeMinutes: pick(edited.prepTimeMinutes, before.prepTimeMinutes, fresh.prepTimeMinutes),
    cookTimeMinutes: pick(edited.cookTimeMinutes, before.cookTimeMinutes, fresh.cookTimeMinutes),
    ingredients: same(ingKey(edited), ingKey(before)) && !same(ingKey(fresh), ingKey(before)) ? fresh.ingredients : edited.ingredients,
    steps: pick(edited.steps, before.steps, fresh.steps),
    dietaryTags: pick(edited.dietaryTags, before.dietaryTags, fresh.dietaryTags),
    servings: pick(edited.servings, before.servings, fresh.servings),
    nutrition: pick(edited.nutrition, before.nutrition, fresh.nutrition),
    allergens: pick(edited.allergens, before.allergens, fresh.allergens),
    mayContain: pick(edited.mayContain, before.mayContain, fresh.mayContain),
    pendingAnalysis: pick(edited.pendingAnalysis, before.pendingAnalysis, fresh.pendingAnalysis),
    // Not the editor's to change: as stored now.
    collabId: pick(edited.collabId, before.collabId, fresh.collabId),
    collabRole: pick(edited.collabRole, before.collabRole, fresh.collabRole),
    imageFileName: photoMoved ? fresh.imageFileName : edited.imageFileName,
    imageStoragePath: photoMoved ? fresh.imageStoragePath : edited.imageStoragePath,
    sharedRecipeId: fresh.sharedRecipeId !== before.sharedRecipeId ? fresh.sharedRecipeId : edited.sharedRecipeId,
    // The stored record's: saveRecipe moves the version on from it when the words differ.
    contentLang: fresh.contentLang ?? edited.contentLang,
    contentVersion: fresh.contentVersion,
  };
}
