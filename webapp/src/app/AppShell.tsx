// The signed-in web app's frame, full screen:
//   desktop (lg+): a side menu on the start edge (right in Hebrew/Arabic) with
//     every section, a top bar with the inbox bell, language, appearance and
//     the profile menu, and the page filling the rest of the width;
//   phone: a top bar and the app's dark bottom dock with the five main tabs.
//   phone (below lg): the native frame instead (PhoneFrame.tsx, NavDock.tsx):
//     a white 68 px bar (avatar · "Easy Plate" · bell on the five main tabs,
//     back · title on pushed pages), the Liquid Glass dock and the Shefi pill
//     on the tabs, the cook-timer banner, and the iOS push/pop slide.
// Menu items follow their Remote Config switch: hidden → not drawn,
// coming soon → dimmed with a tag, Premium-only on a free account → a lock
// that leads to the pricing page.
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Link, NavLink, useLocation, useNavigate } from "react-router-dom";
import { NAV, type NavItem } from "./nav";
import { Icon } from "../components/icons";
import { LANGS, useI18n } from "../lib/i18n";
import { useAuth } from "../lib/auth";
import { useFlags, type Access } from "../lib/flags";
import { THEME_EVENT, applyTheme, isDarkNow, readTheme, toggleTheme, type ThemeMode } from "../lib/theme";
import { useUnreadCount } from "./unread";
import { appLanguageOf, updatePreferences } from "../models/preferences";
import { RouteBoundary, useRouteFocus } from "../components/RouteBoundary";
import { trustedPhotoUrl } from "../lib/photoUrl";
import { useIsPhone } from "../components/useIsPhone";
import { PhoneBar, PhoneBarContext, usePhoneBarState } from "../components/PhoneBar";
import { PhonePageTransitions, usePhoneNavigate } from "../components/pageTransition";
import { ShefiPill } from "../components/FloatingActions";
import { ClayButton, ClayCard, Chip } from "../components/clay";
import { NavDock, type DockTab } from "./NavDock";
import { CookTimerBanner, PhoneTopBar, ProfileAvatar } from "./PhoneFrame";

function useNavAccess() {
  const { access } = useFlags();
  return (item: NavItem): Access => {
    const a = item.flag ? access(item.flag) : "enabled";
    return a === "locked" && item.lockedOpens ? "enabled" : a;
  };
}

function NavEntry({ item, access, compact = false }: { item: NavItem; access: Access; compact?: boolean }) {
  const { t } = useI18n();
  const navigate = useNavigate();
  const unread = useUnreadCount();
  const badge = item.path === "/inbox" && unread > 0 ? unread : 0;
  if (access === "hidden") return null;
  const tag = access === "comingSoon" ? t("shell.soon") : null;
  const base = "group flex items-center gap-3 rounded-full px-4 py-2.5 text-label-md transition-colors";
  if (access === "comingSoon") {
    return (
      <span className={`${base} cursor-default text-on-surface-variant/60`} aria-disabled="true">
        <Icon name={item.icon} />
        {!compact && <span className="flex-1">{t(item.label)}</span>}
        {!compact && tag ? <span className="pill-grey">{tag}</span> : null}
      </span>
    );
  }
  if (access === "locked") {
    return (
      <button type="button" onClick={() => navigate("/pricing")} className={`${base} w-full text-on-surface-variant hover:bg-primary/10`}>
        <Icon name={item.icon} />
        {!compact && <span className="flex-1 text-start">{t(item.label)}</span>}
        <Icon name="lock" size={16} />
      </button>
    );
  }
  return (
    <NavLink
      to={item.path}
      className={({ isActive }) => `${base} ${isActive ? "bg-primary text-on-primary shadow-button" : "text-on-surface hover:bg-primary/10"}`}
    >
      <span className="relative">
        <Icon name={item.icon} />
        {badge ? (
          <span className="absolute -end-2 -top-2 grid h-5 min-w-5 place-items-center rounded-full bg-error px-1 text-[11px] font-bold text-on-error">
            {badge > 99 ? "99+" : badge}
          </span>
        ) : null}
      </span>
      {!compact && <span className="flex-1">{t(item.label)}</span>}
    </NavLink>
  );
}

