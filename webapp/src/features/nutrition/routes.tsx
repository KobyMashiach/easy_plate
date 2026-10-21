import { lazy } from "react";
// The weekly nutrition dashboard of a meal plan (ff_nutrition).
import type { FeatureRoute } from "../../app/routing";
import { FeatureGate } from "../../components/FeatureGate";

// Pages load on first visit (a chunk per page), not with the whole app.
const NutritionPage = lazy(() => import("./NutritionPage").then((m) => ({ default: m.NutritionPage })));

export const routes: FeatureRoute[] = [
  {
    path: "/nutrition",
    element: (
      <FeatureGate flag="ff_nutrition" page>
        <NutritionPage />
      </FeatureGate>
    ),
  },
];
