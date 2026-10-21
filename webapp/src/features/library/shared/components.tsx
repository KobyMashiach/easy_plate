// Dialogs, pickers and states shared by the library, plans and nutrition
// pages. Strings live in src/i18n/library.json under "library.ui.*".
import { useEffect, useId, useMemo, useRef, useState, type FormEvent, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { Notice, Spinner } from "../../../components/ui";
import type { Recipe } from "../../../models/recipe";
import { useStorageUrl } from "./hooks";
import { saveErrorKey } from "./store";
import { useIsPhone } from "../../../components/useIsPhone";
import { BottomSheet } from "../../../components/BottomSheet";
import { AppDialog } from "../../../components/AppDialog";
import { ClayButton, ClayTag, EmptyState as ClayEmptyState, LoadingSpinner } from "../../../components/clay";
import { useToast as useAppToast } from "../../../components/Toaster";

// ---------------------------------------------------------------------------
// Modal: a bottom sheet on a phone, a centred card from `sm` up.

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

type ModalProps = { title: string; onClose: () => void; children: ReactNode; footer?: ReactNode; wide?: boolean; busy?: boolean };

/** Below lg the app's bottom sheet (spec 1.10); from lg up the centred card, unchanged. */
export function Modal(props: ModalProps) {
  const phone = useIsPhone();
  return phone ? <PhoneModal {...props} /> : <DesktopModal {...props} />;
}

// The native sheets end on one full-width ClayButton (dismissed by a drag or
// the scrim), so the desktop footer's ghost "cancel" is left out on a phone.
function PhoneModal({ title, onClose, children, footer, busy = false }: ModalProps) {
  return (
    <BottomSheet
      open
      title={title}
      onClose={onClose}
      dismissible={!busy}
      footer={footer ? <div className="flex flex-col gap-2 [&>*]:w-full [&>.clay-btn-ghost]:hidden">{footer}</div> : undefined}
    >
      {children}
    </BottomSheet>
  );
}

function DesktopModal({ title, onClose, children, footer, wide = false, busy = false }: ModalProps) {
  const { t } = useI18n();
  const panel = useRef<HTMLDivElement>(null);
  const titleId = useId();
  const closeRef = useRef(onClose);
  closeRef.current = onClose;
  const busyRef = useRef(busy);
  busyRef.current = busy;

  useEffect(() => {
    const before = document.activeElement as HTMLElement | null;
    const el = panel.current;
    const first = el?.querySelector<HTMLElement>("[data-autofocus]") ?? el?.querySelector<HTMLElement>(FOCUSABLE) ?? el;
    first?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !busyRef.current) {
        e.stopPropagation();
        closeRef.current();
      }
      if (e.key === "Tab" && el) {
        const all = Array.from(el.querySelectorAll<HTMLElement>(FOCUSABLE));
        if (all.length === 0) return;
        const [a, z] = [all[0], all[all.length - 1]];
        if (e.shiftKey && document.activeElement === a) {
          e.preventDefault();
          z.focus();
        } else if (!e.shiftKey && document.activeElement === z) {
          e.preventDefault();
          a.focus();
        }
      }
    };
    document.addEventListener("keydown", onKey, true);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey, true);
      document.body.style.overflow = overflow;
      before?.focus?.();
    };
  }, []);

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-on-surface/40 sm:items-center sm:p-6" onMouseDown={(e) => e.target === e.currentTarget && !busy && onClose()}>
      <div
        ref={panel}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className={`flex max-h-[92vh] w-full flex-col rounded-t-lg bg-surface-lowest shadow-dialog sm:rounded-lg ${wide ? "sm:max-w-2xl" : "sm:max-w-md"} animate-rise`}
      >
        <header className="flex items-center gap-3 px-5 pb-2 pt-5">
          <h2 id={titleId} className="min-w-0 flex-1 text-headline-md">
            {title}
          </h2>
          <button type="button" className="grid h-10 w-10 place-items-center rounded-full text-on-surface-variant hover:bg-surface-high" onClick={onClose} disabled={busy} aria-label={t("library.ui.close")}>
            <Icon name="close" size={20} />
          </button>
        </header>
        <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-4">{children}</div>
        {footer ? <footer className="flex flex-wrap justify-end gap-2 border-t border-outline-variant/60 px-5 py-4">{footer}</footer> : null}
      </div>
    </div>,
    document.body,
  );
}

