/* eslint-disable react-refresh/only-export-components */
// The iOS push/pop slide between routes (spec 1.8), phone only, on the View
// Transitions API: the new page slides in from the end edge (from the left in
// Hebrew) while the old one drifts a third toward the start and dims; back
// reverses it. Main tabs switch instantly (no transition), like the app's
// IndexedStack. Off under reduced motion and where the API is missing.
//
// <PhonePageTransitions isTab={…} /> (in the frame) animates every in-app
// <a>/<Link> click. Programmatic navigation: `const go = usePhoneNavigate(); go("/x")`,
// and `go(-1)` for back.
import { useCallback, useEffect } from "react";
import { flushSync } from "react-dom";
import { useNavigate, type NavigateOptions } from "react-router-dom";
import { isPhoneNow, reducedMotionNow } from "./useIsPhone";

type VT = { finished: Promise<void> };
type StartVT = (cb: () => void | Promise<void>) => VT;

const BASE = "/app";

function canAnimate(): boolean {
  return isPhoneNow() && !reducedMotionNow() && typeof (document as Document & { startViewTransition?: StartVT }).startViewTransition === "function";
}

function run(kind: "push" | "pop", update: () => void | Promise<void>) {
  const html = document.documentElement;
  html.classList.add(`vt-${kind}`);
  const vt = (document as Document & { startViewTransition: StartVT }).startViewTransition(update);
  vt.finished.finally(() => html.classList.remove(`vt-${kind}`));
}

function waitForPop(): Promise<void> {
  return new Promise((resolve) => {
    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      window.removeEventListener("popstate", on);
      // Let the router commit the previous page before the new snapshot.
      window.setTimeout(resolve, 40);
    };
    const on = () => finish();
    window.addEventListener("popstate", on);
    window.setTimeout(finish, 600);
  });
}

/** navigate() with the phone push/pop slide. */
export function usePhoneNavigate() {
  const navigate = useNavigate();
  return useCallback(
    (to: string | number, options?: NavigateOptions) => {
      if (!canAnimate()) {
        if (typeof to === "number") navigate(to);
        else navigate(to, options);
        return;
      }
      if (typeof to === "number") {
        run(to < 0 ? "pop" : "push", () => {
          navigate(to);
          return waitForPop();
        });
      } else {
        run("push", () => flushSync(() => navigate(to, options)));
      }
    },
    [navigate],
  );
}

export function PhonePageTransitions({ isTab }: { isTab: (path: string) => boolean }) {
  const navigate = useNavigate();
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      if (!canAnimate()) return;
      const a = (e.target as Element | null)?.closest?.("a");
      if (!a || (a.target && a.target !== "_self") || a.hasAttribute("download")) return;
      const url = new URL(a.href, location.href);
      if (url.origin !== location.origin || !(url.pathname === BASE || url.pathname.startsWith(`${BASE}/`))) return;
      const path = url.pathname.slice(BASE.length) || "/";
      // Tabs switch instantly; a link to the page you are on does nothing new.
      if (isTab(path) || `${path}${url.search}` === `${location.pathname.slice(BASE.length)}${location.search}`) return;
      if (url.hash && path === location.pathname.slice(BASE.length)) return;
      // The Link's own onClick still runs (we only prevent the default), and
      // React Router skips its navigation because the default is prevented.
      e.preventDefault();
      run("push", () => flushSync(() => navigate(`${path}${url.search}${url.hash}`)));
    };
    document.addEventListener("click", onClick, true);
    return () => document.removeEventListener("click", onClick, true);
  }, [navigate, isTab]);
  return null;
}
