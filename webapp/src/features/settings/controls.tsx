// Small form controls for the settings screens, in the clay look: a switch
// row (the app's SettingsToggle), a single choice row of pills (language,
// look, shopping day) and a multi choice row of chips (dietary, reminders).
import type { ReactNode } from "react";
import { Icon } from "../../components/icons";

export function Section({ id, title, hint, icon, children, className = "" }: { id: string; title: string; hint?: string; icon: string; children: ReactNode; className?: string }) {
  return (
    <section id={id} aria-labelledby={`${id}-h`} className={`clay scroll-mt-24 p-5 animate-rise ${className}`}>
      <header className="mb-4 flex items-start gap-3">
        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
          <Icon name={icon} size={20} />
        </span>
        <div className="min-w-0">
          <h2 id={`${id}-h`} className="text-body-lg font-bold">
            {title}
          </h2>
          {hint ? <p className="text-label-md text-on-surface-variant">{hint}</p> : null}
        </div>
      </header>
      <div className="space-y-4">{children}</div>
    </section>
  );
}

export function GroupLabel({ children }: { children: ReactNode }) {
  return <h3 className="pt-2 text-label-sm uppercase text-on-surface-variant">{children}</h3>;
}

export function Toggle({ id, label, hint, checked, onChange, disabled = false, busy = false }: { id: string; label: string; hint?: string; checked: boolean; onChange: (v: boolean) => void; disabled?: boolean; busy?: boolean }) {
  const off = disabled || busy;
  return (
    <div className={`flex items-start gap-4 ${disabled ? "opacity-55" : ""}`}>
      <div className="min-w-0 flex-1">
        <label htmlFor={id} className="block text-body-md font-bold">
          {label}
        </label>
        {hint ? (
          <p id={`${id}-hint`} className="mt-0.5 text-label-md text-on-surface-variant">
            {hint}
          </p>
        ) : null}
      </div>
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        aria-describedby={hint ? `${id}-hint` : undefined}
        aria-busy={busy || undefined}
        disabled={off}
        onClick={() => onChange(!checked)}
        className={`relative mt-0.5 inline-flex h-7 w-12 shrink-0 items-center rounded-full shadow-control transition-colors duration-200 disabled:cursor-not-allowed ${checked ? "bg-primary" : "bg-surface-high"}`}
      >
        <span
          aria-hidden="true"
          className={`absolute top-1 h-5 w-5 rounded-full bg-surface-lowest shadow-button transition-[inset-inline-start] duration-200 ${checked ? "start-6" : "start-1"}`}
        />
      </button>
    </div>
  );
}

/** One of several, as a radio group drawn as pills. */
export function Choice<T extends string>({ name, label, options, value, onChange, disabled = false }: { name: string; label: string; options: { value: T; label: string; icon?: string }[]; value: T | null; onChange: (v: T) => void; disabled?: boolean }) {
  return (
    <fieldset disabled={disabled} className="min-w-0">
      <legend className="mb-2 text-label-md text-on-surface-variant">{label}</legend>
      <div className="flex flex-wrap gap-2">
        {options.map((o) => {
          const on = o.value === value;
          return (
            <label
              key={o.value}
              className={`inline-flex min-h-[40px] cursor-pointer items-center gap-2 rounded-full px-4 text-label-md shadow-control transition-colors focus-within:outline focus-within:outline-2 focus-within:outline-primary ${on ? "bg-primary text-on-primary" : "bg-surface-low text-on-surface hover:bg-surface-high"}`}
            >
              <input type="radio" name={name} value={o.value} checked={on} onChange={() => onChange(o.value)} className="sr-only" />
              {o.icon ? <Icon name={o.icon} size={16} aria-hidden="true" /> : null}
              {o.label}
            </label>
          );
        })}
      </div>
    </fieldset>
  );
}

/** Any of several, as checkboxes drawn as chips. */
export function Chips<T extends string>({ label, options, values, onToggle, disabled = false, hint }: { label: string; options: { value: T; label: string }[]; values: T[]; onToggle: (v: T) => void; disabled?: boolean; hint?: string }) {
  return (
    <fieldset disabled={disabled} className="min-w-0">
      <legend className="mb-2 text-label-md text-on-surface-variant">{label}</legend>
      {hint ? <p className="mb-2 text-label-md text-on-surface-variant">{hint}</p> : null}
      <div className="flex flex-wrap gap-2">
        {options.map((o) => {
          const on = values.includes(o.value);
          return (
            <label
              key={o.value}
              className={`inline-flex min-h-[40px] cursor-pointer items-center gap-1.5 rounded-full px-4 text-label-md shadow-control transition-colors focus-within:outline focus-within:outline-2 focus-within:outline-primary ${on ? "bg-secondary-fixed text-on-secondary-fixed" : "bg-surface-low text-on-surface hover:bg-surface-high"}`}
            >
              <input type="checkbox" checked={on} onChange={() => onToggle(o.value)} className="sr-only" />
              {on ? <Icon name="check" size={14} aria-hidden="true" /> : null}
              {o.label}
            </label>
          );
        })}
      </div>
    </fieldset>
  );
}
