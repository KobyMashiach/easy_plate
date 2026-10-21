// Saving and deleting recipes the way the app's RecipesRepositoryImpl does:
// stamp language/version, write the whole record, and take the photo with
// a deleted recipe so it is not billed forever.
import { deleteRecord, getRecord, putRecord } from "./cloud";
import { deleteOwnImage } from "./storage";
import { normalizeRecipe, recipeToDart, stampRecipe, type Recipe } from "../models/recipe";

// One save at a time per recipe: two quick saves of the same recipe would
// otherwise both stamp from the same stored contentVersion and the later one
// would win (the books/plans stores serialize the same way). A failed save
// does not block the next one.
const queues = new Map<string, Promise<unknown>>();

function serial<T>(id: string, run: () => Promise<T>): Promise<T> {
  const prev = queues.get(id) ?? Promise.resolve();
  const next = prev.catch(() => {}).then(run);
  queues.set(id, next);
  void next.finally(() => {
    if (queues.get(id) === next) queues.delete(id);
  }).catch(() => {});
  return next;
}

/** The record a `mustExist` save was meant to update was deleted (on another device, or by the owner). */
export class RecipeGoneError extends Error {
  constructor(readonly id: string) {
    super("recipe gone");
    this.name = "RecipeGoneError";
  }
}

/**
 * `mustExist`: an update of a copy that should already be stored. When it is
 * gone, nothing is written and RecipeGoneError is thrown — a refresh never
 * brings back a recipe deleted on another device. Never set it for a first
 * creation.
 */
export function saveRecipe(recipe: Recipe, lang: string, { mustExist = false }: { mustExist?: boolean } = {}): Promise<Recipe> {
  return serial(recipe.id, async () => {
    const previousRaw = await getRecord<unknown>("recipes", recipe.id);
    if (mustExist && !previousRaw) throw new RecipeGoneError(recipe.id);
    const previous = previousRaw ? normalizeRecipe(previousRaw) : null;
    const stamped = stampRecipe(recipe, previous, lang);
    // The old picture is not deleted when it changes: a community post can
    // still show it. The app removes a photo only with its recipe.
    await putRecord("recipes", stamped.id, recipeToDart(stamped));
    return stamped;
  });
}

export async function deleteRecipe(recipe: Recipe): Promise<void> {
  await deleteRecord("recipes", recipe.id);
  void deleteOwnImage(recipe.imageStoragePath);
}
