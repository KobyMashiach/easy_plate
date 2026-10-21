// The planner's dialogs: the quick entry (quick_entry_sheet.dart — a free-text
// item plus the products it is made of, so it still feeds the grocery list)
// and moving an item to another meal.
import { useId, useRef, useState, type FormEvent } from "react";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { Notice, Spinner } from "../../components/ui";
import { MEASUREMENT_UNITS, type Ingredient, type MeasurementUnit } from "../../models/recipe";
import { mealsForWeekday, WEEKDAYS, type MealPlan } from "../../models/mealPlan";
import { Modal } from "../library/shared/components";
import { saveErrorKey } from "../library/shared/store";
import { useDayNames } from "./days";

interface Draft {
  key: number;
  name: string;
  amount: string;
  unit: MeasurementUnit;
}

/** parseAmount: "1,5" and "1.5" both read; anything else is no amount. */
function parseAmount(s: string): number | null {
  const v = Number(s.trim().replace(",", "."));
  return s.trim() !== "" && Number.isFinite(v) ? v : null;
}

export function QuickEntryDialog({ initialText, initialIngredients = [], onSubmit, onClose }: { initialText?: string; initialIngredients?: Ingredient[]; onSubmit: (text: string, ingredients: Ingredient[]) => Promise<void>; onClose: () => void }) {
  const { t } = useI18n();
  const formId = useId();
  const nameId = useId();
  const productsId = useId();
  const [text, setText] = useState(initialText ?? "");
  const [rows, setRows] = useState<Draft[]>(() => initialIngredients.map((g, i) => ({ key: i, name: g.name, amount: g.amount === null ? "" : String(g.amount), unit: g.unit })));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Row keys from a counter: two quick taps on "add" in one millisecond
  // would give Date.now() twice and tie two rows' inputs together.
  const nextKey = useRef(initialIngredients.length);
  const canSubmit = text.trim() !== "" && !busy;

  const update = (key: number, patch: Partial<Draft>) => setRows((rs) => rs.map((r) => (r.key === key ? { ...r, ...patch } : r)));
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;
    setBusy(true);
    setError(null);
    // Rows left blank are dropped rather than saved as empty products.
    const ingredients = rows.filter((r) => r.name.trim()).map((r) => ({ name: r.name.trim(), amount: parseAmount(r.amount), unit: r.unit }));
    try {
      await onSubmit(text.trim(), ingredients);
      onClose();
    } catch (e) {
      setError(t(saveErrorKey(e)));
      setBusy(false);
    }
  };

  return (
    <Modal
      title={initialText === undefined ? t("plans.quickEntry") : t("plans.editItem")}
      onClose={onClose}
      busy={busy}
      wide
      footer={
        <>
          <button type="button" className="clay-btn-ghost" onClick={onClose} disabled={busy}>
            {t("library.ui.cancel")}
          </button>
          <button type="submit" form={formId} className="clay-btn-primary" disabled={!canSubmit} aria-busy={busy || undefined}>
            {busy ? <Spinner small /> : <Icon name="check" size={18} />}
            {t("library.ui.save")}
          </button>
        </>
      }
    >
      <form id={formId} onSubmit={submit} className="space-y-4">
        <div className="space-y-1.5">
          <label htmlFor={nameId} className="block text-label-md text-on-surface-variant">
            {t("plans.itemName")}
          </label>
          <input id={nameId} className="clay-input" value={text} onChange={(e) => setText(e.target.value)} maxLength={200} data-autofocus />
        </div>
        {/* A <legend> must be the fieldset's first child to name it; inside the row it would not. */}
        <fieldset className="space-y-2" aria-labelledby={productsId}>
          <div className="flex items-center justify-between gap-2">
            <span id={productsId} className="text-label-md text-on-surface-variant">{t("plans.products")}</span>
            <button type="button" className="clay-btn-ghost min-h-0 px-3 py-1.5 text-label-md" onClick={() => setRows((rs) => [...rs, { key: nextKey.current++, name: "", amount: "", unit: "unit" }])}>
              <Icon name="add" size={16} />
              {t("plans.addProduct")}
            </button>
          </div>
          {rows.length === 0 ? <p className="text-label-sm text-on-surface-variant">{t("plans.noProducts")}</p> : null}
          {rows.map((r, i) => (
            <div key={r.key} className="flex flex-wrap items-end gap-2 rounded-md border border-outline-variant/60 bg-surface-low p-2">
              <label className="min-w-[10rem] flex-1 space-y-1">
                <span className="block text-label-sm text-on-surface-variant">{t("plans.productName")}</span>
                <input className="clay-input" value={r.name} onChange={(e) => update(r.key, { name: e.target.value })} />
              </label>
              <label className="w-20 space-y-1">
                <span className="block text-label-sm text-on-surface-variant">{t("plans.amount")}</span>
                <input className="clay-input text-center" inputMode="decimal" dir="ltr" value={r.amount} onChange={(e) => update(r.key, { amount: e.target.value })} />
              </label>
              <label className="w-36 space-y-1">
                <span className="block text-label-sm text-on-surface-variant">{t("plans.unit")}</span>
                <select className="clay-input" value={r.unit} onChange={(e) => update(r.key, { unit: e.target.value as MeasurementUnit })}>
                  {MEASUREMENT_UNITS.map((u) => (
                    <option key={u} value={u}>
                      {u === "unspecified" ? "—" : t(`unit.${u}`)}
                    </option>
                  ))}
                </select>
              </label>
              <button type="button" className="grid h-11 w-11 place-items-center rounded-full text-error hover:bg-error-container" onClick={() => setRows((rs) => rs.filter((x) => x.key !== r.key))} aria-label={t("plans.removeProduct", { n: i + 1 })}>
                <Icon name="close" size={18} />
              </button>
            </div>
          ))}
        </fieldset>
        {error ? <Notice kind="error">{error}</Notice> : null}
      </form>
    </Modal>
  );
}

