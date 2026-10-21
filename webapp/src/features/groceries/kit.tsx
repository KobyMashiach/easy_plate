// Small pieces the groceries and prices pages share: a modal (the app's
// bottom sheets and AppDialogs), a confirm, a one-line prompt, the transient
// status line (the app's AppDialog.notify — never a SnackBar), chips, and
// the app's amount parsing/formatting.
import { useCallback, useEffect, useId, useMemo, useRef, useState, type ReactNode } from "react";
import { useCollection } from "../../lib/cloud";
import { useTranslatedList } from "../../lib/contentTranslation";
import { normalizeRecipe } from "../../models/recipe";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { useI18n } from "../../lib/i18n";
import { isPhoneNow, useIsPhone } from "../../components/useIsPhone";
import { BottomSheet } from "../../components/BottomSheet";
import { AppDialog } from "../../components/AppDialog";

/**
 * A typed quantity, as a shopper types it (parse_amount.dart): "1.5" and
 * "1,5" alike, spaces ignored. Null for anything that is not a positive
 * number — a zero or negative amount is not a quantity of anything.
 */
export function parseAmount(text: string): number | null {
  const t = text.trim().replace(",", ".");
  if (!/^[+]?\d*\.?\d+$|^[+]?\d+\.$/.test(t)) return null;
  const value = Number(t);
  return Number.isFinite(value) && value > 0 ? value : null;
}

/** formatAmount (lib/core/utils/amount_format.dart): whole numbers bare, else up to two decimals. */
export function formatAmount(n: number): string {
  if (!Number.isFinite(n)) return "";
  if (Math.abs(n - Math.round(n)) < 1e-9) return String(Math.round(n));
  return String(Number(n.toFixed(2)));
}

/** priceLabel (price_widgets.dart): the symbol in front, two decimals. */
export function priceLabel(amount: number, currency = "ILS"): string {
  const symbol = currency === "USD" ? "$" : currency === "EUR" ? "€" : "₪";
  return `${symbol}${amount.toFixed(2)}`;
}

export function Modal({
  open,
  onClose,
  title,
  children,
  footer,
  wide = false,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  footer?: ReactNode;
  wide?: boolean;
}) {
  const phone = useIsPhone();
  if (phone) {
    // The app's bottom sheet; a sheet's "cancel" is the scrim or a drag
    // (secondary buttons carry max-lg:hidden), its one action full width.
    return (
      <BottomSheet open={open} onClose={onClose} title={title} footer={footer ? <div className="flex flex-col gap-2">{footer}</div> : undefined}>
        {children}
      </BottomSheet>
    );
  }
  return <DesktopModal open={open} onClose={onClose} title={title} footer={footer} wide={wide}>{children}</DesktopModal>;
}

function DesktopModal({
  open,
  onClose,
  title,
  children,
  footer,
  wide = false,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  footer?: ReactNode;
  wide?: boolean;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  const { t } = useI18n();
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    const onCancel = (e: Event) => {
      e.preventDefault();
      onClose();
    };
    d.addEventListener("cancel", onCancel);
    return () => d.removeEventListener("cancel", onCancel);
  }, [onClose]);
  return (
    <dialog
      ref={ref}
      aria-labelledby={titleId}
      className={`m-auto w-[calc(100%-2rem)] ${wide ? "max-w-2xl" : "max-w-md"} rounded-lg bg-surface p-0 text-on-surface shadow-card backdrop:bg-black/40`}
      onClick={(e) => {
        if (e.target === ref.current) onClose();
      }}
    >
      {open ? (
        <div className="flex max-h-[85vh] flex-col">
          <header className="flex items-center gap-3 px-5 pb-2 pt-5">
            <h2 id={titleId} className="min-w-0 flex-1 text-headline-md">
              {title}
            </h2>
            <button type="button" onClick={onClose} className="grid h-10 w-10 place-items-center rounded-full text-on-surface-variant hover:bg-surface-high" aria-label={t("groceries.close")}>
              <Icon name="close" size={20} />
            </button>
          </header>
          <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-4">{children}</div>
          {footer ? <footer className="flex flex-wrap gap-3 border-t border-outline-variant/40 px-5 py-4">{footer}</footer> : null}
        </div>
      ) : null}
    </dialog>
  );
}