/** "Are you sure?" with a destructive confirm. Resolves via the callbacks. */
export function ConfirmDialog({ title, message, confirmLabel, onConfirm, onClose, icon = "delete_outline" }: { title: string; message: string; confirmLabel: string; onConfirm: () => Promise<void> | void; onClose: () => void; /** The phone medallion's icon (AppDialog.warning). */ icon?: string }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const go = async () => {
    setBusy(true);
    setError(null);
    try {
      await onConfirm();
      onClose();
    } catch (e) {
      setError(t(saveErrorKey(e)));
      setBusy(false);
    }
  };
  if (phone)
    return (
      <AppDialog open kind="warning" icon={icon} title={title} message={message} confirmLabel={confirmLabel} cancelLabel={t("library.ui.cancel")} destructive busy={busy} onConfirm={go} onCancel={onClose}>
        {error ? <Notice kind="error">{error}</Notice> : null}
      </AppDialog>
    );
  return (
    <Modal
      title={title}
      onClose={onClose}
      busy={busy}
      footer={
        <>
          <button type="button" className="clay-btn-ghost" onClick={onClose} disabled={busy}>
            {t("library.ui.cancel")}
          </button>
          <button type="button" className="clay-btn-danger" onClick={go} disabled={busy} aria-busy={busy || undefined} data-autofocus>
            {busy ? <Spinner small /> : null}
            {confirmLabel}
          </button>
        </>
      }
    >
      <p className="text-body-md text-on-surface-variant">{message}</p>
      {error ? (
        <div className="mt-3">
          <Notice kind="error">{error}</Notice>
        </div>
      ) : null}
    </Modal>
  );
}

/** One text field (a name). Submit is disabled while empty or busy. */
export function PromptDialog({
  title,
  label,
  initial = "",
  confirmLabel,
  onSubmit,
  onClose,
  children,
  requiredHint,
  icon = "drive_file_rename_outline",
}: {
  /** The phone medallion's icon (AppDialog.prompt). */
  icon?: string;
  title: string;
  label: string;
  initial?: string;
  confirmLabel: string;
  onSubmit: (value: string) => Promise<void> | void;
  onClose: () => void;
  children?: ReactNode;
  requiredHint?: string;
}) {
  const { t } = useI18n();
  const phone = useIsPhone();
  const formRef = useRef<HTMLFormElement>(null);
  const [value, setValue] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const id = useId();
  const formId = useId();
  const empty = value.trim() === "";
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (empty || busy) return;
    setBusy(true);
    setError(null);
    try {
      await onSubmit(value.trim());
      onClose();
    } catch (e) {
      setError(t(saveErrorKey(e)));
      setBusy(false);
    }
  };
  if (phone)
    return (
      <AppDialog open kind="general" icon={icon} title={title} confirmLabel={confirmLabel} cancelLabel={t("library.ui.cancel")} busy={busy} confirmDisabled={empty} onConfirm={() => formRef.current?.requestSubmit()} onCancel={onClose}>
        <form ref={formRef} id={formId} onSubmit={submit} className="space-y-4">
          <div className="space-y-1.5">
            <label htmlFor={id} className="sr-only">
              {label}
            </label>
            <input id={id} className="clay-input" placeholder={label} value={value} onChange={(e) => setValue(e.target.value)} maxLength={120} autoFocus aria-describedby={requiredHint && empty ? `${id}-hint` : undefined} />
            {requiredHint && empty ? (
              <p id={`${id}-hint`} className="ps-4 text-label-sm text-on-surface-variant">
                {requiredHint}
              </p>
            ) : null}
          </div>
          {children}
          {error ? <Notice kind="error">{error}</Notice> : null}
        </form>
      </AppDialog>
    );
  return (
    <Modal
      title={title}
      onClose={onClose}
      busy={busy}
      footer={
        <>
          <button type="button" className="clay-btn-ghost" onClick={onClose} disabled={busy}>
            {t("library.ui.cancel")}
          </button>
          <button type="submit" form={formId} className="clay-btn-primary" disabled={empty || busy} aria-busy={busy || undefined}>
            {busy ? <Spinner small /> : null}
            {confirmLabel}
          </button>
        </>
      }
    >
      <form id={formId} onSubmit={submit} className="space-y-4">
        <div className="space-y-1.5">
          <label htmlFor={id} className="block text-label-md text-on-surface-variant">
            {label}
          </label>
          <input id={id} className="clay-input" value={value} onChange={(e) => setValue(e.target.value)} maxLength={120} data-autofocus aria-describedby={requiredHint && empty ? `${id}-hint` : undefined} />
          {requiredHint && empty ? (
            <p id={`${id}-hint`} className="text-label-sm text-on-surface-variant">
              {requiredHint}
            </p>
          ) : null}
        </div>
        {children}
        {error ? <Notice kind="error">{error}</Notice> : null}
      </form>
    </Modal>
  );
}