function Avatar({ size = 36 }: { size?: number }) {
  const { user } = useAuth();
  const name = user?.displayName || user?.email || user?.phoneNumber || "?";
  const initial = name.trim().charAt(0).toUpperCase();
  const photo = trustedPhotoUrl(user?.photoURL);
  return photo ? (
    <img src={photo} alt="" width={size} height={size} referrerPolicy="no-referrer" className="rounded-full object-cover" style={{ width: size, height: size }} />
  ) : (
    <span className="grid rounded-full bg-primary-container font-bold text-on-primary-container" style={{ width: size, height: size, placeItems: "center" }}>
      {initial}
    </span>
  );
}

/**
 * "Manage" — only for an administrator account (users/{uid}.permission ==
 * "admin", set in the Firebase console). Opens the web console at /admin,
 * a separate page, so a plain <a> rather than a router link.
 */
function AdminLink({ menu = false }: { menu?: boolean }) {
  const { t } = useI18n();
  const { isAdmin } = useFlags();
  if (!isAdmin) return null;
  return menu ? (
    <a href="/admin" role="menuitem" tabIndex={-1} className="flex items-center gap-3 rounded-std px-3 py-2 font-bold text-primary hover:bg-primary/10">
      <Icon name="settings" size={20} />
      {t("shell.admin")}
    </a>
  ) : (
    <ul className="flex flex-col gap-1">
      <li className="px-4 pt-2 text-label-sm uppercase text-on-surface-variant">{t("shell.group.admin")}</li>
      <li>
        <a href="/admin" className="flex items-center gap-3 rounded-full px-4 py-2.5 text-label-md font-bold text-primary hover:bg-primary/10">
          <Icon name="settings" />
          <span className="flex-1">{t("shell.admin")}</span>
          <Icon name="external" size={16} />
        </a>
      </li>
    </ul>
  );
}

export function ProfileMenu() {
  const { t } = useI18n();
  const { user, premium, signOut } = useAuth();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const menu = useRef<HTMLDivElement>(null);
  // How the menu was opened: from the keyboard the first item takes the focus.
  const focusFirst = useRef(false);
  const location = useLocation();
  useEffect(() => setOpen(false), [location.pathname]);
  useEffect(() => {
    if (!open) return;
    if (focusFirst.current) menu.current?.querySelector<HTMLElement>('[role="menuitem"]')?.focus();
    focusFirst.current = false;
    const onDoc = (e: PointerEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== "Escape") return;
      setOpen(false);
      trigger.current?.focus();
    };
    document.addEventListener("pointerdown", onDoc);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("pointerdown", onDoc);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);
  // The menu pattern: arrows move between items, Home/End jump, Tab leaves.
  const onMenuKey = (e: React.KeyboardEvent) => {
    const items = [...(menu.current?.querySelectorAll<HTMLElement>('[role="menuitem"]') ?? [])];
    if (!items.length) return;
    const i = items.indexOf(document.activeElement as HTMLElement);
    const go = (n: number) => {
      e.preventDefault();
      items[(n + items.length) % items.length].focus();
    };
    if (e.key === "ArrowDown") go(i + 1);
    else if (e.key === "ArrowUp") go(i < 0 ? items.length - 1 : i - 1);
    else if (e.key === "Home") go(0);
    else if (e.key === "End") go(items.length - 1);
    else if (e.key === "Tab") setOpen(false);
  };
  if (!user) return null;
  return (
    <div className="relative" ref={ref}>
      <button
        ref={trigger}
        type="button"
        onClick={(e) => {
          // A keyboard "click" (Enter/Space) reports no pointer position.
          focusFirst.current = e.detail === 0;
          setOpen((o) => !o);
        }}
        onKeyDown={(e) => {
          if (e.key === "ArrowDown" && !open) {
            e.preventDefault();
            focusFirst.current = true;
            setOpen(true);
          }
        }}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls="profile-menu"
        aria-label={t("shell.profileMenu")} className="rounded-full ring-2 ring-transparent transition hover:ring-primary/40">
        <Avatar />
      </button>
      {open ? (
        <div id="profile-menu" ref={menu} role="menu" aria-label={t("shell.profileMenu")} onKeyDown={onMenuKey} className="clay absolute end-0 top-12 z-40 w-64 p-2 animate-rise">
          <div role="none" className="flex items-center gap-3 px-3 py-2">
            <Avatar size={40} />
            <div className="min-w-0">
              <p className="truncate font-bold">{user.displayName || t("app.name")}</p>
              <p className="truncate text-label-sm text-on-surface-variant" dir="ltr">
                {user.email || user.phoneNumber}
              </p>
            </div>
          </div>
          <div role="separator" className="my-1 h-px bg-outline-variant/50" />
          {[
            ["/account", "account", t("nav.account")],
            ["/pricing", "premium", premium ? t("shell.manageSubscription") : t("shell.upgrade")],
            ["/settings", "settings", t("shell.settings")],
            ["/support", "support", t("shell.support")],
          ].map(([to, icon, label]) => (
            <Link key={to} to={to} role="menuitem" tabIndex={-1} className="flex items-center gap-3 rounded-std px-3 py-2 hover:bg-primary/10">
              <Icon name={icon} size={20} />
              {label}
            </Link>
          ))}
          <AdminLink menu />
          <div role="separator" className="my-1 h-px bg-outline-variant/50" />
          <button type="button" role="menuitem" tabIndex={-1} onClick={() => void signOut()} className="flex w-full items-center gap-3 rounded-std px-3 py-2 text-error hover:bg-error/10">
            <Icon name="logout" size={20} />
            {t("nav.signOut")}
          </button>
        </div>
      ) : null}
    </div>
  );
}

