// Once per sign-in, the site takes the account's own language and look, as
// the app does on a second device (AuthSessionService applies the stored
// preferences): preferences/current → language and themeMode. A visitor who
// then changes either on the site keeps their choice for the session.
import { useEffect, useRef } from "react";
import { useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";
import { getRecord } from "../lib/cloud";
import { useContentTranslation } from "../lib/contentTranslation";
import { applyTheme, readTheme, type ThemeMode } from "../lib/theme";
import { PREFERENCES_ID, langOf, normalizePreferences } from "../models/preferences";

export function AccountSync() {
  const { user, needsPhone } = useAuth();
  const { lang, setLang } = useI18n();
  const { translateTo } = useContentTranslation();
  const translateRef = useRef(translateTo);
  translateRef.current = translateTo;
  const applied = useRef<string | null>(null);
  // The language on screen now (not when the effect ran): a switch made while
  // the preferences were loading is the visitor's and wins.
  const langNow = useRef(lang);
  langNow.current = lang;
  useEffect(() => {
    if (!user) {
      // Signed out: the next sign-in (this account or another) applies again.
      applied.current = null;
      return;
    }
    if (needsPhone || applied.current === user.uid) return;
    applied.current = user.uid;
    const langAtStart = langNow.current;
    const themeAtStart = readTheme();
    let live = true;
    let settled = false;
    getRecord<unknown>("preferences", PREFERENCES_ID)
      .then((raw) => {
        settled = true;
        if (!live || !raw) return;
        const prefs = normalizePreferences(raw);
        const wanted = langOf(prefs.language);
        if (wanted && langNow.current === langAtStart && wanted !== langNow.current) {
          setLang(wanted);
          // The account's language is now on screen: its content follows.
          translateRef.current(wanted);
        }
        const mode = prefs.themeMode;
        if ((mode === "light" || mode === "dark" || mode === "system") && readTheme() === themeAtStart) applyTheme(mode as ThemeMode);
      })
      .catch(() => {
        settled = true;
      });
    return () => {
      live = false;
      // Cancelled before the answer (StrictMode's second run, an account
      // switch): let the next run read it again.
      if (!settled && applied.current === user.uid) applied.current = null;
    };
  }, [user, needsPhone, setLang]);
  return null;
}
