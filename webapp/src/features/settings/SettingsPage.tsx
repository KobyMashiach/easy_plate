// הגדרות + העדפות + הגדרות התראות on one wide page: the app's three views
// over the one preferences record (users/{uid}/preferences/current), plus
// the profile (users/{uid} + public_profiles/{uid}) and links to sharing,
// the household and the account page (subscription, delete account).
import { useEffect, useRef, useState, type ChangeEvent, type FormEvent } from "react";
import { trustedPhotoUrl } from "../../lib/photoUrl";
import { Link, Navigate, useLocation } from "react-router-dom";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneNotificationSettings, PhonePreferences, PhoneSettings } from "./PhoneSettings";
import { useAuth } from "../../lib/auth";
import { LANGS, useI18n, type Lang } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { useContentTranslation } from "../../lib/contentTranslation";
import { applyTheme, readTheme, type ThemeMode } from "../../lib/theme";
import { Button, Field, Notice, PageTitle, Row, Spinner } from "../../components/ui";
import { Icon } from "../../components/icons";
import { DIETARY, type DietaryPreference } from "../../models/recipe";
import { appLanguageOf, REMINDER_SLOTS, SHOPPING_DAYS, type NotificationFlag, type Preferences, type ReminderSlot, type ShoppingDay } from "../../models/preferences";
import { saveProfile, uploadProfilePhoto, usePreferences, useProfileDoc } from "./data";
import { Chips, Choice, GroupLabel, Section, Toggle } from "./controls";

const MAX_PHOTO_MB = 25;

export function SettingsPage() {
  const phone = useIsPhone();
  const { hash } = useLocation();
  if (!phone) return <DesktopSettingsPage />;
  // The app's separate screens: a deep link to a section (#notifications,
  // #preferences from Shefi or the what's-new book) opens its own page.
  if (hash === "#notifications") return <Navigate to="/settings/notifications" replace />;
  if (hash === "#preferences") return <Navigate to="/settings/preferences" replace />;
  if (hash === "#profile") return <Navigate to="/account" replace />;
  return <PhoneSettings />;
}

/** /settings/notifications — the phone's הגדרות התראות; the desktop shows it on /settings. */
export function NotificationSettingsPage() {
  return useIsPhone() ? <PhoneNotificationSettings /> : <Navigate to="/settings#notifications" replace />;
}

/** /settings/preferences — the phone's העדפות; the desktop shows it on /settings. */
export function PreferencesPage() {
  return useIsPhone() ? <PhonePreferences /> : <Navigate to="/settings#preferences" replace />;
}

