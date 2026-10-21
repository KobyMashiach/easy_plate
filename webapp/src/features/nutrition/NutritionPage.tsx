// The week of a meal plan as numbers (nutrition_dashboard_page.dart): the
// daily average and the week total up top, a bar per day split by macro
// (tap one for its line), the week's calorie split, then each meal. The app
// opens it from a plan; here the plan is chosen at the top (?plan=<id>).
import { useMemo } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { PageTitle } from "../../components/ui";
import { macroShares, planNutrition, type DayNutrition, type PlanNutrition } from "../../models/mealPlan";
import { usePlans } from "../plans/plansStore";
import { useDayNames } from "../plans/days";
import { EmptyState, ErrorState, LoadingState } from "../library/shared/components";
import { useRecipes } from "../library/shared/hooks";
import { MACROS, MacroLegend, MacroRing, MissingNote, useKcal } from "./widgets";
import { kcalNumber, PhoneMacroRingWithBars, PhoneMissingNote } from "./widgets";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneBar } from "../../components/PhoneBar";
import { ClayButton, PageHeader } from "../../components/clay";
import { useWeekdayLabels } from "../plans/PhonePlanBoard";

export function NutritionPage() {
  const { t } = useI18n();
  const { user } = useAuth();
  const [params, setParams] = useSearchParams();
  const { plans, error } = usePlans(user?.uid);
  const recipes = useRecipes(user?.uid);
  const planId = params.get("plan");
  const dayParam = params.get("day");
  const selectedDay = dayParam !== null && /^[0-6]$/.test(dayParam) ? Number(dayParam) : null;

  // The plan asked for, else the newest one.
  const plan = plans ? plans.find((p) => p.id === planId) ?? plans[plans.length - 1] ?? null : null;
  const week = useMemo(() => (plan ? planNutrition(plan, recipes.byId) : null), [plan, recipes.byId]);

  const phone = useIsPhone();
  const navigate = useNavigate();

  const set = (key: string, value: string | null) => {
    const next = new URLSearchParams(params);
    if (value === null) next.delete(key);
    else next.set(key, value);
    setParams(next, { replace: true });
  };

  // Below lg: the app's pushed dashboard (nutrition_dashboard_page.dart),
  // opened from a plan; the bar says "דאשבורד תזונה", back goes to the plan.
  if (phone)
    return (
      <>
        <PhoneBar title={t("nutrition.dashboard")} back={plan ? `/plans/${encodeURIComponent(plan.id)}` : "/plans"} />
        {(error && !plans) || (recipes.error && recipes.list === null) ? (
          <ErrorState />
        ) : plans === null || recipes.list === null ? (
          <LoadingState />
        ) : !plan || !week ? (
          <EmptyState
            icon="plans"
            phoneIcon="insights"
            message={t("nutrition.noPlans")}
            action={
              <ClayButton onClick={() => navigate("/plans")}>{t("nutrition.toPlans")}</ClayButton>
            }
          />
        ) : (
          <PhoneDashboard name={plan.name || t("library.ui.untitled")} week={week} selectedDay={selectedDay} onSelectDay={(d) => set("day", d === null ? null : String(d))} />
        )}
      </>
    );

  return (
    <>
      <PageTitle title={t("nutrition.dashboard")} lead={plan ? `${plan.name} · ${t("nutrition.weekly")}` : undefined} />
      {(error && !plans) || (recipes.error && recipes.list === null) ? (
        <ErrorState />
      ) : plans === null || recipes.list === null ? (
        <LoadingState />
      ) : plans.length === 0 || !plan || !week ? (
        <EmptyState
          icon="plans"
          message={t("nutrition.noPlans")}
          action={
            <Link to="/plans" className="clay-btn-primary">
              {t("nutrition.toPlans")}
            </Link>
          }
        />
      ) : (
        <>
          {plans.length > 1 ? (
            <div className="mb-5 flex flex-wrap gap-2" role="group" aria-label={t("nutrition.choosePlan")}>
              {plans.map((p) => (
                <button
                  key={p.id}
                  type="button"
                  aria-pressed={p.id === plan.id}
                  onClick={() => {
                    const next = new URLSearchParams(params);
                    next.set("plan", p.id);
                    next.delete("day");
                    setParams(next, { replace: true });
                  }}
                  className={`rounded-full border px-4 py-1.5 text-label-md transition-colors ${p.id === plan.id ? "border-primary bg-primary-fixed text-primary" : "border-outline-variant bg-surface-low text-on-surface-variant hover:bg-surface-container"}`}
                >
                  {p.name || t("library.ui.untitled")}
                </button>
              ))}
            </div>
          ) : null}
          <Dashboard week={week} selectedDay={selectedDay} onSelectDay={(d) => set("day", d === null ? null : String(d))} planHref={`/plans/${encodeURIComponent(plan.id)}`} />
        </>
      )}
    </>
  );
}

