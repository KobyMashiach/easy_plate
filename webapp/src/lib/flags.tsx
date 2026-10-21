/* eslint-disable react-refresh/only-export-components */
// Feature switches, read from the same Remote Config the app reads
// (lib/core/features/features_flags.dart). Each `ff_*` parameter is
//   0 hidden · 1 coming soon · 2 on for everyone · 3 Premium only
// and what a screen draws is that value with the plan applied:
//   hidden | comingSoon | locked (Premium-only, free account) | enabled.
// Unread or unreachable → 2 (enabled), the app's own default, so a failed
// fetch never hides anything. A superuser (users/{uid}.permission) sees all.
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import { useAuth } from "./auth";
import { withFirestore } from "./firebase";

export type Flag =
  | "ff_books" | "ff_meal_plans" | "ff_grocery_lists" | "ff_community"
  | "ff_ingest_text" | "ff_ingest_web_search" | "ff_ingest_link" | "ff_ingest_social_video" | "ff_ingest_ai_request" | "ff_ingest_file"
  | "ff_save_with_ai" | "ff_cook_mode" | "ff_cook_timers" | "ff_nutrition" | "ff_recipe_image_ai" | "ff_recipe_image_search" | "ff_grocery_from_recipe"
  | "ff_shared_recipes" | "ff_forum" | "ff_likes"
  | "ff_share_recipes" | "ff_share_books" | "ff_share_plans" | "ff_share_grocery_lists" | "ff_share_codes" | "ff_households"
  | "ff_price_book" | "ff_receipt_scan" | "ff_grocery_cost" | "ff_shopping_reminder"
  | "ff_assistant" | "ff_assistant_scoped" | "ff_assistant_voice" | "ff_notifications" | "ff_premium" | "ff_content_translation"
  | "ff_theming" | "ff_feedback" | "ff_whats_new" | "ff_support_chat" | "ff_web_checkout" | "ff_web_checkout_il" | "ff_web_checkout_intl";

export type Access = "hidden" | "comingSoon" | "locked" | "enabled";

export function resolveAccess(value: number, premium: boolean, allFeatures = false): Access {
  if (allFeatures) return "enabled";
  if (value === 0) return "hidden";
  if (value === 1) return "comingSoon";
  if (value === 3) return premium ? "enabled" : "locked";
  return "enabled";
}

interface FlagsState {
  ready: boolean;
  values: Record<string, string>;
  allFeatures: boolean;
  /** users/{uid}.permission === "admin" — shows the "Manage" (/admin) entry. */
  isAdmin: boolean;
  access: (flag: Flag) => Access;
  number: (key: string, fallback: number) => number;
  string: (key: string, fallback: string) => string;
}

const Ctx = createContext<FlagsState | null>(null);

// The values the browser activated last time (IndexedDB) come first, so a
// returning visitor's gates are right at once; then a fetch, which the SDK
// skips while the cached one is under an hour old.
async function loadRemoteConfig(app: FirebaseApp, onValues: (v: Record<string, string>) => void): Promise<void> {
  // Preview harness (emulator mode): no Remote Config emulator exists, so the
  // values come from a local JSON (every ff_* = 2) — never the real template.
  if (import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1") {
    const local = (await import("../../scripts/preview/remote-config.json")).default as Record<string, string | number | boolean>;
    onValues(Object.fromEntries(Object.entries(local).map(([k, v]) => [k, String(v)])));
    return;
  }
  const rc = await import("firebase/remote-config");
  const config = rc.getRemoteConfig(app);
  // The console changes reach the app on its next resume; an hour here.
  config.settings.minimumFetchIntervalMillis = 60 * 60 * 1000;
  // Pages wait for the switches (FeatureGate): never the SDK's 60 s default.
  config.settings.fetchTimeoutMillis = 8000;
  const read = () => {
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(rc.getAll(config))) out[k] = v.asString();
    return out;
  };
  await rc.ensureInitialized(config);
  if (config.lastFetchStatus !== "no-fetch-yet") onValues(read());
  await rc.fetchAndActivate(config);
  onValues(read());
}

export function FlagsProvider({ children }: { children: ReactNode }) {
  const { user, premium, entitlementLoaded } = useAuth();
  const [values, setValues] = useState<Record<string, string>>({});
  const [rcReady, setRcReady] = useState(false);
  // Tagged with the account it was read for: after an account switch the
  // previous account's permission must not show for even one render.
  const [perm, setPerm] = useState<{ uid: string; value: string } | null>(null);
  const uid = user?.uid ?? null;
  const permission = perm && perm.uid === uid ? perm.value : "user";

  useEffect(() => {
    const app = getApps()[0] ?? null;
    if (!app) {
      setRcReady(true);
      return;
    }
    let live = true;
    loadRemoteConfig(app, (v) => {
      if (!live) return;
      setValues(v);
      setRcReady(true);
    })
      .catch(() => {})
      .finally(() => live && setRcReady(true));
    return () => {
      live = false;
    };
  }, []);

  // users/{uid}.permission — "superuser" sees every feature, like the app.
  useEffect(() => {
    setPerm(null);
    if (!uid) return;
    return withFirestore((fs, db) =>
      fs.onSnapshot(
        fs.doc(db, "users", uid),
        (snap) => setPerm({ uid, value: String(snap.get("permission") || "user") }),
        () => setPerm({ uid, value: "user" }),
      ),
    );
  }, [uid]);

  const allFeatures = permission === "superuser" || (permission === "admin" && values.admin_all_features === "true");
  // A Premium-only switch is only known once the plan is: until then a
  // Premium account would see "locked" and the upgrade card for a moment.
  const ready = rcReady && (!user || entitlementLoaded);

  const state = useMemo<FlagsState>(() => {
    const num = (key: string, fallback: number) => {
      const raw = values[key];
      const n = raw === undefined || raw.trim() === "" ? NaN : Number(raw);
      return Number.isFinite(n) ? n : fallback;
    };
    return {
      ready,
      values,
      allFeatures,
      isAdmin: permission === "admin",
      access: (flag) => resolveAccess(num(flag, 2), premium, allFeatures),
      number: num,
      string: (key, fallback) => (values[key] !== undefined && values[key] !== "" ? values[key] : fallback),
    };
  }, [ready, values, premium, allFeatures, permission]);

  return <Ctx.Provider value={state}>{children}</Ctx.Provider>;
}

export function useFlags(): FlagsState {
  const v = useContext(Ctx);
  if (!v) throw new Error("FlagsProvider missing");
  return v;
}

export function useAccess(flag: Flag): Access {
  return useFlags().access(flag);
}

// Kept for code that needs an app instance before Firebase is initialised
// elsewhere (never in practice: main.tsx initialises first).
export function ensureApp(options: object): FirebaseApp {
  return getApps()[0] ?? initializeApp(options);
}
