// One meal plan, as the app's planner board (meal_planner_page.dart +
// meal_card.dart): pick a day, see its meals, fill them with a recipe or a
// quick entry, remove or move items, add or remove meals. On a wide screen a
// week view shows all seven days side by side. The day's nutrition roll-up
// (ff_nutrition) sits beside the meals and opens the weekly dashboard.
// With ?addRecipe=<id> every meal offers "add here" for that recipe.
import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { ShareLink } from "../../components/ShareLink";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { newId, useRecord } from "../../lib/cloud";
import { useTranslated, useTranslatedList } from "../../lib/contentTranslation";
import { FeatureGate } from "../../components/FeatureGate";
import { Icon } from "../../components/icons";
import { Notice, Spinner } from "../../components/ui";
import {
  isPlanMine,
  isPlanShared,
  mealsForWeekday,
  newMealPlan,
  normalizeMealPlan,
  planNutrition,
  withItemAdded,
  withItemMoved,
  withItemRemoved,
  withItemUpdated,
  withMealAdded,
  withMealRemoved,
  withMealRenamed,
  WEEKDAYS,
  type Meal,
  type MealItem,
  type MealPlan,
} from "../../models/mealPlan";
import type { Recipe } from "../../models/recipe";
import { createPlan, deletePlan, updatePlan, useFollowPlan, usePlans, webCanEditPlan } from "./plansStore";
import { MoveItemDialog, QuickEntryDialog } from "./dialogs";
import { ACTIVE_PLAN_KEY, inAppOrder, todayWeekday, useDayNames } from "./days";
import { ConfirmDialog, ErrorState, LoadingState, PromptDialog, RecipePicker, RecipeThumb, RoleTag, useToast } from "../library/shared/components";
import { useBusy, useMediaQuery, useRecipes } from "../library/shared/hooks";
import { saveErrorKey, saveOrGone } from "../library/shared/store";
import { DayNutritionCard, useKcal } from "../nutrition/widgets";
import { useAccess } from "../../lib/flags";
import { AskShefiLink } from "../assistant/AskShefiLink";
import { isPhoneNow, useIsPhone } from "../../components/useIsPhone";
import { PhoneBar } from "../../components/PhoneBar";
import { CreatePlanDialog } from "./CreatePlanDialog";
import { PhonePlanBoard, PhonePlanOptions } from "./PhonePlanBoard";


type DialogState =
  | { kind: "renamePlan" }
  | { kind: "deletePlan" }
  | { kind: "addMeal" }
  | { kind: "renameMeal"; meal: Meal }
  | { kind: "deleteMeal"; meal: Meal }
  | { kind: "pickRecipe"; meal: Meal }
  | { kind: "quickEntry"; meal: Meal }
  | { kind: "editItem"; meal: Meal; item: MealItem }
  | { kind: "removeItem"; meal: Meal; item: MealItem; label: string }
  | { kind: "moveItem"; meal: Meal; item: MealItem };

