import { lazy } from "react";
// Meal plans: the list of plans and the weekly planner (ff_meal_plans).
import type { FeatureRoute } from "../../app/routing";
import { FeatureGate } from "../../components/FeatureGate";

// Pages load on first visit (a chunk per page), not with the whole app.
const PlansPage = lazy(() => import("./PlansPage").then((m) => ({ default: m.PlansPage })));
const PlanBoardPage = lazy(() => import("./PlanBoardPage").then((m) => ({ default: m.PlanBoardPage })));

export const routes: FeatureRoute[] = [
  {
    path: "/plans",
    element: (
      <FeatureGate flag="ff_meal_plans" page>
        <PlansPage />
      </FeatureGate>
    ),
  },
  {
    path: "/plans/:id",
    element: (
      <FeatureGate flag="ff_meal_plans" page>
        <PlanBoardPage />
      </FeatureGate>
    ),
  },
];
