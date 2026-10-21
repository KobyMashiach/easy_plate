// One grocery list (grocery_list_page.dart + its bloc): what it is made from,
// the lines to buy and the lines bought side by side on a wide screen, ticks
// that reach every device at once, quick entry, a line's breakdown, rebuild
// that keeps ticks and hand-added lines, the estimated cost (ff_grocery_cost),
// and a read-only view for a viewer of a shared list.
import { useEffect, useId, useMemo, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { newId, useCollection } from "../../lib/cloud";
import { useTranslated } from "../../lib/contentTranslation";
import { FeatureGate } from "../../components/FeatureGate";
import { ShareLink } from "../../components/ShareLink";
import { Icon } from "../../components/icons";
import { Notice, Spinner } from "../../components/ui";
import { MEASUREMENT_UNITS, type MeasurementUnit } from "../../models/recipe";
import {
  adHocItem,
  canEditList,
  canRegenerate,
  includesAllPlans,
  isMyList,
  planLikeOf,
  rescaleRecipeList,
  totalAmount,
  type GroceryItem,
  type GroceryList,
} from "../../models/groceryList";
import type { PriceUnit } from "../../models/priceRecord";
import { EmptyState, IconButton, Loading, formatAmount, parseAmount, priceLabel, useConfirm, usePrompt, useShownRecipeTitles, useStatus } from "./kit";
import { BreakdownDialog, PlanPickerDialog, ScaleStepper, useUnitLabel } from "./dialogs";
import { deleteList, mergeRebuilt, rebuiltItems, useLiveGroceryList, writeActiveList } from "./store";
import { groceryUnitFor, multiplierFor, summarize, useEstimator, usePriceBook, type PriceEstimate } from "../prices/priceBook";
import { AddPriceDialog } from "../prices/dialogs";
import { AskShefiLink } from "../assistant/AskShefiLink";
import { useIsPhone } from "../../components/useIsPhone";
import { usePhoneNavigate } from "../../components/pageTransition";
import { FloatingHeaderView } from "../../components/FloatingHeaderView";
import { ClayButton, ClayIconButton, EmptyState as ClayEmptyState, LoadingSpinner } from "../../components/clay";
import { PhoneGroceries } from "./PhoneGroceries";
import type { ListsManager } from "./listsManager";
import { AddItemSheet, BulkAction, CostCard, ItemCard, ListsSheet, PlanFilterCard, ProgressCard, RecipeCard, RoleTag, Section, SwitcherCard } from "./phoneParts";

export function GroceryListPage() {
  const { id = "" } = useParams();
  const phone = useIsPhone();
  // Below lg the list is the groceries tab itself (PhoneGroceries).
  return phone ? <PhoneGroceries routeId={id} /> : <GroceryListView id={id} />;
}

/** What the phone tab hands the list: every list, their shown names, and the list actions. */
export interface PhoneTab {
  lists: GroceryList[];
  names: Map<string, string>;
  manager: ListsManager;
  onOpenList: (id: string) => void;
}

export function GroceryListView({ id, phone }: { id: string; phone?: PhoneTab }) {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const { list, error, mutate } = useLiveGroceryList(user?.uid, id, lang);
  // Names in the language on screen, for drawing only: ticks, removals,
  // prices and the cost estimate all work on the stored items.
  const translatedList = useTranslated("groceryList", list);
  const shownNames = useMemo(() => new Map((translatedList && translatedList !== list ? translatedList.items : []).map((i) => [i.id, i.name])), [translatedList, list]);
  // Recipe titles in its sources and "made from" line, translated too.
  const refersToRecipes = !!list && (!!list.recipeId || list.items.some((i) => i.sources.some((s) => s.recipeId)));
  const recipeTitles = useShownRecipeTitles(user?.uid, refersToRecipes);
  const costAccess = useAccess("ff_grocery_cost");
  const bookAccess = useAccess("ff_price_book");
  const book = usePriceBook(costAccess === "enabled" || bookAccess === "enabled" ? user?.uid : null, { receipts: false });
  const estimateFor = useEstimator(book);
  const plansLive = useCollection<unknown>("meal_plans", user?.uid);
  const plans = useMemo(() => (plansLive.items ?? []).map(planLikeOf).sort((a, b) => a.name.localeCompare(b.name)), [plansLive.items]);
  const units = useUnitLabel();
  const status = useStatus();
  const prompt = usePrompt();
  const { ask, element: confirm } = useConfirm();

  const [rebuilding, setRebuilding] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [pickingPlans, setPickingPlans] = useState(false);
  const [breakdownId, setBreakdownId] = useState<string | null>(null);
  const [pricing, setPricing] = useState<{ name: string; price: number | null; unit: PriceUnit } | null>(null);
  const [boughtOpen, setBoughtOpen] = useState(() => typeof window !== "undefined" && window.matchMedia?.("(min-width: 1024px)").matches);
  const [listsOpen, setListsOpen] = useState(false);
  const [addingItem, setAddingItem] = useState(false);
  const go = usePhoneNavigate();
  const scanAccess = useAccess("ff_receipt_scan");

  useEffect(() => {
    if (user && list) writeActiveList(user.uid, list.id);
  }, [user, list?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const write = async (fn: (l: GroceryList) => GroceryList) => {
    const result = await mutate(fn);
    if (result === "gone") status.show("error", t("groceries.notFound"));
    else if (result === "failed") status.show("error", t("groceries.saveFailed"));
  };

  const back = (
    <Link to="/groceries" className="mb-4 inline-flex items-center gap-1 text-label-md text-primary">
      <span className="rtl:rotate-180" aria-hidden="true">
        <Icon name="back" size={18} />
      </span>
      {t("groceries.backToLists")}
    </Link>
  );

  if (phone && list === undefined && !error) return <LoadingSpinner label={t("common.loading")} />;
  if (phone && (list === null || list === undefined))
    return list === null ? <ClayEmptyState icon="shopping_basket" message={t("groceries.notFound")} /> : <Notice kind="error">{t("groceries.common.loadFailed")}</Notice>;
  if (error && list === undefined) return <>{back}<Notice kind="error">{t("groceries.common.loadFailed")}</Notice></>;
  if (list === undefined) return <Loading />;
  if (list === null)
    return (
      <>
        {back}
        <EmptyState icon="groceries" text={t("groceries.notFound")} />
      </>
    );

  const editable = canEditList(list);
  const unchecked = list.items.filter((i) => !i.isChecked);
  const checked = list.items.filter((i) => i.isChecked);
  const allChecked = unchecked.length === 0;
  const breakdownItem = list.items.find((i) => i.id === breakdownId) ?? null;
  const leaves = list.collabId !== null && !isMyList(list);

  /** Rebuilds from what the list is made of; ticks and hand-added lines stay. */
  const regenerate = async (base: GroceryList = list) => {
    if (rebuilding || !canRegenerate(base)) return;
    setRebuilding(true);
    try {
      const built = await rebuiltItems(base);
      // The rebuild awaited plans and recipes: another list may be open by
      // now (nothing to write then), and ticks made meanwhile come from the
      // list as it is now.
      if (built) await write((l) => (l.id !== base.id ? l : { ...l, items: mergeRebuilt(l, built) }));
    } catch {
      status.show("error", t("groceries.saveFailed"));
    } finally {
      setRebuilding(false);
    }
  };

  const selectPlans = async (ids: string[]) => {
    setPickingPlans(false);
    await write((l) => ({ ...l, selectedPlanIds: ids }));
    await regenerate({ ...list, selectedPlanIds: ids });
  };

  const rename = async () => {
    const name = await prompt.ask(t("groceries.renameList"), t("groceries.listName"), list.name);
    if (name && name !== list.name) await write((l) => ({ ...l, name }));
  };

  const remove = async () => {
    const ok = await ask(leaves ? t("groceries.leave") : t("groceries.deleteList"), {
      body: leaves ? t("groceries.leaveListConfirm", { name: list.name }) : t("groceries.deleteListConfirm", { name: list.name }),
      confirm: leaves ? t("groceries.leave") : t("groceries.common.delete"),
    });
    if (!ok) return;
    setDeleting(true);
    try {
      await deleteList(list);
      navigate("/groceries", { replace: true });
    } catch {
      status.show("error", t("groceries.saveFailed"));
      setDeleting(false);
    }
  };

  const clearChecked = async () => {
    const ok = await ask(t("groceries.deleteChecked"), { body: t("groceries.clearCheckedConfirm", { count: checked.length }), confirm: t("groceries.common.delete") });
    if (ok) await write((l) => ({ ...l, items: l.items.filter((i) => !i.isChecked) }));
  };

  const removeItem = (item: GroceryItem) => {
    const at = list.items.findIndex((i) => i.id === item.id);
    void write((l) => ({ ...l, items: l.items.filter((i) => i.id !== item.id) }));
    status.show("info", t("groceries.itemRemoved", { name: item.name }), {
      label: t("groceries.undo"),
      run: () =>
        void write((l) => {
          if (l.items.some((i) => i.id === item.id)) return l;
          const items = [...l.items];
          items.splice(Math.min(at, items.length), 0, item);
          return { ...l, items };
        }),
    });
  };

  const updateItem = (itemId: string, fn: (i: GroceryItem) => GroceryItem) => void write((l) => ({ ...l, items: l.items.map((i) => (i.id === itemId ? fn(i) : i)) }));

  /**
   * Where the source the sheet meant now sits (GroceryListBloc.sourcePosition):
   * its index when it still holds that source, else the first with the same
   * recipe and label, else -1 — another device may have changed the line.
   */
  const sourceAt = (item: GroceryItem, index: number, meant: GroceryItem["sources"][number] | undefined): number => {
    if (!meant) return -1;
    const same = (s: GroceryItem["sources"][number]) => s.recipeId === meant.recipeId && s.label === meant.label;
    if (index >= 0 && index < item.sources.length && same(item.sources[index])) return index;
    return item.sources.findIndex(same);
  };
  const adjustSource = (itemId: string, index: number, change: (i: GroceryItem, at: number) => GroceryItem) => {
    const meant = list.items.find((i) => i.id === itemId)?.sources[index];
    updateItem(itemId, (i) => {
      const at = sourceAt(i, index, meant);
      return at < 0 ? i : change(i, at);
    });
  };

  const costEnabled = costAccess === "enabled";
  const cost = costEnabled ? summarize(unchecked.map((i) => ((e) => ({ estimate: e, multiplier: multiplierFor(i, e) }))(estimateFor(i)))) : null;
  const roleTag = list.collabRole === "owner" ? t("groceries.tag.owner") : list.collabRole === "editor" ? t("groceries.tag.editor") : t("groceries.tag.viewer");
  const madeFrom = (list.recipeId ? recipeTitles.get(list.recipeId) : undefined) ?? list.recipeTitle ?? list.name;
  const sourceLabel =
    list.source === "plans" ? t("groceries.sourcePlans") : list.source === "recipe" ? t("groceries.sourceRecipe", { title: madeFrom }) : t("groceries.sourceManual");
  const shownItem = (item: GroceryItem): GroceryItem => {
    const named = shownNames.has(item.id) ? { ...item, name: shownNames.get(item.id)! } : item;
    if (!recipeTitles.size || !item.sources.some((s) => s.recipeId && recipeTitles.has(s.recipeId))) return named;
    return { ...named, sources: named.sources.map((s) => (s.recipeId && recipeTitles.has(s.recipeId) ? { ...s, label: recipeTitles.get(s.recipeId)! } : s)) };
  };
  const plansLabel = includesAllPlans(list) ? t("groceries.planFilter") : list.selectedPlanIds.length === 1 ? t("groceries.onePlanSelected") : t("groceries.plansSelected", { count: list.selectedPlanIds.length });

  const phoneRow = (item: GroceryItem) => (
    <ItemCard
      key={item.id}
      item={shownItem(item)}
      editable={editable}
      unitLabel={units.label(item.unit)}
      estimate={costEnabled ? estimateFor(item) : null}
      onToggle={() => updateItem(item.id, (i) => ({ ...i, isChecked: !item.isChecked }))}
      onRemove={() => removeItem(item)}
      onAdjust={() => setBreakdownId(item.id)}
      onPrice={(e) => setPricing({ name: item.name, price: e.unitPrice, unit: e.unit })}
    />
  );
  const row = (item: GroceryItem) => (
    <ItemRow
      key={item.id}
      item={shownItem(item)}
      editable={editable}
      unitLabel={units.label(item.unit)}
      estimate={costEnabled ? estimateFor(item) : null}
      onToggle={() => updateItem(item.id, (i) => ({ ...i, isChecked: !item.isChecked }))}
      onRemove={() => removeItem(item)}
      onAdjust={() => setBreakdownId(item.id)}
      onPrice={(e) => setPricing({ name: item.name, price: e.unitPrice, unit: e.unit })}
    />
  );

  const dialogs = (
    <>
      <PlanPickerDialog open={pickingPlans} plans={plans} selected={list.selectedPlanIds} onClose={() => setPickingPlans(false)} onApply={(ids) => void selectPlans(ids)} />
      <BreakdownDialog
        item={editable ? breakdownItem : null}
        onClose={() => setBreakdownId(null)}
        onAdjust={(index, amount) => adjustSource(breakdownItem!.id, index, (i, at) => ({ ...i, sources: i.sources.map((s, j) => (j === at ? { ...s, amount } : s)) }))}
        onRemoveSource={(index) => adjustSource(breakdownItem!.id, index, (i, at) => (i.sources.length <= 1 ? i : { ...i, sources: i.sources.filter((_, j) => j !== at) }))}
        onUnit={(unit) => updateItem(breakdownItem!.id, (i) => ({ ...i, unit }))}
        onBuffer={(amount) => updateItem(breakdownItem!.id, (i) => ({ ...i, sources: [...i.sources, { recipeId: null, label: t("groceries.buffer"), amount }] }))}
      />
      <AddPriceDialog
        open={pricing !== null}
        initial={pricing ?? undefined}
        onDone={(saved) => {
          setPricing(null);
          if (saved) status.show("success", t("prices.priceSaved"));
        }}
      />
      {prompt.element}
      {confirm}
      {status.element}
    </>
  );

  if (phone) {
    const priceBookShown = bookAccess !== "hidden";
    const nButtons = (priceBookShown ? 1 : 0) + (editable ? 2 : 0);
    const shownName = phone.names.get(list.id) ?? (translatedList ?? list).name;
    const sourceLabelOf = (l: GroceryList) =>
      l.source === "plans" ? t("groceries.sourcePlans") : l.source === "recipe" ? t("groceries.sourceRecipe", { title: (l.recipeId ? recipeTitles.get(l.recipeId) : undefined) ?? l.recipeTitle ?? l.name }) : t("groceries.sourceManual");
    const actions = (
      <>
        {priceBookShown ? <ClayIconButton icon="receipt_long" size={48} label={t("prices.priceBook")} onClick={() => go("/prices")} /> : null}
        {editable ? (
          <>
            <ClayIconButton
              icon="autorenew"
              size={48}
              label={list.source === "recipe" ? t("groceries.rebuildFromRecipe") : t("groceries.aggregated")}
              onClick={() => void regenerate()}
              disabled={!canRegenerate(list) || rebuilding}
              iconClassName={rebuilding ? "animate-spin" : ""}
            />
            <ClayIconButton icon="add" size={48} filled label={t("groceries.addItem")} onClick={() => setAddingItem(true)} />
          </>
        ) : null}
      </>
    );
    const scan = scanAccess === "hidden" ? null : () => go("/prices/scan");
    return (
      <FloatingHeaderView title={t("groceries.title")} actions={nButtons ? actions : undefined} actionCount={nButtons} bottomGap={32}>
        <div>
          <SwitcherCard name={shownName} sourceLabel={sourceLabel} source={list.source} count={phone.lists.length} onOpen={() => setListsOpen(true)} />
          {list.collabId ? (
            <div className="mt-4">
              <RoleTag list={list} />
            </div>
          ) : null}
          {list.source === "plans" ? (
            <div className="mt-4">
              <PlanFilterCard list={list} plans={plans} editable={editable} busy={rebuilding} onPick={() => setPickingPlans(true)} />
            </div>
          ) : list.source === "recipe" ? (
            <div className="mt-4">
              <RecipeCard title={madeFrom} list={list} editable={editable} onScale={(s) => void write((l) => rescaleRecipeList(l, s))} />
            </div>
          ) : null}
          {list.items.length === 0 ? (
            <div className="mt-6">
              <ClayEmptyState
                icon="shopping_basket"
                message={t("groceries.empty")}
                action={
                  !editable ? undefined : list.source === "manual" ? (
                    <ClayButton icon="add" onClick={() => setAddingItem(true)}>
                      {t("groceries.addFirstItem")}
                    </ClayButton>
                  ) : (
                    <ClayButton icon="autorenew" onClick={() => void regenerate()} busy={rebuilding}>
                      {list.source === "recipe" ? t("groceries.rebuildFromRecipe") : t("groceries.aggregated")}
                    </ClayButton>
                  )
                }
              />
            </div>
          ) : (
            <>
              <div className="mt-4">
                <ProgressCard collected={checked.length} total={list.items.length} />
              </div>
              {editable ? (
                <div className="mt-4 flex gap-3">
                  <BulkAction
                    icon={allChecked ? "remove_done" : "done_all"}
                    label={allChecked ? t("groceries.clearAll") : t("groceries.selectAll")}
                    onClick={() => void write((l) => ({ ...l, items: l.items.map((i) => ({ ...i, isChecked: !allChecked })) }))}
                  />
                  <BulkAction icon="delete_sweep" label={t("groceries.deleteChecked")} destructive onClick={checked.length ? () => void clearChecked() : null} />
                </div>
              ) : null}
              <div className="mt-8">
                <Section title={t("groceries.uncheckedSection")} count={unchecked.length}>
                  {unchecked.map(phoneRow)}
                </Section>
              </div>
              <div className="mt-8">
                <Section title={t("groceries.checkedSection")} count={checked.length} initiallyOpen={false}>
                  {checked.map(phoneRow)}
                </Section>
              </div>
              {cost ? (
                <div className="mt-8">
                  <CostCard total={cost.knownTotal} priced={cost.pricedItems} unpriced={cost.unpricedItems} currency={cost.currency} onScan={scan} />
                </div>
              ) : null}
            </>
          )}
        </div>
        <ListsSheet
          open={listsOpen}
          onClose={() => setListsOpen(false)}
          lists={phone.lists}
          names={phone.names}
          activeId={list.id}
          manager={phone.manager}
          onOpenList={phone.onOpenList}
          sourceLabelOf={sourceLabelOf}
        />
        <AddItemSheet
          open={addingItem}
          onClose={() => setAddingItem(false)}
          knownProducts={book.records ?? []}
          onAdd={(name, amount, unit) => void write((l) => ({ ...l, items: [...l.items, adHocItem(newId(), name, amount, unit)] }))}
        />
        {dialogs}
      </FloatingHeaderView>
    );
  }

  return (
    <>
      {back}
      <header className="mb-5 flex flex-wrap items-start gap-3">
        <div className="min-w-0 flex-1">
          <h1 className="break-words text-headline-lg">{(translatedList ?? list).name}</h1>
          <p className="mt-1 flex flex-wrap items-center gap-2 text-body-md text-on-surface-variant">
            <span>{sourceLabel}</span>
            {list.collabId ? <span className="pill-lavender">{roleTag}</span> : null}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <FeatureGate flag="ff_price_book">
            <Link to="/prices" className="grid h-11 w-11 place-items-center rounded-full bg-surface-low text-on-surface hover:bg-surface-high" aria-label={t("prices.priceBook")} title={t("prices.priceBook")}>
              <Icon name="prices" size={20} />
            </Link>
          </FeatureGate>
          <AskShefiLink kind="list" id={list.id} compact />
          <ShareLink kind="groceryList" id={list.id} mine={list.collabRole === null || list.collabRole === "owner"} compact />
          {editable ? (
            <>
              <IconButton icon="edit" label={t("groceries.renameList")} onClick={() => void rename()} />
              <IconButton
                icon="refresh"
                label={list.source === "recipe" ? t("groceries.rebuildFromRecipe") : t("groceries.aggregated")}
                onClick={() => void regenerate()}
                disabled={!canRegenerate(list)}
                busy={rebuilding}
              />
            </>
          ) : null}
          <IconButton icon={leaves ? "logout" : "trash"} tone="danger" label={leaves ? t("groceries.leave") : t("groceries.deleteList")} onClick={() => void remove()} busy={deleting} />
        </div>
      </header>

      {!editable ? (
        <div className="mb-4">
          <Notice kind="info">{t("groceries.readOnlyHint")}</Notice>
        </div>
      ) : null}

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_340px]">
        <div className="min-w-0 space-y-5">
          {editable ? <QuickEntry knownProducts={book.records ?? []} onAdd={(name, amount, unit) => void write((l) => ({ ...l, items: [...l.items, adHocItem(newId(), name, amount, unit)] }))} /> : null}

          {list.items.length === 0 ? (
            <EmptyState
              icon="groceries"
              text={t("groceries.empty")}
              action={
                editable && list.source !== "manual" ? (
                  <button type="button" className="clay-btn-primary" onClick={() => void regenerate()} disabled={rebuilding} aria-busy={rebuilding || undefined}>
                    {rebuilding ? <Spinner small /> : <Icon name="refresh" size={18} />}
                    {list.source === "recipe" ? t("groceries.rebuildFromRecipe") : t("groceries.aggregated")}
                  </button>
                ) : undefined
              }
            />
          ) : (
            <div className="grid gap-5 xl:grid-cols-2">
              <section aria-labelledby="to-buy" className="min-w-0">
                <h2 id="to-buy" className="mb-3 flex items-center gap-2 border-b border-surface-high pb-2 text-headline-md">
                  <span className="flex-1">{t("groceries.uncheckedSection")}</span>
                  <span className="pill-mint">{unchecked.length}</span>
                </h2>
                {unchecked.length ? <ul className="space-y-2">{unchecked.map(row)}</ul> : <p className="py-4 text-on-surface-variant">{t("groceries.allBought")}</p>}
              </section>
              <section aria-labelledby="bought" className="min-w-0">
                <h2 id="bought" className="mb-3 border-b border-surface-high pb-2 text-headline-md">
                  <button type="button" className="flex w-full items-center gap-2 text-start" aria-expanded={boughtOpen} aria-controls="bought-items" onClick={() => setBoughtOpen((o) => !o)}>
                    <span className={`text-primary transition-transform ${boughtOpen ? "rotate-90" : "rtl:rotate-180"}`} aria-hidden="true">
                      <Icon name="chevron" size={20} />
                    </span>
                    <span className="flex-1">{t("groceries.checkedSection")}</span>
                    <span className="pill-grey">{checked.length}</span>
                  </button>
                </h2>
                <div id="bought-items" hidden={!boughtOpen}>
                  {checked.length ? <ul className="space-y-2">{checked.map(row)}</ul> : <p className="py-4 text-on-surface-variant">{t("groceries.noneBought")}</p>}
                </div>
              </section>
            </div>
          )}
        </div>

        <aside className="space-y-4 lg:sticky lg:top-4 lg:self-start">
          {list.items.length ? (
            <section className="clay space-y-2 p-5" aria-label={t("groceries.collectionProgress")}>
              <p className="text-label-md text-on-surface-variant">{t("groceries.collectionProgress")}</p>
              <p className="text-headline-md">{t("groceries.itemsCollected", { collected: checked.length, total: list.items.length })}</p>
              <div className="h-2.5 overflow-hidden rounded-full bg-surface-low" role="progressbar" aria-valuemin={0} aria-valuemax={list.items.length} aria-valuenow={checked.length} aria-label={t("groceries.collectionProgress")}>
                <div className="h-full rounded-full bg-primary transition-[width]" style={{ width: `${Math.round((checked.length / list.items.length) * 100)}%` }} />
              </div>
              {editable ? (
                <div className="flex flex-wrap gap-2 pt-2">
                  <button type="button" className="clay-btn-ghost flex-1" onClick={() => void write((l) => ({ ...l, items: l.items.map((i) => ({ ...i, isChecked: !allChecked })) }))}>
                    <Icon name="check" size={18} /> {allChecked ? t("groceries.clearAll") : t("groceries.selectAll")}
                  </button>
                  <button type="button" className="clay-btn-ghost flex-1 !text-error" onClick={() => void clearChecked()} disabled={checked.length === 0}>
                    <Icon name="trash" size={18} /> {t("groceries.deleteChecked")}
                  </button>
                </div>
              ) : null}
            </section>
          ) : null}

          {cost ? (
            <section className="clay space-y-1 p-5" aria-labelledby="cost-title">
              <p id="cost-title" className="text-label-md text-on-surface-variant">
                {t("prices.estimatedTotal")}
              </p>
              <p className="text-headline-md font-extrabold" dir="ltr">
                {cost.pricedItems > 0 ? priceLabel(cost.knownTotal, cost.currency) : t("prices.noData")}
              </p>
              <p className="text-label-sm text-outline">{cost.unpricedItems > 0 ? `${t("prices.estimated")} · ${t("prices.unpriced", { count: cost.unpricedItems })}` : t("prices.estimated")}</p>
              <FeatureGate flag="ff_receipt_scan">
                <Link to="/prices/scan" className="clay-btn-tonal mt-2 w-full">
                  <Icon name="upload" size={18} /> {t("prices.title")}
                </Link>
              </FeatureGate>
            </section>
          ) : null}

          {list.source === "plans" ? (
            <section className="clay space-y-3 p-5">
              <p className="text-body-md font-bold">{plansLabel}</p>
              <p className="text-label-sm text-on-surface-variant">{plans.length === 0 ? t("groceries.noPlansToPick") : includesAllPlans(list) ? t("groceries.allPlansHint") : plans.filter((p) => list.selectedPlanIds.includes(p.id)).map((p) => p.name).join(" · ")}</p>
              {editable ? (
                <button type="button" className="clay-btn-tonal w-full" onClick={() => setPickingPlans(true)} disabled={plans.length === 0 || rebuilding}>
                  <Icon name="filter" size={18} /> {t("groceries.choosePlans")}
                </button>
              ) : null}
            </section>
          ) : list.source === "recipe" ? (
            <section className="clay space-y-3 p-5">
              <p className="text-body-md font-bold">{madeFrom}</p>
              <ScaleStepper scale={list.recipeScale} baseServings={list.recipeServings} disabled={!editable} onChange={(s) => void write((l) => rescaleRecipeList(l, s))} />
            </section>
          ) : null}
        </aside>
      </div>

      {dialogs}
    </>
  );
}

function ItemRow({
  item,
  editable,
  unitLabel,
  estimate,
  onToggle,
  onRemove,
  onAdjust,
  onPrice,
}: {
  item: GroceryItem;
  editable: boolean;
  unitLabel: string;
  estimate: PriceEstimate | null;
  onToggle: () => void;
  onRemove: () => void;
  onAdjust: () => void;
  onPrice: (e: PriceEstimate) => void;
}) {
  const { t } = useI18n();
  const [open, setOpen] = useState(false);
  const amount = `${formatAmount(totalAmount(item))} ${unitLabel}`.trim();
  const cbId = useId();
  const multiplier = estimate ? multiplierFor(item, estimate) : 1;
  return (
    <li className="clay overflow-hidden p-0 [content-visibility:auto] [contain-intrinsic-size:auto_68px]">
      <div className="flex items-center gap-2 p-3">
        <input
          id={cbId}
          type="checkbox"
          className="h-6 w-6 shrink-0 cursor-pointer accent-[rgb(var(--c-primary))] disabled:cursor-default"
          checked={item.isChecked}
          disabled={!editable}
          onChange={onToggle}
          aria-label={t("groceries.check", { name: item.name })}
        />
        <button type="button" className="flex min-w-0 flex-1 items-center gap-2 text-start" aria-expanded={open} onClick={() => setOpen((o) => !o)} disabled={item.sources.length === 0}>
          <span className={`text-outline transition-transform ${open ? "rotate-90" : "rtl:rotate-180"}`} aria-hidden="true">
            <Icon name="chevron" size={18} />
          </span>
          <span className="min-w-0 flex-1">
            <span className={`block break-words text-body-lg ${item.isChecked ? "text-outline line-through" : ""}`}>{item.name}</span>
            {amount ? <span className="block text-label-md text-on-surface-variant">{amount}</span> : null}
          </span>
        </button>
        {estimate ? (
          <button type="button" onClick={() => onPrice(estimate)} className="shrink-0 rounded-std px-2 py-1 hover:bg-surface-low" aria-label={t("groceries.setPrice", { name: item.name })} title={estimate.basis === "community" ? t("prices.fromCommunity") : estimate.basis === "personal" ? t("prices.fromReceipt") : undefined}>
            {estimate.unitPrice === null ? (
              <span className="text-label-sm text-outline-variant">{t("prices.noData")}</span>
            ) : (
              <span className="flex items-center gap-1 text-label-md font-extrabold" dir="ltr">
                <Icon name={estimate.basis === "community" ? "users" : "file"} size={13} />
                {priceLabel(estimate.unitPrice * multiplier, estimate.currency)}
              </span>
            )}
          </button>
        ) : null}
        {editable ? <IconButton icon="trash" tone="danger" label={t("groceries.removeItem", { name: item.name })} onClick={onRemove} /> : null}
      </div>
      {open ? (
        <div className="bg-surface-low px-5 py-3">
          <p className="sr-only">{t("groceries.breakdownTitle")}</p>
          <ul className="space-y-1">
            {item.sources.map((s, i) => (
              <li key={i} className="flex gap-3 text-label-md text-on-surface-variant">
                <span className="min-w-0 flex-1 truncate">{s.label}</span>
                <span>{`${formatAmount(s.amount)} ${unitLabel}`.trim()}</span>
              </li>
            ))}
          </ul>
          {editable ? (
            <div className="mt-2 text-end">
              <button type="button" className="inline-flex items-center gap-1 text-label-md text-primary" onClick={onAdjust}>
                <Icon name="edit" size={16} /> {t("groceries.adjustAmounts")}
              </button>
            </div>
          ) : null}
        </div>
      ) : null}
    </li>
  );
}

/** The add sheet, inline: name (known products suggested), amount with comma decimals, unit. */
function QuickEntry({ knownProducts, onAdd }: { knownProducts: { name: string; unit: PriceUnit }[]; onAdd: (name: string, amount: number, unit: MeasurementUnit) => void }) {
  const { t } = useI18n();
  const units = useUnitLabel();
  const id = useId();
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("1");
  const [unit, setUnit] = useState<MeasurementUnit>("unit");
  const [invalid, setInvalid] = useState(false);
  const nameRef = useRef<HTMLInputElement>(null);
  const products = useMemo(() => {
    const m = new Map<string, PriceUnit>();
    for (const p of knownProducts) if (!m.has(p.name)) m.set(p.name, p.unit);
    return m;
  }, [knownProducts]);
  return (
    <form
      className="clay flex flex-wrap items-end gap-2 p-4"
      aria-label={t("groceries.addItem")}
      onSubmit={(e) => {
        e.preventDefault();
        const n = name.trim();
        if (!n) return;
        const a = amount.trim() === "" ? 1 : parseAmount(amount);
        if (a === null) {
          setInvalid(true);
          return;
        }
        onAdd(n, a, unit);
        setName("");
        setAmount("1");
        setInvalid(false);
        nameRef.current?.focus();
      }}
    >
      <div className="min-w-[12rem] flex-[3] space-y-1.5">
        <label htmlFor={`${id}-name`} className="block text-label-md text-on-surface-variant">
          {t("groceries.itemName")}
        </label>
        <input
          ref={nameRef}
          id={`${id}-name`}
          className="clay-input"
          list={products.size ? `${id}-known` : undefined}
          value={name}
          maxLength={120}
          onChange={(e) => {
            setName(e.target.value);
            const known = products.get(e.target.value);
            if (known) setUnit(groceryUnitFor(known));
          }}
        />
        {products.size ? (
          <datalist id={`${id}-known`} aria-label={t("groceries.knownProducts")}>
            {[...products.keys()].map((p) => (
              <option key={p} value={p} />
            ))}
          </datalist>
        ) : null}
      </div>
      <div className="w-24 space-y-1.5">
        <label htmlFor={`${id}-amount`} className="block text-label-md text-on-surface-variant">
          {t("groceries.amount")}
        </label>
        <input
          id={`${id}-amount`}
          className="clay-input"
          inputMode="decimal"
          dir="ltr"
          value={amount}
          aria-invalid={invalid ? "true" : undefined}
          aria-describedby={invalid ? `${id}-err` : undefined}
          onChange={(e) => {
            setAmount(e.target.value.replace(/[^0-9.,]/g, ""));
            setInvalid(false);
          }}
        />
      </div>
      <div className="w-36 space-y-1.5">
        <label htmlFor={`${id}-unit`} className="block text-label-md text-on-surface-variant">
          {t("groceries.unit")}
        </label>
        <select id={`${id}-unit`} className="clay-input" value={unit} onChange={(e) => setUnit(e.target.value as MeasurementUnit)}>
          {MEASUREMENT_UNITS.map((u) => (
            <option key={u} value={u}>
              {units.picker(u)}
            </option>
          ))}
        </select>
      </div>
      <button type="submit" className="clay-btn-primary" disabled={!name.trim()}>
        <Icon name="add" size={18} /> {t("groceries.common.add")}
      </button>
      {invalid ? (
        <p id={`${id}-err`} role="alert" className="w-full text-label-sm text-error">
          {t("groceries.amountInvalid")}
        </p>
      ) : null}
    </form>
  );
}
