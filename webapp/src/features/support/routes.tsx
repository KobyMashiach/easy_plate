import { lazy } from "react";
// Support: help, the feedback form, the support chat and what's new.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const SupportPage = lazy(() => import("./SupportPage").then((m) => ({ default: m.SupportPage })));
const ChatPage = lazy(() => import("./ChatPage").then((m) => ({ default: m.ChatPage })));

export const routes: FeatureRoute[] = [
  { path: "/support", element: <SupportPage /> },
  { path: "/support/:id", element: <ChatPage /> },
];
