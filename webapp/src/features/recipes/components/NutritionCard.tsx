// NutritionFactsCard: per serving (as stored) or for the whole recipe
// (× servings), calories plus the three macros, and the AI estimate button
// when the account may change the recipe and it has ingredients.
import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { ClayButton, ClayCard } from "../../../components/clay";
import { reducedMotionNow } from "../../../components/useIsPhone";
import { SectionHeader } from "./phone";
import type { Nutrition } from "../../../models/recipe";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { grams, kcalNumber, scaledNutrition } from "../lib/format";

export function NutritionCard({ nutrition, servings, estimating, onEstimate }: { nutrition: Nutrition | null; servings: number | null; estimating: boolean; onEstimate: (() => void) | null }) {
  const { t } = useI18n();
  const [whole, setWhole] = useState(false);
  const canScale = servings !== null && servings > 1;
  const n = nutrition ? (whole && canScale ? scaledNutrition(nutrition, servings as number) : nutrition) : null;
  const macroKcal = n ? n.proteinGrams * 4 + n.carbsGrams * 4 + n.fatGrams * 9 : 0;
  const macros: [string, number, string][] = n
    ? [
        [t("recipes.nut.protein"), n.proteinGrams, "bg-secondary"],
        [t("recipes.nut.carbs"), n.carbsGrams, "bg-primary"],
        [t("recipes.nut.fat"), n.fatGrams, "bg-warm-accent"],
      ]
    : [];
  const factor: Record<string, number> = { [t("recipes.nut.protein")]: 4, [t("recipes.nut.carbs")]: 4, [t("recipes.nut.fat")]: 9 };

  const estimateBtn = onEstimate ? (
    <button type="button" className={n ? "clay-btn-ghost w-full" : "clay-btn-tonal w-full"} onClick={onEstimate} disabled={estimating} aria-busy={estimating || undefined}>
      {estimating ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" aria-hidden="true" /> : <Icon name="assistant" size={18} />}
      {estimating ? t("recipes.nut.estimating") : n ? t("recipes.nut.reestimate") : t("recipes.nut.estimate")}
    </button>
  ) : null;

  return (
    <section className="clay space-y-4 p-5" aria-labelledby="nut-h">
      <div className="flex items-center gap-2">
        <h2 id="nut-h" className="flex-1 text-headline-md">
          {t("recipes.nut.title")}
        </h2>
        {n && !canScale ? <span className="text-label-md text-on-surface-variant">{t("recipes.nut.perServing")}</span> : null}
      </div>
      {n && canScale ? (
        <div>
          <div className="grid grid-cols-2 gap-2" role="group" aria-label={t("recipes.nut.title")}>
            {[false, true].map((w) => (
              <button
                key={String(w)}
                type="button"
                aria-pressed={whole === w}
                onClick={() => setWhole(w)}
                className={`rounded-full border py-2 text-label-md ${whole === w ? "border-primary bg-primary text-on-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
              >
                {w ? t("recipes.nut.perRecipe") : t("recipes.nut.perServing")}
              </button>
            ))}
          </div>
          {whole ? <p className="mt-1 text-center text-label-sm text-on-surface-variant">{t("recipes.nut.perRecipeServings", { count: servings as number })}</p> : null}
        </div>
      ) : null}
      {n ? (
        <div className="grid items-center gap-5 sm:grid-cols-[auto_1fr]">
          <div className="mx-auto grid h-28 w-28 place-items-center rounded-full border-8 border-warm-accent/70 text-center">
            <span>
              <span className="block text-headline-md" dir="ltr">
                {kcalNumber(n.calories)}
              </span>
              <span className="text-label-sm text-on-surface-variant">{t("recipes.nut.kcal")}</span>
            </span>
          </div>
          <dl className="space-y-3">
            {macros.map(([label, value, bar]) => (
              <div key={label}>
                <div className="flex justify-between text-label-md">
                  <dt>{label}</dt>
                  <dd dir="ltr">{grams(t, value)}</dd>
                </div>
                <div className="mt-1 h-2 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
                  <div className={`h-full rounded-full ${bar}`} style={{ width: `${macroKcal ? Math.min(100, ((value * factor[label]) / macroKcal) * 100) : 0}%` }} />
                </div>
              </div>
            ))}
          </dl>
        </div>
      ) : (
        <div className="flex items-start gap-3">
          <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
            <Icon name="assistant" />
          </span>
          <div>
            <p className="text-body-md">{t("recipes.nut.none")}</p>
            <p className="mt-1 text-label-md text-on-surface-variant">{t("recipes.nut.noneHint")}</p>
          </div>
        </div>
      )}
      {estimateBtn}
    </section>
  );
}

// ── Below lg: NutritionFactsCard as the app draws it ─────────────────────

const MACRO_COLOR = { protein: "--c-secondary", carbs: "--c-tertiary", fat: "--c-warm-accent" } as const;
type MacroKey = keyof typeof MACRO_COLOR;

function sharesOf(n: Nutrition): Record<MacroKey, number> {
  const total = n.proteinGrams * 4 + n.carbsGrams * 4 + n.fatGrams * 9;
  if (total <= 0) return { protein: 0, carbs: 0, fat: 0 };
  return { protein: (n.proteinGrams * 4) / total, carbs: (n.carbsGrams * 4) / total, fat: (n.fatGrams * 9) / total };
}

/** 0 → 1 over `ms` with easeOutCubic, once per mount (instant under reduced motion). */
function useDrawIn(ms: number): number {
  const [p, setP] = useState(() => (reducedMotionNow() ? 1 : 0));
  useEffect(() => {
    if (reducedMotionNow()) return;
    let frame = 0;
    const start = performance.now();
    const tick = (now: number) => {
      const x = Math.min(1, (now - start) / ms);
      setP(1 - Math.pow(1 - x, 3));
      if (x < 1) frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [ms]);
  return p;
}

/** MacroRing: track surfaceContainerHigh, round caps, 0.06 rad gaps, from 12 o'clock clockwise; kcal in the centre. */
function MacroRing({ n, size, stroke }: { n: Nutrition; size: number; stroke: number }) {
  const { t } = useI18n();
  const progress = useDrawIn(700);
  const r = (size - stroke) / 2;
  const c = size / 2;
  const point = (a: number) => `${c + r * Math.cos(a)} ${c + r * Math.sin(a)}`;
  const shares = sharesOf(n);
  const gap = 0.06;
  let start = -Math.PI / 2;
  const arcs: { key: MacroKey; d: string }[] = [];
  for (const key of ["protein", "carbs", "fat"] as MacroKey[]) {
    const sweep = Math.PI * 2 * shares[key] * progress;
    if (sweep <= 0) continue;
    const trimmed = sweep > gap * 2 ? sweep - gap : sweep;
    const a0 = start + (sweep > gap * 2 ? gap / 2 : 0);
    const a1 = a0 + Math.min(trimmed, Math.PI * 2 - 0.0001);
    arcs.push({ key, d: `M ${point(a0)} A ${r} ${r} 0 ${a1 - a0 > Math.PI ? 1 : 0} 1 ${point(a1)}` });
    start += sweep;
  }
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} aria-hidden="true" className="absolute inset-0">
        <circle cx={c} cy={c} r={r} fill="none" strokeWidth={stroke} style={{ stroke: "rgb(var(--c-surface-container-high))" }} />
        {arcs.map((a) => (
          <path key={a.key} d={a.d} fill="none" strokeWidth={stroke} strokeLinecap="round" style={{ stroke: `rgb(var(${MACRO_COLOR[a.key]}))` }} />
        ))}
      </svg>
      <div className="absolute inset-0 grid place-items-center text-center">
        <span>
          <span className="block text-headline-md font-extrabold" dir="ltr">
            {kcalNumber(n.calories)}
          </span>
          <span className="block text-label-sm text-on-surface-variant">{t("recipes.nut.kcal")}</span>
        </span>
      </div>
    </div>
  );
}

/** MacroBar: dot 10 · label (flex 3) · grams w800 (flex 2) · 34 px percent; then a 10 px track. */
function MacroBar({ label, grams: g, share, color }: { label: string; grams: string; share: number; color: string }) {
  const progress = useDrawIn(500);
  return (
    <div>
      <div className="flex items-center">
        <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: `rgb(var(${color}))` }} aria-hidden="true" />
        <span className="ms-2 min-w-0 flex-[3] truncate text-label-md">{label}</span>
        <span className="ms-1 min-w-0 flex-[2] truncate text-end text-label-md font-extrabold" dir="auto">
          {g}
        </span>
        <span className="ms-2 w-[34px] shrink-0 text-end text-label-sm text-on-surface-variant" dir="ltr">
          {Math.round(share * 100)}%
        </span>
      </div>
      <div className="mt-1 h-2.5 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
        <div className="h-full rounded-full" style={{ width: `${Math.max(0, Math.min(1, share)) * progress * 100}%`, background: `rgb(var(${color}))` }} />
      </div>
    </div>
  );
}

function MacroRingWithBars({ n }: { n: Nutrition }) {
  const { t } = useI18n();
  const box = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(302);
  useLayoutEffect(() => {
    const el = box.current;
    if (!el) return;
    const apply = () => setWidth(el.clientWidth || 302);
    apply();
    const ro = new ResizeObserver(apply);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const ring = Math.min(120, width * 0.34);
  const shares = sharesOf(n);
  const rows: [MacroKey, string, number][] = [
    ["protein", t("recipes.nut.protein"), n.proteinGrams],
    ["carbs", t("recipes.nut.carbs"), n.carbsGrams],
    ["fat", t("recipes.nut.fat"), n.fatGrams],
  ];
  return (
    <div ref={box} className="flex items-center gap-4">
      <MacroRing n={n} size={ring} stroke={12 * (ring / 120)} />
      <dl className="min-w-0 flex-1 space-y-3">
        {rows.map(([key, label, value]) => (
          <div key={key}>
            <dt className="sr-only">{label}</dt>
            <dd>
              <MacroBar label={label} grams={grams(t, value)} share={shares[key]} color={MACRO_COLOR[key]} />
            </dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

/** NutritionFactsCard: r24 p24, underlined header, per-serving / whole-recipe pills, the ring with bars, the estimate. */
export function PhoneNutritionCard({ nutrition, servings, estimating, onEstimate }: { nutrition: Nutrition | null; servings: number | null; estimating: boolean; onEstimate: (() => void) | null }) {
  const { t } = useI18n();
  const [whole, setWhole] = useState(false);
  const canScale = servings !== null && servings > 1;
  const n = nutrition ? (whole && canScale ? scaledNutrition(nutrition, servings as number) : nutrition) : null;
  return (
    <ClayCard radius={24} padding={24} as="section" aria-labelledby="nut-h">
      <SectionHeader id="nut-h" title={t("recipes.nut.title")} trailing={n && !canScale ? <span className="text-label-md text-on-surface-variant">{t("recipes.nut.perServing")}</span> : null} />
      {n && canScale ? (
        <>
          <div className="mt-3 flex gap-2" role="group" aria-label={t("recipes.nut.title")}>
            {[false, true].map((w) => (
              <button
                key={String(w)}
                type="button"
                aria-pressed={whole === w}
                onClick={() => setWhole(w)}
                className={`press flex-1 rounded-full border py-2 text-center text-label-md transition-colors duration-[180ms] ${whole === w ? "border-primary bg-primary text-on-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
              >
                {w ? t("recipes.nut.perRecipe") : t("recipes.nut.perServing")}
              </button>
            ))}
          </div>
          {whole ? <p className="mt-1 text-center text-label-sm text-on-surface-variant">{t("recipes.nut.perRecipeServings", { count: servings as number })}</p> : null}
        </>
      ) : null}
      <div className="mt-4">
        {n ? (
          <>
            <MacroRingWithBars n={n} />
            {onEstimate ? (
              <div className="mt-3 flex justify-end">
                <button type="button" onClick={onEstimate} disabled={estimating} aria-busy={estimating || undefined} className="press inline-flex min-h-10 items-center gap-2 rounded-full px-3 text-label-md text-primary disabled:text-outline-variant">
                  <Icon name="refresh" size={16} />
                  {estimating ? t("recipes.nut.estimating") : t("recipes.nut.estimate")}
                </button>
              </div>
            ) : null}
          </>
        ) : (
          <>
            <div className="flex items-start gap-3">
              <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
                <Icon name="auto_awesome" size={24} />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-body-md">{t("recipes.nut.none")}</p>
                <p className="mt-1 text-label-md text-on-surface-variant">{t("recipes.nut.noneHint")}</p>
              </div>
            </div>
            {onEstimate ? (
              <ClayButton icon="auto_awesome" expanded className="mt-4" onClick={onEstimate} disabled={estimating}>
                {estimating ? t("recipes.nut.estimating") : t("recipes.nut.estimate")}
              </ClayButton>
            ) : null}
          </>
        )}
      </div>
    </ClayCard>
  );
}