function DesktopSettingsPage() {
  const { t, lang, setLang } = useI18n();
  const { user } = useAuth();
  const { prefs, error, busy, failures, change } = usePreferences(user?.uid, appLanguageOf(lang));
  const location = useLocation();
  const [langError, setLangError] = useState(false);
  const { translateTo } = useContentTranslation();

  // A refused save puts the control back; say so (the app's saveFailed dialog).
  const [shownFailures, setShownFailures] = useState(0);
  const failed = failures > shownFailures;

  // #profile, #notifications, #preferences — the what's-new book and the
  // assistant link straight to a section.
  useEffect(() => {
    if (!location.hash || !prefs) return;
    document.getElementById(location.hash.slice(1))?.scrollIntoView({ block: "start" });
  }, [location.hash, prefs === null]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!user) return null;

  const set = (key: string, fn: (p: Preferences) => Preferences) => {
    setShownFailures(failures);
    void change(key, fn);
  };

  const switchLanguage = async (next: Lang) => {
    if (next === lang) return;
    const before = lang;
    setLangError(false);
    setShownFailures(failures);
    setLang(next);
    const saved = await change("language", (p) => ({ ...p, language: appLanguageOf(next) }));
    // Refused: the record kept its language, so the site goes back too.
    if (!saved) {
      setLang(before);
      setLangError(true);
      return;
    }
    // Only a confirmed save moves the account's content (the app's rule).
    translateTo(next);
  };

  return (
    <>
      <PageTitle title={t("settings.title")} lead={t("settings.lead")} />
      {failed ? (
        <div className="mb-4">
          <Notice kind="error">{t("settings.saveFailed")}</Notice>
        </div>
      ) : null}

      <div className="grid items-start gap-4 lg:grid-cols-2 2xl:grid-cols-3">
        <div className="space-y-4">
          <ProfileSection />
          {error && !prefs ? (
            <div className="clay space-y-3 p-5" role="alert">
              <p>{t("settings.loadFailed")}</p>
              <Button variant="tonal" className="!w-auto" onClick={() => window.location.reload()}>
                {t("settings.retry")}
              </Button>
            </div>
          ) : !prefs ? (
            <div className="clay grid place-items-center p-10">
              <Spinner label={t("common.loading")} />
            </div>
          ) : (
            <>
              <Section id="language" icon="globe" title={t("settings.language")} hint={t("settings.languageNote")}>
                <Choice<Lang>
                  name="site-language"
                  label={t("settings.language")}
                  options={LANGS.map((l) => ({ value: l.code, label: l.name }))}
                  value={lang}
                  onChange={(v) => void switchLanguage(v)}
                  disabled={busy.has("language")}
                />
                {langError ? <Notice kind="error">{t("settings.saveFailed")}</Notice> : null}
              </Section>
              <AppearanceSection prefs={prefs} busy={busy.has("theme")} onSave={(mode) => set("theme", (p) => ({ ...p, themeMode: mode }))} />
            </>
          )}
          <MoreLinks />
        </div>

        <div className="space-y-4 2xl:col-span-2 2xl:grid 2xl:grid-cols-2 2xl:items-start 2xl:gap-4 2xl:space-y-0">
          {prefs ? (
            <>
              <PreferencesSection prefs={prefs} busy={busy} set={set} />
              <NotificationsSection prefs={prefs} busy={busy} set={set} />
            </>
          ) : null}
        </div>
      </div>
    </>
  );
}

// ---------------------------------------------------------------------------

