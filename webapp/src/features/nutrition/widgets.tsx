// Nutrition pieces shared by the planner and the dashboard
// (lib/core/widgets/nutrition/nutrition_widgets.dart, day_nutrition_card.dart).
// Macro colours follow the app: protein = secondary, carbs = tertiary,
// fat = warm accent.
import { useLayoutEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { ClayIconButton } from "../../components/clay";
import type { Nutrition } from "../../models/recipe";
import { macroShares, type DayNutrition } from "../../models/mealPlan";

export const MACROS = [
  { key: "protein", grams: (n: Nutrition) => n.proteinGrams, bg: "bg-secondary", text: "text-secondary", label: "nutrition.protein" },
  { key: "carbs", grams: (n: Nutrition) => n.carbsGrams, bg: "bg-tertiary", text: "text-tertiary", label: "nutrition.carbs" },
  { key: "fat", grams: (n: Nutrition) => n.fatGrams, bg: "bg-warm-accent", text: "text-warm-accent", label: "nutrition.fat" },
] as const;

export function useKcal() {
  const { locale } = useI18n();
  // One formatter per locale, not one per render of every bar and card.
  return useMemo(() => {
    const nf = new Intl.NumberFormat(locale, { maximumFractionDigits: 0 });
    return (n: number) => nf.format(n);
  }, [locale]);
}

/** A donut of the three macros' calorie shares, the calories in its middle. */
export function MacroRing({ nutrition, size = 104, thickness = 11, empty = false }: { nutrition: Nutrition; size?: number; thickness?: number; empty?: boolean }) {
  const { t } = useI18n();
  const kcal = useKcal();
  const shares = macroShares(nutrition);
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  let offset = 0;
  const arcs = MACROS.map((m) => {
    const share = shares[m.key];
    const arc = { m, len: share * c, offset };
    offset += share * c;
    return arc;
  }).filter((a) => a.len > 0);
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90" aria-hidden="true">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth={thickness} className="stroke-surface-high" />
        {arcs.map(({ m, len, offset: o }) => (
          <circle key={m.key} cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth={thickness} className={m.text} stroke="currentColor" strokeDasharray={`${Math.max(0, len - 1.5)} ${c}`} strokeDashoffset={-o} />
        ))}
      </svg>
      <div className="absolute inset-0 grid place-items-center text-center">
        {empty ? (
          <Icon name="cook" className="text-outline" />
        ) : (
          <span>
            <span className="block text-body-lg font-extrabold leading-none">{kcal(nutrition.calories)}</span>
            <span className="block text-label-sm text-on-surface-variant">{t("nutrition.kcal")}</span>
          </span>
        )}
      </div>
    </div>
  );
}

export function MacroLegend({ nutrition, bars = false }: { nutrition: Nutrition; bars?: boolean }) {
  const { t } = useI18n();
  const shares = macroShares(nutrition);
  return (
    <dl className="w-full space-y-2">
      {MACROS.map((m) => (
        <div key={m.key}>
          <div className="flex items-center gap-2">
            <span className={`h-2.5 w-2.5 rounded-full ${m.bg}`} aria-hidden="true" />
            <dt className="flex-1 text-label-md">{t(m.label)}</dt>
            <dd className="text-label-md font-bold">
              {t("nutrition.grams", { n: Math.round(m.grams(nutrition)) })}
              {bars ? <span className="ms-2 font-normal text-on-surface-variant">{Math.round(shares[m.key] * 100)}%</span> : null}
            </dd>
          </div>
          {bars ? (
            <div className="mt-1 h-2 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
              <div className={`h-full rounded-full ${m.bg}`} style={{ width: `${Math.round(shares[m.key] * 100)}%` }} />
            </div>
          ) : null}
        </div>
      ))}
    </dl>
  );
}

