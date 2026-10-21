// The groceries tab's pieces below lg, drawn to the app's own widgets
// (grocery_list_page.dart, grocery_lists_ui.dart, grocery_item_card.dart,
// grocery_section.dart, grocery_progress_card.dart, meal_plan_filter_card.dart,
// price_widgets.dart GroceryCostCard / PriceChip). Desktop never draws these.
import { useId, useMemo, useRef, useState, type ReactNode } from "react";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { Icon } from "../../components/icons";
import { BottomSheet, SheetOption } from "../../components/BottomSheet";
import { ClayButton, ClayCard, ClayIconButton, ClayTag, ProgressGroove, RoundCheckbox } from "../../components/clay";
import { usePhoneNavigate } from "../../components/pageTransition";
import { MEASUREMENT_UNITS, type MeasurementUnit } from "../../models/recipe";
import { checkedCount, isMyList, canEditList, totalAmount, type GroceryItem, type GroceryList, type GroceryListSource, type PlanLike } from "../../models/groceryList";
import type { PriceUnit } from "../../models/priceRecord";
import { formatAmount, parseAmount, priceLabel } from "./kit";
import { ScaleStepper, useUnitLabel } from "./dialogs";
import { groceryUnitFor, multiplierFor, type PriceEstimate } from "../prices/priceBook";
import type { ListsManager } from "./listsManager";

const cx = (...c: (string | false | null | undefined)[]) => c.filter(Boolean).join(" ");

/** chevron_right that mirrors in RTL and turns a quarter clockwise when open (AnimatedRotation 0.25). */
const chevron = (open: boolean) =>
  cx("transition-transform duration-[240ms] ease-[cubic-bezier(.23,1,.32,1)]", open ? "[transform:rotate(90deg)] rtl:[transform:rotate(90deg)_scaleX(-1)]" : "rtl:[transform:scaleX(-1)]");

export const sourceIconOf = (s: GroceryListSource) => (s === "plans" ? "calendar_month" : s === "recipe" ? "restaurant_menu" : "edit_note");

/** GroceryListSwitcherCard: the open list, what it is made of, how many lists; a tap opens the lists sheet. */
export function SwitcherCard({ name, sourceLabel, source, count, onOpen }: { name: string; sourceLabel: string; source: GroceryListSource; count: number; onOpen: () => void }) {
  const { t } = useI18n();
  return (
    <ClayCard radius={24} padding={24} onClick={onOpen} aria-haspopup="dialog">
      <span className="flex items-center gap-3">
        <span className="grid shrink-0 place-items-center rounded-[8px] bg-primary-fixed p-2 text-primary" aria-hidden="true">
          <Icon name={sourceIconOf(source)} size={20} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-body-lg text-on-surface">{name}</span>
          <span className="block truncate text-label-md text-on-surface-variant">{sourceLabel}</span>
        </span>
        <span className="flex shrink-0 items-center gap-1 rounded-full border border-outline-variant bg-surface-low px-3 py-1 text-label-sm text-primary">
          {count <= 1 ? t("groceries.oneList") : t("groceries.listsCount", { count })}
          <Icon name="unfold_more" size={16} />
        </span>
      </span>
    </ClayCard>
  );
}

/** The shared-list role tag (ClayTag group_rounded on mint). */
export function RoleTag({ list }: { list: GroceryList }) {
  const { t } = useI18n();
  const label = list.collabRole === "owner" ? t("groceries.tag.owner") : list.collabRole === "editor" ? t("groceries.tag.editor") : t("groceries.tag.viewer");
  return (
    <ClayTag icon="group" className="bg-secondary-container text-on-secondary-container">
      {label}
    </ClayTag>
  );
}

