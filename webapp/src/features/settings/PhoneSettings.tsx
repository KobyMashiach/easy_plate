// The phone (below lg) settings screens, drawn as the app draws them
// (lib/features/settings/presentation): הגדרות with nav rows and the
// language / appearance cards, and the two pushed screens it leads to —
// הגדרות התראות (toggle rows) and העדפות (shopping day, dietary, books).
// Same preferences record and the same writes as the desktop page.
import { useState, type ReactNode } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { LANGS, useI18n, type Lang } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { useContentTranslation } from "../../lib/contentTranslation";
import { applyTheme, readTheme, type ThemeMode } from "../../lib/theme";
import { account, ApiError } from "../../lib/api";
import { AppDialog } from "../../components/AppDialog";
import { Chip, ClayButton, ClayCard, LoadingSpinner, PageHeader, Switch } from "../../components/clay";
import { Icon } from "../../components/icons";
import { useToast } from "../../components/Toaster";
import { DIETARY, type DietaryPreference } from "../../models/recipe";
import { appLanguageOf, REMINDER_SLOTS, SHOPPING_DAYS, type NotificationFlag, type Preferences } from "../../models/preferences";
import { usePreferences } from "./data";

type SetFn = (key: string, fn: (p: Preferences) => Preferences) => void;

// ── Rows (settings_widgets.dart) ─────────────────────────────────────────

/** SettingsGroupLabel: labelMd onSurfaceVariant, start 4, top 8. */
export function GroupLabel({ children }: { children: ReactNode }) {
  return <h2 className="ps-1 pt-2 text-label-md tracking-[0.4px] text-on-surface-variant">{children}</h2>;
}

/** SettingsNavRow: ClayCard r24 p24 — icon 22 → 12 → bodyLg (+ hint labelMd outline) → chevron. */
export function NavRow({ icon, label, hint, to, onClick, destructive = false }: { icon: string; label: string; hint?: string; to?: string; onClick?: () => void; destructive?: boolean }) {
  return (
    <ClayCard radius={24} padding={24} to={to} onClick={onClick} className="flex items-center gap-3">
      <Icon name={icon} size={22} className={destructive ? "text-error" : "text-primary"} />
      <span className="min-w-0 flex-1">
        <span className={`block text-body-lg ${destructive ? "text-error" : "text-on-surface"}`}>{label}</span>
        {hint ? <span className="mt-1 block text-label-md text-outline">{hint}</span> : null}
      </span>
      <Icon name="chevron_right" size={24} className="text-tertiary rtl:-scale-x-100" />
    </ClayCard>
  );
}

/** SettingsCard: ClayCard r24 p24, ClaySectionHeader, 16, the selector. */
export function SettingsCard({ id, title, children }: { id?: string; title: string; children: ReactNode }) {
  return (
    <ClayCard as="section" radius={24} padding={24} aria-labelledby={id ? `${id}-h` : undefined}>
      <h2 id={id ? `${id}-h` : undefined} className="text-headline-md text-on-surface">
        {title}
      </h2>
      <div className="mt-4">{children}</div>
    </ClayCard>
  );
}

/** SettingsToggle: ClayCard r24, padding 12/24, bodyMd title + labelMd outline description, switch at the end. */
export function ToggleRow({ id, title, description, checked, onChange, disabled = false }: { id: string; title: string; description?: string; checked: boolean; onChange: (v: boolean) => void; disabled?: boolean }) {
  return (
    <ClayCard radius={24} style={{ padding: "12px 24px" }} className="flex items-center gap-3">
      <span className="min-w-0 flex-1">
        <span id={`${id}-t`} className={`block text-body-md ${disabled ? "text-outline" : "text-on-surface"}`}>
          {title}
        </span>
        {description ? (
          <span id={`${id}-d`} className="mt-1 block text-label-md text-outline">
            {description}
          </span>
        ) : null}
      </span>
      <Switch id={id} checked={checked} onChange={onChange} disabled={disabled} labelledBy={`${id}-t`} />
    </ClayCard>
  );
}

