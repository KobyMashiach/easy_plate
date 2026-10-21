// The free tier's sharing allowances (ShareGates + ShareUsageService):
// recipes shared per calendar week, books / plans / lists held shared at
// once, from Remote Config; Premium is unlimited and 0 disables a limit.
// The weekly recipe count lives on the device in the app (a Hive box per
// account), so on the web it lives in this browser, per account.
import { containersOwnedBy } from "./containers";
import { getContainerRecord } from "./containerRecords";
import type { ContainerKind } from "./types";

export const LIMIT_KEYS = {
  recipe: ["share_free_recipes_weekly", 5],
  book: ["share_free_books_total", 2],
  mealPlan: ["share_free_plans_total", 2],
  groceryList: ["share_free_lists_total", 2],
} as const;

/** ShareUsageService.weekKey: "2026-W41", the ISO (Monday-based) week. */
export function weekKey(at: Date): string {
  const day = new Date(Date.UTC(at.getFullYear(), at.getMonth(), at.getDate()));
  const weekday = day.getUTCDay() === 0 ? 7 : day.getUTCDay();
  const thursday = new Date(day.getTime() + (4 - weekday) * 86400000);
  const dayOfYear = Math.floor((thursday.getTime() - Date.UTC(thursday.getUTCFullYear(), 0, 1)) / 86400000) + 1;
  const week = Math.floor((dayOfYear - 1) / 7) + 1;
  return `${thursday.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

const storeKey = (uid: string) => `ep-share-usage-${uid}`;

export function recipeSharesThisWeek(uid: string): number {
  try {
    const raw = JSON.parse(localStorage.getItem(storeKey(uid)) || "{}") as Record<string, number>;
    return raw[weekKey(new Date())] ?? 0;
  } catch (_) {
    return 0;
  }
}

export function recordRecipeShare(uid: string): void {
  try {
    const key = weekKey(new Date());
    const raw = JSON.parse(localStorage.getItem(storeKey(uid)) || "{}") as Record<string, number>;
    // Only this week's bucket is kept.
    localStorage.setItem(storeKey(uid), JSON.stringify({ [key]: (raw[key] ?? 0) + 1 }));
  } catch (_) {
    /* not counted; the share itself went out */
  }
}

export function allows(premium: boolean, used: number, limit: number): boolean {
  return premium || limit <= 0 || used < limit;
}

/**
 * The gate before a contact invite or a new code. Null when it may go on,
 * else the limit that stops it. An item already shared holds its slot.
 */
export async function shareBlockedAt(
  kind: "recipe" | ContainerKind,
  p: { uid: string; premium: boolean; number: (key: string, fallback: number) => number; itemId: string; collabId: string | null },
): Promise<number | null> {
  if (p.premium) return null;
  const [key, fallback] = LIMIT_KEYS[kind];
  const limit = p.number(key, fallback);
  if (kind === "recipe") return allows(false, recipeSharesThisWeek(p.uid), limit) ? null : limit;
  if (p.collabId) return null;
  const stored = await getContainerRecord(kind, p.itemId);
  if (stored?.collabId) return null;
  const owned = (await containersOwnedBy(p.uid)).filter((c) => c.kind === kind).length;
  return allows(false, owned, limit) ? null : limit;
}