function Dashboard({ week, selectedDay, onSelectDay, planHref }: { week: PlanNutrition; selectedDay: number | null; onSelectDay: (d: number | null) => void; planHref: string }) {
  const { t } = useI18n();
  const kcal = useKcal();
  const days = useDayNames();

  if (!week.hasData)
    return (
      <EmptyState
        icon="nutrition"
        message={t("nutrition.noPlanned")}
        action={
          <Link to={planHref} className="clay-btn-primary">
            {t("nutrition.openPlan")}
          </Link>
        }
      />
    );

  const selected = selectedDay === null ? null : week.days[selectedDay];
  return (
    <div className="grid gap-4 lg:grid-cols-2 xl:grid-cols-3">
      <div className="grid grid-cols-2 gap-4 lg:col-span-2 xl:col-span-3 xl:grid-cols-4">
        <Hero caption={t("nutrition.dailyAverage")} value={kcal(week.dailyAverage.calories)} unit={t("nutrition.kcalPerDay")} filled />
        <Hero caption={t("nutrition.weekTotal")} value={kcal(week.weekTotal.calories)} unit={t("nutrition.kcal")} />
        <Hero caption={t("nutrition.plannedDays")} value={String(week.plannedDays)} unit={t("nutrition.ofSeven")} className="hidden xl:block" />
        <Hero caption={t("nutrition.proteinPerDay")} value={String(Math.round(week.dailyAverage.proteinGrams))} unit={t("nutrition.gramsPerDay")} className="hidden xl:block" />
      </div>

      <section className="clay p-5 lg:col-span-2" aria-labelledby="per-day-h">
        <div className="mb-4 flex items-center justify-between gap-2">
          <h2 id="per-day-h" className="text-body-lg font-bold">
            {t("nutrition.perDay")}
          </h2>
          <Link to={planHref} className="text-label-md text-primary hover:underline">
            {t("nutrition.openPlan")}
          </Link>
        </div>
        <WeekBars week={week} labels={days.short} selected={selectedDay} onSelect={(d) => onSelectDay(selectedDay === d ? null : d)} />
        {selected ? <DayLine day={selected} label={days.long[selected.weekday]} /> : <p className="mt-3 text-label-sm text-on-surface-variant">{t("nutrition.tapDay")}</p>}
      </section>

      <section className="clay p-5" aria-labelledby="split-h">
        <h2 id="split-h" className="mb-4 text-body-lg font-bold">
          {t("nutrition.macroSplit")}
        </h2>
        <div className="flex flex-col items-center gap-5 sm:flex-row lg:flex-col">
          <MacroRing nutrition={week.dailyAverage} size={140} thickness={15} />
          <MacroLegend nutrition={week.dailyAverage} bars />
        </div>
        <p className="mt-3 text-label-sm text-on-surface-variant">{t("nutrition.dailyAverage")}</p>
      </section>

      <section className="clay p-5 lg:col-span-2 xl:col-span-3" aria-labelledby="per-meal-h">
        <h2 id="per-meal-h" className="mb-3 text-body-lg font-bold">
          {t("nutrition.perMeal")}
        </h2>
        <ul className="grid gap-x-8 gap-y-1 md:grid-cols-2 xl:grid-cols-3">
          {week.days.flatMap((day) =>
            day.hasData
              ? day.meals
                  .filter((m) => m.countedItems > 0)
                  .map((m) => (
                    <li key={m.meal.id} className="flex items-center gap-3 border-b border-outline-variant/40 py-1.5">
                      <span className="w-14 shrink-0 text-label-sm text-on-surface-variant">{days.short[day.weekday]}</span>
                      <span className="min-w-0 flex-1 truncate text-label-md">{m.meal.name}</span>
                      <span className="text-label-md font-extrabold">
                        {kcal(m.total.calories)} {t("nutrition.kcal")}
                      </span>
                    </li>
                  ))
              : [],
          )}
        </ul>
        {week.missingItems > 0 ? (
          <div className="mt-3">
            <MissingNote count={week.missingItems} />
          </div>
        ) : null}
      </section>
    </div>
  );
}

