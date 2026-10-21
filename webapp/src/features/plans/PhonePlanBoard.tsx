// The planner board below lg, drawn as the app draws its "תפריטים" tab
// (meal_planner_page.dart, meal_card.dart, clay_day_selector.dart,
// clay_dashed_card.dart, day_nutrition_card.dart): the plan's name floats
// away with the pinned share / options / new-plan buttons, the plan chips,
// the 72×90 day tiles, the day's totals ring, the meal cards with their
// spine, and the dashed "add meal" card. Every write goes through the same
// callbacks as the desktop board.
import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { Icon } from "../../components/icons";
import { ClayButton, ClayCard, ClayIconButton, ClayTag } from "../../components/clay";
import { BottomSheet, SheetOption } from "../../components/BottomSheet";
import { FloatingHeaderView } from "../../components/FloatingHeaderView";
import { isPlanMine, isPlanShared, mealsForWeekday, WEEKDAYS, type DayNutrition, type Meal, type MealItem, type MealPlan } from "../../models/mealPlan";
import type { Recipe } from "../../models/recipe";
import { RoleTag } from "../library/shared/components";
import { useLongPress } from "../library/shared/hooks";
import { PhoneDayNutritionCard } from "../nutrition/widgets";

/** The weekday names the app shows on its tiles (t.weekday.*). */
export function useWeekdayLabels(): string[] {
  const { t } = useI18n();
  return WEEKDAYS.map((_, i) => t(`plans.day${i}`));
}