export function PlanBoardPage() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const [params, setParams] = useSearchParams();
  const addRecipeId = params.get("addRecipe");
  const { item, error } = useRecord<unknown>("meal_plans", user?.uid, id);
  const plan = useMemo<MealPlan | null | undefined>(() => (item === undefined ? undefined : item === null ? null : normalizeMealPlan(item)), [item]);
  const recipes = useRecipes(user?.uid);
  // Names and quick entries in the language on screen, for drawing the board
  // only: every edit below is by id against the stored plan.
  const translatedPlan = useTranslated("mealPlan", plan);
  // Recipe titles on the board read in the language on screen too (display only).
  const shownRecipeList = useTranslatedList("recipe", recipes.list);
  const shownRecipes = useMemo(() => (shownRecipeList === recipes.list ? recipes.byId : new Map((shownRecipeList ?? []).map((r) => [r.id, r]))), [shownRecipeList, recipes.list, recipes.byId]);
  const days = useDayNames();
  const wide = useMediaQuery("(min-width: 1280px)");
  const [view, setView] = useState<"day" | "week" | null>(null);
  // The app's board opens on Sunday; the wide board on today.
  const [weekday, setWeekday] = useState(() => (isPhoneNow() ? 0 : todayWeekday()));
  const phone = useIsPhone();
  const { plans: allPlans } = usePlans(phone ? user?.uid : null);
  const [phoneOptions, setPhoneOptions] = useState<MealPlan | null>(null);
  const [phoneTarget, setPhoneTarget] = useState<{ kind: "rename" | "delete"; plan: MealPlan } | null>(null);
  const [creatingPlan, setCreatingPlan] = useState(false);
  const [dialog, setDialog] = useState<DialogState | null>(null);
  const [toast, show] = useToast();
  const busy = useBusy();
  const nutritionOn = useAccess("ff_nutrition") === "enabled";
  const nutrition = useMemo(() => (plan ? planNutrition(plan, recipes.byId) : null), [plan, recipes.byId]);
  const kcal = useKcal();
  // A shared plan follows its document while it is open (ContainerCollab.sync).
  useFollowPlan(id, plan?.collabId ?? null, user?.uid, lang);
  useEffect(() => {
    if (!phone || !plan) return;
    try {
      localStorage.setItem(ACTIVE_PLAN_KEY, plan.id);
    } catch {
      // Private mode: the tab opens on the first plan instead.
    }
  }, [phone, plan]);

  if (error && !plan) return <ErrorState />;
  if (plan === undefined) return <LoadingState />;
  if (plan === null)
    return (
      <div className="mx-auto max-w-md space-y-3 py-8 text-center">
        <Notice kind="warn">{t("plans.notFound")}</Notice>
        <Link to="/plans" className="clay-btn-secondary">
          {t("plans.backToPlans")}
        </Link>
      </div>
    );

  const shownPlan = translatedPlan ?? plan;
  const editable = webCanEditPlan(plan);
  const leaves = isPlanShared(plan) && !isPlanMine(plan);
  const mode = view ?? (wide ? "week" : "day");
  const addRecipe = addRecipeId && editable ? recipes.byId.get(addRecipeId) ?? null : null;
  const stopAdding = () => {
    params.delete("addRecipe");
    setParams(params, { replace: true });
  };
  const close = () => setDialog(null);
  // Against the stored plan. A plan deleted or made read-only meanwhile, or
  // a meal / item another device took out, fails with "gone" instead of
  // closing the dialog as if it had saved.
  const save = (edit: (p: MealPlan) => MealPlan, missing?: (p: MealPlan) => boolean) => saveOrGone<MealPlan>((e) => updatePlan(plan.id, e, lang), edit, missing);
  const mealGone = (mealId: string) => (p: MealPlan) => !p.meals.some((m) => m.id === mealId);
  const itemGone = (mealId: string, itemId: string) => (p: MealPlan) => !p.meals.find((m) => m.id === mealId)?.items.some((i) => i.id === itemId);
  /** Resolves true once saved; a failure is shown and the picking mode stays. */
  const quick = (key: string, edit: (p: MealPlan) => MealPlan, missing: (p: MealPlan) => boolean, done?: string) =>
    busy.run(key, async () => {
      try {
        if (!(await save(edit, missing))) throw new Error("not saved");
        if (done) show(done);
        return true;
      } catch (e) {
        show(t(saveErrorKey(e)), "error");
        return false;
      }
    });

  const addHere = (meal: Meal) =>
    addRecipe
      ? void quick(`add-${meal.id}`, (p) => withItemAdded(p, meal.id, { id: newId(), recipeId: addRecipe.id, freeText: null, ingredients: [] }), mealGone(meal.id), t("plans.addedTo", { title: addTitle, meal: `${days.short[meal.weekday]} · ${meal.name}` })).then((ok) => {
          if (ok) stopAdding();
        })
      : undefined;

  // The board shows the translated plan; an edit dialog starts from the
  // stored words, so saving without a change never writes the translation.
  const storedMeal = (m: Meal) => plan.meals.find((x) => x.id === m.id) ?? m;
  const storedItem = (mealId: string, it: MealItem) => plan.meals.find((x) => x.id === mealId)?.items.find((x) => x.id === it.id) ?? it;
  const itemLabel = (it: MealItem) => (it.recipeId !== null ? shownRecipes.get(it.recipeId)?.title ?? t("plans.missingRecipe") : it.freeText ?? "");
  const addTitle = addRecipe ? shownRecipes.get(addRecipe.id)?.title ?? addRecipe.title : "";

  const cardProps = {
    editable,
    busy: busy.any,
    recipes: shownRecipes,
    addRecipe,
    itemLabel,
    onAddHere: addHere,
    onDialog: setDialog,
    isBusy: busy.is,
  };

  const dialogs = (
    <>
      {dialog?.kind === "renamePlan" ? (
        <PromptDialog title={t("plans.rename")} label={t("plans.planName")} initial={plan.name} confirmLabel={t("library.ui.save")} requiredHint={t("plans.nameRequired")} onClose={close} onSubmit={async (name) => void (await save((p) => ({ ...p, name })))} />
      ) : null}
      {dialog?.kind === "deletePlan" ? (
        <ConfirmDialog
          title={leaves ? t("plans.leave") : t("plans.deletePlan")}
          message={t(leaves ? "plans.leavePlanConfirm" : isPlanShared(plan) ? "plans.deleteSharedConfirm" : "plans.deletePlanConfirm", { name: plan.name })}
          confirmLabel={leaves ? t("plans.leave") : t("library.delete")}
          onClose={close}
          onConfirm={async () => {
            await deletePlan(plan);
            navigate("/plans", { replace: true });
          }}
        />
      ) : null}
      {dialog?.kind === "addMeal" ? (
        <PromptDialog title={`${t("plans.addMeal")} · ${days.long[weekday]}`} label={t("plans.mealName")} confirmLabel={t("plans.add")} onClose={close} onSubmit={async (name) => void (await save((p) => withMealAdded(p, weekday, name, newId())))} />
      ) : null}
      {dialog?.kind === "renameMeal" ? (
        <PromptDialog title={t("plans.renameMeal")} label={t("plans.mealName")} initial={storedMeal(dialog.meal).name} confirmLabel={t("library.ui.save")} onClose={close} onSubmit={async (name) => void (await save((p) => withMealRenamed(p, dialog.meal.id, name), mealGone(dialog.meal.id)))} />
      ) : null}
      {dialog?.kind === "deleteMeal" ? (
        <ConfirmDialog title={t("plans.deleteMeal")} message={t("plans.deleteMealConfirm", { name: dialog.meal.name, n: dialog.meal.items.length })} confirmLabel={t("library.delete")} onClose={close} onConfirm={async () => void (await save((p) => withMealRemoved(p, dialog.meal.id)))} />
      ) : null}
      {dialog?.kind === "pickRecipe" ? (
        <RecipePicker
          title={`${t("plans.pickRecipe")} · ${dialog.meal.name}`}
          recipes={shownRecipeList}
          failed={!!recipes.error}
          onPick={async (r: Recipe) => void (await save((p) => withItemAdded(p, dialog.meal.id, { id: newId(), recipeId: r.id, freeText: null, ingredients: [] }), mealGone(dialog.meal.id)))}
          onClose={close}
        />
      ) : null}
      {dialog?.kind === "quickEntry" ? (
        <QuickEntryDialog onClose={close} onSubmit={async (text, ingredients) => void (await save((p) => withItemAdded(p, dialog.meal.id, { id: newId(), recipeId: null, freeText: text, ingredients }), mealGone(dialog.meal.id)))} />
      ) : null}
      {dialog?.kind === "editItem" ? (
        <QuickEntryDialog
          initialText={storedItem(dialog.meal.id, dialog.item)?.freeText ?? ""}
          initialIngredients={storedItem(dialog.meal.id, dialog.item)?.ingredients ?? dialog.item.ingredients}
          onClose={close}
          onSubmit={async (text, ingredients) => void (await save((p) => withItemUpdated(p, dialog.meal.id, dialog.item.id, text, ingredients), itemGone(dialog.meal.id, dialog.item.id)))}
        />
      ) : null}
      {dialog?.kind === "removeItem" ? (
        <ConfirmDialog title={t("plans.removeItem")} message={t("plans.removeItemConfirm", { name: dialog.label, meal: dialog.meal.name })} confirmLabel={t("library.remove")} onClose={close} onConfirm={async () => void (await save((p) => withItemRemoved(p, dialog.meal.id, dialog.item.id)))} />
      ) : null}
      {dialog?.kind === "moveItem" ? <MoveItemDialog plan={plan} fromMealId={dialog.meal.id} onClose={close} onMove={async (to) => void (await save((p) => withItemMoved(p, dialog.meal.id, dialog.item.id, to), (p) => itemGone(dialog.meal.id, dialog.item.id)(p) || mealGone(to)(p)))} /> : null}
    </>
  );

  // Below lg: the app's "תפריטים" tab is this board (PhoneBar tab = avatar,
  // bell, the dock and Shefi), the plans as chips above the day strip.
  if (phone) {
    const openPlan = (pid: string) => navigate(`/plans/${pid}${addRecipeId ? `?addRecipe=${encodeURIComponent(addRecipeId)}` : ""}`, { replace: true });
    const target = phoneTarget?.plan;
    const targetLeaves = target ? isPlanShared(target) && !isPlanMine(target) : false;
    return (
      <>
        <PhoneBar tab />
        <PhonePlanBoard
          plan={shownPlan}
          plans={allPlans ? inAppOrder(allPlans) : null}
          editable={editable}
          weekday={weekday}
          onWeekday={setWeekday}
          nutrition={nutrition ? nutrition.days[weekday] : null}
          recipes={shownRecipes}
          itemLabel={itemLabel}
          addRecipe={addRecipe}
          banner={
            addRecipeId && editable ? (
              <div className="mb-5">
                <Notice kind={recipes.list && !addRecipe ? "warn" : "info"}>
                  <span className="flex flex-wrap items-center justify-between gap-3">
                    <span>{recipes.list && !addRecipe ? t("plans.addRecipeMissing") : addRecipe ? t("plans.addRecipeChooseMeal", { title: addTitle }) : recipes.error ? t("library.ui.loadFailed") : t("common.loading")}</span>
                    <button type="button" className="clay-btn-ghost min-h-0 px-3 py-1" onClick={stopAdding}>
                      {t("library.ui.cancel")}
                    </button>
                  </span>
                </Notice>
              </div>
            ) : null
          }
          busy={busy.any}
          isBusy={busy.is}
          onSelectPlan={openPlan}
          onCreatePlan={() => setCreatingPlan(true)}
          onPlanOptions={setPhoneOptions}
          onAddMeal={() => setDialog({ kind: "addMeal" })}
          onRenameMeal={(meal) => setDialog({ kind: "renameMeal", meal })}
          onDeleteMeal={(meal) => setDialog({ kind: "deleteMeal", meal })}
          onPickRecipe={(meal) => setDialog({ kind: "pickRecipe", meal })}
          onQuickEntry={(meal) => setDialog({ kind: "quickEntry", meal })}
          onEditItem={(meal, item) => setDialog({ kind: "editItem", meal, item })}
          onRemoveItem={(meal, item, label) => setDialog({ kind: "removeItem", meal, item, label })}
          onMoveItem={(meal, item) => setDialog({ kind: "moveItem", meal, item })}
          onAddHere={addHere}
        />
        {phoneOptions ? (
          <PhonePlanOptions
            open
            plan={phoneOptions}
            canRename={webCanEditPlan(phoneOptions)}
            navigate={(to) => {
              setPhoneOptions(null);
              navigate(to);
            }}
            onClose={() => setPhoneOptions(null)}
            onRename={() => {
              setPhoneTarget({ kind: "rename", plan: phoneOptions });
              setPhoneOptions(null);
            }}
            onDelete={() => {
              setPhoneTarget({ kind: "delete", plan: phoneOptions });
              setPhoneOptions(null);
            }}
          />
        ) : null}
        {target && phoneTarget?.kind === "rename" ? (
          <PromptDialog
            title={t("plans.rename")}
            label={t("plans.planName")}
            initial={target.name}
            confirmLabel={t("library.ui.save")}
            requiredHint={t("plans.nameRequired")}
            onClose={() => setPhoneTarget(null)}
            onSubmit={async (name) => void (await saveOrGone<MealPlan>((e) => updatePlan(target.id, e, lang), (p) => ({ ...p, name })))}
          />
        ) : null}
        {target && phoneTarget?.kind === "delete" ? (
          <ConfirmDialog
            icon={targetLeaves ? "logout" : "delete_outline"}
            title={targetLeaves ? t("plans.leave") : t("plans.deletePlan")}
            message={t(targetLeaves ? "plans.leavePlanConfirm" : isPlanShared(target) ? "plans.deleteSharedConfirm" : "plans.deletePlanConfirm", { name: target.name })}
            confirmLabel={targetLeaves ? t("plans.leave") : t("library.delete")}
            onClose={() => setPhoneTarget(null)}
            onConfirm={async () => {
              await deletePlan(target);
              show(targetLeaves ? t("plans.left") : t("plans.planDeleted"));
              if (target.id === plan.id) navigate("/plans", { replace: true });
            }}
          />
        ) : null}
        {creatingPlan ? (
          <CreatePlanDialog
            onClose={() => setCreatingPlan(false)}
            onCreate={async (name, mealNames) => {
              const created = newMealPlan(newId(), name, mealNames, newId);
              await createPlan(created, lang);
              navigate(`/plans/${created.id}`, { replace: true });
            }}
          />
        ) : null}
        {dialogs}
        {toast}
      </>
    );
  }

  return (
    <>
      <nav className="mb-3" aria-label={t("nav.breadcrumb")}>
        <Link to="/plans" className="inline-flex items-center gap-1 text-label-md text-primary">
          <Icon name="back" size={16} className="rtl:rotate-180" />
          {t("plans.title")}
        </Link>
      </nav>

      <header className="mb-4 flex flex-wrap items-center gap-3">
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-headline-lg">{shownPlan.name || t("library.ui.untitled")}</h1>
          <p className="text-label-md text-on-surface-variant">{t("plans.boardSubtitle")}</p>
        </div>
        {isPlanShared(plan) ? <RoleTag role={plan.collabRole} /> : null}
        <div className="flex flex-wrap gap-2">
          <div className="inline-flex rounded-full bg-surface-high p-1" role="group" aria-label={t("plans.view")}>
            {(["day", "week"] as const).map((v) => (
              <button key={v} type="button" aria-pressed={mode === v} onClick={() => setView(v)} className={`rounded-full px-4 py-1.5 text-label-md ${mode === v ? "bg-surface-lowest text-primary shadow-control" : "text-on-surface-variant"}`}>
                {t(v === "day" ? "plans.viewDay" : "plans.viewWeek")}
              </button>
            ))}
          </div>
          <FeatureGate flag="ff_nutrition">
            <Link to={`/nutrition?plan=${encodeURIComponent(plan.id)}`} className="clay-btn-tonal">
              <Icon name="nutrition" size={18} />
              <span className="hidden sm:inline">{t("nutrition.openDashboard")}</span>
            </Link>
          </FeatureGate>
          <AskShefiLink kind="plan" id={plan.id} compact />
          <ShareLink kind="mealPlan" id={plan.id} mine={isPlanMine(plan)} compact />
          <button type="button" className="clay-btn-ghost" disabled={!editable} onClick={() => setDialog({ kind: "renamePlan" })} aria-label={t("plans.rename")} title={t("plans.rename")}>
            <Icon name="edit" size={18} />
          </button>
          <button type="button" className="clay-btn-ghost text-error" onClick={() => setDialog({ kind: "deletePlan" })} aria-label={leaves ? t("plans.leave") : t("plans.deletePlan")} title={leaves ? t("plans.leave") : t("plans.deletePlan")}>
            <Icon name={leaves ? "logout" : "trash"} size={18} />
          </button>
        </div>
      </header>

      {!editable ? (
        <div className="mb-4">
          <Notice kind="info">{t("plans.viewerOnly")}</Notice>
        </div>
      ) : null}
      {addRecipeId && editable ? (
        <div className="mb-4">
          <Notice kind={recipes.list && !addRecipe ? "warn" : "info"}>
            <span className="flex flex-wrap items-center justify-between gap-3">
              <span>{recipes.list && !addRecipe ? t("plans.addRecipeMissing") : addRecipe ? t("plans.addRecipeChooseMeal", { title: addTitle }) : recipes.error ? t("library.ui.loadFailed") : t("common.loading")}</span>
              <button type="button" className="clay-btn-ghost min-h-0 px-3 py-1" onClick={stopAdding}>
                {t("library.ui.cancel")}
              </button>
            </span>
          </Notice>
        </div>
      ) : null}

      {mode === "day" ? (
        <>
          <div className="-mx-4 mb-5 overflow-x-auto px-4 pb-1 lg:mx-0 lg:px-0">
            <div className="flex min-w-max gap-2" role="group" aria-label={t("plans.days")}>
              {WEEKDAYS.map((_, wd) => {
                const count = mealsForWeekday(shownPlan, wd).length;
                const on = wd === weekday;
                return (
                  <button
                    key={wd}
                    type="button"
                    aria-pressed={on}
                    onClick={() => setWeekday(wd)}
                    className={`flex min-w-[4.5rem] flex-col items-center rounded-md border px-3 py-2 transition-colors ${on ? "border-primary bg-primary text-on-primary shadow-button" : "border-outline-variant bg-surface-lowest hover:bg-surface-low"}`}
                  >
                    <span className="text-label-md font-bold">{days.short[wd]}</span>
                    <span className={`text-label-sm ${on ? "opacity-85" : "text-on-surface-variant"}`}>{t("plans.mealsCount", { n: count })}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_340px]">
            <section aria-labelledby="day-h" className="min-w-0">
              <h2 id="day-h" className="mb-3 text-headline-md">
                {days.long[weekday]}
              </h2>
              <div className="grid gap-4 md:grid-cols-2 2xl:grid-cols-3 min-[1900px]:grid-cols-4">
                {mealsForWeekday(shownPlan, weekday).map((meal) => (
                  <MealCard key={meal.id} meal={meal} {...cardProps} />
                ))}
                {editable ? (
                  <button type="button" onClick={() => setDialog({ kind: "addMeal" })} className="flex min-h-[8rem] flex-col items-center justify-center gap-1 rounded-lg border-2 border-dashed border-outline-variant p-5 text-center text-on-surface-variant transition-colors hover:border-primary hover:text-primary">
                    <Icon name="add" />
                    <span className="text-body-md font-bold">{t("plans.addMeal")}</span>
                    <span className="text-label-sm">{t("plans.addMealHint")}</span>
                  </button>
                ) : mealsForWeekday(shownPlan, weekday).length === 0 ? (
                  <p className="text-on-surface-variant">{t("plans.noMealsDay")}</p>
                ) : null}
              </div>
            </section>
            <aside className="space-y-4">
              <FeatureGate flag="ff_nutrition">{nutrition ? <DayNutritionCard day={nutrition.days[weekday]} dashboardHref={`/nutrition?plan=${encodeURIComponent(plan.id)}&day=${weekday}`} /> : null}</FeatureGate>
            </aside>
          </div>
        </>
      ) : (
        <div className="-mx-4 overflow-x-auto px-4 pb-2 lg:mx-0 lg:px-0">
          <div className="grid min-w-[1120px] grid-cols-7 gap-3">
            {WEEKDAYS.map((_, wd) => {
              const dayNut = nutrition?.days[wd];
              return (
                <section key={wd} aria-labelledby={`wd-${wd}`} className={`flex flex-col gap-2 rounded-lg p-2 ${wd === todayWeekday() ? "bg-primary-fixed/50" : "bg-surface-low"}`}>
                  {/* The heading wraps the button (a heading inside a button is lost to screen readers). */}
                  <h2 id={`wd-${wd}`} className="text-body-md font-bold">
                    <button
                      type="button"
                      className="w-full rounded-md px-2 py-1.5 text-start hover:bg-surface-high"
                      onClick={() => {
                        setWeekday(wd);
                        setView("day");
                      }}
                    >
                      {days.long[wd]}
                      {nutritionOn && dayNut?.hasData ? (
                        <span className="block text-label-sm font-normal text-on-surface-variant">
                          {kcal(dayNut.total.calories)} {t("nutrition.kcal")}
                        </span>
                      ) : null}
                    </button>
                  </h2>
                  {mealsForWeekday(shownPlan, wd).map((meal) => (
                    <MealCard key={meal.id} meal={meal} compact {...cardProps} />
                  ))}
                  {editable ? (
                    <button
                      type="button"
                      onClick={() => {
                        setWeekday(wd);
                        setDialog({ kind: "addMeal" });
                      }}
                      className="rounded-md border border-dashed border-outline-variant px-2 py-2 text-label-md text-on-surface-variant hover:border-primary hover:text-primary"
                      aria-label={`${t("plans.addMeal")} · ${days.long[wd]}`}
                    >
                      + {t("plans.addMeal")}
                    </button>
                  ) : null}
                </section>
              );
            })}
          </div>
        </div>
      )}

      {dialogs}
      {toast}
    </>
  );
}

// ---------------------------------------------------------------------------

function MealCard({
  meal,
  compact = false,
  editable,
  busy,
  recipes,
  addRecipe,
  itemLabel,
  onAddHere,
  onDialog,
  isBusy,
}: {
  meal: Meal;
  compact?: boolean;
  editable: boolean;
  busy: boolean;
  recipes: Map<string, Recipe>;
  addRecipe: Recipe | null;
  itemLabel: (it: MealItem) => string;
  onAddHere: (meal: Meal) => void;
  onDialog: (d: DialogState) => void;
  isBusy: (key: string) => boolean;
}) {
  const { t } = useI18n();
  const iconBtn = "grid h-8 w-8 shrink-0 place-items-center rounded-full text-on-surface-variant hover:bg-surface-high disabled:opacity-40";
  return (
    <article className={`clay relative flex flex-col overflow-hidden ${compact ? "gap-1.5 p-2.5" : "gap-2 p-4"}`} aria-label={meal.name}>
      <span className="absolute inset-y-0 start-0 w-1.5 bg-primary" aria-hidden="true" />
      <div className="flex items-center gap-1 ps-1">
        <span className={`pill-lavender inline-flex min-w-0 items-center gap-1 ${compact ? "text-label-sm" : ""}`}>
          {!compact ? <Icon name="cook" size={14} /> : null}
          <span className="truncate">{meal.name}</span>
        </span>
        <span className="flex-1" />
        {editable && !compact ? (
          <>
            <button type="button" className={iconBtn} disabled={busy} onClick={() => onDialog({ kind: "renameMeal", meal })} aria-label={t("plans.renameMealNamed", { name: meal.name })}>
              <Icon name="edit" size={16} />
            </button>
            <button type="button" className={iconBtn} disabled={busy} onClick={() => onDialog({ kind: "deleteMeal", meal })} aria-label={t("plans.deleteMealNamed", { name: meal.name })}>
              <Icon name="trash" size={16} />
            </button>
          </>
        ) : null}
      </div>

      {meal.items.length === 0 ? (
        <p className={`ps-1 text-on-surface-variant ${compact ? "text-label-sm" : "text-label-md"}`}>{compact ? "—" : t("plans.addMealHint")}</p>
      ) : (
        <ul className="space-y-1 ps-1">
          {meal.items.map((it) => {
            const recipe = it.recipeId !== null ? recipes.get(it.recipeId) : undefined;
            const label = itemLabel(it);
            return (
              <li key={it.id} className="group flex items-center gap-2">
                {!compact ? recipe ? <RecipeThumb recipe={recipe} size="h-9 w-9" /> : (
                  <span className="grid h-9 w-9 shrink-0 place-items-center rounded-std bg-surface-high text-primary" aria-hidden="true">
                    <Icon name={it.recipeId !== null ? "recipes" : "edit"} size={16} />
                  </span>
                ) : null}
                <div className="min-w-0 flex-1">
                  {recipe ? (
                    <Link to={`/recipes/${recipe.id}`} className={`block truncate hover:text-primary ${compact ? "text-label-md" : "text-body-md"}`}>
                      {label}
                    </Link>
                  ) : it.recipeId === null && editable ? (
                    <button type="button" className={`block w-full truncate text-start hover:text-primary ${compact ? "text-label-md" : "text-body-md"}`} onClick={() => onDialog({ kind: "editItem", meal, item: it })} title={t("plans.editItem")}>
                      {label}
                    </button>
                  ) : (
                    <span className={`block truncate ${compact ? "text-label-md" : "text-body-md"} ${it.recipeId !== null ? "text-on-surface-variant" : ""}`}>{label}</span>
                  )}
                  {!compact && it.ingredients.length ? <span className="block truncate text-label-sm text-on-surface-variant">{it.ingredients.map((g) => g.name).join(" · ")}</span> : null}
                  {!compact && recipe?.nutrition ? <span className="block text-label-sm text-on-surface-variant">{t("library.ui.kcalServing", { n: recipe.nutrition.calories })}</span> : null}
                </div>
                {editable && !compact ? (
                  <>
                    <button type="button" className={iconBtn} disabled={busy} onClick={() => onDialog({ kind: "moveItem", meal, item: it })} aria-label={t("plans.moveNamed", { name: label })} title={t("plans.moveItem")}>
                      <Icon name="refresh" size={15} />
                    </button>
                    <button type="button" className={iconBtn} disabled={busy} onClick={() => onDialog({ kind: "removeItem", meal, item: it, label })} aria-label={t("plans.removeNamed", { name: label })} title={t("plans.removeItem")}>
                      <Icon name="close" size={15} />
                    </button>
                  </>
                ) : null}
              </li>
            );
          })}
        </ul>
      )}

      {editable ? (
        addRecipe ? (
          <button type="button" className={`clay-btn-primary mt-1 ${compact ? "min-h-0 px-2 py-1.5 text-label-sm" : ""}`} disabled={busy} aria-busy={isBusy(`add-${meal.id}`) || undefined} onClick={() => onAddHere(meal)}>
            {isBusy(`add-${meal.id}`) ? <Spinner small /> : <Icon name="add" size={16} />}
            {t("plans.addHere")}
          </button>
        ) : (
          <div className={`mt-auto grid grid-cols-2 gap-1 border-t border-outline-variant/50 ${compact ? "pt-1.5" : "pt-2"}`}>
            <button type="button" className={`clay-btn-ghost min-h-0 ${compact ? "px-1 py-1 text-label-sm" : "px-2 py-2 text-label-md"}`} disabled={busy} onClick={() => onDialog({ kind: "pickRecipe", meal })}>
              {!compact ? <Icon name="recipes" size={16} /> : null}
              {compact ? t("plans.recipeShort") : t("plans.pickRecipe")}
            </button>
            <button type="button" className={`clay-btn-ghost min-h-0 ${compact ? "px-1 py-1 text-label-sm" : "px-2 py-2 text-label-md"}`} disabled={busy} onClick={() => onDialog({ kind: "quickEntry", meal })}>
              {!compact ? <Icon name="edit" size={16} /> : null}
              {compact ? t("plans.quickShort") : t("plans.quickEntry")}
            </button>
          </div>
        )
      ) : null}
    </article>
  );
}
