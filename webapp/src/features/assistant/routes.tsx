import { lazy } from "react";
// Shefi, the in-app assistant: /assistant (general) and
// /assistant?scope=recipe|plan|list&id=… (one item). The page gates itself on
// ff_assistant (Premium-only shows the app's locked view), ff_assistant_scoped
// and ff_assistant_voice.
import type { FeatureRoute } from "../../app/routing";

// Loaded on first visit (its own chunk), not with the whole app.
const AssistantPage = lazy(() => import("./AssistantPage").then((m) => ({ default: m.AssistantPage })));

export const routes: FeatureRoute[] = [{ path: "/assistant", element: <AssistantPage /> }];
