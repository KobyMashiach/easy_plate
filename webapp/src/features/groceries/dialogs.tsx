// The grocery dialogs (grocery_lists_ui.dart, meal_plan_filter_card.dart,
// item_breakdown_sheet.dart): a new list, a recipe and how many times over,
// the menus a list is built from, and one line's breakdown.
import { useEffect, useId, useMemo, useState } from "react";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { useIsPhone } from "../../components/useIsPhone";
import { MEASUREMENT_UNITS, type MeasurementUnit } from "../../models/recipe";
import { totalAmount, type GroceryItem, type GroceryListSource, type PlanLike, type RecipeLike } from "../../models/groceryList";
import { Chip, Modal, formatAmount, parseAmount } from "./kit";

export function useUnitLabel() {
  const { t } = useI18n();
  return {
    /** measurementUnitLabel: blank for "unspecified". */
    label: (u: MeasurementUnit) => (u === "unspecified" ? "" : t(`groceries.unit.${u}`)),
    /** measurementUnitPickerLabel: the picker still needs something to tap. */
    picker: (u: MeasurementUnit) => t(`groceries.unit.${u}`),
  };
}

const MIN_SCALE = 0.5;
const MAX_SCALE = 20;

/** RecipeScaleStepper: in servings when the recipe says how many it makes, else in halves. */
export function ScaleStepper({ scale, baseServings, onChange, disabled }: { scale: number; baseServings: number | null; onChange: (s: number) => void; disabled?: boolean }) {
  const { t } = useI18n();
  const base = baseServings && baseServings > 0 ? baseServings : null;
  const step = (dir: number) => {
    if (base) {
      const servings = Math.round(scale * base) + dir;
      return Math.min(Math.max(servings, 1), base * MAX_SCALE) / base;
    }
    return Math.min(Math.max(scale + 0.5 * dir, MIN_SCALE), MAX_SCALE);
  };
  const label = base ? t("groceries.servings") : t("groceries.timesOver");
  const value = base ? String(Math.round(scale * base)) : t("groceries.scaleValue", { value: formatAmount(scale) });
  const btn = "grid h-11 w-11 place-items-center rounded-full bg-surface-low text-primary disabled:opacity-40";
  return (
    <div className="flex items-center gap-3" role="group" aria-label={label}>
      <span className="flex-1 text-label-md text-on-surface-variant">{label}</span>
      <button type="button" className={btn} onClick={() => onChange(step(-1))} disabled={disabled || step(-1) >= scale} aria-label={`${t("groceries.less")} — ${label}`}>
        <span aria-hidden="true" className="text-headline-md leading-none">−</span>
      </button>
      <output className="min-w-[3.5rem] text-center text-body-lg font-bold" aria-live="polite">
        {value}
      </output>
      <button type="button" className={btn} onClick={() => onChange(step(1))} disabled={disabled || step(1) <= scale} aria-label={`${t("groceries.more")} — ${label}`}>
        <span aria-hidden="true" className="text-headline-md leading-none">+</span>
      </button>
    </div>
  );
}