function TopBarControls() {
  const { t, lang, setLang } = useI18n();
  const [theme, setTheme] = useState<ThemeMode>(readTheme);
  // Follows a change made anywhere else (the settings page, the account's
  // saved mode on sign-in).
  useEffect(() => {
    const on = (e: Event) => setTheme((e as CustomEvent<ThemeMode>).detail);
    window.addEventListener(THEME_EVENT, on);
    return () => window.removeEventListener(THEME_EVENT, on);
  }, []);
  // Under "system" the icon follows the OS switching light/dark.
  const [, setOsTick] = useState(0);
  useEffect(() => {
    if (theme !== "system" || !window.matchMedia) return;
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const on = () => setOsTick((n) => n + 1);
    mq.addEventListener?.("change", on);
    return () => mq.removeEventListener?.("change", on);
  }, [theme]);
  const dark = theme === "dark" || (theme === "system" && isDarkNow());
  // Dark ↔ light only, with the circle growing from the button.
  const cycle = (e: React.MouseEvent<HTMLButtonElement>) => {
    const r = e.currentTarget.getBoundingClientRect();
    const next = toggleTheme({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
    // Kept on the account too, like the app's theme selector, so the phone
    // and the next sign-in follow it. A failed save leaves the screen as is.
    // A record that does not exist yet is seeded in the language on screen,
    // not the default Hebrew.
    void updatePreferences((p) => ({ ...p, themeMode: next }), appLanguageOf(lang)).catch(() => {});
  };
  const unread = useUnreadCount();
  const { access } = useFlags();
  return (
    <div className="flex items-center gap-2">
      {access("ff_notifications") === "enabled" || access("ff_notifications") === "locked" ? (
        <Link to="/inbox" className="relative grid h-10 w-10 place-items-center rounded-full bg-surface-low shadow-control" aria-label={t("shell.inbox")}>
          <Icon name="inbox" size={20} />
          {unread > 0 ? <span className="absolute -end-0.5 -top-0.5 h-3 w-3 rounded-full bg-error ring-2 ring-background" aria-hidden="true" /> : null}
        </Link>
      ) : null}
      <label className="sr-only" htmlFor="app-lang">
        {t("lang.label")}
      </label>
      <select id="app-lang" value={lang} onChange={(e) => setLang(e.target.value as typeof lang)} className="hidden h-10 rounded-full bg-surface-low px-3 text-label-md shadow-control sm:block">
        {LANGS.map((l) => (
          <option key={l.code} value={l.code}>
            {l.name}
          </option>
        ))}
      </select>
      <button
        type="button"
        onClick={cycle}
        className="grid h-10 w-10 place-items-center rounded-full bg-surface-low shadow-control"
        aria-label={`${t("theme.label")}: ${t(dark ? "theme.dark" : "theme.light")}`}
        aria-pressed={dark}
      >
        <Icon name={dark ? "moon" : "sun"} size={20} />
      </button>
      <ProfileMenu />
    </div>
  );
}

// The dock's short labels (the app's nav.* strings), by path.
const TAB_LABEL: Record<string, string> = {
  "/recipes": "shell.tab.recipes",
  "/library": "shell.tab.library",
  "/plans": "shell.tab.plans",
  "/groceries": "shell.tab.groceries",
  "/community": "shell.tab.community",
};
const DOCK_PATHS = NAV.filter((n) => n.dock).map((n) => n.path);
const isDockPath = (path: string) => DOCK_PATHS.includes(path.replace(/\/+$/, "") || "/");

/** The page's h1 text, live (lazy pages draw it after their chunk lands). */
function useHeading(main: React.RefObject<HTMLElement>, on: boolean) {
  const { pathname } = useLocation();
  const [heading, setHeading] = useState("");
  useEffect(() => {
    const el = main.current;
    if (!on || !el) return;
    const apply = () => setHeading(el.querySelector("h1")?.textContent?.trim() ?? "");
    apply();
    const obs = new MutationObserver(apply);
    obs.observe(el, { childList: true, subtree: true, characterData: true });
    return () => obs.disconnect();
  }, [pathname, main, on]);
  return heading;
}

export function AppShell({ children }: { children: ReactNode }) {
  const { t } = useI18n();
  const accessOf = useNavAccess();
  const groups: NavItem["group"][] = ["main", "tools", "account"];
  const main = useRef<HTMLElement>(null);
  useRouteFocus(main);
  const phone = useIsPhone();
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const go = usePhoneNavigate();
  const { access } = useFlags();
  const bar = usePhoneBarState();
  const barCtx = useMemo(() => ({ options: bar.options, setOptions: bar.setOptions, slot: bar.slot }), [bar.options, bar.setOptions, bar.slot]);
  const heading = useHeading(main, phone);

  const tab = bar.options.tab ?? isDockPath(pathname);
  const shefi = access("ff_assistant") !== "hidden";
  const showDock = phone && tab && !bar.options.hideDock;
  const showShefi = phone && tab && shefi && !bar.options.hideShefi;
  const dockTabs: DockTab[] = NAV.filter((n) => n.dock && accessOf(n) !== "hidden").map((n) => ({
    path: n.path,
    label: TAB_LABEL[n.path] ?? n.label,
    icon: n.icon,
    access: accessOf(n),
  }));
  const parentTab = DOCK_PATHS.find((p) => pathname.startsWith(`${p}/`)) ?? "/recipes";
  const onBack = () => {
    const idx = (window.history.state as { idx?: number } | null)?.idx ?? 0;
    if (idx > 0) go(-1);
    else navigate(bar.options.back ?? parentTab, { replace: true });
  };
  const barTitle = tab ? (pathname.startsWith("/community") ? t("shell.tab.community") : t("shell.appName")) : bar.options.title ?? heading;
  const isTab = useCallback((p: string) => isDockPath(p), []);
  // Under the dock: 96, + 80 when the Shefi pill (or a page FAB) floats above it (spec 1.7).
  const padBottom = showDock ? (showShefi ? "pb-[calc(176px+env(safe-area-inset-bottom))]" : "pb-[calc(96px+env(safe-area-inset-bottom))]") : "pb-[calc(48px+env(safe-area-inset-bottom))]";

  return (
    <PhoneBarContext.Provider value={barCtx}>
    <div className="min-h-dvh lg:grid lg:grid-cols-[272px_1fr]">
      <a href="#main" className="skip-link">
        {t("nav.skip")}
      </a>
      <PhonePageTransitions isTab={isTab} />
      {/* Side menu (desktop) */}
      <aside className="sticky top-0 hidden h-dvh flex-col gap-2 overflow-y-auto border-e border-outline-variant/40 bg-surface/70 px-3 py-4 backdrop-blur lg:flex" aria-label={t("nav.main")}>
        <Link to="/recipes" className="mb-2 flex items-center gap-2 px-3">
          <img src="/icon-64.png" alt="" width="40" height="40" className="rounded-std shadow-control" />
          <span className="text-headline-md">{t("app.name")}</span>
        </Link>
        <nav className="flex flex-1 flex-col gap-4">
          {groups.map((g) => (
            <ul key={g} className="flex flex-col gap-1">
              {g !== "main" ? <li className="px-4 pt-2 text-label-sm uppercase text-on-surface-variant">{t(`shell.group.${g}`)}</li> : null}
              {NAV.filter((n) => n.group === g).map((item) => (
                <li key={item.path}>
                  <NavEntry item={item} access={accessOf(item)} />
                </li>
              ))}
            </ul>
          ))}
          <AdminLink />
        </nav>
      </aside>

      <div className="flex min-h-dvh min-w-0 flex-col">
        {phone ? (
          <PhoneTopBar tab={tab} title={barTitle} onBack={onBack} trailingSlot={bar.setSlot} cookBanner={<CookTimerBanner />} />
        ) : (
          <header className="sticky top-0 z-30 border-b border-outline-variant/30 bg-background/85 backdrop-blur">
            <div className="flex items-center gap-3 px-4 py-3 lg:px-8">
              <Link to="/recipes" className="flex items-center gap-2 lg:hidden" aria-label={t("app.name")}>
                <img src="/icon-64.png" alt="" width="34" height="34" className="rounded-std shadow-control" />
                <span className="text-body-lg font-extrabold">{t("app.name")}</span>
              </Link>
              <div className="ms-auto">
                <TopBarControls />
              </div>
            </div>
          </header>
        )}

        <main id="main" ref={main} tabIndex={-1} className={`w-full min-w-0 flex-1 px-5 pt-6 focus:outline-none lg:px-5 lg:pb-6 lg:pt-4 ${padBottom}`}>
          <RouteBoundary>{children}</RouteBoundary>
        </main>

        {/* Phone: the Liquid Glass dock and the Shefi pill, on the five main tabs only. */}
        {showDock ? <NavDock tabs={dockTabs} /> : null}
        {showShefi ? <ShefiPill /> : null}
      </div>
    </div>
    </PhoneBarContext.Provider>
  );
}

/** The phone's "more" page: every section the dock has no room for. */
export function MenuPage() {
  const phone = useIsPhone();
  return phone ? <PhoneMenuPage /> : <DesktopMenuPage />;
}

function DesktopMenuPage() {
  const { t } = useI18n();
  const { isAdmin } = useFlags();
  const accessOf = useNavAccess();
  return (
    <div className="mx-auto max-w-xl">
      <h1 className="mb-4 text-headline-lg">{t("shell.more")}</h1>
      <ul className="clay flex flex-col gap-1 p-2">
        {NAV.map((item) => (
          <li key={item.path}>
            <NavEntry item={item} access={accessOf(item)} />
          </li>
        ))}
      </ul>
      {isAdmin ? (
        <div className="clay mt-3 p-2">
          <AdminLink />
        </div>
      ) : null}
    </div>
  );
}

/** A nav row (SettingsNavRow / _MenuRow): ClayCard r24 p24, icon 22 → label bodyLg → chevron. */
function MenuRow({ to, href, icon, label, hint, locked = false }: { to?: string; href?: string; icon: string; label: string; hint?: string; locked?: boolean }) {
  const inner = (
    <>
      <Icon name={icon} size={22} className="text-primary" />
      <span className="min-w-0 flex-1">
        <span className="block text-body-lg text-on-surface">{label}</span>
        {hint ? <span className="mt-1 block text-label-md text-outline">{hint}</span> : null}
      </span>
      {locked ? <Icon name="lock" size={18} className="text-outline" /> : null}
      <Icon name="chevron_right" size={24} className="text-tertiary rtl:-scale-x-100" />
    </>
  );
  const cls = "clay-card press flex w-full items-center gap-3 p-6 text-start";
  return href ? (
    <a href={href} className={cls} style={{ borderRadius: 24 }}>
      {inner}
    </a>
  ) : (
    <Link to={to!} className={cls} style={{ borderRadius: 24 }}>
      {inner}
    </Link>
  );
}

/**
 * The phone's account menu (AccountMenuPage, spec 3.13), opened from the
 * avatar: the profile card, every section the dock has no room for, the
 * language and appearance (the desktop top bar's controls), the admin
 * console for an administrator, and sign out.
 */
function PhoneMenuPage() {
  const { t, lang, setLang } = useI18n();
  const { user, premium, signOut } = useAuth();
  const { isAdmin } = useFlags();
  const accessOf = useNavAccess();
  const [theme, setTheme] = useState<ThemeMode>(readTheme);
  useEffect(() => {
    const on = (e: Event) => setTheme((e as CustomEvent<ThemeMode>).detail);
    window.addEventListener(THEME_EVENT, on);
    return () => window.removeEventListener(THEME_EVENT, on);
  }, []);
  const pickTheme = (mode: ThemeMode) => {
    applyTheme(mode);
    void updatePreferences((p) => ({ ...p, themeMode: mode }), appLanguageOf(lang)).catch(() => {});
  };
  // Native order (account_menu_page.dart): premium, sharing, household,
  // settings, preferences, assistant, help — the web adds nutrition and prices.
  const rows: { path: string; icon: string; label: string; hint?: string; gate?: string }[] = [
    { path: "/pricing", icon: "workspace_premium", label: premium ? t("shell.manageSubscription") : t("shell.upgrade") },
    { path: "/sharing", icon: "group", label: t("shell.sharing") },
    { path: "/household", icon: "family_restroom", label: t("shell.household") },
    { path: "/settings", icon: "settings", label: t("shell.settings"), hint: t("shell.settingsHint") },
    { path: "/settings/preferences", icon: "tune", label: t("shell.preferences"), hint: t("shell.preferencesHint"), gate: "/settings" },
    { path: "/assistant", icon: "auto_awesome", label: t("shell.assistant") },
    { path: "/nutrition", icon: "insights", label: t("shell.nutrition") },
    { path: "/prices", icon: "sell", label: t("shell.prices") },
    { path: "/support", icon: "help_outline", label: t("shell.support") },
  ];
  if (!user) return null;
  return (
    <div className="mx-auto max-w-xl">
      <PhoneBar title={t("shell.more")} />
      <h1 className="sr-only">{t("shell.more")}</h1>
      <ClayCard radius={24} padding={24} to="/account" className="flex items-center gap-3">
        <ProfileAvatar size={56} />
        <span className="min-w-0 flex-1">
          <span className="block truncate text-body-lg text-on-surface">{user.displayName || t("nav.account")}</span>
          <span className="block truncate text-label-md text-on-surface-variant" dir="ltr">
            {user.email || user.phoneNumber}
          </span>
        </span>
      </ClayCard>
      <ul className="mt-8 flex flex-col gap-3">
        {rows.map((r) => {
          const item = NAV.find((n) => n.path === (r.gate ?? r.path));
          const a = item ? accessOf(item) : "enabled";
          if (a === "hidden") return null;
          return (
            <li key={r.path}>
              <MenuRow to={a === "locked" ? "/pricing" : r.path} icon={r.icon} label={r.label} hint={a === "comingSoon" ? t("shell.soon") : r.hint} locked={a === "locked"} />
            </li>
          );
        })}
        {isAdmin ? (
          <li>
            <MenuRow href="/admin" icon="admin_panel_settings" label={t("shell.admin")} />
          </li>
        ) : null}
      </ul>

      <section aria-labelledby="menu-lang" className="clay-card mt-6 p-6" style={{ borderRadius: 24 }}>
        <h2 id="menu-lang" className="border-b border-surface-variant pb-2 text-headline-md">
          {t("lang.label")}
        </h2>
        <div className="mt-4 flex flex-wrap justify-center gap-2">
          {LANGS.map((l) => (
            <Chip key={l.code} selected={lang === l.code} icon={lang === l.code ? "check" : undefined} onClick={() => setLang(l.code)}>
              <span lang={l.code}>{l.name}</span>
            </Chip>
          ))}
        </div>
      </section>

      <section aria-labelledby="menu-theme" className="clay-card mt-6 p-6" style={{ borderRadius: 24 }}>
        <h2 id="menu-theme" className="border-b border-surface-variant pb-2 text-headline-md">
          {t("theme.label")}
        </h2>
        <div className="mt-4 flex flex-wrap justify-center gap-2">
          {(
            [
              ["system", "brightness_auto"],
              ["light", "light_mode"],
              ["dark", "dark_mode"],
            ] as [ThemeMode, string][]
          ).map(([mode, icon]) => (
            <Chip key={mode} selected={theme === mode} icon={icon} onClick={() => pickTheme(mode)}>
              {t(`theme.${mode}`)}
            </Chip>
          ))}
        </div>
      </section>

      <ClayButton expanded icon="logout" className="mt-12" onClick={() => void signOut()}>
        {t("nav.signOut")}
      </ClayButton>
    </div>
  );
}