/** MealPlanFilterCard: which menus feed the list, a drawer of their names, and the picker button. */
export function PlanFilterCard({ list, plans, editable, busy, onPick }: { list: GroceryList; plans: PlanLike[]; editable: boolean; busy: boolean; onPick: () => void }) {
  const { t } = useI18n();
  const [open, setOpen] = useState(false);
  const all = list.selectedPlanIds.length === 0;
  const included = all ? plans : plans.filter((p) => list.selectedPlanIds.includes(p.id));
  const summary = all ? t("groceries.planFilter") : included.length === 1 ? t("groceries.onePlanSelected") : t("groceries.plansSelected", { count: included.length });
  const drawer = useId();
  return (
    <ClayCard radius={24} padding={24}>
      <button type="button" className="flex w-full items-center gap-3 text-start" aria-expanded={open} aria-controls={drawer} onClick={() => setOpen((o) => !o)}>
        <Icon name="filter_list" size={20} className="shrink-0 text-primary" />
        <span className="min-w-0 flex-1">
          <span className="block text-body-lg text-on-surface">{summary}</span>
          <span className="block truncate text-label-md text-on-surface-variant">{all ? t("groceries.allPlansHint") : included.map((p) => p.name).join(" · ")}</span>
        </span>
        <span className="shrink-0 text-tertiary transition-transform duration-[180ms]" style={{ transform: open ? "rotate(180deg)" : undefined }} aria-hidden="true">
          <Icon name="keyboard_arrow_down" size={24} />
        </span>
      </button>
      <div id={drawer} hidden={!open} className="pt-3">
        {included.length === 0 ? (
          <p className="text-label-md text-on-surface-variant">{t("groceries.noPlansToPick")}</p>
        ) : (
          <div className="flex flex-wrap gap-2">
            {included.map((p) => (
              <ClayTag key={p.id} icon="calendar_today">
                {p.name}
              </ClayTag>
            ))}
          </div>
        )}
      </div>
      <div className="mt-6">
        <ClayButton icon="checklist" expanded onClick={onPick} disabled={plans.length === 0 || !editable || busy}>
          {t("groceries.choosePlans")}
        </ClayButton>
      </div>
    </ClayCard>
  );
}

/** RecipeListCard: the recipe and how much of it. */
export function RecipeCard({ title, list, editable, onScale }: { title: string; list: GroceryList; editable: boolean; onScale: (s: number) => void }) {
  return (
    <ClayCard radius={24} padding={24}>
      <div className="flex items-center gap-3">
        <Icon name="restaurant_menu" size={20} className="shrink-0 text-primary" />
        <p className="min-w-0 flex-1 truncate text-body-lg">{title}</p>
      </div>
      <div className={cx("mt-3", !editable && "opacity-50")}>
        <ScaleStepper scale={list.recipeScale} baseServings={list.recipeServings} disabled={!editable} onChange={onScale} />
      </div>
    </ClayCard>
  );
}

/** GroceryProgressCard: r48 p24, label + percent, the groove, "x of y collected". */
export function ProgressCard({ collected, total }: { collected: number; total: number }) {
  const { t } = useI18n();
  const ratio = total === 0 ? 0 : collected / total;
  return (
    <ClayCard radius={48} padding={24} as="section" aria-label={t("groceries.collectionProgress")}>
      <div className="flex items-center gap-3">
        <p className="min-w-0 flex-1 text-label-md text-on-surface">{t("groceries.collectionProgress")}</p>
        <p className="text-headline-md text-primary" dir="ltr">
          {Math.round(ratio * 100)}%
        </p>
      </div>
      <div className="mt-3">
        <ProgressGroove value={ratio} label={t("groceries.collectionProgress")} />
      </div>
      <p className="mt-3 text-end text-label-sm text-outline">{t("groceries.itemsCollected", { collected, total })}</p>
    </ClayCard>
  );
}

/** _BulkAction: a pill ClayCard, icon 18 + 8 + labelMd. */
export function BulkAction({ icon, label, onClick, destructive = false }: { icon: string; label: string; onClick: (() => void) | null; destructive?: boolean }) {
  const ink = !onClick ? "text-outline-variant" : destructive ? "text-error" : "text-primary";
  return (
    <button
      type="button"
      onClick={onClick ?? undefined}
      disabled={!onClick}
      className={cx("clay-card press flex min-w-0 flex-1 items-center justify-center gap-2 rounded-full p-3", ink)}
    >
      <Icon name={icon} size={18} className="shrink-0" />
      <span className="truncate text-label-md">{label}</span>
    </button>
  );
}