/** Every meal of the plan, grouped by day, to move an item into. */
export function MoveItemDialog({ plan, fromMealId, onMove, onClose }: { plan: MealPlan; fromMealId: string; onMove: (toMealId: string) => Promise<void>; onClose: () => void }) {
  const { t } = useI18n();
  const days = useDayNames();
  const selectId = useId();
  const options = WEEKDAYS.map((_, wd) => ({ wd, meals: mealsForWeekday(plan, wd).filter((m) => m.id !== fromMealId) })).filter((g) => g.meals.length > 0);
  const [target, setTarget] = useState(options[0]?.meals[0]?.id ?? "");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const go = async () => {
    if (!target) return;
    setBusy(true);
    setError(null);
    try {
      await onMove(target);
      onClose();
    } catch (e) {
      setError(t(saveErrorKey(e)));
      setBusy(false);
    }
  };
  return (
    <Modal
      title={t("plans.moveItem")}
      onClose={onClose}
      busy={busy}
      footer={
        <>
          <button type="button" className="clay-btn-ghost" onClick={onClose} disabled={busy}>
            {t("library.ui.cancel")}
          </button>
          <button type="button" className="clay-btn-primary" onClick={go} disabled={!target || busy} aria-busy={busy || undefined}>
            {busy ? <Spinner small /> : null}
            {t("plans.move")}
          </button>
        </>
      }
    >
      {options.length === 0 ? (
        <p className="text-on-surface-variant">{t("plans.noOtherMeals")}</p>
      ) : (
        <div className="space-y-1.5">
          <label htmlFor={selectId} className="block text-label-md text-on-surface-variant">
            {t("plans.moveTo")}
          </label>
          <select id={selectId} className="clay-input" value={target} onChange={(e) => setTarget(e.target.value)} data-autofocus>
            {options.map((g) => (
              <optgroup key={g.wd} label={days.long[g.wd]}>
                {g.meals.map((m) => (
                  <option key={m.id} value={m.id}>
                    {`${days.short[g.wd]} · ${m.name}`}
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
        </div>
      )}
      {error ? (
        <div className="mt-3">
          <Notice kind="error">{error}</Notice>
        </div>
      ) : null}
    </Modal>
  );
}
