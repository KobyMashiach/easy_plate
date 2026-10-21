// The account's meal plans as cards (the app shows them as chips above the
// board; on a big screen they get their own page). Create with a template,
// rename, delete (asks first). With ?addRecipe=<id> a tap on a plan opens it
// ready to drop that recipe into a meal.
import { useMemo, useState } from "react";
import { useIsPhone } from "../../components/useIsPhone";
import { ClayButton } from "../../components/clay";
import { ACTIVE_PLAN_KEY, inAppOrder } from "./days";
import { Link, Navigate, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { newId } from "../../lib/cloud";
import { useAccess } from "../../lib/flags";
import { Icon } from "../../components/icons";
import { Notice, PageTitle } from "../../components/ui";
import { isPlanMine, isPlanShared, newMealPlan, planNutrition, type MealPlan } from "../../models/mealPlan";
import type { Recipe } from "../../models/recipe";
import { useTranslatedList } from "../../lib/contentTranslation";
import { createPlan, deletePlan, updatePlan, usePlans, webCanEditPlan } from "./plansStore";
import { CreatePlanDialog } from "./CreatePlanDialog";
import { ConfirmDialog, EmptyState, ErrorState, LoadingState, PromptDialog, RoleTag, useToast } from "../library/shared/components";
import { useRecipes } from "../library/shared/hooks";
import { useKcal } from "../nutrition/widgets";
import { saveOrGone } from "../library/shared/store";

/** A member does not delete a shared plan; they leave it. */
const leaving = (p: MealPlan) => isPlanShared(p) && !isPlanMine(p);

export function PlansPage() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const addRecipeId = params.get("addRecipe");
  const { plans, error } = usePlans(user?.uid);
  // Names in the language on screen; rename/delete keep the stored plan.
  const shownPlans = useTranslatedList("mealPlan", plans);
  const recipes = useRecipes(user?.uid);
  const [creating, setCreating] = useState(false);
  const [renaming, setRenaming] = useState<MealPlan | null>(null);
  const [deleting, setDeleting] = useState<MealPlan | null>(null);
  const [toast, show] = useToast();
  const phone = useIsPhone();

  const addRecipe = addRecipeId ? recipes.byId.get(addRecipeId) ?? null : null;
  const stopAdding = () => {
    params.delete("addRecipe");
    setParams(params, { replace: true });
  };
  const suffix = addRecipeId ? `?addRecipe=${encodeURIComponent(addRecipeId)}` : "";

  const create = async (name: string, mealNames: string[]) => {
    const plan = newMealPlan(newId(), name, mealNames, newId);
    await createPlan(plan, lang);
    navigate(`/plans/${plan.id}${suffix}`);
  };

  // Below lg the "תפריטים" tab is the board itself (meal_planner_page.dart):
  // straight to the plan last opened (else the first); the list stays for
  // picking a plan to add a recipe to.
  if (phone && !addRecipeId) {
    if (error && !plans) return <ErrorState />;
    if (plans === null) return <LoadingState />;
    if (plans.length > 0) {
      let last: string | null = null;
      try {
        last = localStorage.getItem(ACTIVE_PLAN_KEY);
      } catch {
        last = null;
      }
      const target = plans.find((p) => p.id === last) ?? inAppOrder(plans)[0];
      return <Navigate to={`/plans/${target.id}`} replace />;
    }
    return (
      <>
        <EmptyState
          icon="plans"
          phoneIcon="calendar_month"
          message={t("plans.empty")}
          action={
            <ClayButton icon="add" onClick={() => setCreating(true)}>
              {t("plans.newPlan")}
            </ClayButton>
          }
        />
        {creating ? <CreatePlanDialog onClose={() => setCreating(false)} onCreate={create} /> : null}
      </>
    );
  }

  const newButton = (
    <button type="button" className="clay-btn-primary w-full sm:w-auto" onClick={() => setCreating(true)}>
      <Icon name="add" size={20} />
      {t("plans.newPlan")}
    </button>
  );

  return (
    <>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <PageTitle title={t("plans.title")} lead={t("plans.subtitle")} />
        {plans && plans.length > 0 ? <div className="w-full sm:w-auto">{newButton}</div> : null}
      </div>

      {addRecipeId ? (
        <div className="mb-5">
          <Notice kind={recipes.list && !addRecipe ? "warn" : "info"}>
            <span className="flex flex-wrap items-center justify-between gap-3">
              <span>{recipes.list && !addRecipe ? t("plans.addRecipeMissing") : addRecipe ? t("plans.addRecipeChoosePlan", { title: addRecipe.title }) : recipes.error ? t("library.ui.loadFailed") : t("common.loading")}</span>
              <button type="button" className="clay-btn-ghost min-h-0 px-3 py-1" onClick={stopAdding}>
                {t("library.ui.cancel")}
              </button>
            </span>
          </Notice>
        </div>
      ) : null}

      {error && !plans ? (
        <ErrorState />
      ) : plans === null ? (
        <LoadingState />
      ) : plans.length === 0 ? (
        <EmptyState icon="plans" message={t("plans.empty")} action={newButton} />
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {plans.map((p, i) => (
            <li key={p.id} className="animate-rise">
              <PlanCard plan={shownPlans?.[i] ?? p} recipes={recipes.byId} href={`/plans/${p.id}${addRecipe && webCanEditPlan(p) ? suffix : ""}`} picking={addRecipe !== null} onRename={() => setRenaming(p)} onDelete={() => setDeleting(p)} />
            </li>
          ))}
        </ul>
      )}

      {creating ? <CreatePlanDialog onClose={() => setCreating(false)} onCreate={create} /> : null}
      {renaming ? (
        <PromptDialog
          title={t("plans.rename")}
          label={t("plans.planName")}
          initial={renaming.name}
          confirmLabel={t("library.ui.save")}
          requiredHint={t("plans.nameRequired")}
          onClose={() => setRenaming(null)}
          onSubmit={async (name) => {
            // Deleted (or made read-only) on another device: the dialog says so.
            await saveOrGone<MealPlan>((e) => updatePlan(renaming.id, e, lang), (p) => ({ ...p, name }));
          }}
        />
      ) : null}
      {deleting ? (
        <ConfirmDialog
          title={leaving(deleting) ? t("plans.leave") : t("plans.deletePlan")}
          message={t(leaving(deleting) ? "plans.leavePlanConfirm" : isPlanShared(deleting) ? "plans.deleteSharedConfirm" : "plans.deletePlanConfirm", { name: deleting.name })}
          confirmLabel={leaving(deleting) ? t("plans.leave") : t("library.delete")}
          onClose={() => setDeleting(null)}
          onConfirm={async () => {
            await deletePlan(deleting);
            show(leaving(deleting) ? t("plans.left") : t("plans.planDeleted"));
          }}
        />
      ) : null}
      {toast}
    </>
  );
}