// ---------------------------------------------------------------------------
// Pictures

export function StorageImage({ path, alt = "", className = "", fallback }: { path: string | null | undefined; alt?: string; className?: string; fallback?: ReactNode }) {
  // The download URL is asked for only once the picture is near the screen:
  // a shelf of hundreds would otherwise resolve every cover up front. Until
  // then a size-less marker (out of the layout) stands where it will be.
  const [near, setNear] = useState(false);
  const marker = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    if (near || !path) return;
    const el = marker.current;
    if (!el || typeof IntersectionObserver === "undefined") {
      setNear(true);
      return;
    }
    const io = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) setNear(true);
    }, { rootMargin: "300px" });
    io.observe(el);
    return () => io.disconnect();
  }, [near, path]);
  const url = useStorageUrl(near ? path : null);
  if (!url)
    return (
      <>
        {path && !near ? <span ref={marker} className="pointer-events-none absolute h-px w-px" aria-hidden="true" /> : null}
        {fallback ?? null}
      </>
    );
  return <img src={url} alt={alt} loading="lazy" decoding="async" className={className} draggable={false} />;
}

export function RecipeThumb({ recipe, size = "h-12 w-12" }: { recipe: Pick<Recipe, "imageStoragePath">; size?: string }) {
  return (
    <StorageImage
      path={recipe.imageStoragePath}
      className={`${size} shrink-0 rounded-std object-cover`}
      fallback={
        <span className={`${size} grid shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant`} aria-hidden="true">
          <Icon name="cook" size={18} />
        </span>
      }
    />
  );
}

// ---------------------------------------------------------------------------
// Recipe picker (the app's showRecipePickerSheet): search over the account's
// recipes. `multi` toggles membership in place (a book), otherwise one tap
// picks and closes (a meal).

const PICKER_PAGE = 40;