/** The selected day's plate, added up, and the way into the week's dashboard. */
export function DayNutritionCard({ day, dashboardHref }: { day: DayNutrition; dashboardHref: string }) {
  const { t } = useI18n();
  return (
    <section className="clay space-y-3 p-4" aria-labelledby="day-nut-h">
      <div className="flex items-center gap-2">
        <h2 id="day-nut-h" className="flex-1 text-body-lg font-bold">
          {t("nutrition.dayTotal")}
        </h2>
        <Link to={dashboardHref} className="clay-btn-tonal min-h-0 px-3 py-2 text-label-md">
          <Icon name="nutrition" size={16} />
          {t("nutrition.openDashboard")}
        </Link>
      </div>
      {day.hasData ? (
        <div className="flex items-center gap-4">
          <MacroRing nutrition={day.total} />
          <MacroLegend nutrition={day.total} />
        </div>
      ) : (
        <div className="flex items-center gap-4">
          <MacroRing nutrition={day.total} size={88} thickness={10} empty />
          <p className="text-label-md text-on-surface-variant">{t("nutrition.noPlanned")}</p>
        </div>
      )}
      {day.missingItems > 0 ? <MissingNote count={day.missingItems} /> : null}
    </section>
  );
}

export function MissingNote({ count }: { count: number }) {
  const { t } = useI18n();
  return (
    <p className="flex items-center gap-1.5 text-label-sm text-on-surface-variant">
      <Icon name="support" size={14} />
      {t("nutrition.missingCount", { n: count })}
    </p>
  );
}

// ---------------------------------------------------------------------------
// Below lg: the app's own pieces (nutrition_widgets.dart, day_nutrition_card.dart).

/** "1,247": the app's kcalNumber, grouping by commas in every language. */
export function kcalNumber(n: number): string {
  const v = Math.round(n);
  const digits = String(Math.abs(v)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return v < 0 ? `-${digits}` : digits;
}

const MACRO_COLOR: Record<(typeof MACROS)[number]["key"], string> = {
  protein: "rgb(var(--c-secondary))",
  carbs: "rgb(var(--c-tertiary))",
  fat: "rgb(var(--c-warm-accent))",
};

/** MacroRing: a donut of the three shares (round caps, a small gap between slices) with the calories in it. */
export function PhoneMacroRing({ nutrition, size = 132, thickness = 14, center }: { nutrition: Nutrition; size?: number; thickness?: number; center?: ReactNode }) {
  const { t } = useI18n();
  const shares = macroShares(nutrition);
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const gap = 0.06 * r;
  let at = 0;
  const arcs = MACROS.map((m) => {
    const len = shares[m.key] * c;
    const arc = len <= 0 ? null : { key: m.key, len: len > gap * 2 ? len - gap : len, start: at + (len > gap * 2 ? gap / 2 : 0) };
    at += len;
    return arc;
  }).filter((a): a is { key: (typeof MACROS)[number]["key"]; len: number; start: number } => a !== null);
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90" aria-hidden="true">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth={thickness} stroke="rgb(var(--c-surface-container-high))" />
        {arcs.map((a) => (
          <circle key={a.key} cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth={thickness} strokeLinecap="round" stroke={MACRO_COLOR[a.key]} strokeDasharray={`${a.len} ${c}`} strokeDashoffset={-a.start} />
        ))}
      </svg>
      <div className="absolute inset-0 grid place-items-center text-center">
        {center ?? (
          <span>
            <span className="block text-headline-md font-extrabold" dir="ltr">
              {kcalNumber(nutrition.calories)}
            </span>
            <span className="block text-label-sm text-on-surface-variant">{t("nutrition.kcal")}</span>
          </span>
        )}
      </div>
    </div>
  );
}

/** MacroLegend: dot 10 · name · grams (w800), rows 4 apart. */
export function PhoneMacroLegend({ nutrition }: { nutrition: Nutrition }) {
  const { t } = useI18n();
  return (
    <dl className="min-w-0">
      {MACROS.map((m) => (
        <div key={m.key} className="flex items-center gap-2 py-1">
          <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: MACRO_COLOR[m.key] }} aria-hidden="true" />
          <dt className="truncate text-label-md">{t(m.label)}</dt>
          <dd className="truncate text-label-md font-extrabold text-on-surface-variant">{t("nutrition.grams", { n: Math.round(m.grams(nutrition)) })}</dd>
        </div>
      ))}
    </dl>
  );
}