/** SettingsBody: the page header at 24/20, 32, the rows 24 apart. */
function Body({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="mx-auto max-w-xl">
      <PageHeader title={title} />
      <div className="mt-8 flex flex-col gap-6">{children}</div>
    </div>
  );
}

/** Loading / failed / the rows, as the three pages' bloc states. */
function PrefsGate({ title, prefs, error, children }: { title: string; prefs: Preferences | null; error: unknown; children: (p: Preferences) => ReactNode }) {
  const { t } = useI18n();
  if (prefs) return <Body title={title}>{children(prefs)}</Body>;
  if (error) {
    return (
      <div className="mx-auto max-w-xl">
        <h1 className="sr-only">{title}</h1>
        <ClayCard radius={24} padding={24} className="m-6 flex flex-col items-center text-center" role="alert">
          <span className="grid h-16 w-16 place-items-center rounded-full bg-error-container text-on-error-container" aria-hidden="true">
            <Icon name="error_outline" size={32} />
          </span>
          <p className="mt-4 text-headline-md">{t("settings.errorTitle")}</p>
          <p className="mt-2 text-label-md text-on-surface-variant">{t("settings.loadFailed")}</p>
          <ClayButton icon="refresh" className="mt-4" onClick={() => window.location.reload()}>
            {t("settings.retry")}
          </ClayButton>
        </ClayCard>
      </div>
    );
  }
  return (
    <div className="grid min-h-[50vh] place-items-center">
      <h1 className="sr-only">{title}</h1>
      <LoadingSpinner label={t("common.loading")} />
    </div>
  );
}

/** The preferences record plus the app's "save failed" notice. */
function usePrefs() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const toast = useToast();
  const state = usePreferences(user?.uid, appLanguageOf(lang));
  const set: SetFn = (key, fn) => {
    void state.change(key, fn).then((saved) => {
      if (!saved) toast.show(t("settings.saveFailed"), "error");
    });
  };
  return { ...state, set };
}

// ── הגדרות ──────────────────────────────────────────────────────────────