/** Resolves true on confirm. Destructive confirms use the danger button. */
export function useConfirm() {
  const [state, setState] = useState<{ title: string; body?: string; confirm: string; danger: boolean; icon?: string; resolve: (v: boolean) => void } | null>(null);
  // What the phone dialog keeps drawing while it animates out.
  const last = useRef(state);
  if (state) last.current = state;
  const ask = useCallback(
    (title: string, opts: { body?: string; confirm: string; danger?: boolean; icon?: string }) =>
      new Promise<boolean>((resolve) => setState({ title, body: opts.body, confirm: opts.confirm, danger: opts.danger ?? true, icon: opts.icon, resolve })),
    [],
  );
  const { t } = useI18n();
  const phone = useIsPhone();
  const done = (v: boolean) => {
    state?.resolve(v);
    setState(null);
  };
  if (phone) {
    const s = state ?? last.current;
    // AppDialog.warning(…, destructive) — the app's confirm.
    const element = (
      <AppDialog
        open={state !== null}
        kind={s?.danger ? "warning" : "general"}
        icon={s?.icon}
        title={s?.title}
        message={s?.body}
        confirmLabel={s?.confirm ?? ""}
        cancelLabel={t("groceries.common.cancel")}
        destructive={s?.danger}
        onConfirm={() => done(true)}
        onCancel={() => done(false)}
      />
    );
    return { ask, element };
  }
  const element = (
    <Modal
      open={state !== null}
      onClose={() => done(false)}
      title={state?.title ?? ""}
      footer={
        <>
          <button type="button" className={`${state?.danger ? "clay-btn-danger" : "clay-btn-primary"} flex-1`} onClick={() => done(true)}>
            {state?.confirm}
          </button>
          <button type="button" className="clay-btn-secondary flex-1" onClick={() => done(false)}>
            {t("groceries.common.cancel")}
          </button>
        </>
      }
    >
      {state?.body ? <p className="text-body-md text-on-surface-variant">{state.body}</p> : null}
    </Modal>
  );
  return { ask, element };
}

/** A one-line text prompt (AppDialog.prompt). Resolves the trimmed text, or null when dismissed. */
export function usePrompt() {
  const [state, setState] = useState<{ title: string; label: string; initial: string; icon?: string; resolve: (v: string | null) => void } | null>(null);
  const last = useRef(state);
  if (state) last.current = state;
  const [value, setValue] = useState("");
  const { t } = useI18n();
  const phone = useIsPhone();
  const id = useId();
  const ask = useCallback(
    (title: string, label: string, initial = "", icon?: string) =>
      new Promise<string | null>((resolve) => {
        setValue(initial);
        setState({ title, label, initial, icon, resolve });
      }),
    [],
  );
  const done = (v: string | null) => {
    state?.resolve(v);
    setState(null);
  };
  const trimmed = value.trim();
  if (phone) {
    const s = state ?? last.current;
    const element = (
      <AppDialog
        open={state !== null}
        icon={s?.icon ?? "edit"}
        title={s?.title}
        confirmLabel={t("groceries.common.save")}
        cancelLabel={t("groceries.common.cancel")}
        confirmDisabled={!trimmed}
        onConfirm={() => trimmed && done(trimmed)}
        onCancel={() => done(null)}
      >
        <form
          onSubmit={(e) => {
            e.preventDefault();
            if (trimmed) done(trimmed);
          }}
        >
          <label htmlFor={`${id}-in`} className="sr-only">
            {s?.label}
          </label>
          <input id={`${id}-in`} className="clay-input" placeholder={s?.label} value={value} onChange={(e) => setValue(e.target.value)} autoFocus maxLength={120} />
        </form>
      </AppDialog>
    );
    return { ask, element };
  }
  const element = (
    <Modal
      open={state !== null}
      onClose={() => done(null)}
      title={state?.title ?? ""}
      footer={
        <>
          <button type="submit" form={id} className="clay-btn-primary flex-1" disabled={!trimmed}>
            {t("groceries.common.save")}
          </button>
          <button type="button" className="clay-btn-secondary flex-1" onClick={() => done(null)}>
            {t("groceries.common.cancel")}
          </button>
        </>
      }
    >
      <form
        id={id}
        onSubmit={(e) => {
          e.preventDefault();
          if (trimmed) done(trimmed);
        }}
        className="space-y-1.5"
      >
        <label htmlFor={`${id}-in`} className="block text-label-md text-on-surface-variant">
          {state?.label}
        </label>
        <input id={`${id}-in`} className="clay-input" value={value} onChange={(e) => setValue(e.target.value)} autoFocus maxLength={120} />
      </form>
    </Modal>
  );
  return { ask, element };
}

