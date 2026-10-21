// Light / dark / system, stored under the key the landing pages share.
export type ThemeMode = "system" | "light" | "dark";
const KEY = "ep-theme";

export function readTheme(): ThemeMode {
  try {
    const v = localStorage.getItem(KEY);
    return v === "light" || v === "dark" ? v : "system";
  } catch (_) {
    return "system";
  }
}

export function applyTheme(mode: ThemeMode): void {
  const root = document.documentElement;
  if (mode === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", mode);
  try {
    if (mode === "system") localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, mode);
  } catch (_) {
    /* private window: the attribute alone is fine */
  }
  // Every control showing the mode (the top bar, the settings page) follows.
  window.dispatchEvent(new CustomEvent<ThemeMode>(THEME_EVENT, { detail: mode }));
}

export const THEME_EVENT = "ep-theme-change";

export function isDarkNow(): boolean {
  const forced = document.documentElement.getAttribute("data-theme");
  if (forced) return forced === "dark";
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

/**
 * The top-bar toggle: dark ↔ light only (never back to "system"), with the
 * app's switch animation — the new theme grows as a circle from the tap
 * point over the old one (ThemeSwitcher in the app: 650 ms easeInOutCubic).
 * Uses the View Transitions API; without it, or with reduced motion, the
 * theme simply switches.
 */
export function toggleTheme(origin?: { x: number; y: number }): ThemeMode {
  const next: ThemeMode = isDarkNow() ? "light" : "dark";
  const doc = document as Document & { startViewTransition?: (cb: () => void) => { ready: Promise<void> } };
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!doc.startViewTransition || reduce) {
    applyTheme(next);
    return next;
  }
  const x = origin?.x ?? window.innerWidth / 2;
  const y = origin?.y ?? 0;
  const radius = Math.hypot(Math.max(x, window.innerWidth - x), Math.max(y, window.innerHeight - y));
  const transition = doc.startViewTransition(() => applyTheme(next));
  void transition.ready
    .then(() => {
      document.documentElement.animate(
        { clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${radius}px at ${x}px ${y}px)`] },
        { duration: 650, easing: "cubic-bezier(0.65, 0, 0.35, 1)", pseudoElement: "::view-transition-new(root)" },
      );
    })
    .catch(() => {});
  return next;
}
