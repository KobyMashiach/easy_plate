// One community recipe for cook mode (/cook/community/:postId), read-only
// from shared_recipes — the app hands RecipeDetailsPage's RecipeEntity to
// CookModePage as it is, nothing saved into My Recipes. Arriving from the
// recipe page (the post passed in navigation state) the day's count was
// already applied there; arriving by address the same gate applies here
// (a recipe already opened today is free again).
import { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useFlags } from "../../../lib/flags";
import type { Recipe } from "../../../models/recipe";
import { getSharedPost, type SharedPost } from "./sharedRecipes";
import { openSharedAllowed } from "./usage";

export interface SharedRecipeState {
  /** undefined while loading, null when there is no such post (or it was refused). */
  recipe: Recipe | null | undefined;
  error: Error | null;
  /** The free tier's daily allowance is spent. */
  blocked: boolean;
}

export function useSharedRecipe(postId: string | undefined): SharedRecipeState {
  const { user, premium } = useAuth();
  const flags = useFlags();
  const uid = user?.uid ?? "";
  const passed = (useLocation().state as { post?: SharedPost } | null)?.post;
  const initial = postId && passed && passed.id === postId ? passed.recipe : undefined;
  const [state, setState] = useState<SharedRecipeState>({ recipe: initial, error: null, blocked: false });

  useEffect(() => {
    if (!postId || !uid || initial) return;
    let live = true;
    (async () => {
      try {
        const post = await getSharedPost(postId, uid);
        if (!live) return;
        if (post) {
          const ok = await openSharedAllowed(post.id, post.authorUid, uid, { premium, number: flags.number, string: flags.string }).catch(() => true);
          if (!live) return;
          if (!ok) return setState({ recipe: null, error: null, blocked: true });
        }
        setState({ recipe: post ? post.recipe : null, error: null, blocked: false });
      } catch (e) {
        if (live) setState({ recipe: null, error: e as Error, blocked: false });
      }
    })();
    return () => {
      live = false;
    };
    // Asked once per open, not on every flag refresh.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [postId, uid]);

  return postId ? state : { recipe: undefined, error: null, blocked: false };
}