/** A name and what to build the list from. */
export function NewListDialog({ open, onClose, onPick }: { open: boolean; onClose: () => void; onPick: (name: string, source: GroceryListSource) => void }) {
  const { t } = useI18n();
  const id = useId();
  const [name, setName] = useState("");
  useEffect(() => {
    if (open) setName("");
  }, [open]);
  const phone = useIsPhone();
  const choices: { source: GroceryListSource; icon: string; phoneIcon: string; title: string; hint: string }[] = [
    { source: "plans", icon: "plans", phoneIcon: "calendar_month", title: t("groceries.fromPlans"), hint: t("groceries.fromPlansHint") },
    { source: "recipe", icon: "recipes", phoneIcon: "restaurant_menu", title: t("groceries.fromRecipe"), hint: t("groceries.fromRecipeHint") },
    { source: "manual", icon: "edit", phoneIcon: "edit_note", title: t("groceries.emptyList"), hint: t("groceries.emptyListHint") },
  ];
  return (
    <Modal open={open} onClose={onClose} title={t("groceries.newListTitle")}>
      <div className="space-y-4">
        <div className="space-y-1.5">
          <label htmlFor={id} className="block text-label-md text-on-surface-variant">
            {t("groceries.listName")}
          </label>
          <input id={id} className="clay-input" placeholder={t("groceries.defaultListName")} value={name} onChange={(e) => setName(e.target.value)} maxLength={80} autoFocus />
        </div>
        <ul className="space-y-3">
          {choices.map((c) => (
            <li key={c.source}>
              {phone ? (
                <button type="button" onClick={() => onPick(name.trim(), c.source)} className="clay-card press flex w-full items-center gap-3 p-6 text-start" style={{ borderRadius: 24 }}>
                  <Icon name={c.phoneIcon} size={24} className="shrink-0 text-primary" />
                  <span className="min-w-0 flex-1">
                    <span className="block text-body-lg">{c.title}</span>
                    <span className="block text-label-md text-on-surface-variant">{c.hint}</span>
                  </span>
                  <Icon name="chevron_right" size={24} className="shrink-0 text-tertiary rtl:-scale-x-100" />
                </button>
              ) : (
              <button type="button" onClick={() => onPick(name.trim(), c.source)} className="clay flex w-full items-center gap-3 p-4 text-start transition-transform active:scale-[.99]">
                <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
                  <Icon name={c.icon} size={20} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-body-md font-bold">{c.title}</span>
                  <span className="block text-label-sm text-on-surface-variant">{c.hint}</span>
                </span>
              </button>
              )}
            </li>
          ))}
        </ul>
      </div>
    </Modal>
  );
}

