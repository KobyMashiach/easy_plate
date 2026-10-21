import { lazy } from "react";
// Recipes: the library, the protected details view, the editor and cook mode.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const CookModePage = lazy(() => import("./CookModePage").then((m) => ({ default: m.CookModePage })));
const RecipeDetailsPage = lazy(() => import("./RecipeDetailsPage").then((m) => ({ default: m.RecipeDetailsPage })));
const RecipeEditPage = lazy(() => import("./RecipeEditorPage").then((m) => ({ default: m.RecipeEditPage })));
const RecipeNewPage = lazy(() => import("./RecipeEditorPage").then((m) => ({ default: m.RecipeNewPage })));
const RecipesListPage = lazy(() => import("./RecipesListPage").then((m) => ({ default: m.RecipesListPage })));

export const routes: FeatureRoute[] = [
  { path: "/recipes", element: <RecipesListPage /> },
  { path: "/recipes/new", element: <RecipeNewPage /> },
  { path: "/recipes/:id", element: <RecipeDetailsPage /> },
  { path: "/recipes/:id/edit", element: <RecipeEditPage /> },
  { path: "/cook/:id", element: <CookModePage />, bare: true },
  // A community recipe cooks from the post itself (the app saves nothing first).
  { path: "/cook/community/:postId", element: <CookModePage community />, bare: true },
];
