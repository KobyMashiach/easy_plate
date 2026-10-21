import { lazy } from "react";
// Community: shared recipes and the forum, a community recipe, a thread.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const CommunityPage = lazy(() => import("./pages/CommunityPage").then((m) => ({ default: m.CommunityPage })));
const SharedRecipePage = lazy(() => import("./pages/SharedRecipePage").then((m) => ({ default: m.SharedRecipePage })));
const ThreadPage = lazy(() => import("./pages/ThreadPage").then((m) => ({ default: m.ThreadPage })));

export const routes: FeatureRoute[] = [
  { path: "/community", element: <CommunityPage /> },
  { path: "/community/recipe/:id", element: <SharedRecipePage /> },
  { path: "/community/thread/:id", element: <ThreadPage /> },
];