function PlanCard({ plan, recipes, href, picking, onRename, onDelete }: { plan: MealPlan; recipes: Map<string, Recipe>; href: string; picking: boolean; onRename: () => void; onDelete: () => void }) {
  const { t } = useI18n();
  const kcal = useKcal();
  const nutritionOn = useAccess("ff_nutrition") === "enabled";
  const stats = useMemo(() => {
    const items = plan.meals.reduce((n, m) => n + m.items.length, 0);
    const days = new Set(plan.meals.filter((m) => m.items.length > 0).map((m) => m.weekday)).size;
    return { items, days, nutrition: planNutrition(plan, recipes) };
  }, [plan, recipes]);
  const editable = webCanEditPlan(plan);
  const disabled = picking && !editable;
  return (
    <article className={`clay relative flex h-full flex-col gap-3 p-5 ${disabled ? "opacity-60" : ""}`}>
      <div className="flex items-start gap-3">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
          <Icon name="plans" />
        </span>
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-body-lg font-bold">
            {disabled ? (
              plan.name
            ) : (
              <Link to={href} className="after:absolute after:inset-0 hover:text-primary">
                {plan.name || t("library.ui.untitled")}
              </Link>
            )}
          </h2>
          <p className="text-label-sm text-on-surface-variant">{t("plans.cardStats", { meals: plan.meals.length, items: stats.items, days: stats.days })}</p>
        </div>
        {isPlanShared(plan) ? <RoleTag role={plan.collabRole} /> : null}
      </div>
      {nutritionOn && stats.nutrition.hasData ? (
        <p className="text-label-md">
          <span className="font-bold">{kcal(stats.nutrition.dailyAverage.calories)}</span> {t("nutrition.kcalPerDay")}
        </p>
      ) : null}
      {!picking ? (
        <div className="relative z-10 mt-auto flex flex-wrap gap-2">
          <button type="button" className="clay-btn-ghost min-h-0 px-3 py-2 text-label-md" disabled={!editable} onClick={onRename}>
            <Icon name="edit" size={16} />
            {t("plans.rename")}
          </button>
          <button type="button" className="clay-btn-ghost min-h-0 px-3 py-2 text-label-md text-error" onClick={onDelete}>
            <Icon name={leaving(plan) ? "logout" : "trash"} size={16} />
            {leaving(plan) ? t("plans.leave") : t("library.delete")}
          </button>
        </div>
      ) : disabled ? (
        <p className="text-label-sm text-on-surface-variant">{t("plans.viewerOnly")}</p>
      ) : null}
    </article>
  );
}