/** The transient status line: what the app shows with AppDialog.notify. */
export function useStatus() {
  const [status, setStatus] = useState<{ kind: "info" | "success" | "error"; text: string; action?: { label: string; run: () => void } } | null>(null);
  const timer = useRef<number | null>(null);
  const show = useCallback((kind: "info" | "success" | "error", text: string, action?: { label: string; run: () => void }) => {
    if (timer.current) window.clearTimeout(timer.current);
    setStatus({ kind, text, action });
    timer.current = window.setTimeout(() => setStatus(null), action ? 7000 : isPhoneNow() ? 3200 : 4500);
  }, []);
  useEffect(() => () => {
    if (timer.current) window.clearTimeout(timer.current);
  }, []);
  const phone = useIsPhone();
  if (phone) {
    // AppDialog.notify: a white card dropping from the top, a kind medallion,
    // 3.2 s (longer with an action, so "undo" can still be reached).
    const m = status ? { info: { cls: "bg-info-container text-on-info-container", icon: "info" }, success: { cls: "bg-secondary-container text-on-secondary-container", icon: "check" }, error: { cls: "bg-error text-on-error", icon: "error_outline" } }[status.kind] : null;
    const element = (
      <div aria-live="polite" className="pointer-events-none fixed inset-x-0 z-50 flex justify-center px-4" style={{ top: "calc(env(safe-area-inset-top) + 8px)" }}>
        {status && m ? (
          <div
            role={status.kind === "error" ? "alert" : "status"}
            onClick={() => !status.action && setStatus(null)}
            className="notice-in pointer-events-auto flex w-full max-w-[440px] items-center gap-3 rounded-md border-[0.5px] border-surface-highest bg-surface-lowest pb-3 pe-4 ps-3 pt-3 text-on-surface shadow-dock"
          >
            <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${m.cls}`} aria-hidden="true">
              <Icon name={m.icon} size={20} />
            </span>
            <p className="min-w-0 flex-1 text-body-md">{status.text}</p>
            {status.action ? (
              <button
                type="button"
                className="press shrink-0 rounded-full px-2 py-1 text-label-md text-primary"
                onClick={() => {
                  status.action?.run();
                  setStatus(null);
                }}
              >
                {status.action.label}
              </button>
            ) : null}
          </div>
        ) : null}
      </div>
    );
    return { show, element };
  }
  const cls = status
    ? { info: "bg-info-container text-on-info-container", success: "bg-secondary-fixed text-on-secondary-fixed", error: "bg-error-container text-on-error-container" }[status.kind]
    : "";
  const element = (
    <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-24 z-40 flex justify-center px-4 lg:bottom-8">
      {status ? (
        <div role={status.kind === "error" ? "alert" : "status"} className={`pointer-events-auto flex max-w-lg items-center gap-3 rounded-std px-4 py-3 text-body-md shadow-card ${cls}`}>
          <span className="min-w-0 flex-1">{status.text}</span>
          {status.action ? (
            <button
              type="button"
              className="shrink-0 font-bold underline"
              onClick={() => {
                status.action?.run();
                setStatus(null);
              }}
            >
              {status.action.label}
            </button>
          ) : null}
        </div>
      ) : null}
    </div>
  );
  return { show, element };
}

export function Chip({ selected, onClick, disabled, children, label }: { selected: boolean; onClick: () => void; disabled?: boolean; children: ReactNode; label?: string }) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      aria-label={label}
      disabled={disabled}
      onClick={onClick}
      className={`rounded-full border px-3 py-1.5 text-label-md transition-colors disabled:opacity-40 ${
        selected ? "border-primary bg-primary text-on-primary" : "border-outline-variant bg-surface-low text-on-surface hover:bg-surface-high"
      }`}
    >
      {children}
    </button>
  );
}

export function Loading() {
  const { t } = useI18n();
  return (
    <div className="py-10 text-center">
      <Spinner label={t("common.loading")} />
    </div>
  );
}

export function EmptyState({ icon, text, action }: { icon: string; text: string; action?: ReactNode }) {
  return (
    <div className="clay mx-auto max-w-lg space-y-4 p-8 text-center">
      <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
        <Icon name={icon} />
      </span>
      <p className="text-body-md text-on-surface-variant">{text}</p>
      {action}
    </div>
  );
}

/** A round icon button with a visible tooltip-less label for screen readers. */
export function IconButton({ icon, label, onClick, disabled, tone = "plain", busy }: { icon: string; label: string; onClick: () => void; disabled?: boolean; tone?: "plain" | "primary" | "danger"; busy?: boolean }) {
  const cls = {
    plain: "bg-surface-low text-on-surface hover:bg-surface-high",
    primary: "bg-primary text-on-primary shadow-button",
    danger: "bg-surface-low text-error hover:bg-error-container",
  }[tone];
  return (
    <button type="button" onClick={onClick} disabled={disabled || busy} aria-label={label} title={label} className={`grid h-11 w-11 shrink-0 place-items-center rounded-full transition-transform active:scale-95 disabled:opacity-40 ${cls}`}>
      {busy ? <Spinner small /> : <Icon name={icon} size={20} />}
    </button>
  );
}

/**
 * Recipe id → its title in the language on screen, for recipes that have a
 * translation overlay only (display only: a source label or a list's
 * "made from" line). Listens to the recipes only while `enabled`.
 */
export function useShownRecipeTitles(uid: string | null | undefined, enabled: boolean): Map<string, string> {
  const live = useCollection<unknown>("recipes", enabled ? uid : null);
  const stored = useMemo(() => (live.items ? live.items.map(normalizeRecipe).filter((r) => r.id) : null), [live.items]);
  const shown = useTranslatedList("recipe", stored);
  return useMemo(() => {
    const out = new Map<string, string>();
    if (!shown || !stored || shown === stored) return out;
    shown.forEach((r, i) => {
      if (r !== stored[i] && r.title) out.set(r.id, r.title);
    });
    return out;
  }, [shown, stored]);
}
