// The review step: the parsed recipe, editable in full before it is saved
// (the app shows the parsed recipe, then its structured editor on "edit").
// Nothing is written until Save; the saved record is recipeToDart's shape.
import { useId, useRef, useState } from "react";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { Notice, Spinner } from "../../components/ui";
import { ClayButton, ClayCard } from "../../components/clay";
import { useIsPhone } from "../../components/useIsPhone";
import { AllergenNotice } from "../recipes/components/Chips";
import { DIET_ICON, PHONE_DIET_TONE, PhoneTag, SectionHeader } from "../recipes/components/phone";
import { ingredientLine } from "../recipes/lib/format";
import { safeHref } from "../recipes/lib/safeHref";
import { ALLERGENS, DIETARY, MEASUREMENT_UNITS, type Allergen, type DietaryPreference, type MeasurementUnit, type Recipe } from "../../models/recipe";

/** Whole numbers only; empty → null. `min` clamps (servings start at 1). */
function intOrNull(v: string, min = 0): number | null {
  const n = Number(v);
  if (v.trim() === "" || !Number.isFinite(n)) return null;
  const i = Math.trunc(n);
  return i < min ? null : i;
}

function numOrNull(v: string): number | null {
  const n = Number(v.replace(",", "."));
  return v.trim() === "" || !Number.isFinite(n) || n < 0 ? null : n;
}

/** Drops empty rows and trims, the way the app's editor saves. */
export function cleanRecipe(r: Recipe): Recipe {
  return {
    ...r,
    title: r.title.trim(),
    ingredients: r.ingredients.map((i) => ({ ...i, name: i.name.trim() })).filter((i) => i.name),
    steps: r.steps.map((s) => s.trim()).filter(Boolean),
    // The app's rule (dietaryTagsFromModel, and the editor's allergen detail
    // living under the "allergy" topic): listed allergens carry the tag.
    dietaryTags: (r.allergens.length || r.mayContain.length) && !r.dietaryTags.includes("allergy") ? [...r.dietaryTags, "allergy"] : r.dietaryTags,
  };
}