function ProfileSection() {
  const { t } = useI18n();
  const { user } = useAuth();
  const { profile, error } = useProfileDoc(user?.uid);
  const [name, setName] = useState<string | null>(null);
  const [photo, setPhoto] = useState<{ file: File; preview: string } | null>(null);
  const [removed, setRemoved] = useState(false);
  const [busy, setBusy] = useState(false);
  const [nameError, setNameError] = useState<string | null>(null);
  const [notice, setNotice] = useState<{ kind: "success" | "error"; text: string } | null>(null);
  const fileInput = useRef<HTMLInputElement>(null);

  useEffect(() => () => {
    if (photo) URL.revokeObjectURL(photo.preview);
  }, [photo]);

  if (!user) return null;
  const storedName = profile?.fullName || user.displayName || "";
  const value = name ?? storedName;
  // A URL from the stored document: only our Storage or Google's CDN reaches the <img>.
  const storedPhoto = trustedPhotoUrl(profile?.photoUrl ?? user.photoURL ?? null);
  const shownPhoto = photo?.preview ?? (removed ? null : storedPhoto);
  const dirty = (name !== null && name.trim() !== storedName.trim()) || photo !== null || (removed && !!storedPhoto);

  const pick = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (!file.type.startsWith("image/") || file.type.startsWith("image/svg")) {
      setNotice({ kind: "error", text: t("settings.photoInvalid") });
      return;
    }
    // Refused before it is decoded: the picture is downscaled in the page.
    if (file.size > MAX_PHOTO_MB * 1024 * 1024) {
      setNotice({ kind: "error", text: t("settings.photoTooLarge", { max: MAX_PHOTO_MB }) });
      return;
    }
    setNotice(null);
    setRemoved(false);
    setPhoto({ file, preview: URL.createObjectURL(file) });
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    // The stored profile could not be read: a save now would stamp a new createdAt over it.
    if (busy || error) return;
    const fullName = value.trim();
    if (!fullName) {
      setNameError(t("settings.fullNameRequired"));
      return;
    }
    setNameError(null);
    setNotice(null);
    setBusy(true);
    try {
      // Upload first, so the saved document already carries the final URL.
      const photoUrl = photo ? await uploadProfilePhoto(user.uid, photo.file) : removed ? null : storedPhoto;
      await saveProfile(
        { uid: user.uid, email: user.email, emailVerified: user.emailVerified, phoneNumber: user.phoneNumber },
        { fullName, photoUrl, createdAt: profile?.createdAt ?? null },
      );
      setName(null);
      setPhoto(null);
      setRemoved(false);
      setNotice({ kind: "success", text: t("settings.profileSaved") });
    } catch (_) {
      setNotice({ kind: "error", text: t("settings.profileFailed") });
    } finally {
      setBusy(false);
    }
  };

  return (
    <Section id="profile" icon="account" title={t("settings.profile")} hint={t("settings.publicNote")}>
      {profile === undefined && !error ? (
        <div className="grid place-items-center py-6">
          <Spinner label={t("common.loading")} />
        </div>
      ) : (
        <form onSubmit={submit} className="space-y-4" noValidate>
          <div className="flex flex-wrap items-center gap-4">
            <span className="grid h-20 w-20 shrink-0 place-items-center overflow-hidden rounded-full bg-primary-fixed text-headline-md text-on-primary-fixed-variant shadow-control">
              {shownPhoto ? <img src={shownPhoto} alt={t("settings.photo")} className="h-full w-full object-cover" /> : <span aria-hidden="true">{(value.trim()[0] || "?").toUpperCase()}</span>}
            </span>
            <div className="flex flex-wrap gap-2">
              <input ref={fileInput} type="file" accept="image/*" className="sr-only" tabIndex={-1} aria-hidden="true" onChange={pick} />
              <button type="button" className="clay-btn-tonal" onClick={() => fileInput.current?.click()} disabled={busy}>
                <Icon name="image" size={18} /> {shownPhoto ? t("settings.changePhoto") : t("settings.addPhoto")}
              </button>
              {shownPhoto ? (
                <button
                  type="button"
                  className="clay-btn-ghost"
                  disabled={busy}
                  onClick={() => {
                    setPhoto(null);
                    setRemoved(true);
                  }}
                >
                  <Icon name="trash" size={18} /> {t("settings.removePhoto")}
                </button>
              ) : null}
            </div>
          </div>
          <Field
            id="profile-name"
            label={t("settings.fullName")}
            placeholder={t("settings.fullNameHint")}
            value={value}
            maxLength={80}
            autoComplete="name"
            onChange={(e) => {
              setName(e.target.value);
              setNameError(null);
            }}
            disabled={busy}
            error={nameError}
          />
          <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-body-md">
            <dt className="text-on-surface-variant">{t("settings.phone")}</dt>
            <dd dir="ltr" className="truncate text-start">
              {user.phoneNumber || "—"}
            </dd>
            <dt className="text-on-surface-variant">{t("settings.email")}</dt>
            <dd dir="ltr" className="truncate text-start">
              {user.email || "—"}
            </dd>
          </dl>
          <p className="text-label-md text-on-surface-variant">{t("settings.identityNote")}</p>
          {error ? <Notice kind="error">{t("settings.loadFailed")}</Notice> : null}
          {notice ? <Notice kind={notice.kind}>{notice.text}</Notice> : null}
          <Button type="submit" busy={busy} disabled={!dirty || !!error}>
            {busy ? t("settings.saving") : t("settings.saveProfile")}
          </Button>
        </form>
      )}
    </Section>
  );
}

// ---------------------------------------------------------------------------

