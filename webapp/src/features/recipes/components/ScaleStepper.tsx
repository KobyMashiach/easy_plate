// RecipeScaleStepper (grocery_lists_ui.dart): steps in servings when the
// recipe says how many it makes, otherwise as a multiplier in halves,
// between ×0.5 and ×20.
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { formatAmount } from "../lib/format";

const MIN_SCALE = 0.5;
const MAX_SCALE = 20;

export function ScaleStepper({ scale, baseServings, onChange }: { scale: number; baseServings: number | null; onChange: (scale: number) => void }) {
  const { t } = useI18n();
  const byServings = baseServings !== null && baseServings > 0;
  const step = (direction: number) => {
    if (byServings) {
      const base = baseServings as number;
      const servings = Math.round(scale * base) + direction;
      return Math.min(Math.max(servings, 1), base * MAX_SCALE) / base;
    }
    return Math.min(Math.max(scale + 0.5 * direction, MIN_SCALE), MAX_SCALE);
  };
  const label = byServings ? t("recipes.scaleServings") : t("recipes.scaleTimes");
  const value = byServings ? String(Math.round(scale * (baseServings as number))) : t("recipes.scaleValue", { value: formatAmount(scale) });
  const down = step(-1);
  const up = step(1);
  const btn = "grid h-10 w-10 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant shadow-control disabled:opacity-40";
  return (
    <div className="flex items-center gap-2" role="group" aria-label={label}>
      <span className="flex-1 text-body-md">{label}</span>
      <button type="button" className={btn} disabled={!(down < scale)} onClick={() => onChange(down)} aria-label={`${label} −`}>
        <span aria-hidden="true" className="text-headline-md leading-none">−</span>
      </button>
      <output className="w-14 text-center text-headline-md" dir="ltr" aria-live="polite">
        {value}
      </output>
      <button type="button" className={btn} disabled={!(up > scale)} onClick={() => onChange(up)} aria-label={`${label} +`}>
        <Icon name="add" size={20} />
      </button>
    </div>
  );
}