export function RecipePicker({
  title,
  recipes,
  selectedIds,
  multi = false,
  onPick,
  onToggle,
  onClose,
  failed = false,
}: {
  title: string;
  recipes: Recipe[] | null;
  /** The recipes could not be loaded: says so instead of spinning forever. */
  failed?: boolean;
  selectedIds?: Set<string>;
  multi?: boolean;
  onPick?: (recipe: Recipe) => Promise<void> | void;
  onToggle?: (recipe: Recipe, selected: boolean) => Promise<void>;
  onClose: () => void;
}) {
  const { t } = useI18n();
  const phone = useIsPhone();
  const [query, setQuery] = useState("");
  const [pending, setPending] = useState<Set<string>>(() => new Set());
  const [error, setError] = useState<string | null>(null);
  const searchId = useId();
  // Rows are added a page at a time as the end comes into view: a library of
  // hundreds would otherwise mount every card (and fetch every photo URL) at once.
  const [limit, setLimit] = useState(PICKER_PAGE);
  const sentinel = useRef<HTMLDivElement>(null);
  useEffect(() => setLimit(PICKER_PAGE), [query]);
  const shown = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!recipes) return null;
    return q ? recipes.filter((r) => r.title.toLowerCase().includes(q) || r.ingredients.some((i) => i.name.toLowerCase().includes(q))) : recipes;
  }, [recipes, query]);

  const total = shown?.length ?? 0;
  useEffect(() => {
    const el = sentinel.current;
    if (!el || limit >= total) return;
    const io = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) setLimit((n) => n + PICKER_PAGE);
    }, { rootMargin: "400px" });
    io.observe(el);
    return () => io.disconnect();
  }, [limit, total]);

  const choose = async (r: Recipe) => {
    if (pending.has(r.id)) return;
    setError(null);
    setPending((s) => new Set(s).add(r.id));
    try {
      if (multi) await onToggle?.(r, !(selectedIds?.has(r.id) ?? false));
      else {
        await onPick?.(r);
        onClose();
        return;
      }
    } catch (e) {
      setError(t(saveErrorKey(e)));
    }
    setPending((s) => {
      const n = new Set(s);
      n.delete(r.id);
      return n;
    });
  };

  return (
    <Modal
      title={title}
      onClose={onClose}
      wide
      footer={
        multi && !phone ? (
          <button type="button" className="clay-btn-primary" onClick={onClose}>
            {t("library.ui.done")}
          </button>
        ) : undefined
      }
    >
      {phone ? (
        // The app's ClayInset search pill: recessed stadium, 56 tall.
        <div className="sticky top-0 z-10 bg-surface-lowest pb-4">
          {multi ? (
            <div className="-mt-2 mb-2 flex justify-end">
              <button type="button" onClick={onClose} className="press min-h-10 rounded-full px-3 text-label-md text-primary">
                {t("library.ui.done")}
              </button>
            </div>
          ) : null}
          <label className="flex h-14 items-center gap-3 rounded-full border border-surface-highest px-4" style={{ background: "linear-gradient(to bottom, rgb(var(--c-surface-container-highest)), rgb(var(--c-surface-container-low)) 45%)" }}>
            <Icon name="search" size={24} className="shrink-0 text-outline" />
            <span className="sr-only">{t("library.ui.search")}</span>
            <input type="search" className="min-w-0 flex-1 bg-transparent text-body-md outline-none placeholder:text-outline" placeholder={t("library.ui.search")} value={query} onChange={(e) => setQuery(e.target.value)} />
          </label>
        </div>
      ) : (
      <div className="sticky top-0 z-10 bg-surface-lowest pb-3">
        <label htmlFor={searchId} className="sr-only">
          {t("library.ui.search")}
        </label>
        <div className="relative">
          <span className="pointer-events-none absolute inset-y-0 start-3 grid place-items-center text-on-surface-variant" aria-hidden="true">
            <Icon name="search" size={18} />
          </span>
          <input id={searchId} type="search" className="clay-input ps-10" placeholder={t("library.ui.search")} value={query} onChange={(e) => setQuery(e.target.value)} data-autofocus />
        </div>
      </div>
      )}
      {error ? (
        <div className="mb-3">
          <Notice kind="error">{error}</Notice>
        </div>
      ) : null}
      {shown === null ? (
        failed ? <Notice kind="error">{t("library.ui.loadFailed")}</Notice> : <LoadingState />
      ) : recipes && recipes.length === 0 ? (
        <p className="py-6 text-center text-on-surface-variant">{t("library.ui.noRecipes")}</p>
      ) : shown.length === 0 ? (
        <p className="py-6 text-center text-on-surface-variant">{t("library.ui.noMatches")}</p>
      ) : (
        <>
        <ul className={phone ? "space-y-2" : "grid gap-2 sm:grid-cols-2"}>
          {shown.slice(0, limit).map((r) => {
            const selected = selectedIds?.has(r.id) ?? false;
            const busy = pending.has(r.id);
            // The app's picker row: ClayCard r16 p16, the title, a 28 px add/check disc.
            if (phone)
              return (
                <li key={r.id}>
                  <button type="button" onClick={() => choose(r)} disabled={busy} aria-pressed={multi ? selected : undefined} className="clay-card press flex w-full items-center gap-3 p-4 text-start" style={{ borderRadius: 16 }}>
                    <span className="min-w-0 flex-1 truncate text-body-md">{r.title || t("library.ui.untitled")}</span>
                    {busy ? (
                      <Spinner small />
                    ) : (
                      <span className={`grid h-7 w-7 shrink-0 place-items-center rounded-full border-2 transition-colors duration-[180ms] ${selected ? "border-secondary-container bg-secondary-container text-on-secondary-container" : "border-outline-variant bg-surface-low text-primary"}`} aria-hidden="true">
                        <Icon name={selected ? "check" : "add"} size={18} />
                      </span>
                    )}
                  </button>
                </li>
              );
            return (
              <li key={r.id}>
                <button
                  type="button"
                  onClick={() => choose(r)}
                  disabled={busy}
                  aria-pressed={multi ? selected : undefined}
                  className={`flex w-full items-center gap-3 rounded-md border p-2 text-start transition-colors ${selected ? "border-primary bg-primary-fixed" : "border-outline-variant bg-surface-low hover:bg-surface-container"}`}
                >
                  <RecipeThumb recipe={r} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-body-md font-bold">{r.title || t("library.ui.untitled")}</span>
                    {r.nutrition ? <span className="block text-label-sm text-on-surface-variant">{t("library.ui.kcalServing", { n: r.nutrition.calories })}</span> : null}
                  </span>
                  {busy ? <Spinner small /> : multi ? (
                    <span className={`grid h-7 w-7 shrink-0 place-items-center rounded-full ${selected ? "bg-primary text-on-primary" : "border border-outline-variant text-transparent"}`} aria-hidden="true">
                      <Icon name="check" size={16} />
                    </span>
                  ) : null}
                </button>
              </li>
            );
          })}
        </ul>
        <div ref={sentinel} aria-hidden="true" className="h-2" />
        </>
      )}
    </Modal>
  );
}

