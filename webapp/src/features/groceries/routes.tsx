import { lazy } from "react";
// Grocery lists: every list of the account, and one list (ff_grocery_lists).
import type { FeatureRoute } from "../../app/routing";
import { FeatureGate } from "../../components/FeatureGate";

// Pages load on first visit (a chunk per page), not with the whole app.
const GroceriesPage = lazy(() => import("./GroceriesPage").then((m) => ({ default: m.GroceriesPage })));
const GroceryListPage = lazy(() => import("./GroceryListPage").then((m) => ({ default: m.GroceryListPage })));

export const routes: FeatureRoute[] = [
  { path: "/groceries", element: <FeatureGate flag="ff_grocery_lists" page><GroceriesPage /></FeatureGate> },
  { path: "/groceries/:id", element: <FeatureGate flag="ff_grocery_lists" page><GroceryListPage /></FeatureGate> },
];
