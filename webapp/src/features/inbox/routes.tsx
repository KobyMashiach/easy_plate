import { lazy } from "react";
// The notifications inbox.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const InboxPage = lazy(() => import("./InboxPage").then((m) => ({ default: m.InboxPage })));

export const routes: FeatureRoute[] = [{ path: "/inbox", element: <InboxPage /> }];
