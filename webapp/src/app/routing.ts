// How a feature plugs into the app: src/features/<feature>/routes.tsx exports
// `routes: FeatureRoute[]`. App.tsx discovers every routes.tsx by itself
// (import.meta.glob), so features never edit a shared route list.
import type { ReactNode } from "react";

export interface FeatureRoute {
  /** Path under /app, e.g. "/recipes/:id". */
  path: string;
  element: ReactNode;
  /** Reachable signed out (login-like pages). Default: requires sign-in. */
  public?: boolean;
  /** Draw without the side menu / dock (cook mode, full-screen readers). */
  bare?: boolean;
}

/**
 * Where to go back to after sign-in (`location.state.from`): only a path of
 * this app. Anything else — not a string, "//host", "/\host", a scheme, or
 * the sign-in pages themselves — falls back, so the redirect can never leave
 * the site or loop.
 */
export function safeAppPath(value: unknown, fallback = "/recipes"): string {
  if (typeof value !== "string" || value.length > 2048) return fallback;
  if (!value.startsWith("/") || value.startsWith("//") || value.startsWith("/\\")) return fallback;
  if (/[\u0000-\u001f]/.test(value)) return fallback;
  if (/^\/(login|phone)(?=[/?#]|$)/.test(value)) return fallback;
  return value;
}
