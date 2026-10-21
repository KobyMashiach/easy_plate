// The daily AI allowance, counted exactly where the app counts it
// (lib/core/monetization: QuotaGates.extractWithAi, DailyUsageService,
// DailyQuotaPolicy.aiExtraction). The record is the account's personal
// `usage/current` document — DailyUsageModel.toJson: { day, viewedSharedIds,
// aiExtractions } — shared with the phone, so a slot spent here is spent there.
//
// The rewarded-video step has no web equivalent: a free account spends its
// `quota_ai_rewarded` slots without a video, and once they are gone it sees
// the "limit reached / upgrade" card instead of the ad sheet.
import { useCallback } from "react";
import { useAuth } from "../../lib/auth";
import { useRecord, updateRecord } from "../../lib/cloud";
import { useFlags } from "../../lib/flags";

export interface DailyUsage {
  day: string;
  viewedSharedIds: string[];
  aiExtractions: number;
}

export const USAGE_DOC_ID = "current";

/** TrustedClock.dayKeyOf: yyyy-MM-dd in the device's timezone. */
export function dayKey(d = new Date()): string {
  const two = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())}`;
}

export function normalizeUsage(raw: unknown, today = dayKey()): DailyUsage {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const usage: DailyUsage = {
    day: typeof r.day === "string" ? r.day : today,
    viewedSharedIds: Array.isArray(r.viewedSharedIds) ? r.viewedSharedIds.filter((x): x is string => typeof x === "string") : [],
    aiExtractions: typeof r.aiExtractions === "number" && Number.isFinite(r.aiExtractions) ? Math.trunc(r.aiExtractions) : 0,
  };
  // DailyUsageModel.forDay: only a *later* day resets; an earlier one keeps
  // what is stored rather than hand out a second allowance.
  return today > usage.day ? { day: today, viewedSharedIds: [], aiExtractions: 0 } : usage;
}

export function usageToDart(u: DailyUsage): Record<string, unknown> {
  return { day: u.day, viewedSharedIds: u.viewedSharedIds, aiExtractions: u.aiExtractions };
}

/** FirebaseService.remoteBool: blank falls back, else Remote Config's truthy set. */
function remoteBool(raw: string, fallback: boolean): boolean {
  const v = raw.trim().toLowerCase();
  if (!v) return fallback;
  return ["1", "true", "t", "yes", "y", "on"].includes(v);
}

export type Verdict = "free" | "blocked";

export interface AiQuota {
  /** MonetizationConfig.aiGated (`ads_enabled`): off, nothing is counted. */
  gated: boolean;
  premium: boolean;
  limit: number;
  used: number;
  remaining: number;
  loaded: boolean;
  /** QuotaGates.extractWithAi: true (and the slot recorded) when it may go ahead. */
  spend: () => Promise<Verdict>;
}

export function useAiQuota(): AiQuota {
  const { user, premium } = useAuth();
  const flags = useFlags();
  const gated = remoteBool(flags.string("ads_enabled", ""), true);
  // FirebaseService.remoteInt: a non-integer falls back to the default.
  const intParam = (key: string, fallback: number) => {
    const n = flags.number(key, fallback);
    return Number.isInteger(n) ? n : fallback;
  };
  const limit = premium ? intParam("quota_ai_premium", 10) : intParam("quota_ai_rewarded", 2);
  const { item } = useRecord<unknown>("usage", user?.uid, USAGE_DOC_ID);
  const used = item === undefined ? 0 : normalizeUsage(item).aiExtractions;

  const spend = useCallback(async (): Promise<Verdict> => {
    if (!gated) return "free";
    // Read fresh, not from the listener: the phone may have spent one a
    // second ago, and the count is recorded before the model is called.
    // In a transaction: the community feed writes the same record.
    let blocked = false;
    await updateRecord("usage", USAGE_DOC_ID, (raw) => {
      const current = normalizeUsage(raw);
      blocked = current.aiExtractions >= limit;
      return blocked ? null : usageToDart({ ...current, aiExtractions: current.aiExtractions + 1 });
    });
    return blocked ? "blocked" : "free";
  }, [gated, limit]);

  return { gated, premium, limit, used, remaining: Math.max(0, limit - used), loaded: item !== undefined, spend };
}
