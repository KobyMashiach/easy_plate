// One recipe of this account, live, normalised. `undefined` while loading,
// `null` when there is no such record.
import { useMemo } from "react";
import { useAuth } from "../../../lib/auth";
import { useRecord } from "../../../lib/cloud";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";

export function useRecipe(id: string | undefined): { recipe: Recipe | null | undefined; error: Error | null } {
  const { user } = useAuth();
  const { item, error } = useRecord<unknown>("recipes", user?.uid, id);
  const recipe = useMemo(() => (item === undefined ? undefined : item === null ? null : normalizeRecipe(item)), [item]);
  return { recipe, error };
}

/** The file name the app caches a picture under: the storage object's own name. */
export function fileNameOf(path: string | null): string | null {
  if (!path) return null;
  const name = path.split("/").pop();
  return name || null;
}