function Hero({ caption, value, unit, filled = false, className = "" }: { caption: string; value: string; unit: string; filled?: boolean; className?: string }) {
  return (
    <div className={`rounded-md p-4 ${filled ? "bg-primary text-on-primary shadow-button" : "border-[1.5px] border-warm-accent/60 bg-surface-lowest"} ${className}`}>
      <p className={`text-label-sm ${filled ? "opacity-85" : "text-on-surface-variant"}`}>{caption}</p>
      <p className="mt-2 text-headline-lg font-extrabold leading-none">{value}</p>
      <p className={`text-label-md ${filled ? "opacity-85" : "text-on-surface-variant"}`}>{unit}</p>
    </div>
  );
}

/** Seven stacked bars, each split by macro calorie share; the tallest is the peak. */
function WeekBars({ week, labels, selected, onSelect }: { week: PlanNutrition; labels: string[]; selected: number | null; onSelect: (d: number) => void }) {
  const { t } = useI18n();
  const kcal = useKcal();
  return (
    <div className="flex h-56 items-stretch gap-2 sm:gap-3">
      {week.days.map((day) => {
        const shares = macroShares(day.total);
        const h = day.hasData ? Math.max(0.06, Math.min(1, day.total.calories / week.peakCalories)) : 0.06;
        const on = selected === day.weekday;
        const dim = selected !== null && !on;
        return (
          <button
            key={day.weekday}
            type="button"
            aria-pressed={on}
            onClick={() => onSelect(day.weekday)}
            aria-label={day.hasData ? t("nutrition.barLabel", { day: labels[day.weekday], n: kcal(day.total.calories) }) : `${labels[day.weekday]} · ${t("nutrition.noPlanned")}`}
            className={`flex min-w-0 flex-1 flex-col items-center gap-1 rounded-md transition-opacity ${dim ? "opacity-40" : ""}`}
          >
            <span className={`text-[10px] leading-none ${on ? "font-bold text-primary" : "text-on-surface-variant"}`}>{day.hasData ? kcal(day.total.calories) : " "}</span>
            <span className="flex w-full flex-1 items-end">
              <span className="flex w-full flex-col overflow-hidden rounded-std transition-[height] duration-500 ease-out motion-reduce:transition-none" style={{ height: `${h * 100}%` }}>
                {day.hasData ? (
                  (["fat", "carbs", "protein"] as const).map((k) => {
                    const m = MACROS.find((x) => x.key === k)!;
                    return shares[k] > 0 ? <span key={k} className={m.bg} style={{ flexGrow: shares[k] }} /> : null;
                  })
                ) : (
                  <span className="flex-1 bg-surface-high" />
                )}
              </span>
            </span>
            <span className={`w-full truncate text-center text-label-sm ${on ? "font-extrabold text-primary" : "text-on-surface-variant"}`}>{labels[day.weekday]}</span>
          </button>
        );
      })}
    </div>
  );
}

