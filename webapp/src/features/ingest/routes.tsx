import { lazy } from "react";
// Add a recipe: every way in the app has (paste, link, video, file, ask,
// search, by hand), each behind its own switch. ?url= / ?text= prefill it.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const IngestPage = lazy(() => import("./IngestPage").then((m) => ({ default: m.IngestPage })));

export const routes: FeatureRoute[] = [{ path: "/add", element: <IngestPage /> }];
