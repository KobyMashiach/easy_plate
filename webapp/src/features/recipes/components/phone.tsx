/* eslint-disable react-refresh/only-export-components */
// Small pieces the recipe screens draw below lg, to the native numbers
// (docs/web/mobile-native-spec.md): the dietary tag colours and icons, the
// recessed search pill (ClayInset), the underlined section header, the
// stat tile and the native topic chips. Desktop never renders these.
import { useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { Icon } from "../../../components/icons";
import { useI18n } from "../../../lib/i18n";
import { DIETARY, type DietaryPreference } from "../../../models/recipe";

/** dietaryIcon (all `_rounded`). */
export const DIET_ICON: Record<DietaryPreference, string> = {
  meat: "set_meal",
  dairy: "egg_alt",
  vegetarian: "eco",
  vegan: "spa",
  kosher: "verified",
  glutenFree: "block",
  allergy: "warning_amber",
};

/** dietaryTagColors (fill / ink), exactly as the app paints them. */
export const PHONE_DIET_TONE: Record<DietaryPreference, string> = {
  meat: "bg-error-container text-on-error-container",
  dairy: "bg-info-container text-on-info-container",
  vegetarian: "bg-secondary-container text-on-secondary-container",
  vegan: "bg-[rgb(var(--c-secondary-fixed-dim))] text-on-secondary-fixed",
  kosher: "bg-tertiary-fixed text-[rgb(var(--c-on-tertiary-fixed-variant))]",
  glutenFree: "bg-primary-fixed text-on-primary-fixed-variant",
  allergy: "bg-surface-highest text-on-surface-variant",
};

/** The selected-state classes of a topic chip: fill and rim in the tag colour. */
const CHIP_ON: Record<DietaryPreference, string> = {
  meat: "bg-error-container border-error-container text-on-error-container",
  dairy: "bg-info-container border-info-container text-on-info-container",
  vegetarian: "bg-secondary-container border-secondary-container text-on-secondary-container",
  vegan: "bg-[rgb(var(--c-secondary-fixed-dim))] border-[rgb(var(--c-secondary-fixed-dim))] text-on-secondary-fixed",
  kosher: "bg-tertiary-fixed border-tertiary-fixed text-[rgb(var(--c-on-tertiary-fixed-variant))]",
  glutenFree: "bg-primary-fixed border-primary-fixed text-on-primary-fixed-variant",
  allergy: "bg-surface-highest border-surface-highest text-on-surface-variant",
};

/** DietaryChipSelector: stadium 8/12, icon 16 + 4 + labelMd; off = low fill, outlineVariant rim, tertiary ink. */
export function PhoneDietaryChips({ selected, onToggle, label }: { selected: DietaryPreference[]; onToggle: (d: DietaryPreference) => void; label: string }) {
  const { t } = useI18n();
  return (
    <div role="group" aria-label={label} className="flex flex-wrap gap-2">
      {DIETARY.map((d) => {
        const on = selected.includes(d);
        return (
          <button
            key={d}
            type="button"
            aria-pressed={on}
            onClick={() => onToggle(d)}
            className={`press inline-flex items-center gap-1 rounded-full border px-3 py-2 text-label-md transition-colors duration-[180ms] ease-[cubic-bezier(.23,1,.32,1)] ${on ? CHIP_ON[d] : "border-outline-variant bg-surface-low text-tertiary"}`}
          >
            <Icon name={DIET_ICON[d]} size={16} />
            {t(`recipes.diet.${d}`)}
          </button>
        );
      })}
    </div>
  );
}

/** ClayTag with a dietary colour and icon (icon 14 + 4, labelSm, padding 4/8). */
export function PhoneTag({ icon, className, children }: { icon?: string; className: string; children: ReactNode }) {
  return (
    <span className={`inline-flex shrink-0 items-center gap-1 whitespace-nowrap rounded-full px-2 py-1 text-label-sm ${className}`}>
      {icon ? <Icon name={icon} size={14} /> : null}
      {children}
    </span>
  );
}

/** ClayInset search pill: recessed gradient, 56 tall, search icon 24 outline. */
export function SearchPill({ id, value, onChange, placeholder }: { id: string; value: string; onChange: (v: string) => void; placeholder: string }) {
  const { t } = useI18n();
  return (
    <div
      className="flex items-center gap-3 rounded-full border border-surface-highest px-4"
      style={{ background: "linear-gradient(to bottom, rgb(var(--c-surface-container-highest)), rgb(var(--c-surface-container-low)) 45%)" }}
    >
      <Icon name="search" size={24} className="shrink-0 text-outline" />
      <label htmlFor={id} className="sr-only">
        {placeholder}
      </label>
      <input
        id={id}
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="min-w-0 flex-1 appearance-none border-0 bg-transparent py-4 text-body-md text-on-surface outline-none placeholder:text-outline [&::-webkit-search-cancel-button]:hidden"
      />
      {value ? (
        <button type="button" onClick={() => onChange("")} aria-label={t("recipes.close")} className="grid h-8 w-8 shrink-0 place-items-center text-outline">
          <Icon name="close" size={20} />
        </button>
      ) : null}
    </div>
  );
}

/** ClaySectionHeader(underline: true): headlineMd, 8 px under it, a 1 px surfaceVariant rule. */
export function SectionHeader({ id, title, trailing }: { id?: string; title: string; trailing?: ReactNode }) {
  return (
    <div className="flex items-end gap-2 border-b border-[rgb(var(--c-surface-variant))] pb-2">
      <h2 id={id} className="min-w-0 flex-1 text-headline-md">
        {title}
      </h2>
      {trailing}
    </div>
  );
}

/** StatTile: white, r16, 1 px rim, padding 12/8; 36 medallion (accent @ 14 %) → 8 → value bodyLg w800 (+ unit) → caption labelSm. */
export function StatTile({ icon, value, unit, caption, accent }: { icon: string; value: string; unit?: string | null; caption: string; accent: string }) {
  return (
    <div className="flex min-w-0 flex-1 flex-col items-center rounded-std border border-surface-highest bg-surface-lowest px-2 py-3 text-center">
      <span className="grid h-9 w-9 place-items-center rounded-full" style={{ background: `rgb(var(${accent}) / .14)`, color: `rgb(var(${accent}))` }} aria-hidden="true">
        <Icon name={icon} size={18} />
      </span>
      <FitText className="mt-2 text-body-lg font-extrabold">
        {value}
        {unit ? <span className="ms-1 text-label-sm text-on-surface-variant">{unit}</span> : null}
      </FitText>
      <FitText className="text-label-sm text-on-surface-variant">{caption}</FitText>
    </div>
  );
}

/** FittedBox(scaleDown) around one line: shrinks to the room it has, never wraps or clips. */
export function FitText({ className = "", children }: { className?: string; children: ReactNode }) {
  const box = useRef<HTMLSpanElement>(null);
  const inner = useRef<HTMLSpanElement>(null);
  const [scale, setScale] = useState(1);
  useLayoutEffect(() => {
    const b = box.current;
    const i = inner.current;
    if (!b || !i) return;
    const apply = () => {
      const room = b.clientWidth;
      const need = i.scrollWidth;
      setScale(need > room && need > 0 ? room / need : 1);
    };
    apply();
    const ro = new ResizeObserver(apply);
    ro.observe(b);
    return () => ro.disconnect();
  }, [children]);
  return (
    <span ref={box} className={`flex w-full justify-center overflow-hidden ${className}`}>
      <span ref={inner} className="shrink-0 whitespace-nowrap" style={scale < 1 ? { transform: `scale(${scale})`, transformOrigin: "center" } : undefined}>
        {children}
      </span>
    </span>
  );
}