function DayLine({ day, label }: { day: DayNutrition; label: string }) {
  const { t } = useI18n();
  const kcal = useKcal();
  return (
    <div className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-1 rounded-std bg-primary-fixed px-4 py-3 text-on-primary-fixed" aria-live="polite">
      <span className="text-label-md font-extrabold">{label}</span>
      <span className="flex-1" />
      {!day.hasData ? (
        <span className="text-label-sm">{t("nutrition.noPlanned")}</span>
      ) : (
        <>
          <span className="text-label-md">
            {kcal(day.total.calories)} {t("nutrition.kcal")}
          </span>
          {MACROS.map((m) => (
            <span key={m.key} className="inline-flex items-center gap-1 text-label-sm">
              <span className={`h-2 w-2 rounded-full ${m.bg}`} aria-hidden="true" />
              {t(m.label)} {t("nutrition.grams", { n: Math.round(m.grams(day.total)) })}
            </span>
          ))}
          {day.missingItems > 0 ? <MissingNote count={day.missingItems} /> : null}
        </>
      )}
    </div>
  );
}


// ---------------------------------------------------------------------------
// Below lg (nutrition_dashboard_page.dart).

function PhoneDashboard({ name, week, selectedDay, onSelectDay }: { name: string; week: PlanNutrition; selectedDay: number | null; onSelectDay: (d: number | null) => void }) {
  const { t } = useI18n();
  const labels = useWeekdayLabels();
  const selected = selectedDay === null ? null : week.days[selectedDay];
  return (
    <div className="-mt-0 pb-6">
      <PageHeader title={name} subtitle={t("nutrition.weekly")} />
      {!week.hasData ? (
        <EmptyState icon="nutrition" phoneIcon="insights" message={t("nutrition.noPlanned")} />
      ) : (
        <>
          <div className="mt-4 grid grid-cols-2 gap-3">
            <PhoneHero caption={t("nutrition.dailyAverage")} value={kcalNumber(week.dailyAverage.calories)} unit={t("nutrition.kcalPerDay")} filled />
            <PhoneHero caption={t("nutrition.weekTotal")} value={kcalNumber(week.weekTotal.calories)} unit={t("nutrition.kcal")} />
          </div>
          <section className="clay-card mt-4 p-4" style={{ borderRadius: 24 }} aria-labelledby="per-day-h">
            <h2 id="per-day-h" className="text-headline-md">
              {t("nutrition.perDay")}
            </h2>
            <PhoneWeekBars week={week} labels={labels} selected={selectedDay} onSelect={(d) => onSelectDay(selectedDay === d ? null : d)} />
            {selected ? <PhoneDayLine day={selected} label={labels[selected.weekday]} /> : null}
          </section>
          <section className="clay-card mt-4 p-4" style={{ borderRadius: 24 }} aria-labelledby="split-h">
            <h2 id="split-h" className="text-headline-md">
              {t("nutrition.macroSplit")}
            </h2>
            <div className="mt-4">
              <PhoneMacroRingWithBars nutrition={week.dailyAverage} ringSize={128} thickness={14} />
            </div>
            <p className="mt-2 text-label-sm text-on-surface-variant">{t("nutrition.dailyAverage")}</p>
          </section>
          <section className="clay-card mt-4 p-4" style={{ borderRadius: 24 }} aria-labelledby="per-meal-h">
            <h2 id="per-meal-h" className="text-headline-md">
              {t("nutrition.perMeal")}
            </h2>
            <ul className="mt-3">
              {week.days.flatMap((day) =>
                day.hasData
                  ? day.meals
                      .filter((m) => m.countedItems > 0)
                      .map((m) => (
                        <li key={m.meal.id} className="flex items-center py-1">
                          <span className="w-11 shrink-0 truncate text-label-sm text-on-surface-variant">{labels[day.weekday]}</span>
                          <span className="min-w-0 flex-1 truncate text-label-md">{m.meal.name}</span>
                          <span className="text-label-md font-extrabold">
                            {kcalNumber(m.total.calories)} {t("nutrition.kcal")}
                          </span>
                        </li>
                      ))
                  : [],
              )}
            </ul>
          </section>
          {week.missingItems > 0 ? (
            <div className="mt-3">
              <PhoneMissingNote count={week.missingItems} />
            </div>
          ) : null}
        </>
      )}
    </div>
  );
}

