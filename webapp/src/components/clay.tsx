// The app's clay controls, drawn to the native numbers (docs/web/mobile-native-spec.md §2).
// They look the same at every width; a page uses them where the phone layout
// needs them (below `lg`) and keeps its desktop markup above it. Every one is
// a real button/link with a label, keyboard reachable, and presses down on
// pointer-down (the `.press*` classes in styles/native.css).
import { useLayoutEffect, useRef, useState, type ButtonHTMLAttributes, type CSSProperties, type KeyboardEvent, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { Icon } from "./icons";
import { Spinner } from "./ui";

const cx = (...c: (string | false | null | undefined)[]) => c.filter(Boolean).join(" ");

// ── ClayButton (2.3) ────────────────────────────────────────────────────
// The one filled button: stadium, 4 px slab, labelMd w600. Below lg the
// `.clay-btn-primary` / `.clay-btn-danger` classes take the native slab,
// press and disabled face; above lg they keep the desktop look.
export function ClayButton({
  icon,
  expanded = false,
  destructive = false,
  busy = false,
  className = "",
  children,
  type = "button",
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { icon?: string; expanded?: boolean; destructive?: boolean; busy?: boolean }) {
  return (
    <button {...rest} type={type} className={cx(destructive ? "clay-btn-danger" : "clay-btn-primary", expanded && "w-full", className)} aria-busy={busy || undefined} disabled={rest.disabled || busy}>
      {busy ? <Spinner small /> : icon ? <Icon name={icon} size={20} /> : null}
      {children}
    </button>
  );
}

// ── ClayIconButton (1.6) ────────────────────────────────────────────────
// Round, 40 by default (48 in headers), icon 0.55×. Ghost = lavender low
// fill + rim; filled = the one lead action in primary. Press .92.
// Disabled: a ghost button's icon turns outlineVariant; a filled one takes
// the grey outlineVariant face (no glow) by default. `keepFillWhenDisabled`
// opts a filled button into the native behaviour (clay_icon_button.dart
// never greys a filled button): primary fill, white icon and glow stay, it
// just stops pressing and taking clicks — use it for send buttons, so an
// empty composer keeps its purple send. Phone and desktop alike.
export function ClayIconButton({
  icon,
  label,
  size = 40,
  filled = false,
  to,
  onClick,
  disabled = false,
  badge,
  className = "",
  iconClassName = "",
  keepFillWhenDisabled = false,
  ...rest
}: {
  icon: string;
  /** Accessible name (also the tooltip). */
  label: string;
  size?: number;
  filled?: boolean;
  to?: string;
  onClick?: (e: React.MouseEvent<HTMLElement>) => void;
  disabled?: boolean;
  badge?: number;
  className?: string;
  iconClassName?: string;
  /** Filled only, opt-in: keep the primary fill/glow while disabled (native send buttons) instead of the grey face. */
  keepFillWhenDisabled?: boolean;
} & Omit<ButtonHTMLAttributes<HTMLButtonElement>, "onClick">) {
  const cls = cx(
    "press-icon relative inline-grid shrink-0 place-items-center rounded-full",
    filled ? "bg-primary text-on-primary shadow-button" : "border border-surface-highest bg-surface-low text-primary shadow-control disabled:text-outline-variant",
    filled && disabled && !keepFillWhenDisabled && "!bg-outline-variant !shadow-none",
    className,
  );
  const style: CSSProperties = { width: size, height: size };
  const inner = (
    <>
      <Icon name={icon} size={Math.round(size * 0.55)} className={iconClassName} />
      {badge ? <CountBadge count={badge} className="absolute -top-1.5 -end-2" /> : null}
    </>
  );
  if (to && !disabled) {
    return (
      <Link to={to} onClick={onClick} aria-label={label} title={label} className={cls} style={style}>
        {inner}
      </Link>
    );
  }
  return (
    <button type="button" {...rest} onClick={onClick} disabled={disabled} aria-label={label} title={label} className={cls} style={style}>
      {inner}
    </button>
  );
}

// ── CountBadge ──────────────────────────────────────────────────────────
// min 18×18, radius 9, error fill, 2 px ring, 10 px w700, 99+ cap, LTR.
// Only the number is LTR (so "99+" never reads "+99"): the box keeps the
// page's direction, so `-end-2` pins it to the top trailing corner — the
// left in RTL, as BadgedBox's PositionedDirectional(end:) does natively.
// A dir="ltr" on the box itself would resolve `end` to the right.
export function CountBadge({ count, className = "", ring = "ring-surface-lowest" }: { count: number; className?: string; ring?: string }) {
  if (!count || count <= 0) return null;
  return (
    <span aria-hidden="true" className={cx("pointer-events-none grid h-[18px] min-w-[18px] place-items-center rounded-[9px] bg-error px-[5px] py-px text-[10px] font-bold leading-[1.2] text-on-error ring-2", ring, className)}>
      <bdi dir="ltr">{count > 99 ? "99+" : count}</bdi>
    </span>
  );
}

// ── ClayCard (2.4) ──────────────────────────────────────────────────────
// White, 0.5 px rim, card shadow, the top-left bevel. Radius 16 by default
// (most screens pass 24), padding 16. `spine` draws the 8 px start strip
// (meal and grocery cards). `onClick`/`to` make it a pressable (.98).
export function ClayCard({
  radius = 16,
  padding = 16,
  spine,
  active = false,
  onClick,
  to,
  as: Tag = "div",
  className = "",
  style,
  children,
  ...rest
}: {
  radius?: 8 | 16 | 24 | 32 | 48;
  padding?: number;
  /** true = primaryFixed; or any CSS colour. */
  spine?: boolean | string;
  active?: boolean;
  onClick?: () => void;
  to?: string;
  as?: "div" | "section" | "article" | "li";
  className?: string;
  style?: CSSProperties;
  children: ReactNode;
} & Record<string, unknown>) {
  const spineColor = spine === true ? "rgb(var(--c-primary-fixed) / .7)" : typeof spine === "string" ? spine : null;
  const cls = cx("clay-card", active && "is-active", spineColor && "has-spine", (onClick || to) && "press block w-full text-start", className);
  const st: CSSProperties = {
    borderRadius: radius,
    padding,
    ...(spineColor ? { paddingInlineStart: padding + 16, ["--spine" as string]: spineColor } : null),
    ...style,
  };
  if (to) {
    return (
      <Link to={to} className={cls} style={st} {...rest}>
        {children}
      </Link>
    );
  }
  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={cls} style={st} {...rest}>
        {children}
      </button>
    );
  }
  return (
    <Tag className={cls} style={st} {...rest}>
      {children}
    </Tag>
  );
}

