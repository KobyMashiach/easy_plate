// AppDialog.show (spec 2.1): the app's modal question. Below lg the native
// card — centred, radius 32, a 64 px icon medallion, centred title and
// message, a full-width ClayButton and a text cancel under it, a blurred
// scrim. Above lg today's dialog (header, side-by-side buttons), unchanged.
//
//   <AppDialog open={ask} kind="warning" title={t("x.deleteTitle")} message={t("x.deleteBody")}
//              confirmLabel={t("x.delete")} destructive busy={busy}
//              onConfirm={doDelete} onCancel={() => setAsk(false)} />
//
// `cancelLabel={null}` = a single-button alert. `children` = custom content
// (a text field) between the message and the buttons.
import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { Icon } from "./icons";
import { useI18n } from "../lib/i18n";
import { useIsPhone, reducedMotionNow } from "./useIsPhone";

export type DialogKind = "general" | "info" | "success" | "warning" | "error";

const KIND: Record<DialogKind, { cls: string; icon: string }> = {
  general: { cls: "bg-primary-fixed text-primary", icon: "auto_awesome" },
  info: { cls: "bg-info-container text-on-info-container", icon: "info" },
  success: { cls: "bg-secondary-container text-on-secondary-container", icon: "check" },
  warning: { cls: "bg-error-container text-on-error-container", icon: "warning_amber" },
  error: { cls: "bg-error text-on-error", icon: "error_outline" },
};

const EXIT_MS = 180;

export function AppDialog({
  open,
  kind = "general",
  icon,
  title,
  message,
  confirmLabel,
  cancelLabel,
  destructive = false,
  busy = false,
  confirmDisabled = false,
  onConfirm,
  onCancel,
  children,
}: {
  open: boolean;
  kind?: DialogKind;
  /** Overrides the kind's medallion icon. */
  icon?: string;
  title?: string;
  message?: ReactNode;
  confirmLabel: string;
  /** Default "Cancel"; null = no cancel button (an alert). */
  cancelLabel?: string | null;
  destructive?: boolean;
  busy?: boolean;
  confirmDisabled?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  children?: ReactNode;
}) {
  const phone = useIsPhone();
  const { t } = useI18n();
  const ref = useRef<HTMLDialogElement>(null);
  const id = useId();
  const [closing, setClosing] = useState(false);
  const cancel = cancelLabel === null ? null : cancelLabel ?? t("common.cancel");
  const dismiss = () => {
    if (!busy) onCancel();
  };

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) {
      setClosing(false);
      d.showModal();
      return;
    }
    if (!open && d.open) {
      if (!phone || reducedMotionNow()) {
        d.close();
        return;
      }
      setClosing(true);
      const timer = window.setTimeout(() => {
        d.close();
        setClosing(false);
      }, EXIT_MS);
      return () => window.clearTimeout(timer);
    }
  }, [open, phone]);

  const shared = {
    ref,
    "aria-labelledby": title ? `${id}-h` : undefined,
    "aria-describedby": message ? `${id}-m` : undefined,
    onCancel: (e: React.SyntheticEvent) => {
      e.preventDefault();
      dismiss();
    },
    onClick: (e: React.MouseEvent) => {
      if (e.target === ref.current) dismiss();
    },
  };

  if (!phone) {
    // Today's dialog (features/recipes/components/Modal.tsx ConfirmDialog).
    return (
      <dialog {...shared} className="clay m-auto max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-md overflow-hidden p-0 text-on-surface shadow-dialog backdrop:bg-on-surface/40">
        {open ? (
          <div className="flex max-h-[calc(100dvh-2rem)] flex-col">
            <header className="flex items-center gap-3 border-b border-outline-variant/40 px-5 py-4">
              <h2 id={`${id}-h`} className="min-w-0 flex-1 text-headline-md">
                {title}
              </h2>
              <button type="button" onClick={dismiss} className="grid h-10 w-10 place-items-center rounded-full hover:bg-primary/10" aria-label={t("shell.close")}>
                <Icon name="close" />
              </button>
            </header>
            <div className="min-h-0 flex-1 overflow-y-auto p-5">
              {message ? (
                <p id={`${id}-m`} className="text-body-md text-on-surface-variant">
                  {message}
                </p>
              ) : null}
              {children ? <div className={message ? "mt-4" : ""}>{children}</div> : null}
            </div>
            <footer className="flex flex-wrap gap-3 border-t border-outline-variant/40 px-5 py-4">
              {cancel ? (
                <button type="button" className="clay-btn-ghost flex-1" onClick={dismiss} disabled={busy}>
                  {cancel}
                </button>
              ) : null}
              <button type="button" className={`${destructive ? "clay-btn-danger" : "clay-btn-primary"} flex-1`} onClick={onConfirm} disabled={busy || confirmDisabled} aria-busy={busy || undefined}>
                {busy ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" aria-hidden="true" /> : null}
                {confirmLabel}
              </button>
            </footer>
          </div>
        ) : null}
      </dialog>
    );
  }

  const k = KIND[kind];
  return (
    <dialog {...shared} className={`app-dialog ${closing ? "is-closing" : ""}`}>
      {open || closing ? (
        <div className="app-dialog-card flex max-h-[calc(100dvh-48px)] flex-col items-center overflow-y-auto rounded-lg border-[0.5px] border-surface-highest bg-surface-lowest p-6 text-center text-on-surface shadow-dialog">
          <span className={`grid h-16 w-16 shrink-0 place-items-center rounded-full ${k.cls}`} aria-hidden="true">
            <Icon name={icon ?? k.icon} size={32} />
          </span>
          {title ? (
            <h2 id={`${id}-h`} className="mt-4 text-headline-md">
              {title}
            </h2>
          ) : null}
          {message ? (
            <p id={`${id}-m`} className={`mt-2 text-body-md ${title ? "text-on-surface-variant" : "text-on-surface"}`}>
              {message}
            </p>
          ) : null}
          {children ? <div className="mt-4 w-full text-start">{children}</div> : null}
          <div className="mt-6 flex w-full flex-col items-center gap-2">
            {busy ? (
              <span role="status" className="grid h-14 place-items-center">
                <span className="inline-block h-7 w-7 animate-spin rounded-full border-[3px] border-primary border-t-transparent" aria-hidden="true" />
              </span>
            ) : (
              <button type="button" className={`${destructive ? "clay-btn-danger" : "clay-btn-primary"} w-full`} onClick={onConfirm} disabled={confirmDisabled}>
                {confirmLabel}
              </button>
            )}
            {cancel && !busy ? (
              <button type="button" onClick={dismiss} className="press min-h-11 rounded-full px-4 text-label-md text-on-surface-variant">
                {cancel}
              </button>
            ) : null}
          </div>
        </div>
      ) : null}
    </dialog>
  );
}
