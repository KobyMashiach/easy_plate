// Calls to the Cloud Functions the app uses, from the browser. Every one of
// these verifies the Firebase ID token and allows the site's origin (CORS,
// functions/origins.js). Errors come back as ApiError with the server's
// stable `code` (quota, rate_limited, too_many_lines, household_owner…).
import { auth, FUNCTIONS_ORIGIN } from "./firebase";
import { ApiError } from "./api";

export type FunctionName =
  | "aiProxy"
  | "socialRecipe"
  | "translateContent"
  | "imageSearch"
  | "speak"
  | "shareCodes"
  | "households"
  | "priceStats"
  | "deleteAccount";

async function token(fresh = false): Promise<string> {
  const user = auth().currentUser;
  if (!user) throw new ApiError(401, { error: { code: "unauthenticated", message: "Sign in first" } });
  return user.getIdToken(fresh);
}

/// Fired (on `window`) when a function answers 403 `account_disabled`: the
/// console switched the account off. AuthProvider listens and holds the
/// account on the blocked page, as the app's gate does.
export const ACCOUNT_DISABLED_EVENT = "easyplate:account-disabled";

function codeOf(json: unknown): string | null {
  const code = (json as { error?: { code?: unknown } } | null)?.error?.code;
  return typeof code === "string" ? code : null;
}

/** POST JSON to a function (optionally a sub-path), with the caller's ID token. */
export async function callFunction<T>(
  name: FunctionName,
  body: unknown,
  { path = "", headers = {}, signal }: { path?: string; headers?: Record<string, string>; signal?: AbortSignal } = {},
): Promise<T> {
  const payload = JSON.stringify(body);
  const send = async (fresh: boolean) => {
    const res = await fetch(`${FUNCTIONS_ORIGIN}/${name}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${await token(fresh)}`, ...headers },
      body: payload,
      signal,
    });
    const text = await res.text();
    let json: unknown = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch (_) {
      json = { error: { message: text.slice(0, 200) } };
    }
    return { res, json };
  };
  let { res, json } = await send(false);
  // The paid endpoints refuse a token without a phone number. Right after
  // linking one the cached token still lacks it: one refresh, one retry (the
  // app's rule for the same 403).
  if (res.status === 403 && codeOf(json) === "phone_required") ({ res, json } = await send(true));
  if (!res.ok) {
    const err = new ApiError(res.status, json);
    if (err.status === 403 && err.code === "account_disabled") window.dispatchEvent(new Event(ACCOUNT_DISABLED_EVENT));
    throw err;
  }
  return json as T;
}

/**
 * One Gemini Interactions call through the proxy — the exact request the app
 * sends (lib/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart
 * builds the bodies; copy them field for field). `sourceUrl` names the link
 * being extracted so the proxy's shared URL cache can answer it.
 */
export function interactions<T>(body: unknown, opts: { sourceUrl?: string; sourceKind?: string; feature?: string; signal?: AbortSignal } = {}): Promise<T> {
  const headers: Record<string, string> = {};
  if (opts.sourceUrl) headers["x-easyplate-source-url"] = opts.sourceUrl;
  if (opts.sourceKind) headers["x-easyplate-source-kind"] = opts.sourceKind;
  if (opts.feature) headers["x-easyplate-feature"] = opts.feature;
  return callFunction<T>("aiProxy", body, { path: "/v1beta/interactions", headers, signal: opts.signal });
}

/** The daily-quota object a 429 carries, when it is a quota refusal. */
export function quotaOf(err: unknown): { used: number; limit: number; kind?: string; requested?: number } | null {
  if (!(err instanceof ApiError) || err.status !== 429) return null;
  const e = (err.extra as { error?: { quota?: unknown } }).error;
  const q = e && typeof e === "object" ? (e as { quota?: unknown }).quota : null;
  return q && typeof q === "object" ? (q as { used: number; limit: number }) : null;
}