// ── ClayTag (2.5) ───────────────────────────────────────────────────────
export function ClayTag({ icon, children, className = "bg-primary-fixed text-primary" }: { icon?: string; children: ReactNode; className?: string }) {
  return (
    <span className={cx("inline-flex max-w-full items-center gap-1 rounded-full px-2 py-1 text-label-sm", className)}>
      {icon ? <Icon name={icon} size={14} /> : null}
      <span className="truncate">{children}</span>
    </span>
  );
}

// ── Chip (2.5) ──────────────────────────────────────────────────────────
// filter: off = low fill + outlineVariant rim + tertiary ink, on = `onClass`
//   (the dietary tag colours); choice: on = primary; plan: on = primaryFixed
//   with a primary rim. Stadium, padding 8/12, icon 16 + 4, labelMd, 180 ms.
export function Chip({
  selected,
  onClick,
  icon,
  kind = "choice",
  onClass,
  size = "md",
  disabled = false,
  className = "",
  children,
}: {
  selected: boolean;
  onClick?: () => void;
  icon?: string;
  kind?: "filter" | "choice" | "plan";
  /** Classes for the selected state of a filter chip, e.g. "bg-error-container border-error-container text-on-error-container". */
  onClass?: string;
  /** "lg" = the ingestion channel chips (10/14, icon 18, gap 6). */
  size?: "md" | "lg";
  disabled?: boolean;
  className?: string;
  children: ReactNode;
}) {
  const on =
    kind === "choice"
      ? "bg-primary border-primary text-on-primary"
      : kind === "plan"
        ? "bg-primary-fixed border-primary text-primary"
        : onClass ?? "bg-primary-fixed border-primary-fixed text-primary";
  const off = "bg-surface-low border-outline-variant text-tertiary";
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-pressed={selected}
      className={cx(
        "press inline-flex items-center rounded-full border text-label-md transition-colors duration-[180ms] ease-[cubic-bezier(.23,1,.32,1)] disabled:opacity-50",
        size === "lg" ? "gap-1.5 px-[14px] py-[10px]" : "gap-1 px-3 py-2",
        selected ? on : off,
        className,
      )}
    >
      {icon ? <Icon name={icon} size={size === "lg" ? 18 : 16} /> : null}
      {children}
    </button>
  );
}