/** One of the account's recipes that has something to buy. */
export function RecipePickerDialog({ open, recipes, error = false, onClose, onPick }: { open: boolean; recipes: RecipeLike[] | null; error?: boolean; onClose: () => void; onPick: (r: RecipeLike) => void }) {
  const { t } = useI18n();
  const [q, setQ] = useState("");
  const id = useId();
  useEffect(() => {
    if (open) setQ("");
  }, [open]);
  const shown = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return (recipes ?? []).filter((r) => r.ingredients.length > 0 && (!needle || r.title.toLowerCase().includes(needle))).sort((a, b) => a.title.localeCompare(b.title));
  }, [recipes, q]);
  return (
    <Modal open={open} onClose={onClose} title={t("groceries.pickRecipe")} wide>
      <label htmlFor={id} className="sr-only">
        {t("groceries.searchRecipes")}
      </label>
      <input id={id} type="search" className="clay-input mb-3" placeholder={t("groceries.searchRecipes")} value={q} onChange={(e) => setQ(e.target.value)} autoFocus />
      {recipes === null && error ? (
        <p className="py-6 text-center text-error" role="alert">{t("groceries.common.loadFailed")}</p>
      ) : recipes === null ? (
        <p className="py-6 text-center text-on-surface-variant">{t("common.loading")}</p>
      ) : shown.length === 0 ? (
        <p className="py-6 text-center text-on-surface-variant">{t("groceries.noRecipes")}</p>
      ) : (
        <ul className="grid gap-2 sm:grid-cols-2">
          {shown.map((r) => (
            <li key={r.id}>
              <button type="button" onClick={() => onPick(r)} className="flex w-full items-center gap-3 rounded-std bg-surface-low px-4 py-3 text-start hover:bg-surface-high">
                <span className="min-w-0 flex-1 truncate text-body-md">{r.title}</span>
                <span className="text-label-sm text-on-surface-variant">{r.ingredients.length}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </Modal>
  );
}

/** The recipe list's name and scale (showRecipeGroceryListSheet). */
export function RecipeListDialog({
  recipe,
  initialName,
  initialScale = 1,
  busy,
  onClose,
  onCreate,
}: {
  recipe: RecipeLike | null;
  initialName: string;
  /** From the recipe page's link (?scale=), clamped to the stepper's range. */
  initialScale?: number;
  busy: boolean;
  onClose: () => void;
  onCreate: (name: string, scale: number) => void;
}) {
  const { t } = useI18n();
  const id = useId();
  const [name, setName] = useState("");
  const [scale, setScale] = useState(1);
  useEffect(() => {
    if (recipe) {
      setName(initialName || recipe.title);
      setScale(Number.isFinite(initialScale) ? Math.min(Math.max(initialScale, MIN_SCALE), MAX_SCALE) : 1);
    }
  }, [recipe, initialName, initialScale]);
  const empty = (recipe?.ingredients.length ?? 0) === 0;
  return (
    <Modal
      open={recipe !== null}
      onClose={() => !busy && onClose()}
      title={t("groceries.recipeListTitle")}
      footer={
        <button type="submit" form={id} className="clay-btn-primary flex-1" disabled={busy || empty} aria-busy={busy || undefined}>
          {t("groceries.createList")}
        </button>
      }
    >
      <form
        id={id}
        className="space-y-4"
        onSubmit={(e) => {
          e.preventDefault();
          if (!busy && !empty) onCreate(name.trim(), scale);
        }}
      >
        <p className="text-body-md text-on-surface-variant">{t("groceries.recipeListHint")}</p>
        <div className="space-y-1.5">
          <label htmlFor={`${id}-name`} className="block text-label-md text-on-surface-variant">
            {t("groceries.listName")}
          </label>
          <input id={`${id}-name`} className="clay-input" value={name} onChange={(e) => setName(e.target.value)} maxLength={80} />
        </div>
        <ScaleStepper scale={scale} baseServings={recipe?.servings ?? null} onChange={setScale} />
        {empty ? <p className="text-label-md text-error">{t("groceries.noIngredients")}</p> : null}
      </form>
    </Modal>
  );
}

/** Which menus feed the list. Everything ticked is stored as "all" (an empty list). */
export function PlanPickerDialog({ open, plans, selected, onClose, onApply }: { open: boolean; plans: PlanLike[]; selected: string[]; onClose: () => void; onApply: (ids: string[]) => void }) {
  const { t } = useI18n();
  const [picked, setPicked] = useState<Set<string>>(new Set());
  useEffect(() => {
    if (open) setPicked(new Set(selected.length === 0 ? plans.map((p) => p.id) : selected));
  }, [open, plans, selected]);
  const all = picked.size === plans.length;
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t("groceries.selectPlansTitle")}
      footer={
        <button type="button" className="clay-btn-primary flex-1" disabled={picked.size === 0} onClick={() => onApply(all ? [] : [...picked])}>
          {t("groceries.applySelection")}
        </button>
      }
    >
      <label className="mb-2 flex items-center gap-3 rounded-std bg-surface-low px-4 py-3">
        <input type="checkbox" className="h-5 w-5 accent-[rgb(var(--c-primary))]" checked={all} onChange={(e) => setPicked(new Set(e.target.checked ? plans.map((p) => p.id) : []))} />
        <span className="text-body-md font-bold">{t("groceries.selectAllPlans")}</span>
      </label>
      <ul className="space-y-1">
        {plans.map((p) => (
          <li key={p.id}>
            <label className="flex items-center gap-3 rounded-std px-4 py-2.5 hover:bg-surface-low">
              <input
                type="checkbox"
                className="h-5 w-5 accent-[rgb(var(--c-primary))]"
                checked={picked.has(p.id)}
                onChange={(e) =>
                  setPicked((s) => {
                    const n = new Set(s);
                    if (e.target.checked) n.add(p.id);
                    else n.delete(p.id);
                    return n;
                  })
                }
              />
              <span className="text-body-md">{p.name}</span>
            </label>
          </li>
        ))}
      </ul>
    </Modal>
  );
}

/**
 * One line's drill-down: which recipe contributed how much, each amount
 * editable, any source but the last removable, the unit, and a free extra
 * amount. Every change is applied at once, as the app's sheet does.
 */
export function BreakdownDialog({
  item,
  onClose,
  onAdjust,
  onRemoveSource,
  onUnit,
  onBuffer,
}: {
  item: GroceryItem | null;
  onClose: () => void;
  onAdjust: (index: number, amount: number) => void;
  onRemoveSource: (index: number) => void;
  onUnit: (u: MeasurementUnit) => void;
  onBuffer: (amount: number) => void;
}) {
  const { t } = useI18n();
  const units = useUnitLabel();
  const id = useId();
  const [drafts, setDrafts] = useState<string[]>([]);
  const [buffer, setBuffer] = useState("");
  const [bufferError, setBufferError] = useState(false);
  const sources = item?.sources ?? [];
  const sig = sources.map((s) => s.amount).join("|");
  useEffect(() => {
    setDrafts(sources.map((s) => formatAmount(s.amount)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [item?.id, sig]);
  useEffect(() => {
    if (item) {
      setBuffer("");
      setBufferError(false);
    }
  }, [item?.id]); // eslint-disable-line react-hooks/exhaustive-deps
  if (!item) return <Modal open={false} onClose={onClose} title="">{null}</Modal>;
  const unit = units.label(item.unit);
  const canRemove = sources.length > 1;
  const commit = (i: number) => {
    const amount = parseAmount(drafts[i] ?? "");
    if (amount === null) {
      setDrafts((d) => d.map((v, j) => (j === i ? formatAmount(sources[i].amount) : v)));
      return;
    }
    if (amount !== sources[i].amount) onAdjust(i, amount);
  };
  return (
    <Modal open onClose={onClose} title={item.name} wide>
      <div className="space-y-5">
        <p className="text-label-md text-on-surface-variant">
          {t("groceries.breakdownTitle")} · <span dir="ltr">{formatAmount(totalAmount(item))}</span> {unit}
        </p>
        <fieldset>
          <legend className="mb-2 text-label-md">{t("groceries.unit")}</legend>
          <div className="flex flex-wrap gap-2">
            {MEASUREMENT_UNITS.map((u) => (
              <Chip key={u} selected={item.unit === u} onClick={() => onUnit(u)}>
                {units.picker(u)}
              </Chip>
            ))}
          </div>
        </fieldset>
        <fieldset>
          <legend className="mb-2 text-label-md">{t("groceries.amount")}</legend>
          <ul className="space-y-2">
            {sources.map((s, i) => (
              <li key={`${i}-${s.label}`} className="flex items-center gap-2">
                <span className="min-w-0 flex-1 truncate text-body-md">{s.label}</span>
                <label htmlFor={`${id}-${i}`} className="sr-only">
                  {t("groceries.amountFor", { label: s.label })}
                </label>
                <input
                  id={`${id}-${i}`}
                  className="clay-input !min-h-[44px] w-24 text-center"
                  inputMode="decimal"
                  dir="ltr"
                  value={drafts[i] ?? ""}
                  aria-invalid={drafts[i] !== undefined && parseAmount(drafts[i]) === null ? "true" : undefined}
                  onChange={(e) => setDrafts((d) => d.map((v, j) => (j === i ? e.target.value.replace(/[^0-9.,]/g, "") : v)))}
                  onBlur={() => commit(i)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      commit(i);
                    }
                  }}
                />
                <span className="w-14 text-label-md text-on-surface-variant">{unit}</span>
                <button
                  type="button"
                  className="grid h-10 w-10 place-items-center rounded-full text-error disabled:text-outline-variant"
                  disabled={!canRemove}
                  onClick={() => onRemoveSource(i)}
                  aria-label={canRemove ? `${t("groceries.common.delete")} — ${s.label}` : t("groceries.lastSource")}
                  title={canRemove ? t("groceries.common.delete") : t("groceries.lastSource")}
                >
                  <Icon name="close" size={18} />
                </button>
              </li>
            ))}
          </ul>
          {!canRemove ? <p className="mt-1 text-label-sm text-on-surface-variant">{t("groceries.lastSource")}</p> : null}
        </fieldset>
        <form
          className="flex items-end gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            const amount = parseAmount(buffer);
            if (amount === null) {
              setBufferError(true);
              return;
            }
            onBuffer(amount);
            onClose();
          }}
        >
          <div className="flex-1 space-y-1.5">
            <label htmlFor={`${id}-buffer`} className="block text-label-md text-on-surface-variant">
              {t("groceries.buffer")}
            </label>
            <input
              id={`${id}-buffer`}
              className="clay-input"
              inputMode="decimal"
              dir="ltr"
              value={buffer}
              aria-invalid={bufferError ? "true" : undefined}
              onChange={(e) => {
                setBuffer(e.target.value.replace(/[^0-9.,]/g, ""));
                setBufferError(false);
              }}
            />
          </div>
          <button type="submit" className="clay-btn-primary" disabled={!buffer.trim()}>
            {t("groceries.common.add")}
          </button>
        </form>
        {bufferError ? <p className="text-label-sm text-error" role="alert">{t("groceries.amountInvalid")}</p> : null}
      </div>
    </Modal>
  );
}