// ---------------------------------------------------------------------------
// States

export function LoadingState() {
  const { t } = useI18n();
  const phone = useIsPhone();
  if (phone) return <LoadingSpinner label={t("common.loading")} />;
  return (
    <div className="py-12 text-center">
      <Spinner label={t("common.loading")} />
    </div>
  );
}

export function ErrorState({ message }: { message?: string }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  // The app's ErrorRetryView: a centred card, the error medallion, "try again".
  if (phone)
    return (
      <div className="clay-card m-6 flex flex-col items-center p-6 text-center" style={{ borderRadius: 24 }}>
        <span className="grid h-16 w-16 place-items-center rounded-full bg-error-container text-on-error-container" aria-hidden="true">
          <Icon name="error_outline" size={32} />
        </span>
        <h2 className="mt-4 text-headline-md">{t("library.ui.errorTitle")}</h2>
        <p className="mt-2 text-label-md text-on-surface-variant">{message ?? t("library.ui.loadFailed")}</p>
        <ClayButton icon="refresh" className="mt-4" onClick={() => location.reload()}>
          {t("common.retry")}
        </ClayButton>
      </div>
    );
  return (
    <div className="mx-auto max-w-md space-y-3 py-8 text-center">
      <Notice kind="error">{message ?? t("library.ui.loadFailed")}</Notice>
      <button type="button" className="clay-btn-secondary" onClick={() => location.reload()}>
        <Icon name="refresh" size={18} />
        {t("common.retry")}
      </button>
    </div>
  );
}

export function EmptyState({ icon, message, action, phoneIcon }: { icon: string; message: string; action?: ReactNode; /** The Material icon of the phone's ClayEmptyState. */ phoneIcon?: string }) {
  const phone = useIsPhone();
  if (phone) return <ClayEmptyState icon={phoneIcon ?? icon} message={message} action={action} />;
  return (
    <div className="clay mx-auto mt-6 max-w-lg space-y-4 p-8 text-center">
      <span className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
        <Icon name={icon} size={28} />
      </span>
      <p className="text-body-lg text-on-surface-variant">{message}</p>
      {action}
    </div>
  );
}

/** The shared-copy tag (owner / editor / view only), like the app's ClayTag. */
export function RoleTag({ role }: { role: "owner" | "editor" | "viewer" | null }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  const label = role === "owner" ? t("library.ui.roleOwner") : role === "editor" ? t("library.ui.roleEditor") : t("library.ui.roleViewer");
  if (phone)
    return (
      <ClayTag icon="group" className="bg-secondary-container text-on-secondary-container">
        {label}
      </ClayTag>
    );
  return (
    <span className="pill-mint inline-flex items-center gap-1">
      <Icon name="users" size={14} />
      {label}
    </span>
  );
}

/** A transient status line, announced politely. */
export function useToast(): [ReactNode, (message: string, kind?: "success" | "error") => void] {
  // Below lg the app's notice (AppDialog.notify, dropping from the top).
  const phone = useIsPhone();
  const app = useAppToast();
  const [msg, setMsg] = useState<{ text: string; kind: "success" | "error"; n: number } | null>(null);
  useEffect(() => {
    if (!msg) return;
    const h = setTimeout(() => setMsg(null), 4000);
    return () => clearTimeout(h);
  }, [msg]);
  const node = (
    <div aria-live="polite" className="pointer-events-none fixed inset-x-0 bottom-28 z-40 flex justify-center px-4 lg:bottom-8">
      {msg ? (
        <div key={msg.n} className={`pointer-events-auto animate-rise rounded-full px-5 py-3 text-body-md shadow-card ${msg.kind === "error" ? "bg-error-container text-on-error-container" : "bg-secondary-fixed text-on-secondary-fixed"}`}>
          {msg.text}
        </div>
      ) : null}
    </div>
  );
  if (phone) return [null, (text, kind = "success") => app.show(text, kind)];
  return [node, (text, kind = "success") => setMsg({ text, kind, n: Date.now() })];
}