/** MacroBar ×3: name and grams with the share, the 10 px bar under them, 12 apart. */
export function PhoneMacroBars({ nutrition }: { nutrition: Nutrition }) {
  const { t } = useI18n();
  const shares = macroShares(nutrition);
  return (
    <dl className="min-w-0 flex-1 space-y-3">
      {MACROS.map((m) => (
        <div key={m.key}>
          <div className="flex items-center">
            <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: MACRO_COLOR[m.key] }} aria-hidden="true" />
            <dt className="ms-2 min-w-0 flex-[3] truncate text-label-md">{t(m.label)}</dt>
            <dd className="ms-1 min-w-0 flex-[2] truncate text-end text-label-md font-extrabold">{t("nutrition.grams", { n: Math.round(m.grams(nutrition)) })}</dd>
            <dd className="ms-2 w-[34px] shrink-0 text-end text-label-sm text-on-surface-variant" dir="ltr">
              {Math.round(shares[m.key] * 100)}%
            </dd>
          </div>
          <div className="mt-1 h-2.5 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
            <div className="h-full rounded-full transition-[width] duration-500 ease-out motion-reduce:transition-none" style={{ width: `${Math.round(shares[m.key] * 100)}%`, background: MACRO_COLOR[m.key] }} />
          </div>
        </div>
      ))}
    </dl>
  );
}

/** MacroRingWithBars: the ring takes at most a third of the row, then the bars. */
export function PhoneMacroRingWithBars({ nutrition, ringSize = 128, thickness = 14 }: { nutrition: Nutrition; ringSize?: number; thickness?: number }) {
  const row = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(318);
  useLayoutEffect(() => {
    const el = row.current;
    if (!el) return;
    const apply = () => setWidth(el.clientWidth || 318);
    apply();
    const ro = new ResizeObserver(apply);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const ring = Math.min(ringSize, width * 0.34);
  return (
    <div ref={row} className="flex items-center gap-4">
      <PhoneMacroRing nutrition={nutrition} size={ring} thickness={thickness * (ring / ringSize)} />
      <PhoneMacroBars nutrition={nutrition} />
    </div>
  );
}

/** "3 items without nutrition values": info_outline 14 + labelSm outline. */
export function PhoneMissingNote({ count }: { count: number }) {
  const { t } = useI18n();
  return (
    <p className="flex items-center gap-1 text-label-sm text-outline">
      <Icon name="info_outline" size={14} />
      {t("nutrition.missingCount", { n: count })}
    </p>
  );
}

/** DayNutritionCard: "total for the day" + the filled 40 px insights button, the ring and its legend. */
export function PhoneDayNutritionCard({ day, dashboardHref }: { day: DayNutrition; dashboardHref: string }) {
  const { t } = useI18n();
  return (
    <section className="clay-card p-4" style={{ borderRadius: 24 }} aria-labelledby="day-nut-h">
      <div className="flex items-end gap-3">
        <h2 id="day-nut-h" className="min-w-0 flex-1 text-headline-md">
          {t("nutrition.dayTotal")}
        </h2>
        <ClayIconButton icon="insights" filled size={40} label={t("nutrition.openDashboard")} to={dashboardHref} />
      </div>
      <div className="mt-3 flex items-center gap-4">
        {day.hasData ? (
          <>
            <PhoneMacroRing nutrition={day.total} size={104} thickness={11} />
            <PhoneMacroLegend nutrition={day.total} />
          </>
        ) : (
          <>
            <PhoneMacroRing nutrition={day.total} size={88} thickness={10} center={<Icon name="restaurant" className="text-outline" />} />
            <p className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("nutrition.noPlanned")}</p>
          </>
        )}
      </div>
      {day.missingItems > 0 ? (
        <div className="mt-3">
          <PhoneMissingNote count={day.missingItems} />
        </div>
      ) : null}
    </section>
  );
}
