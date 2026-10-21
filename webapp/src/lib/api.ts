// The two Cloud Functions behind the website. Every call is a POST with a
// JSON body naming an `action`; signed-in calls carry the Firebase ID token.
import { auth, FUNCTIONS_ORIGIN } from "./firebase";

export class ApiError extends Error {
  status: number;
  code: string;
  extra: Record<string, unknown>;
  constructor(status: number, body: unknown) {
    const b = (body ?? {}) as { error?: { code?: string; message?: string } } & Record<string, unknown>;
    super(b.error?.message || `HTTP ${status}`);
    this.status = status;
    this.code = b.error?.code || "failed";
    this.extra = b;
  }
}

async function post<T>(fn: "webBilling" | "upgradeLinks" | "deleteAccount", body: Record<string, unknown>, withAuth: boolean): Promise<T> {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (withAuth) {
    const user = auth().currentUser;
    if (!user) throw new ApiError(401, { error: { code: "unauthenticated", message: "Sign in first" } });
    headers.Authorization = `Bearer ${await user.getIdToken()}`;
  }
  const res = await fetch(`${FUNCTIONS_ORIGIN}/${fn}`, { method: "POST", headers, body: JSON.stringify(body) });
  const text = await res.text();
  let json: unknown = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = { error: { message: text.slice(0, 200) } };
  }
  if (!res.ok) throw new ApiError(res.status, json);
  return json as T;
}

export type Provider = "payplus" | "revenuecat";

// One plan on sale, from the webBilling catalogue (Remote Config
// `web_billing_catalog`). `planId` is what the entitlement records as
// productId (the household tier is in it).
export interface Plan {
  planId: string;
  provider: Provider;
  tier: "pro" | "duo" | "family";
  seats: number;
  interval: "month" | "year";
  intervalCount: number;
  amount: number;
  currency: string;
  name: string | null;
  description: string | null;
  introAmount: number | null;
  /** RevenueCat: the product (the Paddle price, pri_…) and package behind the plan. */
  productId?: string;
  packageId?: string | null;
}

export interface PlansResponse {
  enabled: boolean;
  flag: number;
  /** Who sells to this visitor: PayPlus for Israeli accounts, RevenueCat (Paddle) otherwise. */
  provider: Provider;
  providerFlag: number;
  comingSoon: boolean;
  configured: boolean;
  plans: Plan[];
}

// Both providers answer a checkout with a hosted page to go to: PayPlus's
// payment page, or RevenueCat's Web Purchase Link (pay.rev.cat, Paddle's
// checkout inside) carrying this account's uid, which the server put there.
export type CheckoutResult = { provider: "payplus"; url: string } | { provider: "revenuecat"; url: string };

export type ManageResult =
  | { provider: "revenuecat"; url: string }
  | { provider: "payplus"; confirmRequired?: boolean; cancelled?: boolean; alreadyCancelled?: boolean; currentPeriodEnd: number | null };

// The account page and the pricing page both ask for the plans on every
// visit; one answer per language and account is kept for a minute (a
// failure is not). A signed-in visitor sends the token: the server routes
// by the account's verified phone.
const plansCache = new Map<string, { at: number; promise: Promise<PlansResponse> }>();
const PLANS_TTL_MS = 60_000;
function plans(lang: string): Promise<PlansResponse> {
  const uid = auth().currentUser?.uid ?? "-";
  const key = `${lang}:${uid}`;
  const hit = plansCache.get(key);
  if (hit && Date.now() - hit.at < PLANS_TTL_MS) return hit.promise;
  const promise = post<PlansResponse>("webBilling", { action: "plans", lang }, uid !== "-");
  plansCache.set(key, { at: Date.now(), promise });
  promise.catch(() => plansCache.delete(key));
  return promise;
}

// The page goes wherever these URLs say, so only the providers' own hosted
// pages are followed (never javascript:, a relative path or another host):
// PayPlus payment pages (payments.payplus.co.il / paymentsdev…), RevenueCat
// purchase links (pay.rev.cat) and the portal a RevenueCat subscription is
// managed in (Paddle's customer-portal.paddle.com / sandbox-…, or a
// RevenueCat page).
export const PAYPLUS_PAGE = /^https:\/\/[a-z0-9-]+\.payplus\.co\.il\//;
export const PURCHASE_LINK = /^https:\/\/pay\.rev\.cat\//;
export const MANAGE_PAGE = /^https:\/\/([a-z0-9-]+\.)*(paddle\.com|revenuecat\.com|rev\.cat)\//;
function guardCheckout(r: CheckoutResult): CheckoutResult {
  if (r?.provider === "payplus" && typeof r.url === "string" && PAYPLUS_PAGE.test(r.url)) return r;
  if (r?.provider === "revenuecat" && typeof r.url === "string" && PURCHASE_LINK.test(r.url)) return r;
  throw new ApiError(502, { error: { code: "failed" } });
}
function guardManage(r: ManageResult): ManageResult {
  if (r?.provider === "revenuecat" && !(typeof r.url === "string" && MANAGE_PAGE.test(r.url))) throw new ApiError(502, { error: { code: "failed" } });
  return r;
}

export const billing = {
  plans,
  checkout: (planId: string, lang: string) => post<CheckoutResult>("webBilling", { action: "checkout", planId, lang }, true).then(guardCheckout),
  /** RevenueCat (Paddle): the portal URL. PayPlus: `confirm` false asks, true cancels at period end. */
  manage: (confirm = false) => post<ManageResult>("webBilling", { action: "manage", confirm }, true).then(guardManage),
  forgetPlans: () => plansCache.clear(),
};

export const links = {
  mint: (lang: string) => post<{ url: string; expiresAt: number }>("upgradeLinks", { action: "mint", lang }, true),
  send: (channel: "sms" | "email", lang: string, to?: string, signedIn = false) =>
    post<{ ok: true; channel: string; expiresAt?: number }>("upgradeLinks", { action: "send", channel, lang, ...(to ? { to } : {}) }, signedIn),
  redeem: (token: string, lang: string) => post<{ customToken: string; uid: string; path: string }>("upgradeLinks", { action: "redeem", token, lang }, false),
};

// The same self-service deletion the app's Settings row calls. The function
// may run for up to 300 s (the web subscription, every collection, the photos): no client
// timeout is set, so the browser waits for the real answer. 409
// `household_owner` = close the household in the app first.
export const account = {
  delete: () => post<{ ok: true }>("deleteAccount", { confirm: true }, true),
};

/// The two verdicts a paid endpoint, priceStats or shareCodes return about
/// the account itself (403 `phone_required` / `account_disabled`): these have
/// one wording everywhere, whatever the screen's own fallback says.
export function refusalText(t: (key: string) => string, err: unknown): string | null {
  if (err instanceof ApiError && err.status === 403 && (err.code === "phone_required" || err.code === "account_disabled")) return t(`err.${err.code}`);
  return null;
}

/// A failed call → the text to show. `${prefix}.${code}` first (a page's own
/// wording), then the shared `err.${code}`, then a network or generic line.
/// A fetch that never reached the server is a TypeError, not an ApiError.
export function apiErrorText(t: (key: string, vars?: Record<string, string | number>) => string, err: unknown, prefix?: string): string {
  if (!(err instanceof ApiError)) return t(err instanceof TypeError ? "common.network" : "common.error");
  for (const key of [prefix ? `${prefix}.${err.code}` : null, `err.${err.code}`]) {
    if (key && t(key) !== key) return t(key);
  }
  return t("common.error");
}