/** _HeroFigure: padding 16, r24; filled primary, or white with a 1.5 px warm-accent @ 50 % rim. */
function PhoneHero({ caption, value, unit, filled = false }: { caption: string; value: string; unit: string; filled?: boolean }) {
  return (
    <div className={`rounded-md p-4 ${filled ? "bg-primary text-on-primary" : "border-[1.5px] border-warm-accent/50 bg-surface-lowest text-on-surface"}`}>
      <p className="text-label-sm opacity-80">{caption}</p>
      <p className="mt-2 text-headline-lg-mobile font-extrabold">
        <bdi>{value}</bdi>
      </p>
      <p className="text-label-md opacity-80">{unit}</p>
    </div>
  );
}

/** _WeekBars: seven bars 8 apart in 168 px, fat / carbs / protein top to bottom, radius 8, min 6 %. */
function PhoneWeekBars({ week, labels, selected, onSelect }: { week: PlanNutrition; labels: string[]; selected: number | null; onSelect: (d: number) => void }) {
  const { t } = useI18n();
  return (
    <div className="mt-4 flex h-[168px] items-end gap-2">
      {week.days.map((day) => {
        const shares = macroShares(day.total);
        const h = day.hasData ? Math.max(0.06, Math.min(1, day.total.calories / week.peakCalories)) : 0.06;
        const on = selected === day.weekday;
        const dim = selected !== null && !on;
        return (
          <button
            key={day.weekday}
            type="button"
            aria-pressed={on}
            onClick={() => onSelect(day.weekday)}
            aria-label={day.hasData ? t("nutrition.barLabel", { day: labels[day.weekday], n: kcalNumber(day.total.calories) }) : `${labels[day.weekday]} · ${t("nutrition.noPlanned")}`}
            className="flex h-full min-w-0 flex-1 flex-col items-center justify-end"
          >
            {day.hasData ? <span className={`text-[10px] font-bold leading-4 tracking-[.03em] ${on ? "text-primary" : "text-on-surface-variant"}`}>{kcalNumber(day.total.calories)}</span> : null}
            <span className={`mt-1 flex w-full flex-1 items-end transition-opacity duration-[180ms] ${dim ? "opacity-40" : ""}`}>
              <span className="flex w-full flex-col overflow-hidden rounded-sm transition-[height] duration-500 ease-out motion-reduce:transition-none" style={{ height: `${h * 100}%` }}>
                {day.hasData ? (
                  (["fat", "carbs", "protein"] as const).map((k) => {
                    const m = MACROS.find((x) => x.key === k)!;
                    return shares[k] > 0 ? <span key={k} className={m.bg} style={{ flexGrow: shares[k], flexBasis: 0 }} /> : null;
                  })
                ) : (
                  <span className="flex-1 bg-surface-high" />
                )}
              </span>
            </span>
            <span className={`mt-2 w-full truncate text-center text-label-sm ${on ? "font-extrabold text-primary" : "font-semibold text-on-surface-variant"}`}>{labels[day.weekday]}</span>
          </button>
        );
      })}
    </div>
  );
}

/** _DayLine: primaryFixed r16 p12 — the day, its calories, the three macros' grams. */
function PhoneDayLine({ day, label }: { day: DayNutrition; label: string }) {
  const { t } = useI18n();
  return (
    <div className="mt-4 flex items-center rounded-std bg-primary-fixed p-3" aria-live="polite">
      <span className="text-label-md font-extrabold text-on-primary-fixed">{label}</span>
      <span className="flex-1" />
      {!day.hasData ? (
        <span className="text-label-sm text-on-primary-fixed-variant">{t("nutrition.noPlanned")}</span>
      ) : (
        <>
          <span className="text-label-md text-on-primary-fixed">
            {kcalNumber(day.total.calories)} {t("nutrition.kcal")}
          </span>
          {MACROS.map((m) => (
            <span key={m.key} className="ms-2 inline-flex items-center gap-[3px] text-label-sm text-on-primary-fixed-variant">
              <span className={`h-2 w-2 rounded-full ${m.bg}`} aria-hidden="true" />
              {t("nutrition.grams", { n: Math.round(m.grams(day.total)) })}
            </span>
          ))}
        </>
      )}
    </div>
  );
}
