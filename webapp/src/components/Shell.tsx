// The page frame. On a phone it is the whole viewport, like the app; on a
// desktop the same column sits centred in a rounded clay "device" so the
// product looks like itself rather than a stretched website. Header: logo,
// language, appearance; footer: the legal pair and support.
// Below lg the header is the app's ClayTopAppBar instead (SignedOutPhoneBar):
// a round back arrow (or the app icon on /login) · the page title · round
// language and appearance buttons — the app's signed-out screens. Desktop
// keeps the web header unchanged.
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import { LANGS, useI18n } from "../lib/i18n";
import { useAuth } from "../lib/auth";
import { THEME_EVENT, isDarkNow, readTheme, toggleTheme, type ThemeMode } from "../lib/theme";
import { Icons } from "./ui";
import { SITE_ORIGIN } from "../lib/firebase";
import { RouteBoundary, useRouteFocus } from "./RouteBoundary";
import { useIsPhone } from "./useIsPhone";
import { ClayIconButton } from "./clay";
import { Icon } from "./icons";
import { PhoneBarContext, usePhoneBarState } from "./PhoneBar";
import { usePhoneNavigate } from "./pageTransition";

export function Shell({ children, wide = false }: { children: ReactNode; wide?: boolean }) {
  const { t, lang, setLang } = useI18n();
  const { user, needsPhone, signOut } = useAuth();
  const [theme, setTheme] = useState<ThemeMode>(readTheme);

  // Follows a change made anywhere else (the account's saved mode applied on
  // sign-in, the full app's top bar).
  useEffect(() => {
    const on = (e: Event) => setTheme((e as CustomEvent<ThemeMode>).detail);
    window.addEventListener(THEME_EVENT, on);
    return () => window.removeEventListener(THEME_EVENT, on);
  }, []);

  // Dark ↔ light only, with the app's circle growing from the button.
  const dark = theme === "dark" || (theme === "system" && isDarkNow());
  const cycleTheme = (e: React.MouseEvent<HTMLButtonElement>) => {
    const r = e.currentTarget.getBoundingClientRect();
    toggleTheme({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
  };
  const themeIcon = dark ? Icons.moon : Icons.sun;
  const legalLang = lang === "en" ? "" : `/${lang}`;
  const signedIn = !!user && !needsPhone;
  const main = useRef<HTMLElement>(null);
  useRouteFocus(main);
  const phone = useIsPhone();
  const bar = usePhoneBarState();
  const barCtx = useMemo(() => ({ options: bar.options, setOptions: bar.setOptions, slot: bar.slot }), [bar.options, bar.setOptions, bar.slot]);

  return (
    <PhoneBarContext.Provider value={barCtx}>
    <div className="min-h-dvh md:flex md:items-start md:justify-center md:py-10">
      <a href="#main" className="skip-link">
        {t("nav.skip")}
      </a>
      <div className={`flex min-h-dvh w-full flex-col md:min-h-[760px] md:rounded-[44px] md:border md:border-outline-variant/40 md:bg-surface/80 md:shadow-dock md:backdrop-blur ${wide ? "md:max-w-[840px]" : "md:max-w-[480px]"}`}>
        {phone ? (
          <SignedOutPhoneBar main={main} dark={dark} onTheme={cycleTheme} title={bar.options.title} back={bar.options.back} trailingSlot={bar.setSlot} />
        ) : (
        <header className="sticky top-0 z-20 bg-background/85 backdrop-blur md:static md:rounded-t-[44px]">
          <div className="flex items-center gap-3 px-4 pb-3 pt-[max(12px,env(safe-area-inset-top))]">
            <NavLink to="/" className="flex items-center gap-2" aria-label={t("app.name")}>
              <img src="/icon-64.png" alt="" width="36" height="36" className="rounded-std shadow-control" />
              <span className="text-body-lg font-extrabold tracking-tight">{t("app.name")}</span>
            </NavLink>
            <div className="ms-auto flex items-center gap-1">
              <label className="sr-only" htmlFor="lang">
                {t("lang.label")}
              </label>
              <select
                id="lang"
                value={lang}
                onChange={(e) => setLang(e.target.value as typeof lang)}
                className="h-10 rounded-full bg-surface-low px-3 text-label-md text-on-surface shadow-control"
              >
                {LANGS.map((l) => (
                  <option key={l.code} value={l.code}>
                    {l.name}
                  </option>
                ))}
              </select>
              <button
                type="button"
                onClick={cycleTheme}
                className="grid h-10 w-10 place-items-center rounded-full bg-surface-low text-on-surface shadow-control"
                aria-label={`${t("theme.label")}: ${t(dark ? "theme.dark" : "theme.light")}`}
                aria-pressed={dark}
                title={t(dark ? "theme.dark" : "theme.light")}
              >
                {themeIcon}
              </button>
            </div>
          </div>
          {signedIn ? (
            <nav aria-label={t("nav.main")} className="px-4 pb-3">
              <ul className="flex gap-1 rounded-full bg-surface-low p-1 shadow-control">
                {[
                  ["/account", t("nav.account")],
                  ["/pricing", t("nav.pricing")],
                  ["/recipes", t("nav.recipes")],
                ].map(([to, label]) => (
                  <li key={to} className="flex-1">
                    <NavLink
                      to={to}
                      className={({ isActive }) =>
                        `block rounded-full px-3 py-2 text-center text-label-md transition-colors ${isActive ? "bg-primary text-on-primary shadow-button" : "text-on-surface-variant hover:bg-primary/10"}`
                      }
                    >
                      {label}
                    </NavLink>
                  </li>
                ))}
              </ul>
            </nav>
          ) : null}
        </header>
        )}

        <main id="main" ref={main} className="flex-1 px-4 pb-8 pt-2 focus:outline-none" tabIndex={-1}>
          <RouteBoundary>{children}</RouteBoundary>
        </main>

        <footer className="px-4 pb-[max(16px,env(safe-area-inset-bottom))] pt-4 text-label-sm text-on-surface-variant">
          <ul className="flex flex-wrap items-center justify-center gap-x-4 gap-y-2">
            <li>
              <a className="hover:text-primary" href={`${SITE_ORIGIN}${legalLang}/privacy`}>
                {t("footer.privacy")}
              </a>
            </li>
            <li>
              <a className="hover:text-primary" href={`${SITE_ORIGIN}${legalLang}/terms`}>
                {t("footer.terms")}
              </a>
            </li>
            <li>
              <a className="hover:text-primary" href="mailto:support@aieasyplate.app">
                {t("footer.support")}
              </a>
            </li>
            <li>
              <a className="hover:text-primary" href={`${SITE_ORIGIN}${legalLang || "/"}`}>
                {t("footer.getApp")}
              </a>
            </li>
            {signedIn ? (
              <li>
                <button type="button" onClick={() => void signOut()} className="inline-flex items-center gap-1 hover:text-primary">
                  {t("nav.signOut")}
                </button>
              </li>
            ) : null}
          </ul>
        </footer>
      </div>
    </div>
    </PhoneBarContext.Provider>
  );
}

/** The page's h1 text, live (lazy pages draw it after their chunk lands). */
function useHeading(main: React.RefObject<HTMLElement>) {
  const { pathname } = useLocation();
  const [heading, setHeading] = useState("");
  useEffect(() => {
    const el = main.current;
    if (!el) return;
    const apply = () => setHeading(el.querySelector("h1")?.textContent?.trim() ?? "");
    apply();
    const obs = new MutationObserver(apply);
    obs.observe(el, { childList: true, subtree: true, characterData: true });
    return () => obs.disconnect();
  }, [pathname, main]);
  return heading;
}

// The signed-out screens' bar on a phone (ClayTopAppBar, spec 1.1): opaque
// surfaceContainerLowest, 68 px under the status bar, hairline + control
// shadow. /login is the app's first screen, so it shows the app icon and name
// instead of a back arrow (login_page.dart has no way back either); /phone is
// the gate, whose only way out is signing out (phone_gate_page.dart).
function SignedOutPhoneBar({
  main,
  dark,
  onTheme,
  title,
  back,
  trailingSlot,
}: {
  main: React.RefObject<HTMLElement>;
  dark: boolean;
  onTheme: (e: React.MouseEvent<HTMLButtonElement>) => void;
  title?: string;
  back?: string;
  trailingSlot: (el: HTMLElement | null) => void;
}) {
  const { t, lang, setLang } = useI18n();
  const { user, signOut } = useAuth();
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const go = usePhoneNavigate();
  const heading = useHeading(main);
  const root = pathname === "/login" || pathname === "/phone";
  const onBack = () => {
    const idx = (window.history.state as { idx?: number } | null)?.idx ?? 0;
    if (idx > 0) go(-1);
    else navigate(back ?? "/login", { replace: true });
  };
  return (
    <header className="sticky top-0 z-20 border-b border-surface-highest bg-surface-lowest pt-[env(safe-area-inset-top)] shadow-control md:rounded-t-[44px]">
      <div className="flex h-[68px] items-center px-5">
        {root ? (
          <img src="/icon-64.png" alt="" width="40" height="40" className="h-10 w-10 shrink-0 rounded-std shadow-control" />
        ) : (
          <ClayIconButton icon="back" label={t("common.back")} onClick={onBack} iconClassName="rtl:rotate-180" />
        )}
        <p className="ms-3 min-w-0 flex-1 truncate text-headline-md text-primary" aria-hidden={!root || undefined}>
          {root ? t("app.name") : title ?? heading}
        </p>
        <div ref={trailingSlot} className="ms-2 flex items-center gap-2 empty:hidden" />
        <div className="ms-2 flex items-center gap-2">
          {/* A round ghost button with the native picker laid over it. */}
          <span className="press-icon relative inline-grid h-10 w-10 shrink-0 place-items-center rounded-full border border-surface-highest bg-surface-low text-primary shadow-control">
            <Icon name="language" size={22} />
            <select
              value={lang}
              onChange={(e) => setLang(e.target.value as typeof lang)}
              aria-label={t("lang.label")}
              className="absolute inset-0 cursor-pointer appearance-none rounded-full opacity-0"
            >
              {LANGS.map((l) => (
                <option key={l.code} value={l.code}>
                  {l.name}
                </option>
              ))}
            </select>
          </span>
          <ClayIconButton
            icon={dark ? "dark_mode" : "light_mode"}
            label={`${t("theme.label")}: ${t(dark ? "theme.dark" : "theme.light")}`}
            aria-pressed={dark}
            onClick={(e) => onTheme(e as React.MouseEvent<HTMLButtonElement>)}
          />
          {pathname === "/phone" && user ? <ClayIconButton icon="logout" label={t("nav.signOut")} onClick={() => void signOut()} /> : null}
        </div>
      </div>
    </header>
  );
}
