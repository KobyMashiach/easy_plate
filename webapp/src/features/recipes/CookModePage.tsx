// /cook/:id and /cook/community/:postId (bare) — CookModePage (a community
// recipe cooks straight from the post, read-only, as the app does): one step at a time in large type, the
// screen kept awake (Screen Wake Lock), the ingredients the step mentions
// under it, and a timer on every step that names a duration (ff_cook_timers)
// with all running timers pinned in a strip. Steps move with the buttons,
// the arrow keys (reading direction aware) and a swipe. A finished timer
// rings (Web Audio) and, with permission asked once, sends a notification.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useAccess } from "../../lib/flags";
import { useI18n } from "../../lib/i18n";
import { FeatureGate } from "../../components/FeatureGate";
import { Protected } from "../../components/Protected";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { AppDialog } from "../../components/AppDialog";
import { BottomSheet } from "../../components/BottomSheet";
import { ClayButton, ClayCard, ClayIconButton, EmptyState, LoadingSpinner, ProgressGroove, RoundCheckbox } from "../../components/clay";
import { useIsPhone } from "../../components/useIsPhone";
import { SectionHeader } from "./components/phone";
import type { Ingredient } from "../../models/recipe";
import { Modal } from "./components/Modal";
import { progressOf, remainingOf, useCookSession, type CookTimer } from "./lib/cookSession";
import { ingredientLine, quantityLabel } from "./lib/format";
import { formatClock } from "./lib/stepDuration";
import { useRecipe } from "./lib/useRecipe";
import { useSharedRecipe } from "../community/data/useSharedRecipe";

const NOTIFY_ASKED = "ep-cook-notify-asked";

/** Three short beeps, without any audio file. */
function ring() {
  try {
    const Ctx = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctx) return;
    const ctx = new Ctx();
    [0, 0.35, 0.7].forEach((at) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.value = 880;
      gain.gain.setValueAtTime(0.0001, ctx.currentTime + at);
      gain.gain.exponentialRampToValueAtTime(0.4, ctx.currentTime + at + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + at + 0.28);
      osc.connect(gain).connect(ctx.destination);
      osc.start(ctx.currentTime + at);
      osc.stop(ctx.currentTime + at + 0.3);
    });
    setTimeout(() => void ctx.close(), 1500);
  } catch (_) {
    /* no audio */
  }
}

/** The ingredients whose name (or a 4+ letter first word of it) the step mentions. */
function ingredientsIn(step: string, ingredients: Ingredient[]): Ingredient[] {
  const hay = step.toLowerCase();
  return ingredients.filter((i) => {
    const name = i.name.trim().toLowerCase();
    if (name.length < 3) return false;
    if (hay.includes(name)) return true;
    const head = name.split(/\s+/)[0];
    return head.length >= 4 && hay.includes(head);
  });
}

/** `community`: the route names a shared_recipes post, not one of this account's recipes. */
export function CookModePage({ community = false }: { community?: boolean }) {
  return (
    <FeatureGate flag="ff_cook_mode" page>
      <CookMode community={community} />
    </FeatureGate>
  );
}

