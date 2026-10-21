// The app's DietaryChipSelector and AllergenChipSelector as toggle buttons
// (aria-pressed), plus the read-only tag.
import { ALLERGENS, DIETARY, type Allergen, type DietaryPreference } from "../../../models/recipe";
import { useI18n } from "../../../lib/i18n";
import { DIET_TONE } from "../lib/format";
import { Icon } from "../../../components/icons";
import { useIsPhone } from "../../../components/useIsPhone";

export function DietTag({ tag }: { tag: DietaryPreference }) {
  const { t } = useI18n();
  return <span className={`pill ${DIET_TONE[tag]}`}>{t(`recipes.diet.${tag}`)}</span>;
}

export function DietaryChips({ selected, onToggle, label }: { selected: DietaryPreference[]; onToggle: (d: DietaryPreference) => void; label: string }) {
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
            className={`rounded-full border px-3 py-1.5 text-label-md transition-colors ${on ? `${DIET_TONE[d]} border-transparent` : "border-outline-variant bg-surface-low text-tertiary hover:bg-primary/5"}`}
          >
            {t(`recipes.diet.${d}`)}
          </button>
        );
      })}
    </div>
  );
}

export function AllergenChips({ selected, onToggle, label }: { selected: Allergen[]; onToggle: (a: Allergen) => void; label: string }) {
  const { t } = useI18n();
  return (
    <div role="group" aria-label={label} className="flex flex-wrap gap-2">
      {ALLERGENS.map((a) => {
        const on = selected.includes(a);
        return (
          <button
            key={a}
            type="button"
            aria-pressed={on}
            onClick={() => onToggle(a)}
            className={`rounded-full border px-3 py-1.5 text-label-md transition-colors ${on ? "border-transparent bg-error-container text-on-error-container" : "border-outline-variant bg-surface-low text-tertiary hover:bg-primary/5"}`}
          >
            {t(`recipes.allergen.${a}`)}
          </button>
        );
      })}
    </div>
  );
}

/** "Contains: eggs, sesame" / "May contain: tree nuts" (AllergenNotice). */
export function AllergenNotice({ allergens, mayContain }: { allergens: Allergen[]; mayContain: Allergen[] }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  if (!allergens.length && !mayContain.length) return null;
  if (phone) {
    // AllergenNotice: 12 above, rows 4/4, warning_amber 16 (onErrorContainer) → 4 → labelMd.
    const row = (label: string, items: Allergen[]) => (
      <p className="flex items-start gap-1 py-1 text-label-md text-on-surface-variant">
        <Icon name="warning_amber" size={16} className="mt-0.5 shrink-0 text-on-error-container" />
        <span>
          {label}: {items.map((a) => t(`recipes.allergen.${a}`)).join(", ")}
        </span>
      </p>
    );
    return (
      <div className="pt-3">
        {allergens.length ? row(t("recipes.allergen.contains"), allergens) : null}
        {mayContain.length ? row(t("recipes.allergen.mayContain"), mayContain) : null}
      </div>
    );
  }
  const line = (label: string, items: Allergen[]) => (
    <p className="flex items-start gap-2 text-label-md text-on-surface-variant">
      <span aria-hidden="true" className="text-on-error-container">⚠</span>
      <span>
        {label}: {items.map((a) => t(`recipes.allergen.${a}`)).join(", ")}
      </span>
    </p>
  );
  return (
    <div className="space-y-1">
      {allergens.length ? line(t("recipes.allergen.contains"), allergens) : null}
      {mayContain.length ? line(t("recipes.allergen.mayContain"), mayContain) : null}
    </div>
  );
}
