import { lazy } from "react";
// Sharing: the management page, the share sheet for any recipe, book, plan
// or list, and joining with a code or a link.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const SharingPage = lazy(() => import("./pages/SharingPage").then((m) => ({ default: m.SharingPage })));
const SharePage = lazy(() => import("./pages/SharePage").then((m) => ({ default: m.SharePage })));
const JoinPage = lazy(() => import("./pages/JoinPage").then((m) => ({ default: m.JoinPage })));

export const routes: FeatureRoute[] = [
  { path: "/sharing", element: <SharingPage /> },
  { path: "/sharing/share", element: <SharePage /> },
  { path: "/join", element: <JoinPage /> },
  { path: "/join/:code", element: <JoinPage /> },
];
