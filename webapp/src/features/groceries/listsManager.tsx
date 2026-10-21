// Everything about having more than one list, shared by the desktop lists
// page and the phone's groceries tab (grocery_lists_ui.dart): a new list
// from the menus / a recipe / empty, `?fromRecipe=<id>` (the recipe page's
// "create a grocery list", ff_grocery_from_recipe), rename, delete or leave.
// `onOpen` decides what "open this list" means on each layout.
import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { newId, useCollection } from "../../lib/cloud";
import { normalizeRecipe } from "../../models/recipe";
import { isMyList, newGroceryList, type GroceryList, type GroceryListSource, type RecipeLike } from "../../models/groceryList";
import { usePrompt, useConfirm, useStatus } from "./kit";
import { NewListDialog, RecipeListDialog, RecipePickerDialog } from "./dialogs";
import { ListGoneError, createRecipeList, deleteList, loadRecipe, rebuiltItems, saveList, updateList } from "./store";

export function useListsManager(onOpen: (id: string) => void) {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const [params, setParams] = useSearchParams();
  const fromRecipeAccess = useAccess("ff_grocery_from_recipe");
  const status = useStatus();
  const prompt = usePrompt();
  const { ask, element: confirm } = useConfirm();

  const [creating, setCreating] = useState(false);
  const [pickingRecipe, setPickingRecipe] = useState(false);
  // Every recipe, live, only while the picker is open — not for the whole visit.
  const recipesLive = useCollection<unknown>("recipes", pickingRecipe ? user?.uid : null);
  const recipes = useMemo<RecipeLike[] | null>(() => (recipesLive.items ? recipesLive.items.map(normalizeRecipe) : null), [recipesLive.items]);
  const [pendingName, setPendingName] = useState("");
  const [recipe, setRecipe] = useState<RecipeLike | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  // ?fromRecipe=<id>: the recipe's own "grocery list" button.
  const fromRecipe = params.get("fromRecipe");
  const linkScale = Number(params.get("scale") ?? "1");
  const [pendingScale, setPendingScale] = useState(1);
  useEffect(() => {
    if (!fromRecipe || fromRecipeAccess !== "enabled") return;
    let alive = true;
    loadRecipe(fromRecipe)
      .then((r) => {
        if (!alive) return;
        if (r) {
          setPendingName("");
          setPendingScale(Number.isFinite(linkScale) && linkScale > 0 ? linkScale : 1);
          setRecipe(r);
        } else status.show("error", t("groceries.recipeMissing"));
      })
      .catch(() => alive && status.show("error", t("groceries.common.loadFailed")));
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fromRecipe, fromRecipeAccess]);

  const clearFromRecipe = () => {
    if (!fromRecipe) return;
    params.delete("fromRecipe");
    params.delete("scale");
    setParams(params, { replace: true });
  };

  /** createList: a plans list is built from every menu at once; an empty list is just saved. */
  const create = async (name: string, source: GroceryListSource) => {
    if (busy) return;
    if (source === "recipe") {
      setPendingName(name);
      setCreating(false);
      setPickingRecipe(true);
      return;
    }
    setBusy("create");
    try {
      let list = newGroceryList(newId(), name || t("groceries.defaultListName"), source);
      if (source === "plans") list = { ...list, items: (await rebuiltItems(list)) ?? [] };
      await saveList(list, null, lang);
      setCreating(false);
      onOpen(list.id);
    } catch {
      status.show("error", t("groceries.saveFailed"));
    } finally {
      setBusy(null);
    }
  };

  /** CreateRecipeGroceryListUseCase: the recipe's lines, scaled; title and servings copied. */
  const createFromRecipe = async (name: string, scale: number) => {
    if (!recipe || busy) return;
    setBusy("create");
    try {
      const list = await createRecipeList(recipe, name, scale, lang);
      setRecipe(null);
      clearFromRecipe();
      onOpen(list.id);
    } catch {
      status.show("error", t("groceries.saveFailed"));
    } finally {
      setBusy(null);
    }
  };

  const rename = async (list: GroceryList) => {
    const name = await prompt.ask(t("groceries.renameList"), t("groceries.listName"), list.name);
    if (!name || name === list.name) return;
    setBusy(list.id);
    try {
      // Onto the stored list: ticks made elsewhere since this page drew it stay.
      await updateList(list.id, (l) => ({ ...l, name }), lang);
    } catch (e) {
      status.show("error", e instanceof ListGoneError ? t("groceries.notFound") : t("groceries.saveFailed"));
    } finally {
      setBusy(null);
    }
  };

  /** A member does not delete a shared list; they leave it. Resolves true once gone. */
  const remove = async (list: GroceryList): Promise<boolean> => {
    const leaves = list.collabId !== null && !isMyList(list);
    const ok = await ask(leaves ? t("groceries.leave") : t("groceries.deleteList"), {
      body: leaves ? t("groceries.leaveListConfirm", { name: list.name }) : t("groceries.deleteListConfirm", { name: list.name }),
      confirm: leaves ? t("groceries.leave") : t("groceries.common.delete"),
      icon: leaves ? "logout" : "delete_outline",
    });
    if (!ok) return false;
    setBusy(list.id);
    try {
      await deleteList(list);
      return true;
    } catch {
      status.show("error", t("groceries.saveFailed"));
      return false;
    } finally {
      setBusy(null);
    }
  };

  const elements = (
    <>
      <NewListDialog open={creating} onClose={() => setCreating(false)} onPick={(name, source) => void create(name, source)} />
      <RecipePickerDialog
        open={pickingRecipe}
        recipes={recipes}
        error={recipesLive.error !== null}
        onClose={() => setPickingRecipe(false)}
        onPick={(r) => {
          setPickingRecipe(false);
          setPendingScale(1);
          setRecipe(r);
        }}
      />
      <RecipeListDialog
        recipe={recipe}
        initialName={pendingName}
        initialScale={pendingScale}
        busy={busy === "create"}
        onClose={() => {
          setRecipe(null);
          clearFromRecipe();
        }}
        onCreate={(name, scale) => void createFromRecipe(name, scale)}
      />
      {prompt.element}
      {confirm}
      {status.element}
    </>
  );

  return { busy, startNew: () => setCreating(true), rename, remove, elements };
}

export type ListsManager = ReturnType<typeof useListsManager>;