export function ReviewEditor({
  initial,
  saving,
  notice,
  onSave,
  onDiscard,
}: {
  initial: Recipe;
  saving: boolean;
  notice: string | null;
  onSave: (r: Recipe) => void;
  onDiscard: () => void;
}) {
  const { t } = useI18n();
  const uid = useId();
  const [r, setR] = useState<Recipe>(initial);
  const [titleError, setTitleError] = useState(false);
  const phone = useIsPhone();
  const [editing, setEditing] = useState(false);
  // Stable row keys, so removing a row never hands its neighbour's inputs over.
  const [ingKeys, setIngKeys] = useState<number[]>(() => initial.ingredients.map((_, i) => i));
  const [stepKeys, setStepKeys] = useState<number[]>(() => initial.steps.map((_, i) => i));
  const nextKey = useRef(10_000);
  const fresh = () => nextKey.current++;
  const set = <K extends keyof Recipe>(k: K, v: Recipe[K]) => setR((cur) => ({ ...cur, [k]: v }));

  const toggle = <T extends string>(list: T[], v: T, order: readonly T[]): T[] =>
    list.includes(v) ? list.filter((x) => x !== v) : order.filter((x) => x === v || list.includes(x));

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (saving) return;
    const cleaned = cleanRecipe(r);
    if (!cleaned.title) {
      setTitleError(true);
      document.getElementById(`${uid}-title`)?.focus();
      return;
    }
    onSave(cleaned);
  };

  const n = r.nutrition;

  // Below lg the app's review: the parsed recipe as it will be saved, then
  // "edit" (the full form below) or "save" — the app's _ReviewRecipe.
  if (phone && !editing) {
    const saveNow = () => {
      if (saving) return;
      const cleaned = cleanRecipe(r);
      if (!cleaned.title) {
        setEditing(true);
        setTitleError(true);
        return;
      }
      onSave(cleaned);
    };
    return (
      <div className="pb-28">
        <PhoneTag icon="fact_check" className="bg-primary-fixed text-primary">
          {t("ingest.review.title")}
        </PhoneTag>
        <h1 className="mt-3 text-headline-lg-mobile">{r.title || t("ingest.untitledRecipe")}</h1>
        {r.dietaryTags.length ? (
          <div className="mt-3 flex flex-wrap gap-2">
            {r.dietaryTags.map((d) => (
              <PhoneTag key={d} icon={DIET_ICON[d]} className={PHONE_DIET_TONE[d]}>
                {t(`ingest.diet.${d}`)}
              </PhoneTag>
            ))}
          </div>
        ) : null}
        <AllergenNotice allergens={r.allergens} mayContain={r.mayContain} />
        {r.pendingAnalysis ? <p className="mt-3 text-label-md text-on-surface-variant">{t("ingest.review.pending")}</p> : null}
        {notice ? (
          <div className="mt-3">
            <Notice kind="error">{notice}</Notice>
          </div>
        ) : null}
        <div className="mt-6 space-y-6">
          <ClayCard radius={24} padding={24} as="section" aria-labelledby={`${uid}-ing`}>
            <SectionHeader id={`${uid}-ing`} title={t("ingest.ingredients")} />
            <ul className="mt-3">
              {r.ingredients.map((ing, i) => (
                <li key={ingKeys[i]} className="flex items-start gap-3 py-1">
                  <span className="mt-[9px] h-1.5 w-1.5 shrink-0 rounded-full bg-primary" aria-hidden="true" />
                  <span className="min-w-0 flex-1 text-body-md">{ingredientLine(t, ing)}</span>
                </li>
              ))}
            </ul>
          </ClayCard>
          <ClayCard radius={24} padding={24} as="section" aria-labelledby={`${uid}-steps`}>
            <SectionHeader id={`${uid}-steps`} title={t("ingest.steps")} />
            <ol className="mt-3">
              {r.steps.map((st, i) => (
                <li key={stepKeys[i]} className="flex items-start gap-3 py-2">
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary" aria-hidden="true">
                    {i + 1}
                  </span>
                  <p className="min-w-0 flex-1 text-body-md">{st}</p>
                </li>
              ))}
            </ol>
          </ClayCard>
        </div>
        <div className="fixed inset-x-0 bottom-0 z-30 flex items-center gap-3 bg-background px-5 pb-[calc(20px+env(safe-area-inset-bottom))] pt-3">
          <ClayButton icon="edit" onClick={() => setEditing(true)} disabled={saving}>
            {t("ingest.review.edit")}
          </ClayButton>
          <ClayButton icon="bookmark_added" expanded className="flex-1" busy={saving} onClick={saveNow}>
            {saving ? t("ingest.saving") : t("ingest.save")}
          </ClayButton>
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="mx-auto w-full max-w-6xl space-y-5" noValidate>
      <header className="space-y-1">
        <h2 className="text-headline-md">{t("ingest.review.title")}</h2>
        <p className="text-body-md text-on-surface-variant">{t("ingest.review.lead")}</p>
        {r.pendingAnalysis ? <span className="pill-amber">{t("ingest.review.pending")}</span> : null}
      </header>

      {notice ? <Notice kind="error">{notice}</Notice> : null}

      <section className="clay space-y-4 p-5">
        <div className="space-y-1.5">
          <label htmlFor={`${uid}-title`} className="block text-label-md text-on-surface-variant">{t("ingest.field.title")}</label>
          <input
            id={`${uid}-title`}
            className="clay-input"
            value={r.title}
            onChange={(e) => {
              set("title", e.target.value);
              if (titleError) setTitleError(false);
            }}
            aria-invalid={titleError || undefined}
            aria-describedby={titleError ? `${uid}-title-err` : undefined}
            required
          />
          {titleError ? <p id={`${uid}-title-err`} role="alert" className="text-label-sm text-error">{t("ingest.titleRequired")}</p> : null}
        </div>
        <div className="grid gap-4 sm:grid-cols-3">
          <NumberField id={`${uid}-servings`} label={t("ingest.field.servings")} value={r.servings} min={1} onChange={(v) => set("servings", intOrNull(v, 1))} />
          <NumberField id={`${uid}-prep`} label={t("ingest.field.prep")} value={r.prepTimeMinutes} min={0} onChange={(v) => set("prepTimeMinutes", intOrNull(v))} />
          <NumberField id={`${uid}-cook`} label={t("ingest.field.cook")} value={r.cookTimeMinutes} min={0} onChange={(v) => set("cookTimeMinutes", intOrNull(v))} />
        </div>
        {n ? (
          <p className="text-label-sm text-on-surface-variant">
            {t("ingest.nutrition", { cal: n.calories, p: Math.round(n.proteinGrams), c: Math.round(n.carbsGrams), f: Math.round(n.fatGrams) })}
          </p>
        ) : null}
        {safeHref(r.sourceUrl) ? (
          <p className="truncate text-label-sm text-on-surface-variant">
            {t("ingest.source")}:{" "}
            <a href={safeHref(r.sourceUrl)!} target="_blank" rel="noopener noreferrer" className="text-primary underline" dir="ltr">{r.sourceUrl}</a>
          </p>
        ) : null}
      </section>

      <section className="clay space-y-3 p-5" aria-labelledby={`${uid}-ing`}>
        <h3 id={`${uid}-ing`} className="text-body-lg font-bold">{t("ingest.ingredients")}</h3>
        <ul className="space-y-3">
          {r.ingredients.map((ing, i) => (
            <li key={ingKeys[i]} className="grid grid-cols-[1fr_auto] gap-2 sm:grid-cols-[1fr_7rem_9rem_auto] sm:items-end">
              <div className="col-span-2 space-y-1 sm:col-span-1">
                <label htmlFor={`${uid}-in-${i}`} className="block text-label-sm text-on-surface-variant">{t("ingest.ingredient.name", { n: i + 1 })}</label>
                <input id={`${uid}-in-${i}`} className="clay-input" value={ing.name} onChange={(e) => set("ingredients", r.ingredients.map((x, j) => (j === i ? { ...x, name: e.target.value } : x)))} />
              </div>
              <div className="flex gap-2 sm:contents">
                <div className="flex-1 space-y-1">
                  <label htmlFor={`${uid}-ia-${i}`} className="block text-label-sm text-on-surface-variant">{t("ingest.ingredient.amount")}</label>
                  <input
                    id={`${uid}-ia-${i}`}
                    className="clay-input"
                    inputMode="decimal"
                    dir="ltr"
                    defaultValue={ing.amount ?? ""}
                    onChange={(e) => set("ingredients", r.ingredients.map((x, j) => (j === i ? { ...x, amount: numOrNull(e.target.value) } : x)))}
                  />
                </div>
                <div className="flex-1 space-y-1">
                  <label htmlFor={`${uid}-iu-${i}`} className="block text-label-sm text-on-surface-variant">{t("ingest.ingredient.unit")}</label>
                  <select
                    id={`${uid}-iu-${i}`}
                    className="clay-input"
                    value={ing.unit}
                    onChange={(e) => set("ingredients", r.ingredients.map((x, j) => (j === i ? { ...x, unit: e.target.value as MeasurementUnit } : x)))}
                  >
                    {MEASUREMENT_UNITS.map((u) => (
                      <option key={u} value={u}>{u === "unspecified" ? t("ingest.unitNone") : t(`unit.${u}`)}</option>
                    ))}
                  </select>
                </div>
              </div>
              <button
                type="button"
                className="clay-btn-ghost row-start-1 col-start-2 self-end sm:row-auto sm:col-auto"
                aria-label={t("ingest.removeIngredient", { n: i + 1 })}
                onClick={() => {
                  set("ingredients", r.ingredients.filter((_, j) => j !== i));
                  setIngKeys((k) => k.filter((_, j) => j !== i));
                }}
              >
                <Icon name="trash" size={18} />
              </button>
            </li>
          ))}
        </ul>
        <button type="button" className="clay-btn-tonal" onClick={() => {
          set("ingredients", [...r.ingredients, { name: "", amount: null, unit: "unspecified" }]);
          setIngKeys((k) => [...k, fresh()]);
        }}>
          <Icon name="add" size={18} /> {t("ingest.addIngredient")}
        </button>
      </section>

      <section className="clay space-y-3 p-5" aria-labelledby={`${uid}-steps`}>
        <h3 id={`${uid}-steps`} className="text-body-lg font-bold">{t("ingest.steps")}</h3>
        <ol className="space-y-3">
          {r.steps.map((s, i) => (
            <li key={stepKeys[i]} className="flex items-start gap-2">
              <span className="mt-8 grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-md text-on-primary-fixed-variant" aria-hidden="true">{i + 1}</span>
              <div className="min-w-0 flex-1 space-y-1">
                <label htmlFor={`${uid}-st-${i}`} className="block text-label-sm text-on-surface-variant">{t("ingest.step", { n: i + 1 })}</label>
                <textarea id={`${uid}-st-${i}`} className="clay-input min-h-[4.5rem]" rows={2} value={s} onChange={(e) => set("steps", r.steps.map((x, j) => (j === i ? e.target.value : x)))} />
              </div>
              <button type="button" className="clay-btn-ghost mt-7" aria-label={t("ingest.removeStep", { n: i + 1 })} onClick={() => {
                  set("steps", r.steps.filter((_, j) => j !== i));
                  setStepKeys((k) => k.filter((_, j) => j !== i));
                }}>
                <Icon name="trash" size={18} />
              </button>
            </li>
          ))}
        </ol>
        <button type="button" className="clay-btn-tonal" onClick={() => {
          set("steps", [...r.steps, ""]);
          setStepKeys((k) => [...k, fresh()]);
        }}>
          <Icon name="add" size={18} /> {t("ingest.addStep")}
        </button>
      </section>

      <section className="clay space-y-4 p-5">
        <ChipGroup
          legend={t("ingest.tags")}
          all={DIETARY}
          selected={r.dietaryTags}
          label={(d) => t(`ingest.diet.${d}`)}
          onToggle={(d: DietaryPreference) => set("dietaryTags", toggle(r.dietaryTags, d, DIETARY))}
        />
        <ChipGroup
          legend={t("ingest.allergens")}
          all={ALLERGENS}
          selected={r.allergens}
          label={(a) => t(`ingest.allergen.${a}`)}
          onToggle={(a: Allergen) => set("allergens", toggle(r.allergens, a, ALLERGENS))}
        />
        <ChipGroup
          legend={t("ingest.mayContain")}
          all={ALLERGENS}
          selected={r.mayContain}
          label={(a) => t(`ingest.allergen.${a}`)}
          onToggle={(a: Allergen) => set("mayContain", toggle(r.mayContain, a, ALLERGENS))}
        />
      </section>

      <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <button type="button" className="clay-btn-secondary" disabled={saving} onClick={onDiscard}>
          {t("ingest.startOver")}
        </button>
        <button type="submit" className="clay-btn-primary sm:min-w-[12rem]" disabled={saving} aria-busy={saving || undefined}>
          {saving ? <Spinner small /> : <Icon name="check" size={18} />}
          {saving ? t("ingest.saving") : t("ingest.save")}
        </button>
      </div>
    </form>
  );
}

function NumberField({ id, label, value, min, onChange }: { id: string; label: string; value: number | null; min: number; onChange: (v: string) => void }) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={id} className="block text-label-md text-on-surface-variant">{label}</label>
      <input id={id} type="number" inputMode="numeric" min={min} step={1} dir="ltr" className="clay-input" defaultValue={value ?? ""} onChange={(e) => onChange(e.target.value)} />
    </div>
  );
}

function ChipGroup<T extends string>({ legend, all, selected, label, onToggle }: { legend: string; all: readonly T[]; selected: T[]; label: (v: T) => string; onToggle: (v: T) => void }) {
  return (
    <fieldset className="space-y-2">
      <legend className="mb-2 text-label-md text-on-surface-variant">{legend}</legend>
      <div className="flex flex-wrap gap-2">
        {all.map((v) => {
          const on = selected.includes(v);
          return (
            <button
              key={v}
              type="button"
              aria-pressed={on}
              onClick={() => onToggle(v)}
              className={`rounded-full px-3 py-1.5 text-label-md transition-colors ${on ? "bg-primary text-on-primary shadow-control" : "bg-surface-high text-on-surface-variant"}`}
            >
              {on ? <span aria-hidden="true">✓ </span> : null}
              {label(v)}
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}