export function PhonePlanBoard({
  plan,
  plans,
  editable,
  weekday,
  onWeekday,
  nutrition,
  recipes,
  itemLabel,
  addRecipe,
  banner,
  busy,
  isBusy,
  onSelectPlan,
  onCreatePlan,
  onPlanOptions,
  onAddMeal,
  onRenameMeal,
  onDeleteMeal,
  onPickRecipe,
  onQuickEntry,
  onEditItem,
  onRemoveItem,
  onMoveItem,
  onAddHere,
}: {
  plan: MealPlan;
  plans: MealPlan[] | null;
  editable: boolean;
  weekday: number;
  onWeekday: (wd: number) => void;
  nutrition: DayNutrition | null;
  recipes: Map<string, Recipe>;
  itemLabel: (it: MealItem) => string;
  addRecipe: Recipe | null;
  banner: ReactNode;
  busy: boolean;
  isBusy: (key: string) => boolean;
  onSelectPlan: (id: string) => void;
  onCreatePlan: () => void;
  onPlanOptions: (plan: MealPlan) => void;
  onAddMeal: () => void;
  onRenameMeal: (meal: Meal) => void;
  onDeleteMeal: (meal: Meal) => void;
  onPickRecipe: (meal: Meal) => void;
  onQuickEntry: (meal: Meal) => void;
  onEditItem: (meal: Meal, item: MealItem) => void;
  onRemoveItem: (meal: Meal, item: MealItem, label: string) => void;
  onMoveItem: (meal: Meal, item: MealItem) => void;
  onAddHere: (meal: Meal) => void;
}) {
  const { t } = useI18n();
  const labels = useWeekdayLabels();
  const shareAccess = useAccess("ff_share_plans");
  const canShare = isPlanMine(plan) && shareAccess === "enabled";
  const nutritionOn = useAccess("ff_nutrition") === "enabled";
  const meals = mealsForWeekday(plan, weekday);
  const n = canShare ? 3 : 2;

  return (
    <FloatingHeaderView
      title={plan.name || t("library.ui.untitled")}
      subtitle={t("plans.boardSubtitle")}
      bottomGap={0}
      actionCount={n}
      actions={
        <>
          {canShare ? <ClayIconButton icon="person_add_alt_1" size={48} label={t("plans.sharePlan")} to={`/sharing/share?kind=mealPlan&id=${encodeURIComponent(plan.id)}`} /> : null}
          <ClayIconButton icon="more_horiz" size={48} label={t("plans.planOptions")} onClick={() => onPlanOptions(plan)} />
          <ClayIconButton icon="playlist_add" size={48} filled label={t("plans.newPlan")} onClick={onCreatePlan} />
        </>
      }
    >
      {isPlanShared(plan) ? (
        <div className="mt-2">
          <RoleTag role={plan.collabRole} />
        </div>
      ) : null}
      {plans && plans.length > 1 ? (
        <div className="mt-4 flex flex-wrap gap-2" role="group" aria-label={t("plans.title")}>
          {plans.map((p) => (
            <PlanChip key={p.id} plan={p} selected={p.id === plan.id} onSelect={() => onSelectPlan(p.id)} onOptions={() => onPlanOptions(p)} />
          ))}
        </div>
      ) : null}
      <div className="h-8" />
      {banner}

      {/* ClayDaySelector: 72×90 tiles, 12 apart, scrolling from the start edge. */}
      <div className="-mx-5 overflow-x-auto px-5 pb-6 pt-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" style={{ marginBottom: -20 }}>
        <div className="flex w-max gap-3" role="group" aria-label={t("plans.days")}>
          {WEEKDAYS.map((_, wd) => {
            const on = wd === weekday;
            const count = mealsForWeekday(plan, wd).length;
            return (
              <ClayCard key={wd} radius={24} padding={0} active={on} onClick={() => onWeekday(wd)} className="!w-[72px] shrink-0" style={{ height: 90 }} aria-pressed={on} aria-label={`${labels[wd]} · ${t("plans.mealsCount", { n: count })}`}>
                <span className="flex h-full flex-col items-center justify-center gap-1 px-1">
                  <span className={`max-w-full truncate text-label-sm ${on ? "text-primary-fixed" : "text-primary"}`}>{labels[wd]}</span>
                  <span className={`flex items-center gap-1 ${on ? "text-on-primary-container" : "text-primary"}`}>
                    <Icon name="restaurant" size={16} />
                    <span className="text-headline-md">{count}</span>
                  </span>
                </span>
              </ClayCard>
            );
          })}
        </div>
      </div>

      {nutritionOn && nutrition ? (
        <div className="mt-4">
          <PhoneDayNutritionCard day={nutrition} dashboardHref={`/nutrition?plan=${encodeURIComponent(plan.id)}`} />
        </div>
      ) : null}

      <div className="mt-4 space-y-6">
        {meals.map((meal) => (
          <PhoneMealCard
            key={meal.id}
            meal={meal}
            editable={editable}
            busy={busy}
            recipes={recipes}
            itemLabel={itemLabel}
            addRecipe={addRecipe}
            adding={isBusy(`add-${meal.id}`)}
            onRename={() => onRenameMeal(meal)}
            onDelete={() => onDeleteMeal(meal)}
            onPickRecipe={() => onPickRecipe(meal)}
            onQuickEntry={() => onQuickEntry(meal)}
            onEditItem={(it) => onEditItem(meal, it)}
            onRemoveItem={(it, label) => onRemoveItem(meal, it, label)}
            onMoveItem={(it) => onMoveItem(meal, it)}
            onAddHere={() => onAddHere(meal)}
          />
        ))}
        {editable ? <DashedAddCard label={t("plans.addMeal")} description={t("plans.addMealHint")} onClick={onAddMeal} /> : meals.length === 0 ? <p className="text-center text-body-md text-on-surface-variant">{t("plans.noMealsDay")}</p> : null}
      </div>
    </FloatingHeaderView>
  );
}

