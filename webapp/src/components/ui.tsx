import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode } from "react";
import { Link } from "react-router-dom";

type Variant = "primary" | "secondary" | "tonal" | "ghost" | "danger";

export function Button({ variant = "primary", className = "", busy = false, children, ...rest }: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; busy?: boolean }) {
  return (
    <button {...rest} className={`clay-btn-${variant} w-full ${className}`} aria-busy={busy || undefined} disabled={rest.disabled || busy}>
      {busy ? <Spinner small /> : null}
      {children}
    </button>
  );
}

export function LinkButton({ to, variant = "primary", className = "", children }: { to: string; variant?: Variant; className?: string; children: ReactNode }) {
  return (
    <Link to={to} className={`clay-btn-${variant} w-full ${className}`}>
      {children}
    </Link>
  );
}

export function Card({ className = "", children, as: Tag = "section", ...rest }: { className?: string; children: ReactNode; as?: "section" | "div" | "article" | "li" } & Record<string, unknown>) {
  return (
    <Tag className={`clay p-5 ${className}`} {...rest}>
      {children}
    </Tag>
  );
}

export function Field({ id, label, hint, error, ...rest }: InputHTMLAttributes<HTMLInputElement> & { id: string; label: string; hint?: string; error?: string | null }) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={id} className="block text-label-md text-on-surface-variant">
        {label}
      </label>
      <input id={id} className="clay-input" aria-invalid={error ? "true" : undefined} aria-describedby={hint || error ? `${id}-desc` : undefined} {...rest} />
      {(hint || error) && (
        <p id={`${id}-desc`} className={`text-label-sm ${error ? "text-error" : "text-on-surface-variant"}`} role={error ? "alert" : undefined}>
          {error || hint}
        </p>
      )}
    </div>
  );
}

export function Spinner({ small = false, label }: { small?: boolean; label?: string }) {
  const size = small ? "h-4 w-4 border-2" : "h-8 w-8 border-[3px]";
  return (
    <span role="status" aria-label={label} className="inline-flex items-center gap-3">
      <span className={`${size} inline-block animate-spin rounded-full border-current border-t-transparent`} aria-hidden="true" />
      {label ? <span className="text-on-surface-variant">{label}</span> : null}
    </span>
  );
}

export function Notice({ kind = "info", children }: { kind?: "info" | "success" | "error" | "warn"; children: ReactNode }) {
  const cls = {
    info: "bg-info-container text-on-info-container",
    success: "bg-secondary-fixed text-on-secondary-fixed",
    error: "bg-error-container text-on-error-container",
    warn: "bg-warm-accent/25 text-on-surface",
  }[kind];
  return (
    <div role={kind === "error" ? "alert" : "status"} className={`rounded-std px-4 py-3 text-body-md ${cls}`}>
      {children}
    </div>
  );
}

export function Pill({ tone = "grey", children }: { tone?: "mint" | "lavender" | "grey" | "amber"; children: ReactNode }) {
  return <span className={`pill-${tone}`}>{children}</span>;
}

export function PageTitle({ title, lead }: { title: string; lead?: string }) {
  return (
    <header className="mb-6 animate-rise">
      <h1 className="text-headline-lg">{title}</h1>
      {lead ? <p className="mt-2 text-body-md text-on-surface-variant">{lead}</p> : null}
    </header>
  );
}

export function Row({ icon, label, hint, onClick, to }: { icon: ReactNode; label: string; hint?: string; onClick?: () => void; to?: string }) {
  const inner = (
    <>
      <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
        {icon}
      </span>
      <span className="min-w-0 flex-1 text-start">
        <span className="block truncate text-body-md font-bold">{label}</span>
        {hint ? <span className="block text-label-sm text-on-surface-variant">{hint}</span> : null}
      </span>
      <span className="text-on-surface-variant rtl:rotate-180" aria-hidden="true">
        ›
      </span>
    </>
  );
  const cls = "clay flex w-full items-center gap-4 p-4 transition-transform active:scale-[.99]";
  return to ? (
    <Link to={to} className={cls}>
      {inner}
    </Link>
  ) : (
    <button type="button" onClick={onClick} className={cls}>
      {inner}
    </button>
  );
}

export const Icons = {
  crown: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 17h18l1-10-5 4-5-7-5 7-5-4z" /><path d="M5 21h14" /></svg>,
  card: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="5" width="20" height="14" rx="3" /><path d="M2 10h20" /></svg>,
  book: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h12a3 3 0 0 1 3 3v13H7a3 3 0 0 0-3 3z" /><path d="M4 4v16" /></svg>,
  send: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 2 11 13" /><path d="M22 2 15 22l-4-9-9-4z" /></svg>,
  phone: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="6" y="2" width="12" height="20" rx="3" /><path d="M11 18h2" /></svg>,
  mail: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="14" rx="3" /><path d="m3 7 9 6 9-6" /></svg>,
  logout: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><path d="m16 17 5-5-5-5" /><path d="M21 12H9" /></svg>,
  check: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m5 12 5 5L20 7" /></svg>,
  sun: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="4" /><path d="M12 2v2m0 16v2M2 12h2m16 0h2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" /></svg>,
  moon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8z" /></svg>,
  auto: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="9" /><path d="M12 3v18" /><path d="M12 3a9 9 0 0 1 0 18" fill="currentColor" /></svg>,
};