export function PhoneSettings() {
  const { t, lang, setLang } = useI18n();
  const { prefs, error, busy, change } = usePrefs();
  const { translateTo } = useContentTranslation();
  const toast = useToast();
  const notifications = useAccess("ff_notifications");
  const theming = useAccess("ff_theming");
  const shares = [useAccess("ff_share_recipes"), useAccess("ff_share_books"), useAccess("ff_share_plans"), useAccess("ff_share_grocery_lists")];
  const anyShare = shares.some((a) => a !== "hidden");
  const [mode, setMode] = useState<ThemeMode>(readTheme);
  const deletion = useAccountDeletion();

  const switchLanguage = async (next: Lang) => {
    if (next === lang || busy.has("language")) return;
    const before = lang;
    setLang(next);
    const saved = await change("language", (p) => ({ ...p, language: appLanguageOf(next) }));
    if (!saved) {
      setLang(before);
      toast.show(t("settings.saveFailed"), "error");
      return;
    }
    translateTo(next);
  };

  const chooseTheme = (m: ThemeMode) => {
    setMode(m);
    applyTheme(m);
    if (prefs && prefs.themeMode !== m) {
      void change("theme", (p) => ({ ...p, themeMode: m })).then((saved) => {
        if (!saved) toast.show(t("settings.saveFailed"), "error");
      });
    }
  };

  return (
    <PrefsGate title={t("settings.title")} prefs={prefs} error={error}>
      {() => (
        <>
          <GroupLabel>{t("settings.account")}</GroupLabel>
          <NavRow icon="person" label={t("settings.profileRow")} to="/account" />
          {anyShare ? <NavRow icon="group" label={t("settings.sharedAccess")} to="/sharing" /> : null}

          {notifications !== "hidden" ? (
            <>
              <GroupLabel>{t("settings.notifications")}</GroupLabel>
              <NavRow icon="notifications" label={t("settings.notifTitle")} hint={t("settings.notificationsHint")} to={notifications === "locked" ? "/pricing" : "/settings/notifications"} />
            </>
          ) : null}

          {/* The account menu has no preferences row on the web yet: reached from here. */}
          <NavRow icon="tune" label={t("settings.prefsTitle")} hint={t("settings.preferencesHint")} to="/settings/preferences" />

          <SettingsCard id="language" title={t("settings.language")}>
            <div className="flex flex-wrap justify-center gap-2" role="radiogroup" aria-label={t("settings.language")}>
              {LANGS.map((l) => (
                <Chip key={l.code} selected={lang === l.code} icon={lang === l.code ? "check" : undefined} disabled={busy.has("language")} onClick={() => void switchLanguage(l.code)}>
                  <span lang={l.code}>{l.name}</span>
                </Chip>
              ))}
            </div>
          </SettingsCard>

          {theming !== "hidden" && theming !== "comingSoon" ? (
            <SettingsCard id="appearance" title={t("settings.appearance")}>
              <div className="flex flex-wrap justify-center gap-2" role="radiogroup" aria-label={t("settings.appearance")}>
                {(
                  [
                    ["system", "brightness_auto", "settings.themeSystem"],
                    ["light", "light_mode", "settings.themeLight"],
                    ["dark", "dark_mode", "settings.themeDark"],
                  ] as [ThemeMode, string, string][]
                ).map(([m, icon, key]) => (
                  <Chip key={m} selected={mode === m} icon={icon} disabled={busy.has("theme")} onClick={() => chooseTheme(m)}>
                    {t(key)}
                  </Chip>
                ))}
              </div>
            </SettingsCard>
          ) : null}

          {/* The stores require deletion to be reachable; never behind a flag. */}
          <GroupLabel>{t("settings.dangerZone")}</GroupLabel>
          <NavRow icon="delete_forever" label={t("settings.deleteAccount")} hint={t("settings.deleteAccountHint")} destructive onClick={deletion.ask} />
          {deletion.dialog}
        </>
      )}
    </PrefsGate>
  );
}

/**
 * Settings → delete account, as the app does it: one warning dialog that
 * spells out what goes, then the busy dialog while the server deletes, then
 * sign-out. A household owner is refused with the app's message.
 */
function useAccountDeletion() {
  const { t } = useI18n();
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);

  const run = async () => {
    if (busy) return;
    setBusy(true);
    try {
      await account.delete();
    } catch (err) {
      setBusy(false);
      setOpen(false);
      setFailure(err instanceof ApiError && err.code === "household_owner" ? t("settings.deleteHousehold") : t("settings.deleteFailed"));
      return;
    }
    navigate("/login", { replace: true, state: { deleted: user?.uid ?? "" } });
    await signOut().catch(() => {});
  };

  const dialog = (
    <>
      <AppDialog
        open={open}
        kind="warning"
        icon="delete_forever"
        title={busy ? undefined : t("settings.deleteTitle")}
        message={busy ? t("settings.deleting") : t("settings.deleteBody")}
        confirmLabel={t("settings.deleteConfirm")}
        cancelLabel={busy ? null : t("settings.cancel")}
        destructive
        busy={busy}
        onConfirm={() => void run()}
        onCancel={() => setOpen(false)}
      />
      <AppDialog open={failure !== null} kind="error" message={failure ?? ""} confirmLabel={t("settings.ok")} cancelLabel={null} onConfirm={() => setFailure(null)} onCancel={() => setFailure(null)} />
    </>
  );
  return { ask: () => setOpen(true), dialog };
}

// ── הגדרות התראות ────────────────────────────────────────────────────────

