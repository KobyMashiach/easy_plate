import { lazy } from "react";
// Settings: profile, language, look, notifications and preferences. On a
// phone the notification settings and the preferences are their own pushed
// pages (the app's NotificationSettingsPage / PreferencesPage); on the
// desktop those two paths lead back to their sections of /settings.
import type { FeatureRoute } from "../../app/routing";

// Pages load on first visit (a chunk per page), not with the whole app.
const SettingsPage = lazy(() => import("./SettingsPage").then((m) => ({ default: m.SettingsPage })));
const NotificationSettingsPage = lazy(() => import("./SettingsPage").then((m) => ({ default: m.NotificationSettingsPage })));
const PreferencesPage = lazy(() => import("./SettingsPage").then((m) => ({ default: m.PreferencesPage })));

export const routes: FeatureRoute[] = [
  { path: "/settings", element: <SettingsPage /> },
  { path: "/settings/notifications", element: <NotificationSettingsPage /> },
  { path: "/settings/preferences", element: <PreferencesPage /> },
];
