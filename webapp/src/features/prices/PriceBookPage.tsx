// The price book (price_book_page.dart): every receipt, and the latest price
// of every product, each sortable and filterable; typing a price, scanning a
// receipt, a product's pricing choice, and deleting.
import { useMemo, useRef, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { FeatureGate } from "../../components/FeatureGate";
import { Icon } from "../../components/icons";
import { Notice } from "../../components/ui";
import { MANUAL_RECEIPT_ID, PRICE_UNITS, type PriceRecord, type PriceUnit } from "../../models/priceRecord";
import type { Receipt } from "../../models/receipt";
import { Chip, EmptyState, IconButton, Loading, priceLabel, useConfirm, useStatus } from "../groceries/kit";
import { deleteAll, deleteReceipt, usePriceBook } from "./priceBook";
import { useIsPhone } from "../../components/useIsPhone";
import { useAccess } from "../../lib/flags";
import { PhoneBar } from "../../components/PhoneBar";
import { BottomSheet } from "../../components/BottomSheet";
import { usePhoneNavigate } from "../../components/pageTransition";
import { ClayButton, ClayCard, ClayIconButton, EmptyState as ClayEmptyState, LoadingSpinner, PageHeader, SegmentedControl } from "../../components/clay";
import { AddPriceDialog, ProductPricingDialog, useDeleteReceiptChoice, usePriceUnitLabel, useShortDate } from "./dialogs";

type ReceiptSort = "date" | "store" | "total";
type PriceSort = "name" | "date" | "price";
const ms = (iso: string) => Date.parse(iso) || 0;

export function PriceBookPage() {
  const { t } = useI18n();
  const { user } = useAuth();
  const book = usePriceBook(user?.uid);
  const date = useShortDate();
  const unitLabel = usePriceUnitLabel();
  const status = useStatus();
  const { ask, element: confirm } = useConfirm();
  const receiptChoice = useDeleteReceiptChoice();

  const [tab, setTab] = useState<"receipts" | "prices">("receipts");
  const [receiptSort, setReceiptSort] = useState<ReceiptSort>("date");
  const [priceSort, setPriceSort] = useState<PriceSort>("name");
  const [query, setQuery] = useState("");
  const [storeFilter, setStoreFilter] = useState<string | null>(null);
  const [periodDays, setPeriodDays] = useState<number | null>(null);
  const [priceStore, setPriceStore] = useState<string | null>(null);
  const [unitFilter, setUnitFilter] = useState<PriceUnit | null>(null);
  const [manualFilter, setManualFilter] = useState<boolean | null>(null);
  const [adding, setAdding] = useState(false);
  const [product, setProduct] = useState<PriceRecord | null>(null);
  const [busy, setBusy] = useState(false);

  const records = useMemo(() => book.records ?? [], [book.records]);
  const receipts = useMemo(() => book.receipts ?? [], [book.receipts]);
  const loading = book.records === null || book.receipts === null;

  const receiptStores = useMemo(() => [...new Set(receipts.map((r) => r.store).filter((s): s is string => !!s))].sort(), [receipts]);
  const recordStores = useMemo(() => [...new Set(records.map((r) => r.store).filter((s): s is string => !!s))].sort(), [records]);

  const shownReceipts = useMemo(() => {
    const now = Date.now();
    const list = receipts
      .filter((r) => storeFilter === null || r.store === storeFilter)
      .filter((r) => periodDays === null || (now - ms(r.purchasedAt)) / 86_400_000 <= periodDays);
    if (receiptSort === "date") list.sort((a, b) => ms(b.purchasedAt) - ms(a.purchasedAt));
    else if (receiptSort === "store") list.sort((a, b) => (a.store ?? "").localeCompare(b.store ?? ""));
    else list.sort((a, b) => b.total - a.total);
    return list;
  }, [receipts, storeFilter, periodDays, receiptSort]);

  /** One line per product (name + unit): its most recent record — at the filtered store, when one is chosen. */
  const latestPrices = useMemo(() => {
    const latest = new Map<string, PriceRecord>();
    for (const r of records) {
      if (priceStore !== null && r.store !== priceStore) continue;
      const key = `${r.normalizedName}|${r.unit}`;
      const have = latest.get(key);
      if (!have || ms(r.purchasedAt) > ms(have.purchasedAt)) latest.set(key, r);
    }
    const q = query.trim().toLowerCase();
    const list = [...latest.values()]
      .filter((r) => !q || r.name.toLowerCase().includes(q))
      .filter((r) => unitFilter === null || r.unit === unitFilter)
      .filter((r) => manualFilter === null || (r.receiptId === MANUAL_RECEIPT_ID) === manualFilter);
    if (priceSort === "name") list.sort((a, b) => a.name.localeCompare(b.name));
    else if (priceSort === "date") list.sort((a, b) => ms(b.purchasedAt) - ms(a.purchasedAt));
    else list.sort((a, b) => b.unitPrice - a.unitPrice);
    return list;
  }, [records, priceStore, query, unitFilter, manualFilter, priceSort]);

  const removeReceipt = async (r: Receipt) => {
    const keep = await receiptChoice.ask();
    if (keep === null) return;
    setBusy(true);
    try {
      await deleteReceipt(r, records, keep);
    } catch {
      status.show("error", t("prices.deleteFailed"));
    } finally {
      setBusy(false);
    }
  };

  const removeAll = async () => {
    const ok = await ask(t("prices.deleteAll"), { body: t("prices.deleteAllBody"), confirm: t("groceries.common.delete") });
    if (!ok) return;
    setBusy(true);
    try {
      await deleteAll(book);
    } catch {
      status.show("error", t("prices.deleteFailed"));
    } finally {
      setBusy(false);
    }
  };

  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const scanAccess = useAccess("ff_receipt_scan");
  const [filtering, setFiltering] = useState(false);
  const longPress = useLongPress();

  const filtersActive = tab === "receipts" ? storeFilter !== null || periodDays !== null : priceStore !== null || unitFilter !== null || manualFilter !== null;

  if (phone) {
    const receiptsTab = tab === "receipts";
    return (
      <>
        <PhoneBar title={t("prices.priceBook")} />
        <PageHeader
          title={t("prices.priceBook")}
          trailing={
            <>
              {!receiptsTab && records.length > 0 ? <ClayIconButton icon="delete_sweep" size={48} label={t("prices.deleteAll")} onClick={() => void removeAll()} disabled={busy} /> : null}
              <ClayIconButton icon="sell" size={48} label={t("prices.addPrice")} onClick={() => setAdding(true)} />
              {scanAccess !== "hidden" ? <ClayIconButton icon="document_scanner" size={48} filled label={t("prices.title")} onClick={() => go("/prices/scan")} /> : null}
            </>
          }
        />
        <SegmentedControl
          className="mt-4"
          label={t("prices.priceBook")}
          value={tab}
          onChange={setTab}
          segments={[
            { value: "receipts", label: t("prices.receipts"), icon: "receipt_long" },
            { value: "prices", label: t("prices.prices"), icon: "sell" },
          ]}
        />
        <div className="mt-3">
          {!receiptsTab ? (
            <div className="relative mb-2">
              <label htmlFor="price-search-phone" className="sr-only">
                {t("prices.search")}
              </label>
              <Icon name="search" size={20} className="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-on-surface-variant" />
              <input id="price-search-phone" type="search" className="clay-input !min-h-[44px] ps-10" placeholder={t("prices.search")} value={query} onChange={(e) => setQuery(e.target.value)} />
            </div>
          ) : null}
          <div className="flex items-center gap-2">
            <div className="flex min-w-0 flex-1 items-center gap-2 overflow-x-auto">
              <span className="shrink-0 text-label-md text-on-surface-variant">{t("prices.sortBy")}</span>
              {receiptsTab
                ? (["date", "store", "total"] as const).map((v) => (
                    <SortChip key={v} selected={receiptSort === v} onClick={() => setReceiptSort(v)}>
                      {v === "date" ? t("prices.sortDate") : v === "store" ? t("prices.sortStore") : t("prices.sortTotal")}
                    </SortChip>
                  ))
                : (["name", "date", "price"] as const).map((v) => (
                    <SortChip key={v} selected={priceSort === v} onClick={() => setPriceSort(v)}>
                      {v === "name" ? t("prices.sortName") : v === "date" ? t("prices.sortDate") : t("prices.price")}
                    </SortChip>
                  ))}
            </div>
            <button
              type="button"
              onClick={() => setFiltering(true)}
              aria-label={t("prices.filter")}
              title={t("prices.filter")}
              aria-pressed={filtersActive}
              className={`press-icon grid h-10 w-10 shrink-0 place-items-center rounded-full ${filtersActive ? "bg-primary-fixed text-primary" : "bg-surface-low text-tertiary"}`}
            >
              <Icon name="filter_alt" size={20} />
            </button>
          </div>
        </div>
        {book.error ? (
          <div className="mt-3">
            <Notice kind="error">{t("groceries.common.loadFailed")}</Notice>
          </div>
        ) : null}
        <div className="mt-3">
          {loading ? (
            book.error ? null : <LoadingSpinner label={t("common.loading")} />
          ) : receiptsTab ? (
            shownReceipts.length === 0 ? (
              <ClayEmptyState icon="receipt_long" message={receipts.length === 0 ? t("prices.priceBookEmpty") : t("prices.noReceipts")} />
            ) : (
              <ul className="space-y-3">
                {shownReceipts.map((r) => (
                  <li key={r.id}>
                    <Link to={`/prices/receipts/${encodeURIComponent(r.id)}`} className="clay-card press block w-full text-start" style={{ borderRadius: 24, padding: 16 }} {...longPress(() => void removeReceipt(r))}>
                      <span className="flex items-center gap-3">
                        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
                          <Icon name="receipt_long" size={24} />
                        </span>
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-body-lg text-on-surface">{r.store ?? "—"}</span>
                          <span className="block text-label-md text-on-surface-variant">
                            {date(r.purchasedAt)} · {t("prices.itemsInReceipt", { count: r.itemCount })}
                          </span>
                        </span>
                        <span className="shrink-0 text-body-lg font-extrabold text-on-surface" dir="ltr">
                          {priceLabel(r.total, r.currency)}
                        </span>
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            )
          ) : latestPrices.length === 0 ? (
            <ClayEmptyState icon="sell" message={t("prices.noPrices")} />
          ) : (
            <ul className="space-y-2">
              {latestPrices.map((r) => (
                <li key={`${r.normalizedName}|${r.unit}`}>
                  <ClayCard radius={24} padding={0} onClick={() => setProduct(r)} aria-label={t("prices.productActions", { name: r.name })} className="!px-4 !py-3">
                    <span className="flex items-center gap-3">
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-body-md text-on-surface">{r.name}</span>
                        <span className="block text-label-sm text-on-surface-variant">
                          {r.receiptId === MANUAL_RECEIPT_ID ? t("prices.manualSource") : (r.store ?? t("prices.lastPaid"))} · {date(r.purchasedAt)}
                        </span>
                      </span>
                      <span className="shrink-0 text-end">
                        <span className="block text-body-lg font-extrabold text-on-surface" dir="ltr">
                          {priceLabel(r.unitPrice, r.currency)}
                        </span>
                        <span className="block text-label-sm text-on-surface-variant">{unitLabel(r.unit)}</span>
                      </span>
                    </span>
                  </ClayCard>
                </li>
              ))}
            </ul>
          )}
        </div>
        <FilterSheet
          open={filtering}
          onClose={() => setFiltering(false)}
          rows={
            receiptsTab
              ? [
                  { values: [null, ...receiptStores], selected: storeFilter, label: (s: string | null) => s ?? t("prices.allStores") },
                  { values: [null, 30, 90], selected: periodDays, label: (d: number | null) => (d === null ? t("prices.periodAll") : d === 30 ? t("prices.period30") : t("prices.period90")) },
                ]
              : [
                  { values: [null, ...recordStores], selected: priceStore, label: (s: string | null) => s ?? t("prices.allStores") },
                  { values: [null, ...PRICE_UNITS], selected: unitFilter, label: (u: PriceUnit | null) => (u === null ? t("prices.filterAll") : unitLabel(u)) },
                  { values: [null, false, true], selected: manualFilter, label: (m: boolean | null) => (m === null ? t("prices.filterAll") : m ? t("prices.sourceManual") : t("prices.sourceReceipt")) },
                ]
          }
          onApply={(picked) => {
            if (receiptsTab) {
              setStoreFilter(picked[0] as string | null);
              setPeriodDays(picked[1] as number | null);
            } else {
              setPriceStore(picked[0] as string | null);
              setUnitFilter(picked[1] as PriceUnit | null);
              setManualFilter(picked[2] as boolean | null);
            }
            setFiltering(false);
          }}
        />
        <AddPriceDialog
          open={adding}
          onDone={(saved) => {
            setAdding(false);
            if (saved) status.show("success", t("prices.priceSaved"));
          }}
        />
        <ProductPricingDialog product={product} records={records} receipts={receipts} pricing={book.pricing} onClose={() => setProduct(null)} onStatus={(k, text) => status.show(k, text)} />
        {confirm}
        {receiptChoice.element}
        {status.element}
      </>
    );
  }

  return (
    <>
      <header className="mb-5 flex flex-wrap items-center gap-3">
        <h1 className="min-w-0 flex-1 text-headline-lg">{t("prices.priceBook")}</h1>
        <div className="flex items-center gap-2">
          {tab === "prices" && records.length > 0 ? <IconButton icon="trash" label={t("prices.deleteAll")} tone="danger" onClick={() => void removeAll()} busy={busy} /> : null}
          <button type="button" className="clay-btn-tonal" onClick={() => setAdding(true)}>
            <Icon name="add" size={18} /> {t("prices.addPrice")}
          </button>
          <FeatureGate flag="ff_receipt_scan">
            <Link to="/prices/scan" className="clay-btn-primary">
              <Icon name="upload" size={18} /> {t("prices.title")}
            </Link>
          </FeatureGate>
        </div>
      </header>

      <div role="tablist" aria-label={t("prices.priceBook")} className="mb-4 inline-flex rounded-full bg-surface-low p-1">
        {(["receipts", "prices"] as const).map((k) => (
          <button
            key={k}
            role="tab"
            type="button"
            aria-selected={tab === k}
            aria-controls={`panel-${k}`}
            id={`tab-${k}`}
            onClick={() => setTab(k)}
            className={`rounded-full px-5 py-2 text-label-md ${tab === k ? "bg-primary text-on-primary shadow-button" : "text-on-surface-variant"}`}
          >
            {k === "receipts" ? t("prices.receipts") : t("prices.prices")}
          </button>
        ))}
      </div>

      {book.error ? (
        <div className="mb-4">
          <Notice kind="error">{t("groceries.common.loadFailed")}</Notice>
        </div>
      ) : null}

      <section className="clay mb-4 space-y-3 p-4" aria-label={t("prices.filter")}>
        {tab === "prices" ? (
          <div className="space-y-1.5">
            <label htmlFor="price-search" className="sr-only">
              {t("prices.search")}
            </label>
            <input id="price-search" type="search" className="clay-input" placeholder={t("prices.search")} value={query} onChange={(e) => setQuery(e.target.value)} />
          </div>
        ) : null}
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-label-md text-on-surface-variant">{t("prices.sortBy")}</span>
          {tab === "receipts"
            ? (["date", "store", "total"] as const).map((s) => (
                <Chip key={s} selected={receiptSort === s} onClick={() => setReceiptSort(s)}>
                  {s === "date" ? t("prices.sortDate") : s === "store" ? t("prices.sortStore") : t("prices.sortTotal")}
                </Chip>
              ))
            : (["name", "date", "price"] as const).map((s) => (
                <Chip key={s} selected={priceSort === s} onClick={() => setPriceSort(s)}>
                  {s === "name" ? t("prices.sortName") : s === "date" ? t("prices.sortDate") : t("prices.price")}
                </Chip>
              ))}
        </div>
        <details className="group" open={filtersActive || undefined}>
          <summary className="flex cursor-pointer list-none items-center gap-2 text-label-md text-primary">
            <Icon name="filter" size={18} /> {t("prices.filter")}
            {filtersActive ? <span className="h-2 w-2 rounded-full bg-primary" aria-hidden="true" /> : null}
          </summary>
          <div className="mt-3 space-y-2">
            {tab === "receipts" ? (
              <>
                <div className="flex flex-wrap gap-2">
                  {[null, ...receiptStores].map((s) => (
                    <Chip key={s ?? "_all"} selected={storeFilter === s} onClick={() => setStoreFilter(s)}>
                      {s ?? t("prices.allStores")}
                    </Chip>
                  ))}
                </div>
                <div className="flex flex-wrap gap-2">
                  {[null, 30, 90].map((d) => (
                    <Chip key={d ?? 0} selected={periodDays === d} onClick={() => setPeriodDays(d)}>
                      {d === null ? t("prices.periodAll") : d === 30 ? t("prices.period30") : t("prices.period90")}
                    </Chip>
                  ))}
                </div>
              </>
            ) : (
              <>
                <div className="flex flex-wrap gap-2">
                  {[null, ...recordStores].map((s) => (
                    <Chip key={s ?? "_all"} selected={priceStore === s} onClick={() => setPriceStore(s)}>
                      {s ?? t("prices.allStores")}
                    </Chip>
                  ))}
                </div>
                <div className="flex flex-wrap gap-2">
                  {[null, ...PRICE_UNITS].map((u) => (
                    <Chip key={u ?? "_all"} selected={unitFilter === u} onClick={() => setUnitFilter(u)}>
                      {u === null ? t("prices.filterAll") : unitLabel(u)}
                    </Chip>
                  ))}
                </div>
                <div className="flex flex-wrap gap-2">
                  {[null, false, true].map((m) => (
                    <Chip key={String(m)} selected={manualFilter === m} onClick={() => setManualFilter(m)}>
                      {m === null ? t("prices.filterAll") : m ? t("prices.sourceManual") : t("prices.sourceReceipt")}
                    </Chip>
                  ))}
                </div>
              </>
            )}
            {filtersActive ? (
              <button
                type="button"
                className="text-label-md text-primary underline"
                onClick={() => {
                  if (tab === "receipts") {
                    setStoreFilter(null);
                    setPeriodDays(null);
                  } else {
                    setPriceStore(null);
                    setUnitFilter(null);
                    setManualFilter(null);
                  }
                }}
              >
                {t("prices.clearFilters")}
              </button>
            ) : null}
          </div>
        </details>
      </section>

      {loading ? (
        book.error ? null : <Loading />
      ) : tab === "receipts" ? (
        <div id="panel-receipts" role="tabpanel" aria-labelledby="tab-receipts">
          {shownReceipts.length === 0 ? (
            <EmptyState icon="file" text={receipts.length === 0 ? t("prices.priceBookEmpty") : t("prices.noReceipts")} />
          ) : (
            <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
              {shownReceipts.map((r) => (
                <li key={r.id} className="clay flex items-center gap-3 p-4 [content-visibility:auto] [contain-intrinsic-size:auto_80px]">
                  <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
                    <Icon name="file" size={20} />
                  </span>
                  <Link to={`/prices/receipts/${encodeURIComponent(r.id)}`} className="min-w-0 flex-1">
                    <span className="block truncate text-body-md font-bold">{r.store ?? t("prices.noStore")}</span>
                    <span className="block text-label-sm text-on-surface-variant">
                      {date(r.purchasedAt)} · {t("prices.itemsInReceipt", { count: r.itemCount })}
                    </span>
                  </Link>
                  <span className="text-body-lg font-extrabold" dir="ltr">
                    {priceLabel(r.total, r.currency)}
                  </span>
                  <IconButton icon="trash" tone="danger" label={`${t("prices.deleteReceipt")} — ${r.store ?? t("prices.noStore")}`} onClick={() => void removeReceipt(r)} disabled={busy} />
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : (
        <div id="panel-prices" role="tabpanel" aria-labelledby="tab-prices">
          {latestPrices.length === 0 ? (
            <EmptyState icon="prices" text={t("prices.noPrices")} />
          ) : (
            <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
              {latestPrices.map((r) => (
                <li key={`${r.normalizedName}|${r.unit}`}>
                  <button type="button" onClick={() => setProduct(r)} className="clay flex w-full items-center gap-3 p-4 text-start transition-transform active:scale-[.99]" aria-label={t("prices.productActions", { name: r.name })}>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-body-md">{r.name}</span>
                      <span className="block text-label-sm text-on-surface-variant">
                        {r.receiptId === MANUAL_RECEIPT_ID ? t("prices.manualSource") : (r.store ?? t("prices.lastPaid"))} · {date(r.purchasedAt)}
                      </span>
                    </span>
                    <span className="text-end">
                      <span className="block text-body-lg font-extrabold" dir="ltr">
                        {priceLabel(r.unitPrice, r.currency)}
                      </span>
                      <span className="block text-label-sm text-on-surface-variant">{unitLabel(r.unit)}</span>
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      <AddPriceDialog
        open={adding}
        onDone={(saved) => {
          setAdding(false);
          if (saved) status.show("success", t("prices.priceSaved"));
        }}
      />
      <ProductPricingDialog
        product={product}
        records={records}
        receipts={receipts}
        pricing={book.pricing}
        onClose={() => setProduct(null)}
        onStatus={(k, text) => status.show(k, text)}
      />
      {confirm}
      {receiptChoice.element}
      {status.element}
    </>
  );
}

/** _SortRow's chip: padding 6/12, labelSm; on = primaryFixed + primary rim. */
function SortChip({ selected, onClick, children }: { selected: boolean; onClick: () => void; children: ReactNode }) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      onClick={onClick}
      className={`press shrink-0 rounded-full border px-3 py-1.5 text-label-sm transition-colors duration-[180ms] ${selected ? "border-primary bg-primary-fixed text-on-primary-fixed-variant" : "border-outline-variant bg-surface-low text-tertiary"}`}
    >
      {children}
    </button>
  );
}

type FilterRow = { values: unknown[]; selected: unknown; label: (v: never) => string };

/** _showFilterSheet: the tab's filters as chip rows, "clear", and "apply". */
function FilterSheet({ open, onClose, rows, onApply }: { open: boolean; onClose: () => void; rows: FilterRow[]; onApply: (picked: unknown[]) => void }) {
  const { t } = useI18n();
  const [picked, setPicked] = useState<unknown[]>([]);
  const [wasOpen, setWasOpen] = useState(false);
  if (open !== wasOpen) {
    setWasOpen(open);
    if (open) setPicked(rows.map((r) => r.selected));
  }
  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title={t("prices.filter")}
      footer={
        <ClayButton icon="check" expanded onClick={() => onApply(picked)}>
          {t("prices.applyFilters")}
        </ClayButton>
      }
    >
      <div className="-mt-2 mb-3 text-end">
        <button type="button" className="press min-h-10 rounded-full px-3 text-label-md text-primary" onClick={() => setPicked(rows.map(() => null))}>
          {t("prices.clearFilters")}
        </button>
      </div>
      <div className="space-y-3">
        {rows.map((row, i) => (
          <div key={i} className="flex flex-wrap gap-2">
            {row.values.map((v) => (
              <button
                key={String(v)}
                type="button"
                aria-pressed={picked[i] === v}
                onClick={() => setPicked((p) => p.map((x, j) => (j === i ? v : x)))}
                className={`press rounded-full border px-3 py-2 text-label-md transition-colors duration-[180ms] ${picked[i] === v ? "border-primary bg-primary-fixed text-on-primary-fixed-variant" : "border-outline-variant bg-surface-low text-tertiary"}`}
              >
                {(row.label as (v: unknown) => string)(v)}
              </button>
            ))}
          </div>
        ))}
      </div>
    </BottomSheet>
  );
}

/** A long press (the app's onLongPress) on a link: the action runs, the tap that follows is swallowed. */
function useLongPress() {
  const timer = useRef<number | null>(null);
  const fired = useRef(false);
  return (action: () => void) => ({
    onPointerDown: () => {
      fired.current = false;
      timer.current = window.setTimeout(() => {
        fired.current = true;
        navigator.vibrate?.(15);
        action();
      }, 500);
    },
    onPointerUp: () => timer.current && window.clearTimeout(timer.current),
    onPointerLeave: () => timer.current && window.clearTimeout(timer.current),
    onPointerCancel: () => timer.current && window.clearTimeout(timer.current),
    onContextMenu: (e: React.MouseEvent) => e.preventDefault(),
    onClick: (e: React.MouseEvent) => {
      if (fired.current) {
        e.preventDefault();
        e.stopPropagation();
        fired.current = false;
      }
    },
  });
}