const NOTIF_GROUPS: { group: string; rows: { flag: NotificationFlag; key: string; hint: boolean }[] }[] = [
  {
    group: "settings.notif.community",
    rows: [
      { flag: "notifyRepliesOnMyPosts", key: "repliesOnMyPosts", hint: true },
      { flag: "notifyRepliesOnThreads", key: "repliesOnThreads", hint: true },
    ],
  },
  {
    group: "settings.notif.sharing",
    rows: [
      { flag: "notifyShareInvites", key: "shareInvites", hint: true },
      { flag: "notifySharedRecipeUpdates", key: "sharedRecipeUpdates", hint: true },
    ],
  },
  {
    group: "settings.notif.easyPlate",
    rows: [
      { flag: "notifyAdminReplies", key: "adminReplies", hint: false },
      { flag: "notifyAnnouncements", key: "announcements", hint: true },
    ],
  },
  {
    group: "settings.notif.inApp",
    rows: [{ flag: "foregroundPopupsEnabled", key: "foregroundPopups", hint: true }],
  },
];

export function PhoneNotificationSettings() {
  const { t } = useI18n();
  const { prefs, error, busy, set } = usePrefs();
  const reminders = useAccess("ff_shopping_reminder");
  return (
    <PrefsGate title={t("settings.notifTitle")} prefs={prefs} error={error}>
      {(p) => (
        <>
          <ToggleRow id="notif-push" title={t("settings.notif.push")} description={t("settings.notif.pushHint")} checked={p.pushEnabled} disabled={busy.has("pushEnabled")} onChange={(v) => set("pushEnabled", (x) => ({ ...x, pushEnabled: v }))} />
          {NOTIF_GROUPS.map((g) => (
            <NotifGroup key={g.group} label={t(g.group)}>
              {g.rows.map((r) => (
                <ToggleRow
                  key={r.flag}
                  id={`notif-${r.key}`}
                  title={t(`settings.notif.${r.key}`)}
                  description={r.hint ? t(`settings.notif.${r.key}Hint`) : undefined}
                  checked={p[r.flag]}
                  // With the master switch off the rows are moot: drawn disabled, not hidden.
                  disabled={!p.pushEnabled || busy.has(r.flag)}
                  onChange={(v) => set(r.flag, (x) => ({ ...x, [r.flag]: v }))}
                />
              ))}
            </NotifGroup>
          ))}
          {reminders === "enabled" ? (
            <NotifGroup label={t("settings.notif.reminders")}>
              <SettingsCard id="reminders" title={t("settings.shoppingReminders")}>
                <div className="flex flex-wrap gap-2">
                  {REMINDER_SLOTS.map((s) => {
                    const on = p.shoppingReminderSlots.includes(s);
                    return (
                      <Chip
                        key={s}
                        selected={on}
                        icon={on ? "notifications_active" : "notifications_none"}
                        disabled={busy.has(`slot.${s}`)}
                        onClick={() =>
                          set(`slot.${s}`, (x) => ({
                            ...x,
                            shoppingReminderSlots: x.shoppingReminderSlots.includes(s) ? x.shoppingReminderSlots.filter((y) => y !== s) : REMINDER_SLOTS.filter((y) => y === s || x.shoppingReminderSlots.includes(y)),
                          }))
                        }
                      >
                        {t(`settings.slot.${s}`)}
                      </Chip>
                    );
                  })}
                </div>
                <p className="mt-2 text-label-md text-outline">{t("settings.shoppingRemindersHint")}</p>
              </SettingsCard>
            </NotifGroup>
          ) : null}
        </>
      )}
    </PrefsGate>
  );
}

/** A group label and its rows; the list's 24 px rhythm runs through it. */
function NotifGroup({ label, children }: { label: string; children: ReactNode }) {
  return (
    <>
      <GroupLabel>{label}</GroupLabel>
      {children}
    </>
  );
}

// ── העדפות ───────────────────────────────────────────────────────────────

