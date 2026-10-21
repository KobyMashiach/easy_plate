// The community recipe's two actions, as RecipeDetailsPage has them for a
// read-only recipe in the app: "start cooking" opens cook mode on the post
// itself (nothing is saved into My Recipes first; ff_cook_mode, only with
// steps) and "create a shopping list" asks for the name and amount
// (showRecipeGroceryListSheet), makes a new list from the recipe in hand
// (CreateRecipeGroceryListUseCase — a new list every time, made the open
// one), then offers "open list" (the groceries tab) or "stay here"
// (ff_grocery_from_recipe, only with ingredients).
import { useState } from "react";
import { useI18n } from "../../../lib/i18n";
import { useIsPhone } from "../../../components/useIsPhone";
import { usePhoneNavigate } from "../../../components/pageTransition";
import { AppDialog } from "../../../components/AppDialog";
import { RecipeListDialog } from "../../groceries/dialogs";
import { createRecipeList } from "../../groceries/store";
import type { GroceryList } from "../../../models/groceryList";
import type { SharedPost } from "../data/sharedRecipes";

export function useCommunityRecipeActions(post: SharedPost | null | undefined, onError: (msg: string) => void) {
  const { t, lang } = useI18n();
  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const [sheet, setSheet] = useState(false);
  const [busy, setBusy] = useState(false);
  // The list just made; kept while its dialog closes so the words do not blank mid-exit.
  const [created, setCreated] = useState<GroceryList | null>(null);
  const [asking, setAsking] = useState(false);
  const recipe = post?.recipe ?? null;

  // The post rides along so cook mode does not fetch it (or count it) again.
  const cook = () => {
    if (post) go(`/cook/community/${encodeURIComponent(post.id)}`, { state: { post } });
  };

  const create = async (name: string, scale: number) => {
    if (!recipe || busy) return;
    setBusy(true);
    try {
      const list = await createRecipeList(recipe, name, scale, lang);
      setSheet(false);
      setCreated(list);
      setAsking(true);
    } catch {
      onError(t("common.error"));
    } finally {
      setBusy(false);
    }
  };

  // The groceries tab opens the active list (already this one); the desktop
  // lists page has no such tab, so the list's own page.
  const openList = () => {
    const list = created;
    setAsking(false);
    if (list) go(phone ? "/groceries" : `/groceries/${encodeURIComponent(list.id)}`);
  };

  const elements = (
    <>
      <RecipeListDialog recipe={sheet ? recipe : null} initialName="" busy={busy} onClose={() => setSheet(false)} onCreate={(name, scale) => void create(name, scale)} />
      <AppDialog
        open={asking}
        kind="info"
        icon="shopping_cart"
        message={created ? t("groceries.listCreated", { name: created.name }) : ""}
        confirmLabel={t("groceries.openList")}
        cancelLabel={t("groceries.stayHere")}
        onConfirm={openList}
        onCancel={() => setAsking(false)}
      />
    </>
  );

  return { cook, shop: () => setSheet(true), elements };
}
