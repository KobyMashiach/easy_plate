// Weekday names in the UI language (weekday 0 = Sunday, as ShoppingDay).
import { useMemo } from "react";
import { useI18n } from "../../lib/i18n";

// 1 January 2023 was a Sunday.
const SUNDAY = Date.UTC(2023, 0, 1, 12);

export function useDayNames(): { long: string[]; short: string[] } {
  const { locale } = useI18n();
  return useMemo(() => {
    const long = new Intl.DateTimeFormat(locale, { weekday: "long", timeZone: "UTC" });
    const short = new Intl.DateTimeFormat(locale, { weekday: "short", timeZone: "UTC" });
    const days = Array.from({ length: 7 }, (_, i) => new Date(SUNDAY + i * 86400000));
    return { long: days.map((d) => long.format(d)), short: days.map((d) => short.format(d)) };
  }, [locale]);
}

export function todayWeekday(): number {
  return new Date().getDay();
}

/** The plan the phone's "תפריטים" tab opens on (the app keeps its selection in its bloc). */
export const ACTIVE_PLAN_KEY = "easyplate.plans.active";

/**
 * The plans in the order the app lists them below lg: its Hive box keeps
 * string keys sorted, so the chips (and the plan the tab falls back to) go by id.
 */
export function inAppOrder<T extends { id: string }>(plans: T[]): T[] {
  return [...plans].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
}