/** dietaryTagColors (spec 2.5): fill / border / ink of a selected chip. */
const DIET_ON: Record<DietaryPreference, string> = {
  meat: "bg-error-container border-error-container text-on-error-container",
  dairy: "bg-info-container border-info-container text-on-info-container",
  vegetarian: "bg-secondary-container border-secondary-container text-on-secondary-container",
  vegan: "bg-[rgb(var(--c-secondary-fixed-dim))] border-[rgb(var(--c-secondary-fixed-dim))] text-on-secondary-fixed",
  kosher: "bg-tertiary-fixed border-tertiary-fixed text-[rgb(var(--c-on-tertiary-fixed-variant))]",
  glutenFree: "bg-primary-fixed border-primary-fixed text-on-primary-fixed-variant",
  allergy: "bg-surface-highest border-surface-highest text-on-surface-variant",
};
const DIET_ICON: Record<DietaryPreference, string> = {
  meat: "set_meal",
  dairy: "egg_alt",
  vegetarian: "eco",
  vegan: "spa",
  kosher: "verified",
  glutenFree: "block",
  allergy: "warning_amber",
};

export function PhonePreferences() {
  const { t } = useI18n();
  const { prefs, error, busy, set } = usePrefs();
  const priceBook = useAccess("ff_price_book");
  return (
    <PrefsGate title={t("settings.prefsTitle")} prefs={prefs} error={error}>
      {(p) => (
        <>
          <GroupLabel>{t("settings.shopping")}</GroupLabel>
          <SettingsCard id="shopping-day" title={t("settings.shoppingDay")}>
            <div className="flex flex-wrap gap-2" role="radiogroup" aria-label={t("settings.shoppingDay")}>
              {SHOPPING_DAYS.map((d) => (
                <Chip key={d} selected={p.shoppingDay === d} disabled={busy.has("shoppingDay")} className="!px-4" onClick={() => set("shoppingDay", (x) => ({ ...x, shoppingDay: d }))}>
                  {t(`settings.day.${d}`)}
                </Chip>
              ))}
            </div>
          </SettingsCard>
          {priceBook === "enabled" || priceBook === "locked" ? (
            <ToggleRow
              id="pref-community-prices"
              title={t("settings.communityPrices")}
              description={t("settings.communityPricesHint")}
              checked={p.communityPricesEnabled}
              disabled={priceBook === "locked" || busy.has("communityPrices")}
              onChange={(v) => set("communityPrices", (x) => ({ ...x, communityPricesEnabled: v }))}
            />
          ) : null}

          <GroupLabel>{t("settings.dietaryPreferences")}</GroupLabel>
          <SettingsCard id="dietary" title={t("settings.dietaryPreferences")}>
            <div className="flex flex-wrap gap-2">
              {DIETARY.map((d) => (
                <Chip
                  key={d}
                  kind="filter"
                  onClass={DIET_ON[d]}
                  selected={p.dietaryPreferences.includes(d)}
                  icon={DIET_ICON[d]}
                  disabled={busy.has(`diet.${d}`)}
                  // Toggled on the record as re-read, never on this screen's copy.
                  onClick={() =>
                    set(`diet.${d}`, (x) => ({
                      ...x,
                      dietaryPreferences: x.dietaryPreferences.includes(d) ? x.dietaryPreferences.filter((y) => y !== d) : [...x.dietaryPreferences, d],
                    }))
                  }
                >
                  {t(`settings.diet.${d}`)}
                </Chip>
              ))}
            </div>
          </SettingsCard>

          <GroupLabel>{t("settings.books")}</GroupLabel>
          <ToggleRow id="pref-fast-page-turn" title={t("settings.fastPageTurn")} description={t("settings.fastPageTurnHint")} checked={p.fastPageTurnEnabled} disabled={busy.has("fastPageTurn")} onChange={(v) => set("fastPageTurn", (x) => ({ ...x, fastPageTurnEnabled: v }))} />
          <ToggleRow id="pref-sound" title={t("settings.soundEffects")} checked={p.soundEffectsEnabled} disabled={busy.has("sound")} onChange={(v) => set("sound", (x) => ({ ...x, soundEffectsEnabled: v }))} />
        </>
      )}
    </PrefsGate>
  );
}