/** GrocerySection: a collapsible group with a rotating chevron and a count pill. */
export function Section({ title, count, initiallyOpen = true, children }: { title: string; count: number; initiallyOpen?: boolean; children: ReactNode }) {
  const [open, setOpen] = useState(initiallyOpen);
  const body = useId();
  return (
    <section>
      <h2>
        <button type="button" className="flex w-full items-center gap-2 border-b border-surface-highest pb-2 text-start" aria-expanded={open} aria-controls={body} onClick={() => setOpen((o) => !o)}>
          <span className={cx("shrink-0 text-primary", chevron(open))} aria-hidden="true">
            <Icon name="chevron_right" size={24} />
          </span>
          <span className="min-w-0 flex-1 text-headline-md">{title}</span>
          <span className="shrink-0 rounded-full bg-primary-fixed px-3 py-1 text-label-sm text-primary">{count}</span>
        </button>
      </h2>
      <div id={body} hidden={!open}>
        {count ? <ul className="space-y-3 pt-4">{children}</ul> : null}
      </div>
    </section>
  );
}

/** PriceChip: the figure with its source mark, or a muted "no data". */
function PriceChip({ estimate, multiplier }: { estimate: PriceEstimate; multiplier: number }) {
  const { t } = useI18n();
  if (estimate.unitPrice === null) return <span className="text-label-sm text-outline-variant">{t("prices.noData")}</span>;
  return (
    <span className="flex items-center gap-[3px]" dir="ltr">
      <Icon name={estimate.basis === "community" ? "groups" : "receipt_long"} size={13} className="text-outline" />
      <span className="text-label-md font-extrabold text-on-surface">{priceLabel(estimate.unitPrice * multiplier, estimate.currency)}</span>
    </span>
  );
}

/**
 * GroceryItemCard: a spine card, a chevron that opens the source breakdown,
 * the name and amount, the price chip (tap = record a price) and the round
 * checkbox. Swiping end → start removes the line (Dismissible).
 */
