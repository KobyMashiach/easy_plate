import { lazy } from "react";
// Household (Pro Duo / Pro Family): the shared account page.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const HouseholdPage = lazy(() => import("./HouseholdPage").then((m) => ({ default: m.HouseholdPage })));

export const routes: FeatureRoute[] = [{ path: "/household", element: <HouseholdPage /> }];
