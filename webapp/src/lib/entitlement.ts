// The same verdict the app reaches (EntitlementService.resolvePremium): the
// `premium` flag, honoured only inside its [premiumFrom, premiumUntil) window.
import type { Timestamp } from "firebase/firestore";

export interface EntitlementDoc {
  premium?: boolean;
  premiumFrom?: Timestamp | null;
  premiumUntil?: Timestamp | null;
  source?: "revenuecat" | "payplus" | "paddle" | "stripe" | "household" | "admin" | string;
  /** RevenueCat's store for the purchase: APP_STORE, PLAY_STORE, PADDLE (bought here, abroad), … */
  productId?: string;
  store?: string;
  cancelAtPeriodEnd?: boolean;
  adminLock?: boolean;
  subscriptionId?: string;
}

// web_customers/{uid}: the PayPlus (Israel) subscription behind web Premium
// (or a record of the retired direct-Paddle route), written by webBilling
// and the PayPlus webhook. A Paddle purchase made through RevenueCat lives on
// the entitlement only (source revenuecat, store PADDLE).
export interface WebCustomerDoc {
  provider?: "payplus" | "paddle";
  subscriptionId?: string;
  subscriptionStatus?: string;
  cancelAtPeriodEnd?: boolean;
  planId?: string;
  currentPeriodEnd?: Timestamp | null;
  everSubscribed?: boolean;
}

// Premium bought on the website (any provider, the dormant Stripe included):
// PayPlus by its source, Paddle through RevenueCat by RevenueCat's store
// (the retired direct route wrote source "paddle").
export const WEB_SOURCES = new Set(["payplus", "paddle", "stripe"]);
export const RC_WEB_STORES = new Set(["PADDLE", "RC_BILLING", "STRIPE"]);
export function isWebSource(source: string | undefined | null, store?: string | null): boolean {
  if (!source) return false;
  if (source === "revenuecat") return !!store && RC_WEB_STORES.has(store.toUpperCase());
  return WEB_SOURCES.has(source);
}
/** The same, for a whole entitlement document. */
export function isWebEntitlement(doc: EntitlementDoc | null | undefined): boolean {
  return !!doc && isWebSource(doc.source, doc.store);
}
/** Bought here through Paddle (RevenueCat's route, or the retired direct one). */
export function isPaddleEntitlement(doc: EntitlementDoc | null | undefined): boolean {
  return !!doc && (doc.source === "paddle" || (doc.source === "revenuecat" && (doc.store || "").toUpperCase() === "PADDLE"));
}

// Duck-typed rather than `instanceof Timestamp`: a value import would pull the
// whole Firestore SDK into the first bundle, and only a Timestamp read from a
// snapshot has toMillis().
const ms = (v: unknown): number | null =>
  v && typeof (v as Timestamp).toMillis === "function" ? (v as Timestamp).toMillis() : typeof v === "number" ? v : null;

export function resolvePremium(doc: EntitlementDoc | null | undefined, nowMs = Date.now()): boolean {
  if (!doc || doc.premium !== true) return false;
  const from = ms(doc.premiumFrom);
  if (from !== null && from > nowMs) return false;
  const until = ms(doc.premiumUntil);
  if (until !== null) return until > nowMs;
  return true;
}

export function premiumUntilMs(doc: EntitlementDoc | null | undefined): number | null {
  return doc ? ms(doc.premiumUntil) : null;
}

// HouseholdTier.fromProductId on the app side: a product id naming the tier.
export function tierOf(productId: string | undefined | null): "pro" | "duo" | "family" {
  const key = (productId || "").toLowerCase();
  if (key.includes("family")) return "family";
  if (key.includes("duo")) return "duo";
  return "pro";
}