// ── Switch (2.8) ────────────────────────────────────────────────────────
// Material 3, 52×32. On: mint track, teal 24 px thumb. Off: lavender track
// with a 2 px outline rim and a 16 px white thumb.
export function Switch({
  checked,
  onChange,
  label,
  labelledBy,
  disabled = false,
  id,
}: {
  checked: boolean;
  onChange: (next: boolean) => void;
  label?: string;
  labelledBy?: string;
  disabled?: boolean;
  id?: string;
}) {
  return (
    <button
      id={id}
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      aria-labelledby={labelledBy}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={cx(
        "relative inline-block h-8 w-[52px] shrink-0 rounded-full border-2 transition-colors duration-[180ms] disabled:opacity-40",
        checked ? "border-secondary-container bg-secondary-container" : "border-outline bg-surface-highest",
      )}
    >
      <span
        aria-hidden="true"
        className={cx(
          "absolute top-1/2 rounded-full transition-all duration-[240ms] ease-[cubic-bezier(.23,1,.32,1)]",
          checked ? "h-6 w-6 bg-on-secondary-container" : "h-4 w-4 bg-surface-lowest",
        )}
        style={{ insetInlineStart: checked ? 22 : 6, transform: "translateY(-50%)" }}
      />
    </button>
  );
}

// ── Round checkbox (2.9, BouncyCheckbox) ────────────────────────────────
export function RoundCheckbox({ checked, onChange, label, disabled = false }: { checked: boolean; onChange: (next: boolean) => void; label: string; disabled?: boolean }) {
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => {
        if (!checked) navigator.vibrate?.(8);
        onChange(!checked);
      }}
      className="relative grid h-6 w-6 shrink-0 place-items-center after:absolute after:-inset-2 after:content-[''] disabled:opacity-50"
    >
      <span
        key={checked ? "on" : "off"}
        aria-hidden="true"
        className={cx(
          "grid h-6 w-6 place-items-center rounded-full border-2 transition-colors duration-[180ms]",
          checked ? "check-pop border-secondary-container bg-secondary-container text-on-secondary-container" : "border-outline-variant bg-surface-lowest",
        )}
      >
        {checked ? <Icon name="check" size={16} /> : null}
      </span>
    </button>
  );
}

// ── Segmented control (2.6) ─────────────────────────────────────────────
// Recessed track, white sliding pill; only the selected segment shows its
// label (on the reading-start side of the icon), unfolding over 500 ms with
// the pill and the widths. Arrow keys move the selection.
export interface Segment<V extends string> {
  value: V;
  label: string;
  icon: string;
  badge?: number;
}

const ICON = 18;
const HPAD = 12;

