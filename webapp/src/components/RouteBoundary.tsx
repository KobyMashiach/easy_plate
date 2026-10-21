// What every page is drawn inside: a Suspense for its lazy chunk and an
// error boundary, so a page that throws (or a chunk that no longer exists
// after a deploy) shows a translated "try again" inside the frame instead of
// blanking the whole app. The boundary resets on navigation. Also moves the
// focus to the page (and the view to its top) after an in-app navigation, so
// a screen reader or keyboard user starts on the new page, not on the menu.
import { Component, Suspense, useEffect, type ErrorInfo, type ReactNode, type RefObject } from "react";
import { useLocation, useNavigationType } from "react-router-dom";
import { useI18n } from "../lib/i18n";
import { Spinner } from "./ui";

// A lazy page whose chunk failed to download: React.lazy keeps the rejection,
// so only a reload fetches the (new) chunk.
const CHUNK_ERROR = /dynamically imported module|Importing a module script failed|error loading dynamically|ChunkLoadError|Loading chunk/i;

interface BoundaryProps {
  resetKey: string;
  fallback: (retry: () => void) => ReactNode;
  children: ReactNode;
}

class Boundary extends Component<BoundaryProps, { error: Error | null }> {
  state: { error: Error | null } = { error: null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("[page]", error, info.componentStack);
  }

  componentDidUpdate(prev: BoundaryProps) {
    if (prev.resetKey !== this.props.resetKey && this.state.error) this.setState({ error: null });
  }

  private retry = () => {
    if (CHUNK_ERROR.test(String(this.state.error?.message || this.state.error))) window.location.reload();
    else this.setState({ error: null });
  };

  render() {
    return this.state.error ? this.props.fallback(this.retry) : this.props.children;
  }
}

function PageFailed({ retry }: { retry: () => void }) {
  const { t } = useI18n();
  return (
    <div className="mx-auto mt-10 max-w-md">
      <div className="clay space-y-4 p-8 text-center" role="alert">
        <h1 className="text-headline-md">{t("common.error")}</h1>
        <button type="button" className="clay-btn-primary w-full" onClick={retry}>
          {t("common.retry")}
        </button>
      </div>
    </div>
  );
}

export function RouteBoundary({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();
  return (
    <Boundary resetKey={pathname} fallback={(retry) => <PageFailed retry={retry} />}>
      <Suspense
        fallback={
          <div className="grid min-h-[40vh] place-items-center">
            <Spinner />
          </div>
        }
      >
        {children}
      </Suspense>
    </Boundary>
  );
}

// The last path a frame saw, across frames (the signed-out card and the full
// app are different components): the first page of a visit keeps the
// browser's own focus; every later navigation moves it.
let lastPath: string | null = null;

export function useRouteFocus(main: RefObject<HTMLElement>) {
  const { pathname, hash } = useLocation();
  const type = useNavigationType();
  useEffect(() => {
    const changed = lastPath !== null && lastPath !== pathname;
    lastPath = pathname;
    if (!changed || hash) return;
    // Back/forward keeps the browser's position; a new page starts at the top.
    if (type !== "POP") window.scrollTo(0, 0);
    const el = main.current;
    // A page that focused its own field (autoFocus) keeps it.
    if (el && !el.contains(document.activeElement)) el.focus({ preventScroll: true });
  }, [pathname, hash, type, main]);

  // The tab title names the page (its h1), so history, tabs and a screen
  // reader's page announcement say where you are. Lazy pages draw their h1
  // after the chunk arrives: watch until it appears.
  useEffect(() => {
    const el = main.current;
    if (!el) return;
    const apply = () => {
      const h1 = el.querySelector("h1")?.textContent?.trim();
      const title = h1 ? `${h1} · EasyPlate` : "EasyPlate";
      if (document.title !== title) document.title = title;
    };
    apply();
    const obs = new MutationObserver(apply);
    obs.observe(el, { childList: true, subtree: true, characterData: true });
    return () => obs.disconnect();
  }, [pathname, main]);
}