function AppearanceSection({ prefs, busy, onSave }: { prefs: Preferences; busy: boolean; onSave: (mode: ThemeMode) => void }) {
  const { t } = useI18n();
  const access = useAccess("ff_theming");
  const [mode, setMode] = useState<ThemeMode>(readTheme);
  if (access === "hidden" || access === "comingSoon") return null;
  const choose = (m: ThemeMode) => {
    setMode(m);
    applyTheme(m);
    if (prefs.themeMode !== m) onSave(m);
  };
  return (
    <Section id="appearance" icon={mode === "dark" ? "moon" : mode === "light" ? "sun" : "auto"} title={t("settings.appearance")} hint={t("settings.themeNote")}>
      <Choice<ThemeMode>
        name="theme-mode"
        label={t("settings.appearance")}
        options={[
          { value: "system", label: t("settings.themeSystem"), icon: "auto" },
          { value: "light", label: t("settings.themeLight"), icon: "sun" },
          { value: "dark", label: t("settings.themeDark"), icon: "moon" },
        ]}
        value={mode}
        onChange={choose}
        disabled={busy}
      />
    </Section>
  );
}

// ---------------------------------------------------------------------------

type SetFn = (key: string, fn: (p: Preferences) => Preferences) => void;

function PreferencesSection({ prefs, busy, set }: { prefs: Preferences; busy: Set<string>; set: SetFn }) {
  const { t } = useI18n();
  const priceBook = useAccess("ff_price_book");
  return (
    <Section id="preferences" icon="filter" title={t("settings.preferences")} hint={t("settings.preferencesHint")}>
      <GroupLabel>{t("settings.shopping")}</GroupLabel>
      <Choice<ShoppingDay>
        name="shopping-day"
        label={t("settings.shoppingDay")}
        options={SHOPPING_DAYS.map((d) => ({ value: d, label: t(`settings.day.${d}`) }))}
        value={prefs.shoppingDay}
        onChange={(d) => set("shoppingDay", (p) => ({ ...p, shoppingDay: d }))}
        disabled={busy.has("shoppingDay")}
      />
      {priceBook === "enabled" || priceBook === "locked" ? (
        <Toggle
          id="pref-community-prices"
          label={t("settings.communityPrices")}
          hint={t("settings.communityPricesHint")}
          checked={prefs.communityPricesEnabled}
          busy={busy.has("communityPrices")}
          disabled={priceBook === "locked"}
          onChange={(v) => set("communityPrices", (p) => ({ ...p, communityPricesEnabled: v }))}
        />
      ) : null}

      <GroupLabel>{t("settings.dietaryPreferences")}</GroupLabel>
      <Chips<DietaryPreference>
        label={t("settings.dietaryPreferences")}
        options={DIETARY.map((d) => ({ value: d, label: t(`settings.diet.${d}`) }))}
        values={prefs.dietaryPreferences}
        // Toggled on the record as re-read, never on this screen's copy.
        onToggle={(d) =>
          set(`diet.${d}`, (p) => ({
            ...p,
            dietaryPreferences: p.dietaryPreferences.includes(d) ? p.dietaryPreferences.filter((x) => x !== d) : [...p.dietaryPreferences, d],
          }))
        }
      />

      <GroupLabel>{t("settings.books")}</GroupLabel>
      <Toggle
        id="pref-fast-page-turn"
        label={t("settings.fastPageTurn")}
        hint={t("settings.fastPageTurnHint")}
        checked={prefs.fastPageTurnEnabled}
        busy={busy.has("fastPageTurn")}
        onChange={(v) => set("fastPageTurn", (p) => ({ ...p, fastPageTurnEnabled: v }))}
      />
      <Toggle
        id="pref-sound"
        label={t("settings.soundEffects")}
        checked={prefs.soundEffectsEnabled}
        busy={busy.has("sound")}
        onChange={(v) => set("sound", (p) => ({ ...p, soundEffectsEnabled: v }))}
      />
    </Section>
  );
}

// ---------------------------------------------------------------------------

