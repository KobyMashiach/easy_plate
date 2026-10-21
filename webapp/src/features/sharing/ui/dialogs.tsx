// The web side of the app's AppDialog convention, shared by community,
// inbox, sharing and household: a confirm before anything destructive, a
// blocking alert for what must be read ("show"), and a short notice that
// goes away by itself ("notify"). Built on <dialog> so focus, Escape and
// the backdrop come from the browser.
import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { useIsPhone } from "../../../components/useIsPhone";
import { BottomSheet } from "../../../components/BottomSheet";
import { AppDialog } from "../../../components/AppDialog";
import { useToast } from "../../../components/Toaster";

export function Modal({ open, onClose, title, children, wide = false, radius = 32 }: { open: boolean; onClose: () => void; title: string; children: ReactNode; wide?: boolean; radius?: 24 | 32 }) {
  // Below lg every modal is the app's bottom sheet (spec 1.10).
  const phone = useIsPhone();
  if (phone) {
    return (
      <BottomSheet open={open} onClose={onClose} title={title} radius={radius}>
        {open ? children : null}
      </BottomSheet>
    );
  }
  return <DesktopModal open={open} onClose={onClose} title={title} wide={wide}>{children}</DesktopModal>;
}

function DesktopModal({ open, onClose, title, children, wide = false }: { open: boolean; onClose: () => void; title: string; children: ReactNode; wide?: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  const { t } = useI18n();
  return (
    <dialog
      ref={ref}
      onCancel={(e) => {
        e.preventDefault();
        onClose();
      }}
      onClick={(e) => {
        if (e.target === ref.current) onClose();
      }}
      aria-label={title}
      className={`m-auto w-[calc(100vw-32px)] ${wide ? "max-w-2xl" : "max-w-md"} rounded-lg bg-surface p-0 text-on-surface shadow-card backdrop:bg-black/40`}
    >
      {open ? (
        <div className="max-h-[85vh] overflow-y-auto p-5">
          <div className="mb-4 flex items-start gap-3">
            <h2 className="min-w-0 flex-1 text-headline-md">{title}</h2>
            <button type="button" onClick={onClose} className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-on-surface-variant hover:bg-primary/10" aria-label={t("sharing.ui.close")}>
              <Icon name="close" size={20} />
            </button>
          </div>
          {children}
        </div>
      ) : null}
    </dialog>
  );
}

interface ConfirmOpts {
  title: string;
  body?: string;
  confirmLabel: string;
  destructive?: boolean;
}

/** `const [confirmUi, confirm] = useConfirm(); if (await confirm({...})) …` */
export function useConfirm(): [ReactNode, (opts: ConfirmOpts) => Promise<boolean>] {
  const { t } = useI18n();
  const [state, setState] = useState<(ConfirmOpts & { resolve: (ok: boolean) => void }) | null>(null);
  const confirm = useCallback((opts: ConfirmOpts) => new Promise<boolean>((resolve) => setState({ ...opts, resolve })), []);
  const answer = (ok: boolean) => {
    state?.resolve(ok);
    setState(null);
  };
  const phone = useIsPhone();
  // The confirm's look is kept while it animates out.
  const last = useRef<ConfirmOpts | null>(null);
  if (state) last.current = state;
  const shown = state ?? last.current;
  const ui = phone ? (
    <AppDialog
      open={state !== null}
      kind={shown?.destructive ? "warning" : "general"}
      icon={shown?.destructive ? "delete_outline" : undefined}
      title={shown?.title}
      message={shown?.body}
      confirmLabel={shown?.confirmLabel ?? ""}
      cancelLabel={t("sharing.ui.cancel")}
      destructive={shown?.destructive}
      onConfirm={() => answer(true)}
      onCancel={() => answer(false)}
    />
  ) : (
    <Modal open={state !== null} onClose={() => answer(false)} title={state?.title ?? ""}>
      {state?.body ? <p className="mb-5 text-body-md text-on-surface-variant">{state.body}</p> : null}
      <div className="flex flex-wrap justify-end gap-2">
        <button type="button" className="clay-btn-ghost" onClick={() => answer(false)}>
          {t("sharing.ui.cancel")}
        </button>
        <button type="button" className={state?.destructive ? "clay-btn-danger" : "clay-btn-primary"} onClick={() => answer(true)} autoFocus>
          {state?.confirmLabel}
        </button>
      </div>
    </Modal>
  );
  return [ui, confirm];
}

type NoticeKind = "success" | "error" | "info";

/**
 * `notify` — a word in passing, gone on its own (AppDialog…notify);
 * `alert` — something to read before going on (AppDialog…show).
 */
export function useNotices(): { ui: ReactNode; notify: (msg: string, kind?: NoticeKind) => void; alert: (msg: string) => void } {
  const { t } = useI18n();
  const [toast, setToast] = useState<{ msg: string; kind: NoticeKind; id: number } | null>(null);
  const [alertMsg, setAlertMsg] = useState<string | null>(null);
  const timer = useRef<number | null>(null);
  useEffect(
    () => () => {
      if (timer.current) window.clearTimeout(timer.current);
    },
    [],
  );
  const phone = useIsPhone();
  const shell = useToast();
  const notify = useCallback((msg: string, kind: NoticeKind = "success") => {
    // Below lg: the app's notice dropping from the top (AppDialog.notify).
    if (phone) {
      shell.show(msg, kind);
      return;
    }
    if (timer.current) window.clearTimeout(timer.current);
    setToast({ msg, kind, id: Date.now() });
    timer.current = window.setTimeout(() => setToast(null), 3500);
  }, [phone, shell]);
  const alert = useCallback((msg: string) => setAlertMsg(msg), []);
  const tone = toast?.kind === "error" ? "bg-error-container text-on-error-container" : toast?.kind === "info" ? "bg-info-container text-on-info-container" : "bg-secondary-fixed text-on-secondary-fixed";
  const lastAlert = useRef<string | null>(null);
  if (alertMsg !== null) lastAlert.current = alertMsg;
  const ui = phone ? (
    <AppDialog open={alertMsg !== null} kind="error" message={alertMsg ?? lastAlert.current ?? ""} confirmLabel={t("sharing.ui.ok")} cancelLabel={null} onConfirm={() => setAlertMsg(null)} onCancel={() => setAlertMsg(null)} />
  ) : (
    <>
      <div aria-live="polite" role="status" className="pointer-events-none fixed inset-x-0 bottom-24 z-50 flex justify-center px-4 lg:bottom-8">
        {toast ? (
          <div key={toast.id} className={`pointer-events-auto max-w-md animate-rise rounded-std px-4 py-3 text-body-md shadow-card ${tone}`}>
            {toast.msg}
          </div>
        ) : null}
      </div>
      <Modal open={alertMsg !== null} onClose={() => setAlertMsg(null)} title={t("sharing.ui.notice")}>
        <p className="mb-5 text-body-md">{alertMsg}</p>
        <div className="flex justify-end">
          <button type="button" className="clay-btn-primary" onClick={() => setAlertMsg(null)} autoFocus>
            {t("sharing.ui.ok")}
          </button>
        </div>
      </Modal>
    </>
  );
  return { ui, notify, alert };
}
