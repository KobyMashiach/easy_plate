/* eslint-disable react-refresh/only-export-components */
// The shell's notice: one short message that outlives navigation (the
// provider sits above the router), so a page can say "added to your recipes"
// and then navigate() to it. The app's AppDialog.notify. One message at a
// time; a new one replaces the last.
//   desktop (lg+): a coloured block at the bottom for 3.5 s (unchanged);
//   phone: the app's notice (spec 2.2) — a white card that drops from the
//     top under the status bar with a kind medallion, 3.2 s, tap or swipe up
//     to dismiss.
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { useIsPhone } from "./useIsPhone";
import { Icon } from "./icons";

export type ToastKind = "success" | "error" | "info";
type Toast = { msg: string; kind: ToastKind; id: number };
type ToastApi = { show: (msg: string, kind?: ToastKind) => void };

const Ctx = createContext<ToastApi | null>(null);
const SHOW_MS = 3500;
const PHONE_SHOW_MS = 3200;
const EXIT_MS = 180;

const MEDALLION: Record<ToastKind, { cls: string; icon: string }> = {
  success: { cls: "bg-secondary-container text-on-secondary-container", icon: "check" },
  error: { cls: "bg-error text-on-error", icon: "error_outline" },
  info: { cls: "bg-info-container text-on-info-container", icon: "info" },
};

function PhoneNotice({ toast, leaving, onDismiss }: { toast: Toast; leaving: boolean; onDismiss: () => void }) {
  const startY = useRef<number | null>(null);
  const m = MEDALLION[toast.kind];
  return (
    <div
      key={toast.id}
      onClick={onDismiss}
      onPointerDown={(e) => (startY.current = e.clientY)}
      onPointerUp={(e) => {
        if (startY.current !== null && e.clientY - startY.current < -12) onDismiss();
        startY.current = null;
      }}
      className={`pointer-events-auto flex w-full max-w-[440px] items-center gap-3 rounded-md border-[0.5px] border-surface-highest bg-surface-lowest pb-3 pe-4 ps-3 pt-3 text-on-surface shadow-dock ${leaving ? "notice-out" : "notice-in"}`}
    >
      <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${m.cls}`} aria-hidden="true">
        <Icon name={m.icon} size={20} />
      </span>
      <p className="min-w-0 flex-1 text-body-md">{toast.msg}</p>
    </div>
  );
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const phone = useIsPhone();
  const [toast, setToast] = useState<Toast | null>(null);
  const [leaving, setLeaving] = useState(false);
  const timer = useRef<number | null>(null);
  const exitTimer = useRef<number | null>(null);
  const seq = useRef(0);
  const phoneRef = useRef(phone);
  phoneRef.current = phone;
  useEffect(
    () => () => {
      if (timer.current) window.clearTimeout(timer.current);
      if (exitTimer.current) window.clearTimeout(exitTimer.current);
    },
    [],
  );
  const dismiss = useCallback(() => {
    if (timer.current) window.clearTimeout(timer.current);
    if (!phoneRef.current) {
      setToast(null);
      return;
    }
    setLeaving(true);
    if (exitTimer.current) window.clearTimeout(exitTimer.current);
    exitTimer.current = window.setTimeout(() => {
      setToast(null);
      setLeaving(false);
    }, EXIT_MS);
  }, []);
  const show = useCallback(
    (msg: string, kind: ToastKind = "success") => {
      if (timer.current) window.clearTimeout(timer.current);
      if (exitTimer.current) window.clearTimeout(exitTimer.current);
      seq.current += 1;
      setLeaving(false);
      setToast({ msg, kind, id: seq.current });
      timer.current = window.setTimeout(dismiss, phoneRef.current ? PHONE_SHOW_MS : SHOW_MS);
    },
    [dismiss],
  );
  const api = useMemo(() => ({ show }), [show]);
  const tone =
    toast?.kind === "error"
      ? "bg-error-container text-on-error-container"
      : toast?.kind === "info"
        ? "bg-info-container text-on-info-container"
        : "bg-secondary-fixed text-on-secondary-fixed";
  return (
    <Ctx.Provider value={api}>
      {children}
      {/* Always mounted, so a screen reader hears the message when it lands. */}
      {phone ? (
        <div aria-live="polite" role="status" className="pointer-events-none fixed inset-x-0 top-0 z-[60] flex justify-center px-4 pt-[calc(8px+env(safe-area-inset-top))]">
          {toast ? <PhoneNotice key={toast.id} toast={toast} leaving={leaving} onDismiss={dismiss} /> : null}
        </div>
      ) : (
        <div aria-live="polite" role="status" className="pointer-events-none fixed inset-x-0 bottom-24 z-50 flex justify-center px-4 lg:bottom-8">
          {toast ? (
            <div key={toast.id} className={`pointer-events-auto max-w-md animate-rise rounded-std px-4 py-3 text-body-md shadow-card ${tone}`}>
              {toast.msg}
            </div>
          ) : null}
        </div>
      )}
    </Ctx.Provider>
  );
}

/** `show(message, kind?)` — a notice that survives navigate(). */
export function useToast(): ToastApi {
  const api = useContext(Ctx);
  // Outside the provider (a test render): a silent no-op rather than a crash.
  return api ?? NOOP;
}
const NOOP: ToastApi = { show: () => {} };
