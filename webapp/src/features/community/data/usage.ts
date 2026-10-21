// The free tier's daily allowance of opened community recipes
// (QuotaGates.openSharedRecipe + DailyQuotaPolicy.sharedRecipe), counted in
// the same record the app mirrors: users/{uid}/usage/current, the Dart
// DailyUsageModel { day, viewedSharedIds, aiExtractions }. Recipes 1–N of the
// day are free, the next M cost a rewarded video in the app, then the day
// is closed; a recipe already opened today is free again. The web shows no
// ads, so the video tier follows `ads_fail_open` (the app's rule for "no
// video could be served"): granted when it is on, refused when it is off.
import { getRecord, updateRecord } from "../../../lib/cloud";

export interface DailyUsage {
  day: string;
  viewedSharedIds: string[];
  aiExtractions: number;
}

/** yyyy-MM-dd in this device's timezone, as TrustedClock formats it. */
export function today(now = new Date()): string {
  const p = (n: number) => String(n).padStart(2, "0");
  return `${now.getFullYear()}-${p(now.getMonth() + 1)}-${p(now.getDate())}`;
}

export function normalizeUsage(raw: unknown): DailyUsage {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  return {
    day: typeof r.day === "string" ? r.day : today(),
    viewedSharedIds: Array.isArray(r.viewedSharedIds) ? r.viewedSharedIds.filter((x): x is string => typeof x === "string") : [],
    aiExtractions: typeof r.aiExtractions === "number" ? Math.trunc(r.aiExtractions) : 0,
  };
}

export function usageToDart(u: DailyUsage): Record<string, unknown> {
  return { day: u.day, viewedSharedIds: u.viewedSharedIds, aiExtractions: Math.trunc(u.aiExtractions) };
}

/** DailyUsageModel.forDay: only a later day resets (a clock moved back keeps what is stored). */
export function forDay(u: DailyUsage, day: string): DailyUsage {
  return day.localeCompare(u.day) > 0 ? { day, viewedSharedIds: [], aiExtractions: 0 } : u;
}

export type GateVerdict = "free" | "rewarded" | "blocked";

export function sharedVerdict(viewedToday: number, alreadyViewed: boolean, free: number, rewarded: number): GateVerdict {
  if (alreadyViewed) return "free";
  if (viewedToday < free) return "free";
  if (viewedToday < free + rewarded) return "rewarded";
  return "blocked";
}

export interface QuotaConfig {
  premium: boolean;
  number: (key: string, fallback: number) => number;
  string: (key: string, fallback: string) => string;
}

const bool = (cfg: QuotaConfig, key: string, fallback: boolean) => {
  const v = cfg.string(key, fallback ? "true" : "false").trim().toLowerCase();
  return v === "true" || v === "1";
};

/** MonetizationConfig.adFree: Premium, or the ads (and with them the quota) switched off. */
export function adFree(cfg: QuotaConfig): boolean {
  return cfg.premium || !bool(cfg, "ads_enabled", true);
}

/**
 * Whether this account may open the post now; records the view when it may.
 * The author's own posts never count.
 */
export async function openSharedAllowed(postId: string, authorUid: string, uid: string, cfg: QuotaConfig): Promise<boolean> {
  if (adFree(cfg) || authorUid === uid) return true;
  // In a transaction: the add-recipe page writes the same record.
  let allowed = false;
  await updateRecord("usage", "current", (stored) => {
    const usage = forDay(stored ? normalizeUsage(stored) : { day: today(), viewedSharedIds: [], aiExtractions: 0 }, today());
    const verdict = sharedVerdict(usage.viewedSharedIds.length, usage.viewedSharedIds.includes(postId), cfg.number("quota_shared_free", 3), cfg.number("quota_shared_rewarded", 3));
    allowed = verdict !== "blocked" && !(verdict === "rewarded" && !bool(cfg, "ads_fail_open", true));
    if (!allowed || usage.viewedSharedIds.includes(postId)) return null;
    return usageToDart({ ...usage, viewedSharedIds: [...usage.viewedSharedIds, postId] });
  });
  return allowed;
}

/** Free openings left today (for the banner); null when nothing is counted. */
export async function freeViewsLeft(uid: string, cfg: QuotaConfig): Promise<number | null> {
  if (adFree(cfg) || !uid) return null;
  const stored = await getRecord<unknown>("usage", "current");
  const usage = forDay(stored ? normalizeUsage(stored) : { day: today(), viewedSharedIds: [], aiExtractions: 0 }, today());
  return Math.max(0, cfg.number("quota_shared_free", 3) - usage.viewedSharedIds.length);
}
