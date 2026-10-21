// Pull to refresh (spec 1.9), phone only: a 40 px white disc with a primary
// arc that follows the finger from the top; past ~80 px it spins and calls
// `onRefresh` until its promise settles. Used by the community feed, forum
// list and thread, notifications and sharing management — an empty list
// still pulls. Touch only (a mouse never pulls); off above lg.
//
//   const pull = usePullToRefresh(() => reload());
//   return <>{pull.indicator}…list…</>;
//
// or <PullToRefresh onRefresh={reload}>…list…</PullToRefresh>.
import { useEffect, useRef, useState, type ReactNode } from "react";
import { useIsPhone } from "./useIsPhone";
import { useI18n } from "../lib/i18n";

const THRESHOLD = 80;
const MAX = 120;

export function usePullToRefresh(onRefresh: () => Promise<unknown> | void, { enabled = true }: { enabled?: boolean } = {}) {
  const phone = useIsPhone();
  const { t } = useI18n();
  const [pull, setPull] = useState(0);
  const [busy, setBusy] = useState(false);
  const cb = useRef(onRefresh);
  cb.current = onRefresh;
  const busyRef = useRef(false);

  useEffect(() => {
    if (!phone || !enabled) return;
    let startY: number | null = null;
    let dist = 0;
    const onStart = (e: TouchEvent) => {
      if (busyRef.current || window.scrollY > 0 || e.touches.length !== 1) return;
      // Not from inside a dialog, a horizontal scroller or a field.
      const el = e.target as HTMLElement;
      if (el.closest("dialog, input, textarea, [data-no-pull]")) return;
      startY = e.touches[0].clientY;
      dist = 0;
    };
    const onMove = (e: TouchEvent) => {
      if (startY === null) return;
      const dy = e.touches[0].clientY - startY;
      if (dy <= 0 || window.scrollY > 0) {
        if (dist) setPull(0);
        dist = 0;
        return;
      }
      // Resistance: the disc moves slower than the finger.
      dist = Math.min(MAX, dy * 0.5);
      if (e.cancelable) e.preventDefault();
      setPull(dist);
    };
    const onEnd = () => {
      if (startY === null) return;
      startY = null;
      if (dist >= THRESHOLD * 0.75) {
        busyRef.current = true;
        setBusy(true);
        setPull(THRESHOLD * 0.75);
        Promise.resolve()
          .then(() => cb.current())
          .catch(() => {})
          .finally(() => {
            busyRef.current = false;
            setBusy(false);
            setPull(0);
          });
      } else setPull(0);
      dist = 0;
    };
    window.addEventListener("touchstart", onStart, { passive: true });
    window.addEventListener("touchmove", onMove, { passive: false });
    window.addEventListener("touchend", onEnd);
    window.addEventListener("touchcancel", onEnd);
    return () => {
      window.removeEventListener("touchstart", onStart);
      window.removeEventListener("touchmove", onMove);
      window.removeEventListener("touchend", onEnd);
      window.removeEventListener("touchcancel", onEnd);
    };
  }, [phone, enabled]);

  const progress = Math.min(1, pull / (THRESHOLD * 0.75));
  const indicator =
    phone && (pull > 0 || busy) ? (
      <div className="pointer-events-none fixed inset-x-0 z-20 flex justify-center" style={{ top: "var(--phone-top, 0px)" }}>
        <span
          role="status"
          aria-label={busy ? t("common.loading") : undefined}
          className="grid h-10 w-10 place-items-center rounded-full bg-surface-lowest shadow-dialog"
          style={{ transform: `translateY(${pull - 24}px)`, transition: pull === 0 || busy ? "transform 240ms cubic-bezier(.23,1,.32,1)" : "none" }}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" className={busy ? "animate-spin" : ""} style={busy ? undefined : { transform: `rotate(${progress * 270}deg)` }} aria-hidden="true">
            <circle cx="12" cy="12" r="9" fill="none" stroke="rgb(var(--c-primary))" strokeWidth="2.5" strokeLinecap="round" strokeDasharray={`${busy ? 42 : Math.max(4, progress * 42)} 100`} />
          </svg>
        </span>
      </div>
    ) : null;
  return { indicator, refreshing: busy, pull };
}

export function PullToRefresh({ onRefresh, enabled = true, children }: { onRefresh: () => Promise<unknown> | void; enabled?: boolean; children: ReactNode }) {
  const { indicator } = usePullToRefresh(onRefresh, { enabled });
  return (
    <>
      {indicator}
      {children}
    </>
  );
}