function CookMode({ community }: { community: boolean }) {
  const { id: ownId, postId } = useParams();
  const { t, dir } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const own = useRecipe(community ? undefined : ownId);
  const shared = useSharedRecipe(community ? postId : undefined);
  const { recipe, error } = community ? shared : own;
  const id = community ? postId : ownId;
  const timersOn = useAccess("ff_cook_timers") === "enabled";
  const phone = useIsPhone();

  const [showIngredients, setShowIngredients] = useState(false);
  const [done, setDone] = useState<Set<number>>(new Set());
  const [finished, setFinished] = useState(false);
  const [wakeOk, setWakeOk] = useState<boolean | null>(null);
  const [announce, setAnnounce] = useState("");

  const onTimeUp = useCallback(
    (step: number) => {
      ring();
      const msg = `${t("recipes.cook.stepLabel", { n: step + 1 })} · ${t("recipes.cook.timeUp")}`;
      setAnnounce(msg);
      try {
        if ("Notification" in window && Notification.permission === "granted") {
          new Notification(t("recipes.cook.notifyTitle", { recipe: recipe?.title ?? "" }), { body: t("recipes.cook.timeUpBody", { n: step + 1 }), tag: `cook-${id}-${step}` });
        }
      } catch (_) {
        /* notifications unavailable (e.g. some mobile browsers need a service worker) */
      }
    },
    [t, recipe?.title, id],
  );

  const { state, now, setStep, toggleTimer, resetTimer, finish } = useCookSession(recipe, onTimeUp);
  const total = recipe?.steps.length ?? 0;
  const index = state?.stepIndex ?? 0;
  const isLast = index === total - 1;

  // Keep the screen on while cooking; re-acquired when the tab comes back.
  useEffect(() => {
    const nav = navigator as Navigator & { wakeLock?: { request: (type: "screen") => Promise<{ release: () => Promise<void> }> } };
    if (!nav.wakeLock) {
      setWakeOk(false);
      return;
    }
    let lock: { release: () => Promise<void> } | null = null;
    let live = true;
    const acquire = async () => {
      if (document.visibilityState !== "visible") return;
      try {
        const l = await nav.wakeLock!.request("screen");
        if (!live) {
          void l.release();
          return;
        }
        lock = l;
        setWakeOk(true);
      } catch (_) {
        setWakeOk(false);
      }
    };
    void acquire();
    const onVis = () => void acquire();
    document.addEventListener("visibilitychange", onVis);
    return () => {
      live = false;
      document.removeEventListener("visibilitychange", onVis);
      if (lock) void lock.release().catch(() => {});
    };
  }, []);

  const go = useCallback((i: number) => setStep(i), [setStep]);
  const next = useCallback(() => (isLast ? setFinished(true) : go(index + 1)), [isLast, go, index]);
  const prev = useCallback(() => go(index - 1), [go, index]);

  // Arrow keys follow the reading direction: in Hebrew "next" is to the left.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (finished || e.altKey || e.ctrlKey || e.metaKey) return;
      const target = e.target as HTMLElement | null;
      if (target && (target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName))) return;
      const forward = dir === "rtl" ? "ArrowLeft" : "ArrowRight";
      const back = dir === "rtl" ? "ArrowRight" : "ArrowLeft";
      if (e.key === forward || e.key === "PageDown") {
        e.preventDefault();
        if (index < total - 1) go(index + 1);
      } else if (e.key === back || e.key === "PageUp") {
        e.preventDefault();
        if (index > 0) go(index - 1);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [dir, index, total, go, finished]);

  // Swipe: a mostly horizontal drag of 60px or more, in the reading direction.
  const touch = useRef<{ x: number; y: number } | null>(null);
  const onPointerDown = (e: React.PointerEvent) => {
    if (e.pointerType === "mouse") return;
    touch.current = { x: e.clientX, y: e.clientY };
  };
  const onPointerUp = (e: React.PointerEvent) => {
    const start = touch.current;
    touch.current = null;
    if (!start) return;
    const dx = e.clientX - start.x;
    const dy = e.clientY - start.y;
    if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy) * 1.5) return;
    const forward = dir === "rtl" ? dx > 0 : dx < 0;
    if (forward && index < total - 1) go(index + 1);
    if (!forward && index > 0) go(index - 1);
  };

  const startTimer = (i: number) => {
    // Asked once, from the first tap on a timer (a user gesture, as browsers require).
    try {
      if ("Notification" in window && Notification.permission === "default" && !localStorage.getItem(NOTIFY_ASKED)) {
        localStorage.setItem(NOTIFY_ASKED, "1");
        void Notification.requestPermission();
      }
    } catch (_) {
      /* storage or notifications unavailable */
    }
    toggleTimer(i);
  };

  const activeTimers = useMemo(
    () =>
      state && timersOn
        ? Object.entries(state.timers)
            .map(([k, v]) => [Number(k), v] as [number, CookTimer])
            .filter(([, v]) => v.endsAtMs !== null || v.finished)
            .sort((a, b) => a[0] - b[0])
        : [],
    [state, timersOn],
  );

  const exitTo = community ? `/community/recipe/${id}` : `/recipes/${id}`;
  const onFinishDone = () => {
    finish();
    navigate(exitTo);
  };

  if (!user) return null;
  if (recipe === undefined && !error && phone)
    return (
      <main className="grid min-h-dvh place-items-center bg-background">
        <LoadingSpinner label={t("common.loading")} />
      </main>
    );
  if (recipe === undefined && !error)
    return (
      <main className="grid min-h-dvh place-items-center">
        <Spinner label={t("common.loading")} />
      </main>
    );
  if (!recipe)
    return (
      <main className="grid min-h-dvh place-items-center p-6">
        <div className="clay max-w-md space-y-4 p-8 text-center" role={error ? "alert" : undefined}>
          <p>{shared.blocked ? t("community.ui.quotaReached") : error ? t("recipes.loadFailed") : community ? t("community.recipeUnavailable") : t("recipes.notFound")}</p>
          {community ? (
            <Link to={shared.blocked ? "/pricing" : "/community"} className="clay-btn-tonal">
              {shared.blocked ? t("sharing.code.upgrade") : t("common.back")}
            </Link>
          ) : (
            <Link to="/recipes" className="clay-btn-tonal">
              {t("recipes.backToRecipes")}
            </Link>
          )}
        </div>
      </main>
    );

  const who = user.email || user.phoneNumber || user.uid;
  const step = recipe.steps[index] ?? "";
  const timer = state?.timers[index];
  const inStep = ingredientsIn(step, recipe.ingredients);

  if (phone) {
    const toggleDone = (i: number) =>
      setDone((s) => {
        const n = new Set(s);
        if (!n.delete(i)) n.add(i);
        return n;
      });
    return (
      <div className="flex min-h-dvh flex-col bg-background text-on-surface">
        {/* ClayTopAppBar: close · "מצב בישול" · ingredients · the finish pill. */}
        <header className="fixed inset-x-0 top-0 z-40 border-b border-surface-highest bg-surface-lowest pt-[env(safe-area-inset-top)] shadow-control">
          <div className="flex h-[68px] items-center px-5">
            <ClayIconButton icon="close" label={t("recipes.cook.exit")} to={exitTo} />
            <h1 className="ms-3 min-w-0 flex-1 truncate text-headline-md text-primary">{t("recipes.cook.title")}</h1>
            {recipe.ingredients.length ? (
              <ClayIconButton icon="format_list_bulleted" label={t("recipes.cook.ingredients")} onClick={() => setShowIngredients(true)} className="ms-2" iconClassName="rtl:-scale-x-100" />
            ) : null}
            <button
              type="button"
              onClick={() => setFinished(true)}
              disabled={total === 0}
              className="press ms-2 inline-flex shrink-0 items-center gap-1 rounded-full bg-secondary-container px-3 py-2 text-label-md text-on-secondary-container disabled:bg-surface-container disabled:text-outline"
            >
              <Icon name="check" size={18} />
              {t("recipes.cook.finish")}
            </button>
          </div>
        </header>
        <div aria-hidden="true" style={{ height: "calc(68px + env(safe-area-inset-top))" }} />

        <p className="sr-only" aria-live="assertive">
          {announce}
        </p>

        {total === 0 ? (
          <main className="grid flex-1 place-items-center">
            <EmptyState icon="restaurant" message={t("recipes.cook.noSteps")} />
          </main>
        ) : (
          <Protected who={who}>
            <div className="px-5 pt-4">
              <div className="flex items-center gap-1">
                <span className="min-w-0 flex-1 text-label-md text-on-surface-variant" aria-live="polite">
                  {t("recipes.cook.stepOf", { n: index + 1, total })}
                </span>
                <Icon name="brightness_7" size={14} className="text-outline" />
                <span className="text-label-sm text-outline">{wakeOk === false ? t("recipes.cook.wakeLockOff") : t("recipes.cook.screenOn")}</span>
              </div>
              <div className="mt-2">
                <ProgressGroove value={(index + 1) / total} height={12} label={t("recipes.cook.progress")} />
              </div>
            </div>

            {activeTimers.length ? (
              <div className="px-5 pt-3">
                <ClayCard radius={24} padding={12} as="section" style={{ paddingInline: 16 }} aria-label={t("recipes.cook.runningTimers")}>
                  {activeTimers.map(([k, tm]) => (
                    <button key={k} type="button" onClick={() => go(k)} className="block w-full rounded-sm py-2 text-start">
                      <span className="flex items-center gap-2">
                        <Icon name={tm.finished ? "notifications_active" : "timer"} size={18} className={tm.finished ? "text-secondary" : "text-primary"} />
                        <span className="min-w-0 flex-1 truncate text-label-md text-on-surface-variant">
                          {t("recipes.cook.stepLabel", { n: k + 1 })}
                          {tm.finished ? ` · ${t("recipes.cook.timeUp")}` : ""}
                        </span>
                        <span className={`text-body-lg font-bold tabular-nums ${tm.finished ? "text-secondary" : "text-primary"}`} dir="ltr">
                          {formatClock(remainingOf(tm, now))}/{formatClock(tm.total)}
                        </span>
                      </span>
                      <span className="mt-2 block">
                        <ProgressGroove value={progressOf(tm, now)} height={8} />
                      </span>
                    </button>
                  ))}
                </ClayCard>
              </div>
            ) : null}

            <main className="flex-1 space-y-3 px-5 pb-[calc(100px+env(safe-area-inset-bottom))] pt-4" onPointerDown={onPointerDown} onPointerUp={onPointerUp} style={{ touchAction: "pan-y" }}>
              {timer && timersOn ? <PhoneTimerCard timer={timer} now={now} onToggle={() => startTimer(index)} onReset={() => resetTimer(index)} /> : null}

              <ClayCard radius={32} padding={24} as="article" aria-labelledby="cook-step" key={index}>
                <span className="grid h-11 w-11 place-items-center rounded-full bg-primary-fixed text-headline-md text-primary" aria-hidden="true">
                  {index + 1}
                </span>
                <p id="cook-step" className="mt-4 text-headline-md font-semibold leading-[1.4]">
                  {step}
                </p>
              </ClayCard>

              {inStep.length ? (
                <ClayCard radius={24} padding={16} as="section" aria-label={t("recipes.cook.inThisStep")}>
                  <p className="text-label-md text-on-surface-variant">{t("recipes.cook.inThisStep")}</p>
                  <ul className="mt-2 flex flex-wrap gap-2">
                    {inStep.map((ing, i) => (
                      <li key={i} className="inline-flex items-center gap-2 rounded-full border border-outline-variant bg-surface-low px-3 py-2">
                        <span className="text-body-lg font-bold text-primary">{quantityLabel(t, ing)}</span>
                        <span className="text-body-md">{ing.name}</span>
                      </li>
                    ))}
                  </ul>
                </ClayCard>
              ) : null}
            </main>

            <nav className="fixed inset-x-0 bottom-0 z-30 flex items-center gap-3 bg-background px-5 pb-[calc(16px+env(safe-area-inset-bottom))] pt-3" aria-label={t("recipes.cook.title")}>
              <ClayIconButton icon="arrow_back" size={56} label={t("recipes.cook.previous")} onClick={prev} disabled={index === 0} iconClassName="rtl:-scale-x-100" />
              <ClayButton expanded className="flex-1 rtl:[&_.mi]:-scale-x-100" icon={isLast ? "check" : "arrow_forward"} onClick={next}>
                {isLast ? t("recipes.cook.finish") : t("recipes.cook.next")}
              </ClayButton>
            </nav>
          </Protected>
        )}

        <BottomSheet open={showIngredients} onClose={() => setShowIngredients(false)} title={t("recipes.cook.ingredients")} showTitle={false}>
          <SectionHeader title={t("recipes.cook.ingredients")} />
          <ul className="mt-3 pb-7">
            {recipe.ingredients.map((ing, i) => {
              const checked = done.has(i);
              return (
                <li key={i} className="flex items-center gap-3 py-2">
                  <RoundCheckbox checked={checked} onChange={() => toggleDone(i)} label={ingredientLine(t, ing)} />
                  <button type="button" onClick={() => toggleDone(i)} className={`min-w-0 flex-1 text-start text-body-lg transition-colors duration-[180ms] ${checked ? "text-outline line-through" : ""}`} tabIndex={-1}>
                    {ingredientLine(t, ing)}
                  </button>
                </li>
              );
            })}
          </ul>
        </BottomSheet>

        <AppDialog
          open={finished}
          kind="success"
          icon="restaurant"
          title={t("recipes.cook.finishedTitle")}
          message={t("recipes.cook.finishedBody")}
          confirmLabel={t("recipes.done")}
          cancelLabel={null}
          onConfirm={onFinishDone}
          onCancel={() => setFinished(false)}
        />
      </div>
    );
  }

  return (
    <div className="flex min-h-dvh flex-col">
      <header className="sticky top-0 z-20 flex items-center gap-3 border-b border-outline-variant/40 bg-surface/95 px-4 py-3 backdrop-blur sm:px-6">
        <Link to={exitTo} className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-surface-lowest shadow-control" aria-label={t("recipes.cook.exit")} title={t("recipes.cook.exit")}>
          <Icon name="close" />
        </Link>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-body-lg font-bold">{recipe.title}</h1>
          <p className="text-label-sm text-on-surface-variant">{t("recipes.cook.title")}</p>
        </div>
        {recipe.ingredients.length ? (
          <button type="button" onClick={() => setShowIngredients((v) => !v)} aria-expanded={showIngredients} aria-controls="cook-ings" className="inline-flex items-center gap-2 rounded-full bg-surface-lowest px-4 py-2 text-label-md text-primary shadow-control lg:hidden">
            <Icon name="groceries" size={18} />
            {showIngredients ? t("recipes.cook.hideIngredients") : t("recipes.cook.ingredients")}
          </button>
        ) : null}
        <button type="button" onClick={() => setFinished(true)} disabled={total === 0} className="inline-flex items-center gap-1 rounded-full bg-secondary-container px-4 py-2 text-label-md text-on-secondary-container disabled:bg-surface-container disabled:text-outline">
          <Icon name="check" size={18} />
          {t("recipes.cook.finish")}
        </button>
      </header>

      <p className="sr-only" aria-live="assertive">
        {announce}
      </p>

      {total === 0 ? (
        <main className="grid flex-1 place-items-center p-6">
          <div className="clay max-w-md space-y-3 p-8 text-center">
            <Icon name="cook" size={40} className="mx-auto text-primary" />
            <p>{t("recipes.cook.noSteps")}</p>
          </div>
        </main>
      ) : (
        <Protected who={who}>
          <div className="mx-auto grid w-full max-w-[1400px] flex-1 gap-6 px-4 py-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_22rem] 2xl:max-w-[1760px] 2xl:grid-cols-[minmax(0,1fr)_28rem]">
            <main className="flex min-w-0 flex-col gap-4" onPointerDown={onPointerDown} onPointerUp={onPointerUp} style={{ touchAction: "pan-y" }}>
              <div>
                <div className="flex items-center gap-2 text-label-md text-on-surface-variant">
                  <span className="flex-1" aria-live="polite">
                    {t("recipes.cook.stepOf", { n: index + 1, total })}
                  </span>
                  <span className="inline-flex items-center gap-1 text-label-sm text-outline">
                    <Icon name="sun" size={14} />
                    {wakeOk === false ? t("recipes.cook.wakeLockOff") : t("recipes.cook.screenOn")}
                  </span>
                </div>
                <div className="mt-2 h-2 overflow-hidden rounded-full bg-surface-high" role="progressbar" aria-label={t("recipes.cook.progress")} aria-valuemin={1} aria-valuemax={total} aria-valuenow={index + 1}>
                  <div className="h-full rounded-full bg-primary transition-[width] duration-300" style={{ width: `${((index + 1) / total) * 100}%` }} />
                </div>
              </div>

              {activeTimers.length ? (
                <section className="clay divide-y divide-outline-variant/40 px-4 py-1" aria-label={t("recipes.cook.runningTimers")}>
                  {activeTimers.map(([k, tm]) => (
                    <button key={k} type="button" onClick={() => go(k)} className="block w-full py-2 text-start">
                      <span className="flex items-center gap-2">
                        <Icon name={tm.finished ? "inbox" : "timer"} size={18} className={tm.finished ? "text-secondary" : "text-primary"} />
                        <span className="flex-1 truncate text-label-md text-on-surface-variant">
                          {t("recipes.cook.stepLabel", { n: k + 1 })}
                          {tm.finished ? ` · ${t("recipes.cook.timeUp")}` : ""}
                        </span>
                        <span className={`text-body-lg font-bold tabular-nums ${tm.finished ? "text-secondary" : "text-primary"}`} dir="ltr">
                          {formatClock(remainingOf(tm, now))}/{formatClock(tm.total)}
                        </span>
                      </span>
                      <span className="mt-1 block h-1.5 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
                        <span className="block h-full rounded-full bg-primary" style={{ width: `${progressOf(tm, now) * 100}%` }} />
                      </span>
                    </button>
                  ))}
                </section>
              ) : null}

              {timer && timersOn ? <TimerCard timer={timer} now={now} onToggle={() => startTimer(index)} onReset={() => resetTimer(index)} /> : null}

              <article key={index} className="clay flex-1 animate-rise p-6 sm:p-10" aria-labelledby="cook-step">
                <span className="grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-headline-md text-primary" aria-hidden="true">
                  {index + 1}
                </span>
                <p id="cook-step" className="mt-6 text-[clamp(1.5rem,3.2vw,2.5rem)] font-semibold leading-[1.45]">
                  {step}
                </p>
              </article>

              {inStep.length ? (
                <section className="clay p-4" aria-label={t("recipes.cook.inThisStep")}>
                  <p className="mb-2 text-label-md text-on-surface-variant">{t("recipes.cook.inThisStep")}</p>
                  <ul className="flex flex-wrap gap-2">
                    {inStep.map((ing, i) => (
                      <li key={i} className="inline-flex items-center gap-2 rounded-full border border-outline-variant bg-surface-low px-4 py-2">
                        <span className="text-body-lg font-bold text-primary">{quantityLabel(t, ing)}</span>
                        <span className="text-body-md">{ing.name}</span>
                      </li>
                    ))}
                  </ul>
                </section>
              ) : null}

              <nav className="sticky bottom-0 flex items-center gap-3 bg-gradient-to-t from-background via-background to-transparent pb-4 pt-2" aria-label={t("recipes.cook.title")}>
                <button type="button" onClick={prev} disabled={index === 0} className="grid h-14 w-14 shrink-0 place-items-center rounded-full bg-surface-lowest text-primary shadow-control disabled:opacity-40" aria-label={t("recipes.cook.previous")} title={t("recipes.cook.previous")}>
                  <Icon name="back" className="rtl:rotate-180" />
                </button>
                <button type="button" onClick={next} className="clay-btn-primary flex-1 text-body-lg">
                  {isLast ? t("recipes.cook.finish") : t("recipes.cook.next")}
                  <Icon name={isLast ? "check" : "chevron"} size={20} className={isLast ? "" : "rtl:rotate-180"} />
                </button>
              </nav>
              <p className="hidden text-center text-label-sm text-outline lg:block">{t("recipes.cook.keyboardHint")}</p>
            </main>

            {recipe.ingredients.length ? (
              <aside id="cook-ings" className={`${showIngredients ? "block" : "hidden"} lg:block`} aria-labelledby="cook-ings-h">
                <div className="clay p-5 lg:sticky lg:top-24 lg:max-h-[calc(100dvh-8rem)] lg:overflow-y-auto">
                  <h2 id="cook-ings-h" className="mb-3 text-headline-md">
                    {t("recipes.cook.ingredients")}
                  </h2>
                  <ul className="space-y-1">
                    {recipe.ingredients.map((ing, i) => {
                      const checked = done.has(i);
                      return (
                        <li key={i}>
                          <label className="flex cursor-pointer items-center gap-3 rounded-sm px-1 py-2 hover:bg-primary/5">
                            <input
                              type="checkbox"
                              className="h-5 w-5 shrink-0 accent-[rgb(var(--c-primary))]"
                              checked={checked}
                              onChange={() =>
                                setDone((s) => {
                                  const n = new Set(s);
                                  if (!n.delete(i)) n.add(i);
                                  return n;
                                })
                              }
                            />
                            <span className={`text-body-lg ${checked ? "text-outline line-through" : ""}`}>{ingredientLine(t, ing)}</span>
                          </label>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              </aside>
            ) : null}
          </div>
        </Protected>
      )}

      <Modal open={finished} onClose={() => setFinished(false)} title={t("recipes.cook.finishedTitle")}>
        <div className="space-y-5 text-center">
          <span className="mx-auto grid h-20 w-20 place-items-center rounded-full bg-secondary-container text-on-secondary-container" aria-hidden="true">
            <Icon name="cook" size={36} />
          </span>
          <p className="text-body-md text-on-surface-variant">{t("recipes.cook.finishedBody")}</p>
          <button type="button" className="clay-btn-primary w-full" onClick={onFinishDone}>
            <Icon name="check" size={18} />
            {t("recipes.done")}
          </button>
        </div>
      </Modal>
    </div>
  );
}

function TimerCard({ timer, now, onToggle, onReset }: { timer: CookTimer; now: number; onToggle: () => void; onReset: () => void }) {
  const { t } = useI18n();
  const left = remainingOf(timer, now);
  const running = timer.endsAtMs !== null;
  const label = timer.finished ? t("recipes.cook.reset") : running ? t("recipes.cook.pause") : left === timer.total ? t("recipes.cook.startTimer") : t("recipes.cook.resume");
  return (
    <section className={`clay p-5 ${timer.finished ? "!bg-secondary-container text-on-secondary-container" : ""}`} aria-label={t("recipes.cook.timer")}>
      <div className="flex items-center gap-2">
        <Icon name={timer.finished ? "inbox" : "timer"} size={20} className={timer.finished ? "" : "text-primary"} />
        <span className="flex-1 text-label-md">{timer.finished ? t("recipes.cook.timeUp") : t("recipes.cook.timer")}</span>
        <span className="text-display-lg tabular-nums" dir="ltr" role="timer" aria-live="off">
          {formatClock(left)}
        </span>
      </div>
      <div className="mt-3 h-2 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
        <div className="h-full rounded-full bg-primary" style={{ width: `${progressOf(timer, now) * 100}%` }} />
      </div>
      <div className="mt-4 flex gap-3">
        <button type="button" className="clay-btn-primary flex-1" onClick={onToggle}>
          <Icon name={timer.finished ? "refresh" : running ? "pause" : "play"} size={18} />
          {label}
        </button>
        {!timer.finished && left !== timer.total ? (
          <button type="button" className="grid h-[52px] w-[52px] place-items-center rounded-full bg-surface-lowest text-primary shadow-control" onClick={onReset} aria-label={t("recipes.cook.reset")} title={t("recipes.cook.reset")}>
            <Icon name="refresh" size={20} />
          </button>
        ) : null}
      </div>
    </section>
  );
}

/** _TimerCard below lg: r24 p16; timer 20 + label, displayLg remaining; 8 px groove; start/pause ClayButton + 56 reset; finished → mint. */
function PhoneTimerCard({ timer, now, onToggle, onReset }: { timer: CookTimer; now: number; onToggle: () => void; onReset: () => void }) {
  const { t } = useI18n();
  const left = remainingOf(timer, now);
  const running = timer.endsAtMs !== null;
  const finished = timer.finished;
  const label = finished ? t("recipes.cook.reset") : running ? t("recipes.cook.pause") : left === timer.total ? t("recipes.cook.startTimer") : t("recipes.cook.resume");
  return (
    <ClayCard radius={24} padding={16} as="section" className={finished ? "!bg-secondary-container text-on-secondary-container" : ""} aria-label={t("recipes.cook.timer")}>
      <div className="flex items-center gap-2">
        <Icon name={finished ? "notifications_active" : "timer"} size={20} className={finished ? "" : "text-primary"} />
        <span className={`flex-1 text-label-md ${finished ? "" : "text-on-surface-variant"}`}>{finished ? t("recipes.cook.timeUp") : t("recipes.cook.timer")}</span>
        <span className="text-display-lg tabular-nums" dir="ltr" role="timer" aria-live="off">
          {formatClock(left)}
        </span>
      </div>
      <div className="mt-3">
        <ProgressGroove value={progressOf(timer, now)} height={8} />
      </div>
      <div className="mt-4 flex items-center gap-3">
        <ClayButton expanded className="flex-1" icon={finished ? "refresh" : running ? "pause" : "play_arrow"} onClick={onToggle}>
          {label}
        </ClayButton>
        {!finished && left !== timer.total ? <ClayIconButton icon="refresh" size={56} label={t("recipes.cook.reset")} onClick={onReset} /> : null}
      </div>
    </ClayCard>
  );
}
