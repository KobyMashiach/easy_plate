// A modal on the native <dialog> (focus trap, Esc, inert page behind it),
// and the app's AppDialog confirm on top of it. Below lg each one is the
// app's own: the modal a bottom sheet, the confirm the medallion dialog
// (AppDialog.show), the toast the notice dropping from the top.
import { useEffect, useId, useRef, type ReactNode } from "react";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { AppDialog, type DialogKind } from "../../../components/AppDialog";
import { BottomSheet } from "../../../components/BottomSheet";
import { useToast } from "../../../components/Toaster";
import { useIsPhone } from "../../../components/useIsPhone";

export function Modal(props: { open: boolean; onClose: () => void; title: string; children: ReactNode; wide?: boolean; footer?: ReactNode; sheetRadius?: 24 | 32; showTitle?: boolean }) {
  const phone = useIsPhone();
  if (phone) {
    return (
      <BottomSheet open={props.open} onClose={props.onClose} title={props.title} footer={props.footer} radius={props.sheetRadius} showTitle={props.showTitle}>
        {props.children}
      </BottomSheet>
    );
  }
  return <DesktopModal {...props} />;
}

function DesktopModal({ open, onClose, title, children, wide = false, footer }: { open: boolean; onClose: () => void; title: string; children: ReactNode; wide?: boolean; footer?: ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null);
  const id = useId();
  const { t } = useI18n();
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog
      ref={ref}
      aria-labelledby={`${id}-h`}
      onCancel={(e) => {
        e.preventDefault();
        onClose();
      }}
      onClick={(e) => {
        if (e.target === ref.current) onClose();
      }}
      className={`clay m-auto w-[calc(100%-2rem)] ${wide ? "max-w-4xl" : "max-w-md"} max-h-[calc(100dvh-2rem)] overflow-hidden p-0 text-on-surface shadow-dialog backdrop:bg-on-surface/40`}
    >
      {open ? (
        <div className="flex max-h-[calc(100dvh-2rem)] flex-col">
          <header className="flex items-center gap-3 border-b border-outline-variant/40 px-5 py-4">
            <h2 id={`${id}-h`} className="min-w-0 flex-1 text-headline-md">
              {title}
            </h2>
            <button type="button" onClick={onClose} className="grid h-10 w-10 place-items-center rounded-full hover:bg-primary/10" aria-label={t("recipes.close")}>
              <Icon name="close" />
            </button>
          </header>
          <div className="min-h-0 flex-1 overflow-y-auto p-5">{children}</div>
          {footer ? <footer className="flex flex-wrap gap-3 border-t border-outline-variant/40 px-5 py-4">{footer}</footer> : null}
        </div>
      ) : null}
    </dialog>
  );
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel,
  cancelLabel,
  destructive = false,
  busy = false,
  kind,
  icon,
  onConfirm,
  onCancel,
}: {
  open: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel?: string;
  destructive?: boolean;
  busy?: boolean;
  /** Phone medallion (default: warning for a destructive question, general otherwise). */
  kind?: DialogKind;
  icon?: string;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const { t } = useI18n();
  const phone = useIsPhone();
  if (phone) {
    return (
      <AppDialog
        open={open}
        kind={kind ?? (destructive ? "warning" : "general")}
        icon={icon}
        title={title}
        message={message}
        confirmLabel={confirmLabel}
        cancelLabel={cancelLabel ?? t("recipes.cancel")}
        destructive={destructive}
        busy={busy}
        onConfirm={onConfirm}
        onCancel={onCancel}
      />
    );
  }
  return (
    <Modal
      open={open}
      onClose={busy ? () => {} : onCancel}
      title={title}
      footer={
        <>
          <button type="button" className="clay-btn-ghost flex-1" onClick={onCancel} disabled={busy}>
            {cancelLabel ?? t("recipes.cancel")}
          </button>
          <button type="button" className={`${destructive ? "clay-btn-danger" : "clay-btn-primary"} flex-1`} onClick={onConfirm} disabled={busy} aria-busy={busy || undefined}>
            {busy ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" aria-hidden="true" /> : null}
            {confirmLabel}
          </button>
        </>
      }
    >
      <p className="text-body-md text-on-surface-variant">{message}</p>
    </Modal>
  );
}

/** A small live status line that fades by itself (the app's AppDialog.notify). */
export function Toast({ message, kind = "success", onDone }: { message: string | null; kind?: "success" | "error" | "info"; onDone: () => void }) {
  const phone = useIsPhone();
  const notice = useToast();
  // Phone: the shell's notice (white card from the top, 3.2 s).
  useEffect(() => {
    if (!phone || !message) return;
    notice.show(message, kind);
    onDone();
  }, [phone, message, kind, notice, onDone]);
  useEffect(() => {
    if (phone || !message) return;
    const id = setTimeout(onDone, 3500);
    return () => clearTimeout(id);
  }, [phone, message, onDone]);
  if (phone) return null;
  const cls = kind === "error" ? "bg-error-container text-on-error-container" : kind === "info" ? "bg-info-container text-on-info-container" : "bg-secondary-fixed text-on-secondary-fixed";
  return (
    <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-24 z-50 flex justify-center px-4 md:bottom-8">
      {message ? <p className={`pointer-events-auto animate-rise rounded-full px-5 py-3 text-label-md shadow-dialog ${cls}`} role={kind === "error" ? "alert" : "status"}>{message}</p> : null}
    </div>
  );
}
