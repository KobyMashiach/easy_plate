// The account's preferences exactly as the app stores them: one record,
// users/{uid}/preferences/current (personal — never under a household).
// UserPreferencesModel.toJson in
// lib/features/user_profile/data/models/user_preferences_model.g.dart.
// Read through `normalizePreferences` (older records lack newer keys; the
// app's defaults apply) and write what `preferencesToDart` returns (plus
// any keys a newer app stored, kept as they are).
// Writes go through `updatePreferences`, which re-reads the stored record
// and applies one change to it — never a snapshot held by a screen — the
// same rule as the app's SettingsBloc._commit.
import { updateRecord } from "../lib/cloud";
import type { Lang } from "../lib/i18n";
import { DIETARY, type DietaryPreference } from "./recipe";

export const PREFERENCES_ID = "current";

export const SHOPPING_DAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"] as const;
export type ShoppingDay = (typeof SHOPPING_DAYS)[number];

export const APP_LANGUAGES = ["hebrew", "english", "arabic", "french", "russian"] as const;
export type AppLanguage = (typeof APP_LANGUAGES)[number];

export const REMINDER_SLOTS = ["twoDaysBefore", "dayBefore", "sameDayMorning", "sameDayAfternoon"] as const;
export type ReminderSlot = (typeof REMINDER_SLOTS)[number];
export const DEFAULT_REMINDER_SLOTS: ReminderSlot[] = ["dayBefore", "sameDayMorning"];

export const THEME_MODES = ["system", "light", "dark"] as const;
export type AppThemeMode = (typeof THEME_MODES)[number];

/** The eight notification switches (NotificationSetting in settings_bloc.dart). */
export const NOTIFICATION_FLAGS = [
  "pushEnabled",
  "notifyRepliesOnMyPosts",
  "notifyRepliesOnThreads",
  "notifyShareInvites",
  "notifySharedRecipeUpdates",
  "notifyAdminReplies",
  "notifyAnnouncements",
  "foregroundPopupsEnabled",
] as const;
export type NotificationFlag = (typeof NOTIFICATION_FLAGS)[number];

export interface Preferences {
  shoppingDay: ShoppingDay;
  dietaryPreferences: DietaryPreference[];
  soundEffectsEnabled: boolean;
  onboardingComplete: boolean;
  language: AppLanguage;
  fastPageTurnEnabled: boolean;
  walkthroughSeen: boolean;
  communityPricesEnabled: boolean;
  /** Slot names in enum order; the app writes the list (never null) on save. */
  shoppingReminderSlots: ReminderSlot[];
  pushEnabled: boolean;
  notifyRepliesOnMyPosts: boolean;
  notifyRepliesOnThreads: boolean;
  notifyShareInvites: boolean;
  notifySharedRecipeUpdates: boolean;
  notifyAdminReplies: boolean;
  notifyAnnouncements: boolean;
  foregroundPopupsEnabled: boolean;
  /** An AppThemeMode name, or null: never chosen on this account. */
  themeMode: string | null;
  /** Build number of the last acknowledged "what's new" book, or null. */
  whatsNewSeenBuild: number | null;
}

const LANG_TO_APP: Record<Lang, AppLanguage> = { he: "hebrew", en: "english", ar: "arabic", fr: "french", ru: "russian" };
const APP_TO_LANG: Record<AppLanguage, Lang> = { hebrew: "he", english: "en", arabic: "ar", french: "fr", russian: "ru" };
export const appLanguageOf = (lang: Lang): AppLanguage => LANG_TO_APP[lang];
export const langOf = (language: AppLanguage): Lang => APP_TO_LANG[language];

const bool = (v: unknown, fallback: boolean): boolean => (typeof v === "boolean" ? v : fallback);
const oneOf = <T extends string>(v: unknown, all: readonly T[]): T | null => (typeof v === "string" && (all as readonly string[]).includes(v) ? (v as T) : null);

/** The app's defaults for an account with no record yet (UserPreferencesRepositoryImpl). */
export function defaultPreferences(language: AppLanguage = "hebrew"): Preferences {
  return normalizePreferences({ language });
}