export function SegmentedControl<V extends string>({
  segments,
  value,
  onChange,
  label,
  className = "",
}: {
  segments: Segment<V>[];
  value: V;
  onChange: (v: V) => void;
  /** Accessible name of the group. */
  label: string;
  className?: string;
}) {
  const track = useRef<HTMLDivElement>(null);
  const measure = useRef<HTMLSpanElement>(null);
  const [avail, setAvail] = useState(0);
  const [labelW, setLabelW] = useState(0);
  const n = segments.length;
  const sel = Math.max(0, segments.findIndex((s) => s.value === value));
  const selLabel = segments[sel]?.label ?? "";

  useLayoutEffect(() => {
    const el = track.current;
    if (!el) return;
    const apply = () => setAvail(el.clientWidth - 8); // padding 4 each side
    apply();
    const ro = new ResizeObserver(apply);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  useLayoutEffect(() => {
    setLabelW(measure.current?.getBoundingClientRect().width ?? 0);
  }, [selLabel]);

  // ClaySegmentedControl.widthsFor
  const iconOnly = ICON + 2 * HPAD;
  const wanted = ICON + 4 + labelW + 2 * HPAD + 2;
  const cap = avail - (n - 1) * iconOnly;
  const upper = cap > 0 ? cap : avail;
  const lower = Math.min(avail / n, upper);
  const chosen = Math.min(Math.max(wanted, lower), upper);
  const rest = n > 1 ? (avail - chosen) / (n - 1) : avail;
  const widths = segments.map((_, i) => (i === sel ? chosen : rest));
  const start = widths.slice(0, sel).reduce((a, b) => a + b, 0);
  const ready = avail > 0;

  const onKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const rtl = getComputedStyle(e.currentTarget).direction === "rtl";
    let next = sel;
    if (e.key === "ArrowRight") next = sel + (rtl ? -1 : 1);
    else if (e.key === "ArrowLeft") next = sel + (rtl ? 1 : -1);
    else if (e.key === "Home") next = 0;
    else if (e.key === "End") next = n - 1;
    else return;
    e.preventDefault();
    next = (next + n) % n;
    onChange(segments[next].value);
    (e.currentTarget.querySelectorAll<HTMLButtonElement>('[role="radio"]')[next])?.focus();
  };

  const transition = "500ms cubic-bezier(.23,1,.32,1)";
  return (
    <div
      ref={track}
      role="radiogroup"
      aria-label={label}
      onKeyDown={onKey}
      className={cx("relative flex rounded-full border border-surface-highest bg-surface-container p-1", className)}
    >
      <span ref={measure} aria-hidden="true" className="invisible absolute whitespace-nowrap text-label-md">
        {selLabel}
      </span>
      {ready ? (
        <span
          aria-hidden="true"
          className="absolute bottom-1 top-1 rounded-full bg-surface-lowest shadow-control"
          style={{ insetInlineStart: 4 + start, width: chosen, transition: `inset-inline-start ${transition}, width ${transition}` }}
        />
      ) : null}
      {segments.map((s, i) => {
        const on = i === sel;
        return (
          <button
            key={s.value}
            type="button"
            role="radio"
            aria-checked={on}
            aria-label={s.label}
            title={on ? undefined : s.label}
            tabIndex={on ? 0 : -1}
            onClick={() => onChange(s.value)}
            className={cx("relative z-[1] flex h-12 min-w-0 items-center justify-center overflow-hidden px-3", on ? "text-primary" : "text-on-surface-variant", !ready && "flex-1")}
            style={ready ? { width: widths[i], transition: `width ${transition}` } : undefined}
          >
            <span
              aria-hidden="true"
              className="overflow-hidden whitespace-nowrap text-label-md"
              style={{ maxWidth: on ? labelW + 4 + 1 : 0, opacity: on ? 1 : 0, transition: `max-width ${transition}, opacity ${transition}` }}
            >
              <span className="block pe-1">{s.label}</span>
            </span>
            <span className="relative grid shrink-0 place-items-center" aria-hidden="true">
              <Icon name={s.icon} size={ICON} />
              {s.badge ? <CountBadge count={s.badge} className="absolute -top-[7px] -end-[9px]" ring={on ? "ring-surface-lowest" : "ring-surface-container"} /> : null}
            </span>
          </button>
        );
      })}
    </div>
  );
}

// ── Page header (2.11, ClayPageHeader) ──────────────────────────────────
// For pages without a floating header: headlineLgMobile title, 8 → bodyMd subtitle.
export function PageHeader({ title, subtitle, trailing, className = "" }: { title: string; subtitle?: string; trailing?: ReactNode; className?: string }) {
  return (
    <header className={cx("flex items-start gap-3", className)}>
      <div className="min-w-0 flex-1">
        <h1 className="text-headline-lg-mobile text-on-surface">{title}</h1>
        {subtitle ? <p className="mt-2 text-body-md text-on-surface-variant">{subtitle}</p> : null}
      </div>
      {trailing ? <div className="mt-1 flex shrink-0 items-center gap-2">{trailing}</div> : null}
    </header>
  );
}

// ── Empty state (2.11, ClayEmptyState) ──────────────────────────────────
export function EmptyState({ icon, message, action }: { icon: string; message: string; action?: ReactNode }) {
  return (
    <div className="flex flex-col items-center p-8 text-center">
      <span className="grid h-24 w-24 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
        <Icon name={icon} size={44} />
      </span>
      <p className="mt-6 text-body-md text-on-surface-variant">{message}</p>
      {action ? <div className="mt-6">{action}</div> : null}
    </div>
  );
}

// ── Progress groove (2.10, ClayProgressBar) ─────────────────────────────
export function ProgressGroove({ value, height = 24, label }: { value: number; height?: number; label?: string }) {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  return (
    <div
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(pct)}
      className="overflow-hidden rounded-full"
      style={{ height, background: "linear-gradient(to bottom, rgb(var(--c-surface-container-highest)), rgb(var(--c-surface-container)) 50%)" }}
    >
      <div
        className="h-full rounded-full ltr:bg-gradient-to-r rtl:bg-gradient-to-l from-primary-container to-primary"
        style={{ width: `${pct}%`, transition: "width 240ms cubic-bezier(.23,1,.32,1)" }}
      />
    </div>
  );
}

/** The native centred loading spinner: 36 px, 4 px stroke, primary. */
export function LoadingSpinner({ label }: { label?: string }) {
  return (
    <span role="status" aria-label={label} className="grid place-items-center py-8">
      <span className="inline-block h-9 w-9 animate-spin rounded-full border-4 border-primary border-t-transparent" aria-hidden="true" />
    </span>
  );
}