export function ItemCard({
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
  const [dx, setDx] = useState(0);
  const [leaving, setLeaving] = useState(false);
  const drag = useRef<{ x: number; y: number; w: number; sign: number; on: boolean; moved: boolean } | null>(null);
  const amount = `${formatAmount(totalAmount(item))} ${unitLabel}`.trim();
  const hasSources = item.sources.length > 0;
  const multiplier = estimate ? multiplierFor(item, estimate) : 1;
  const breakdown = useId();

  // Dismissible(endToStart): RTL end is the left edge, so the line moves right.
  const onPointerDown = (e: React.PointerEvent<HTMLLIElement>) => {
    if (!editable || e.pointerType === "mouse") return;
    const rtl = getComputedStyle(e.currentTarget).direction === "rtl";
    drag.current = { x: e.clientX, y: e.clientY, w: e.currentTarget.offsetWidth, sign: rtl ? 1 : -1, on: false, moved: false };
  };
  const onPointerMove = (e: React.PointerEvent<HTMLLIElement>) => {
    const d = drag.current;
    if (!d) return;
    const mx = e.clientX - d.x;
    const my = e.clientY - d.y;
    if (!d.on) {
      if (Math.abs(my) > 10 && Math.abs(my) > Math.abs(mx)) {
        drag.current = null;
        return;
      }
      if (Math.abs(mx) < 10) return;
      d.on = true;
      d.moved = true;
      e.currentTarget.setPointerCapture(e.pointerId);
    }
    setDx(Math.max(0, mx * d.sign) * d.sign);
  };
  const onPointerUp = () => {
    const d = drag.current;
    drag.current = null;
    if (!d?.on) return;
    if (Math.abs(dx) > d.w * 0.4) {
      setLeaving(true);
      setDx(d.sign * d.w);
      navigator.vibrate?.(15);
      window.setTimeout(onRemove, 200);
    } else setDx(0);
  };

  return (
    <li
      className="relative [contain-intrinsic-size:auto_76px] [content-visibility:auto]"
      style={{ touchAction: "pan-y" }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
    >
      {dx !== 0 ? (
        <div className="absolute inset-0 flex items-center justify-end rounded-std bg-error-container pe-5 text-on-error-container" aria-hidden="true">
          <Icon name="delete" size={24} />
        </div>
      ) : null}
      <div
        className="clay-card has-spine relative overflow-hidden"
        style={{
          borderRadius: 16,
          ["--spine" as string]: "rgb(var(--c-primary-fixed) / .7)",
          transform: dx ? `translateX(${dx}px)` : undefined,
          transition: drag.current?.on ? "none" : "transform 200ms cubic-bezier(.23,1,.32,1)",
          opacity: leaving ? 0.6 : 1,
        }}
      >
        <div className="flex items-center gap-2 p-4 ps-8">
          <button
            type="button"
            className="flex min-w-0 flex-1 items-center gap-2 text-start"
            aria-expanded={hasSources ? open : undefined}
            aria-controls={hasSources ? breakdown : undefined}
            disabled={!hasSources}
            onClick={() => setOpen((o) => !o)}
          >
            {hasSources ? (
              <span className={cx("shrink-0 text-outline", chevron(open))} aria-hidden="true">
                <Icon name="chevron_right" size={24} />
              </span>
            ) : (
              <span className="w-6 shrink-0" aria-hidden="true" />
            )}
            <span className="min-w-0 flex-1">
              <span className={cx("block break-words text-body-lg", item.isChecked ? "text-outline line-through" : "text-on-surface")}>{item.name}</span>
              {amount ? <span className="block text-label-md text-outline-variant">{amount}</span> : null}
            </span>
          </button>
          {estimate ? (
            <button
              type="button"
              onClick={() => onPrice(estimate)}
              disabled={!editable}
              className="me-2 shrink-0 rounded-[8px] p-1"
              aria-label={t("groceries.setPrice", { name: item.name })}
              title={estimate.basis === "community" ? t("prices.fromCommunity") : estimate.basis === "personal" ? t("prices.fromReceipt") : undefined}
            >
              <PriceChip estimate={estimate} multiplier={multiplier} />
            </button>
          ) : null}
          <RoundCheckbox checked={item.isChecked} disabled={!editable} onChange={onToggle} label={t("groceries.check", { name: item.name })} />
        </div>
        {open && hasSources ? (
          <div id={breakdown} className="bg-surface-low pb-3 pe-4 ps-8 pt-3">
            <p className="sr-only">{t("groceries.breakdownTitle")}</p>
            <ul>
              {item.sources.map((s, i) => (
                <li key={i} className="flex gap-3 py-1 text-label-md text-on-surface-variant">
                  <span className="min-w-0 flex-1">{s.label}</span>
                  <span>{`${formatAmount(s.amount)} ${unitLabel}`.trim()}</span>
                </li>
              ))}
            </ul>
            {editable ? (
              <div className="text-end">
                <button type="button" className="press inline-flex min-h-10 items-center gap-2 rounded-full px-3 text-label-md text-primary" onClick={onAdjust}>
                  <Icon name="tune" size={16} /> {t("groceries.adjustAmounts")}
                </button>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>
    </li>
  );
}

/** GroceryCostCard: the estimated total, the honesty line, and the scan button. */
export function CostCard({ total, priced, unpriced, currency, onScan }: { total: number; priced: number; unpriced: number; currency: string; onScan: (() => void) | null }) {
  const { t } = useI18n();
  return (
    <ClayCard radius={24} padding={16} as="section" aria-label={t("prices.estimatedTotal")}>
      <div className="flex items-center gap-3">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-warm-accent/[.18] text-warm-accent" aria-hidden="true">
          <Icon name="payments" size={24} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-label-md text-on-surface-variant">{t("prices.estimatedTotal")}</p>
          <p className="text-headline-md font-extrabold">
            <bdi dir={priced > 0 ? "ltr" : undefined}>{priced > 0 ? priceLabel(total, currency) : t("prices.noData")}</bdi>
          </p>
          <p className="text-label-sm text-outline">{unpriced > 0 ? `${t("prices.estimated")} · ${t("prices.unpriced", { count: unpriced })}` : t("prices.estimated")}</p>
        </div>
        {onScan ? <ClayIconButton icon="document_scanner" filled size={44} label={t("prices.title")} onClick={onScan} /> : null}
      </div>
    </ClayCard>
  );
}

/** The lists bottom sheet (_ListsSheet): every list, the open one filled; a row menu; "new list". */
export function ListsSheet({
  open,
  onClose,
  lists,
  names,
  activeId,
  manager,
  onOpenList,
  sourceLabelOf,
}: {
  open: boolean;
  onClose: () => void;
  lists: GroceryList[];
  names: Map<string, string>;
  activeId: string | null;
  manager: ListsManager;
  onOpenList: (id: string) => void;
  sourceLabelOf: (l: GroceryList) => string;
}) {
  const { t } = useI18n();
  const go = usePhoneNavigate();
  const shareAccess = useAccess("ff_share_grocery_lists");
  const [menuFor, setMenuFor] = useState<GroceryList | null>(null);
  const lastMenu = useRef<GroceryList | null>(null);
  if (menuFor) lastMenu.current = menuFor;
  const m = menuFor ?? lastMenu.current;
  const leaves = !!m && m.collabId !== null && !isMyList(m);
  return (
    <>
      <BottomSheet
        open={open}
        onClose={onClose}
        title={t("groceries.myLists")}
        footer={
          <ClayButton
            icon="add"
            expanded
            onClick={() => {
              onClose();
              manager.startNew();
            }}
          >
            {t("groceries.newList")}
          </ClayButton>
        }
      >
        <div className="-mt-2 mb-4 border-b border-surface-highest" aria-hidden="true" />
        <ul className="space-y-3 pb-2">
          {lists.map((l) => {
            const isOpen = l.id === activeId;
            const name = names.get(l.id) ?? l.name;
            return (
              <li key={l.id}>
                <div className={cx("clay-card flex items-center gap-3 py-3 pe-1 ps-6", isOpen && "!bg-primary-fixed")} style={{ borderRadius: 24 }}>
                  <button
                    type="button"
                    className="press flex min-w-0 flex-1 items-center gap-3 text-start"
                    aria-current={isOpen || undefined}
                    onClick={() => {
                      onOpenList(l.id);
                      onClose();
                    }}
                  >
                    <Icon name={isOpen ? "check_circle" : sourceIconOf(l.source)} size={22} className="shrink-0 text-primary" />
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-body-lg">{name}</span>
                      <span className="block truncate text-label-md text-on-surface-variant">{sourceLabelOf(l)}</span>
                    </span>
                    {l.collabId ? <Icon name="group" size={16} className="shrink-0 text-tertiary" /> : null}
                    {l.items.length ? (
                      <span className="shrink-0 text-label-md text-tertiary" dir="ltr">
                        {t("groceries.progress", { checked: checkedCount(l), total: l.items.length })}
                      </span>
                    ) : null}
                  </button>
                  <button
                    type="button"
                    className="press-icon grid h-12 w-12 shrink-0 place-items-center rounded-full text-tertiary"
                    aria-label={t("groceries.listActions", { name })}
                    aria-haspopup="dialog"
                    disabled={manager.busy === l.id}
                    onClick={() => setMenuFor(l)}
                  >
                    <Icon name="more_vert" size={24} />
                  </button>
                </div>
              </li>
            );
          })}
        </ul>
      </BottomSheet>
      <BottomSheet open={menuFor !== null} onClose={() => setMenuFor(null)} title={m ? names.get(m.id) ?? m.name : ""}>
        {m ? (
          <div className="space-y-2">
            {canEditList(m) ? (
              <SheetOption
                icon="edit"
                label={t("groceries.renameList")}
                onClick={() => {
                  setMenuFor(null);
                  void manager.rename(m);
                }}
              />
            ) : null}
            {isMyList(m) && shareAccess !== "hidden" ? (
              <SheetOption
                icon="ios_share"
                label={t("groceries.share")}
                onClick={() => {
                  setMenuFor(null);
                  onClose();
                  go(`/sharing/share?kind=groceryList&id=${encodeURIComponent(m.id)}`);
                }}
              />
            ) : null}
            <SheetOption
              icon={leaves ? "logout" : "delete_outline"}
              label={leaves ? t("groceries.leave") : t("groceries.deleteList")}
              destructive
              onClick={() => {
                setMenuFor(null);
                void manager.remove(m);
              }}
            />
          </div>
        ) : null}
      </BottomSheet>
    </>
  );
}

/** showAddGroceryItemSheet: pick from prices, name, amount, unit chips, add. */
export function AddItemSheet({
  open,
  onClose,
  knownProducts,
  onAdd,
}: {
  open: boolean;
  onClose: () => void;
  knownProducts: { name: string; unit: PriceUnit }[];
  onAdd: (name: string, amount: number, unit: MeasurementUnit) => void;
}) {
  const { t } = useI18n();
  const units = useUnitLabel();
  const id = useId();
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("1");
  const [unit, setUnit] = useState<MeasurementUnit>("unit");
  const [picking, setPicking] = useState(false);
  const [wasOpen, setWasOpen] = useState(open);
  if (open !== wasOpen) {
    setWasOpen(open);
    if (open) {
      setName("");
      setAmount("1");
      setUnit("unit");
    }
  }
  const products = useMemo(() => {
    const m = new Map<string, PriceUnit>();
    for (const p of knownProducts) if (!m.has(p.name)) m.set(p.name, p.unit);
    return [...m.entries()].sort((a, b) => a[0].localeCompare(b[0]));
  }, [knownProducts]);
  const submit = () => {
    const n = name.trim();
    if (!n) return;
    onAdd(n, parseAmount(amount) ?? 1, unit);
    onClose();
  };
  return (
    <>
      <BottomSheet
        open={open && !picking}
        onClose={onClose}
        title={t("groceries.addItem")}
        footer={
          <ClayButton icon="add" expanded type="submit" form={id} disabled={!name.trim()}>
            {t("groceries.common.add")}
          </ClayButton>
        }
      >
        <form
          id={id}
          className="space-y-3"
          onSubmit={(e) => {
            e.preventDefault();
            submit();
          }}
        >
          {products.length ? (
            <ClayButton icon="sell" expanded onClick={() => setPicking(true)}>
              {t("prices.pickFromPrices")}
            </ClayButton>
          ) : null}
          <div className="space-y-1.5">
            <label htmlFor={`${id}-name`} className="block text-label-md text-on-surface-variant">
              {t("groceries.itemName")}
            </label>
            <input id={`${id}-name`} className="clay-input" value={name} maxLength={120} onChange={(e) => setName(e.target.value)} autoFocus />
          </div>
          <div className="space-y-1.5">
            <label htmlFor={`${id}-amount`} className="block text-label-md text-on-surface-variant">
              {t("groceries.amount")}
            </label>
            <input id={`${id}-amount`} className="clay-input" inputMode="decimal" dir="ltr" value={amount} onChange={(e) => setAmount(e.target.value.replace(/[^0-9.,]/g, ""))} />
          </div>
          <fieldset className="pt-1">
            <legend className="mb-2 text-label-md">{t("groceries.unit")}</legend>
            <div className="flex flex-wrap gap-2">
              {MEASUREMENT_UNITS.map((u) => (
                <button
                  key={u}
                  type="button"
                  aria-pressed={unit === u}
                  onClick={() => setUnit(u)}
                  className={cx(
                    "press rounded-full border px-3 py-2 text-label-md transition-colors duration-[180ms]",
                    unit === u ? "border-primary bg-primary text-on-primary" : "border-outline-variant bg-surface-low text-tertiary",
                  )}
                >
                  {units.picker(u)}
                </button>
              ))}
            </div>
          </fieldset>
        </form>
      </BottomSheet>
      <ProductPickerSheet
        open={open && picking}
        products={products}
        onClose={() => setPicking(false)}
        onPick={(n, u) => {
          setName(n);
          setUnit(groceryUnitFor(u));
          setPicking(false);
        }}
      />
    </>
  );
}

/** showProductPickerSheet: the products the receipts know, searchable. */
function ProductPickerSheet({ open, products, onClose, onPick }: { open: boolean; products: [string, PriceUnit][]; onClose: () => void; onPick: (name: string, unit: PriceUnit) => void }) {
  const { t } = useI18n();
  const [q, setQ] = useState("");
  const shown = products.filter(([n]) => !q.trim() || n.toLowerCase().includes(q.trim().toLowerCase()));
  return (
    <BottomSheet open={open} onClose={onClose} title={t("prices.pickerTitle")}>
      <label className="sr-only" htmlFor="product-picker-q">
        {t("prices.search")}
      </label>
      <input id="product-picker-q" type="search" className="clay-input mb-3" placeholder={t("prices.search")} value={q} onChange={(e) => setQ(e.target.value)} />
      <ul className="space-y-2 pb-2">
        {shown.map(([n, u]) => (
          <li key={n}>
            <button type="button" className="clay-card press flex w-full items-center gap-3 px-4 py-3 text-start" style={{ borderRadius: 16 }} onClick={() => onPick(n, u)}>
              <Icon name="sell" size={20} className="shrink-0 text-primary" />
              <span className="min-w-0 flex-1 truncate text-body-md">{n}</span>
            </button>
          </li>
        ))}
      </ul>
    </BottomSheet>
  );
}