/** A plan chip: stadium 8/16, selected = primaryFixed + primary rim; a long press opens its options. */
function PlanChip({ plan, selected, onSelect, onOptions }: { plan: MealPlan; selected: boolean; onSelect: () => void; onOptions: () => void }) {
  const { t } = useI18n();
  const long = useLongPress(onOptions);
  return (
    <button
      type="button"
      {...long.handlers}
      onClick={onSelect}
      aria-pressed={selected}
      className={`press select-none rounded-full border px-4 py-2 text-label-md transition-colors duration-[180ms] [-webkit-touch-callout:none] ${selected ? "border-primary bg-primary-fixed text-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
    >
      {plan.name || t("library.ui.untitled")}
    </button>
  );
}

/** MealCard: ClayCard p16 with the spine; the meal tag, its items, the two text actions. */
function PhoneMealCard({
  meal,
  editable,
  busy,
  recipes,
  itemLabel,
  addRecipe,
  adding,
  onRename,
  onDelete,
  onPickRecipe,
  onQuickEntry,
  onEditItem,
  onRemoveItem,
  onMoveItem,
  onAddHere,
}: {
  meal: Meal;
  editable: boolean;
  busy: boolean;
  recipes: Map<string, Recipe>;
  itemLabel: (it: MealItem) => string;
  addRecipe: Recipe | null;
  adding: boolean;
  onRename: () => void;
  onDelete: () => void;
  onPickRecipe: () => void;
  onQuickEntry: () => void;
  onEditItem: (it: MealItem) => void;
  onRemoveItem: (it: MealItem, label: string) => void;
  onMoveItem: (it: MealItem) => void;
  onAddHere: () => void;
}) {
  const { t } = useI18n();
  return (
    <ClayCard spine as="article" aria-label={meal.name}>
      <div className="flex items-center">
        {editable ? (
          <button type="button" className="min-w-0 flex-1 text-start" onClick={onRename} disabled={busy} aria-label={t("plans.renameMealNamed", { name: meal.name })}>
            <ClayTag icon="restaurant" className="w-full bg-primary-fixed text-primary">
              {meal.name}
            </ClayTag>
          </button>
        ) : (
          <span className="min-w-0 flex-1">
            <ClayTag icon="restaurant" className="w-full bg-primary-fixed text-primary">
              {meal.name}
            </ClayTag>
          </span>
        )}
        {editable ? (
          <button type="button" onClick={onDelete} disabled={busy} className="press-icon -my-2 -me-2 grid h-12 w-12 shrink-0 place-items-center rounded-full text-outline" aria-label={t("plans.deleteMealNamed", { name: meal.name })}>
            <Icon name="delete_outline" size={20} />
          </button>
        ) : null}
      </div>
      <div className="mt-3">
        {meal.items.length === 0 ? (
          <p className="pb-2 text-label-md text-outline">{t("plans.addMealHint")}</p>
        ) : (
          <ul>
            {meal.items.map((it) => (
              <MealItemRow key={it.id} item={it} recipe={it.recipeId !== null ? recipes.get(it.recipeId) : undefined} label={itemLabel(it)} editable={editable} busy={busy} onEdit={() => onEditItem(it)} onRemove={() => onRemoveItem(it, itemLabel(it))} onMove={() => onMoveItem(it)} />
            ))}
          </ul>
        )}
      </div>
      {editable ? (
        <>
          <div className="my-3 h-px bg-surface-highest" aria-hidden="true" />
          {addRecipe ? (
            <ClayButton expanded icon="add" busy={adding} disabled={busy} onClick={onAddHere}>
              {t("plans.addHere")}
            </ClayButton>
          ) : (
            <div className="flex">
              <TextAction icon="restaurant_menu" label={t("plans.pickRecipe")} disabled={busy} onClick={onPickRecipe} />
              <TextAction icon="edit_note" label={t("plans.quickEntry")} disabled={busy} onClick={onQuickEntry} />
            </div>
          )}
        </>
      ) : null}
    </ClayCard>
  );
}

function MealItemRow({ item, recipe, label, editable, busy, onEdit, onRemove, onMove }: { item: MealItem; recipe: Recipe | undefined; label: string; editable: boolean; busy: boolean; onEdit: () => void; onRemove: () => void; onMove: () => void }) {
  const { t } = useI18n();
  // Moving to another meal (web-only, kept): a long press on the row.
  const long = useLongPress(() => editable && !busy && onMove());
  const text = (
    <span className="min-w-0 flex-1">
      <span className="block text-body-md text-on-surface">{label}</span>
      {item.ingredients.length ? <span className="block truncate text-label-sm text-outline">{item.ingredients.map((g) => g.name).join(" · ")}</span> : null}
    </span>
  );
  const body = (
    <>
      <Icon name={item.recipeId !== null ? "menu_book" : "edit_note"} size={18} className="shrink-0 text-primary" />
      {text}
    </>
  );
  return (
    <li className="flex items-center gap-2 py-1" {...long.handlers}>
      {recipe ? (
        <Link to={`/recipes/${recipe.id}`} className="flex min-w-0 flex-1 items-center gap-2 text-start">
          {body}
        </Link>
      ) : item.recipeId === null && editable ? (
        <button type="button" onClick={onEdit} disabled={busy} className="flex min-w-0 flex-1 items-center gap-2 text-start" title={t("plans.editItem")}>
          {body}
        </button>
      ) : (
        <span className="flex min-w-0 flex-1 items-center gap-2">{body}</span>
      )}
      {editable ? (
        <button type="button" onClick={onRemove} disabled={busy} className="press-icon grid h-8 w-8 shrink-0 place-items-center rounded-full text-outline" aria-label={t("plans.removeNamed", { name: label })}>
          <Icon name="close" size={16} />
        </button>
      ) : null}
    </li>
  );
}

/** A Material text button: icon 18 + labelMd in primary, stadium. */
function TextAction({ icon, label, onClick, disabled }: { icon: string; label: string; onClick: () => void; disabled?: boolean }) {
  return (
    <button type="button" onClick={onClick} disabled={disabled} className="press flex h-10 min-w-0 flex-1 items-center justify-center gap-2 rounded-full px-3 text-label-md text-primary disabled:text-outline-variant">
      <Icon name={icon} size={18} className="shrink-0" />
      <span className="truncate">{label}</span>
    </button>
  );
}

/** ClayDashedCard: dashed 2 px primary @ 30 % (8 on, 6 off), radius 16, the 56 px add disc. */
function DashedAddCard({ label, description, onClick }: { label: string; description: string; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} className="press relative flex w-full flex-col items-center rounded-std p-6 text-center" style={{ background: "rgb(var(--c-surface-container) / .3)" }}>
      <svg className="pointer-events-none absolute inset-0 h-full w-full overflow-visible" aria-hidden="true">
        <rect x="1" y="1" rx="15" ry="15" style={{ width: "calc(100% - 2px)", height: "calc(100% - 2px)" }} fill="none" stroke="rgb(var(--c-primary) / .3)" strokeWidth="2" strokeDasharray="8 6" />
      </svg>
      <span className="grid h-14 w-14 place-items-center rounded-full bg-primary text-on-primary" aria-hidden="true">
        <Icon name="add" size={28} />
      </span>
      <span className="mt-3 text-body-lg text-primary">{label}</span>
      <span className="mt-1 text-label-md text-outline">{description}</span>
    </button>
  );
}

/** The plan's options sheet: ask Shefi, share, rename, delete / leave. */
export function PhonePlanOptions({ plan, open, canRename, onClose, onRename, onDelete, navigate }: { plan: MealPlan; open: boolean; canRename: boolean; onClose: () => void; onRename: () => void; onDelete: () => void; navigate: (to: string) => void }) {
  const { t } = useI18n();
  const leaves = isPlanShared(plan) && !isPlanMine(plan);
  const main = useAccess("ff_assistant");
  const scoped = useAccess("ff_assistant_scoped");
  const shareAccess = useAccess("ff_share_plans");
  const shefi = main === "enabled" && scoped === "enabled";
  const share = isPlanMine(plan) && shareAccess === "enabled";
  return (
    <BottomSheet open={open} onClose={onClose} title={plan.name || t("library.ui.untitled")}>
      <div className="space-y-2">
        {shefi ? <SheetOption icon="auto_awesome" label={t("plans.askShefi")} onClick={() => navigate(`/assistant?scope=plan&id=${encodeURIComponent(plan.id)}`)} /> : null}
        {share ? <SheetOption icon="person_add_alt_1" label={t("plans.sharePlan")} onClick={() => navigate(`/sharing/share?kind=mealPlan&id=${encodeURIComponent(plan.id)}`)} /> : null}
        {canRename ? <SheetOption icon="drive_file_rename_outline" label={t("plans.rename")} onClick={onRename} /> : null}
        <SheetOption icon={leaves ? "logout" : "delete_outline"} label={leaves ? t("plans.leave") : t("plans.deletePlan")} destructive onClick={onDelete} />
      </div>
    </BottomSheet>
  );
}