const NOTIF_ROWS: { group: string; rows: { flag: NotificationFlag; key: string; hint: boolean }[] }[] = [
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

function NotificationsSection({ prefs, busy, set }: { prefs: Preferences; busy: Set<string>; set: SetFn }) {
  const { t } = useI18n();
  const access = useAccess("ff_notifications");
  const reminders = useAccess("ff_shopping_reminder");
  if (access === "hidden" || access === "comingSoon") return null;
  const push = prefs.pushEnabled;
  return (
    <Section id="notifications" icon="inbox" title={t("settings.notifications")} hint={t("settings.pushNote")}>
      <Toggle
        id="notif-push"
        label={t("settings.notif.push")}
        hint={t("settings.notif.pushHint")}
        checked={push}
        busy={busy.has("pushEnabled")}
        onChange={(v) => set("pushEnabled", (p) => ({ ...p, pushEnabled: v }))}
      />
      {!push ? <p className="text-label-md text-on-surface-variant">{t("settings.pushOff")}</p> : null}
      {NOTIF_ROWS.map((g) => (
        <div key={g.group} className="space-y-4">
          <GroupLabel>{t(g.group)}</GroupLabel>
          {g.rows.map((r) => (
            <Toggle
              key={r.flag}
              id={`notif-${r.key}`}
              label={t(`settings.notif.${r.key}`)}
              hint={r.hint ? t(`settings.notif.${r.key}Hint`) : undefined}
              checked={prefs[r.flag]}
              // With the master switch off the rows are moot: drawn
              // disabled rather than hidden so the choices are not lost.
              disabled={!push}
              busy={busy.has(r.flag)}
              onChange={(v) => set(r.flag, (p) => ({ ...p, [r.flag]: v }))}
            />
          ))}
        </div>
      ))}
      {reminders === "enabled" ? (
        <div className="space-y-2">
          <GroupLabel>{t("settings.notif.reminders")}</GroupLabel>
          <Chips<ReminderSlot>
            label={t("settings.shoppingReminders")}
            hint={t("settings.shoppingRemindersHint")}
            options={REMINDER_SLOTS.map((s) => ({ value: s, label: t(`settings.slot.${s}`) }))}
            values={prefs.shoppingReminderSlots}
            onToggle={(s) =>
              set(`slot.${s}`, (p) => ({
                ...p,
                shoppingReminderSlots: p.shoppingReminderSlots.includes(s) ? p.shoppingReminderSlots.filter((x) => x !== s) : REMINDER_SLOTS.filter((x) => x === s || p.shoppingReminderSlots.includes(x)),
              }))
            }
          />
        </div>
      ) : null}
    </Section>
  );
}

// ---------------------------------------------------------------------------

function MoreLinks() {
  const { t } = useI18n();
  const shares = [useAccess("ff_share_recipes"), useAccess("ff_share_books"), useAccess("ff_share_plans"), useAccess("ff_share_grocery_lists")];
  const household = useAccess("ff_households");
  const anyShare = shares.some((a) => a !== "hidden");
  return (
    <section aria-labelledby="more-h" className="space-y-3 animate-rise">
      <h2 id="more-h" className="px-1 text-label-sm uppercase text-on-surface-variant">
        {t("settings.more")}
      </h2>
      {anyShare ? <Row icon={<Icon name="share" />} label={t("settings.sharedAccess")} to="/sharing" /> : null}
      {household !== "hidden" ? <Row icon={<Icon name="household" />} label={t("shell.household")} to="/household" /> : null}
      <Row icon={<Icon name="account" />} label={t("shell.account")} hint={t("settings.accountPage")} to="/account" />
      <h2 className="px-1 pt-2 text-label-sm uppercase text-error">{t("settings.dangerZone")}</h2>
      {/* The stores require deletion to be reachable; never behind a flag. */}
      <Link to="/account#delete-account" className="clay flex w-full items-center gap-4 border border-error/40 p-4 transition-transform active:scale-[.99]">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-error-container text-on-error-container" aria-hidden="true">
          <Icon name="trash" />
        </span>
        <span className="min-w-0 flex-1 text-start">
          <span className="block text-body-md font-bold text-error">{t("settings.deleteAccount")}</span>
          <span className="block text-label-sm text-on-surface-variant">{t("settings.deleteAccountHint")}</span>
        </span>
        <span className="text-on-surface-variant rtl:rotate-180" aria-hidden="true">
          ›
        </span>
      </Link>
    </section>
  );
}