/** Any stored document → complete Preferences, with the app's defaults. */
export function normalizePreferences(raw: unknown): Preferences {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const dietary = Array.isArray(r.dietaryPreferences) ? r.dietaryPreferences.map((d) => oneOf(d, DIETARY)).filter((d): d is DietaryPreference => d !== null) : [];
  const slotNames = Array.isArray(r.shoppingReminderSlots) ? r.shoppingReminderSlots.filter((s): s is string => typeof s === "string") : null;
  const seen = r.whatsNewSeenBuild;
  return {
    shoppingDay: oneOf(r.shoppingDay, SHOPPING_DAYS) ?? "sunday",
    dietaryPreferences: [...new Set(dietary)],
    soundEffectsEnabled: bool(r.soundEffectsEnabled, true),
    onboardingComplete: bool(r.onboardingComplete, false),
    language: oneOf(r.language, APP_LANGUAGES) ?? "hebrew",
    fastPageTurnEnabled: bool(r.fastPageTurnEnabled, true),
    walkthroughSeen: bool(r.walkthroughSeen, false),
    communityPricesEnabled: bool(r.communityPricesEnabled, false),
    // ShoppingReminderSlot.fromNames: enum order, unknown names dropped.
    shoppingReminderSlots: slotNames === null ? [...DEFAULT_REMINDER_SLOTS] : REMINDER_SLOTS.filter((s) => slotNames.includes(s)),
    pushEnabled: bool(r.pushEnabled, true),
    notifyRepliesOnMyPosts: bool(r.notifyRepliesOnMyPosts, true),
    notifyRepliesOnThreads: bool(r.notifyRepliesOnThreads, true),
    notifyShareInvites: bool(r.notifyShareInvites, true),
    notifySharedRecipeUpdates: bool(r.notifySharedRecipeUpdates, true),
    notifyAdminReplies: bool(r.notifyAdminReplies, true),
    notifyAnnouncements: bool(r.notifyAnnouncements, true),
    foregroundPopupsEnabled: bool(r.foregroundPopupsEnabled, true),
    themeMode: typeof r.themeMode === "string" ? r.themeMode : null,
    whatsNewSeenBuild: typeof seen === "number" && Number.isFinite(seen) ? Math.trunc(seen) : null,
  };
}

/** Every key UserPreferencesModel.toJson writes, in its shape. */
export function preferencesToDart(p: Preferences): Record<string, unknown> {
  return {
    shoppingDay: p.shoppingDay,
    dietaryPreferences: [...p.dietaryPreferences],
    soundEffectsEnabled: p.soundEffectsEnabled,
    onboardingComplete: p.onboardingComplete,
    language: p.language,
    fastPageTurnEnabled: p.fastPageTurnEnabled,
    walkthroughSeen: p.walkthroughSeen,
    communityPricesEnabled: p.communityPricesEnabled,
    shoppingReminderSlots: REMINDER_SLOTS.filter((s) => p.shoppingReminderSlots.includes(s)),
    pushEnabled: p.pushEnabled,
    notifyRepliesOnMyPosts: p.notifyRepliesOnMyPosts,
    notifyRepliesOnThreads: p.notifyRepliesOnThreads,
    notifyShareInvites: p.notifyShareInvites,
    notifySharedRecipeUpdates: p.notifySharedRecipeUpdates,
    notifyAdminReplies: p.notifyAdminReplies,
    notifyAnnouncements: p.notifyAnnouncements,
    foregroundPopupsEnabled: p.foregroundPopupsEnabled,
    themeMode: p.themeMode,
    whatsNewSeenBuild: p.whatsNewSeenBuild === null ? null : Math.trunc(p.whatsNewSeenBuild),
  };
}

// One queue for every change, like the app's sequential SettingsBloc: two
// switches flipped in quick succession must not both read the record before
// either writes, or the second write would undo the first.
let queue: Promise<unknown> = Promise.resolve();

/**
 * Applies `change` to the record as stored right now (re-read, never a
 * screen's copy) and writes the whole record back. Resolves with what was
 * written; rejects when the read or the write failed (nothing changed).
 * `fallbackLanguage` seeds a brand-new record, as the app seeds it from the
 * language picked before sign-in.
 */
export function updatePreferences(change: (p: Preferences) => Preferences, fallbackLanguage?: AppLanguage): Promise<Preferences> {
  const run = async () => {
    let next: Preferences | null = null;
    // In a transaction (the app on a phone writes the same record), and
    // keys this site does not know — written by a newer app — are kept
    // rather than dropped by a whole-record write.
    await updateRecord("preferences", PREFERENCES_ID, (stored) => {
      const raw = stored && typeof stored === "object" ? (stored as Record<string, unknown>) : null;
      next = change(raw ? normalizePreferences(raw) : defaultPreferences(fallbackLanguage));
      return { ...(raw ?? {}), ...preferencesToDart(next) };
    });
    return next as unknown as Preferences;
  };
  const result = queue.then(run, run);
  queue = result.catch(() => undefined);
  return result;
}
