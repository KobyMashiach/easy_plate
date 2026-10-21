// The price book's dialogs: a price typed by hand (add_price_dialog.dart),
// one product's history and pricing choice (product_pricing_sheet.dart), and
// what deleting a receipt takes with it (delete_receipt_sheet.dart).
import { useEffect, useId, useMemo, useState } from "react";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { useIsPhone } from "../../components/useIsPhone";
import { AppDialog } from "../../components/AppDialog";
import { SheetOption } from "../../components/BottomSheet";
import { Chip, Modal, parseAmount, priceLabel, useConfirm } from "../groceries/kit";
import { MANUAL_RECEIPT_ID, PRICE_UNITS, type PriceRecord, type PriceUnit } from "../../models/priceRecord";
import { pricingKeyFor, resolvePricing, type PricingMode, type ProductPricing } from "../../models/productPricing";
import type { Receipt } from "../../models/receipt";
import { addManualPrice, deleteProduct, productRecords, savePricing } from "./priceBook";

export function usePriceUnitLabel() {
  const { t } = useI18n();
  return (u: PriceUnit) => (u === "kg" ? t("prices.perKg") : u === "liter" ? t("prices.perLiter") : t("prices.perUnit"));
}

export function useShortDate() {
  const { locale } = useI18n();
  return useMemo(() => {
    const f = new Intl.DateTimeFormat(locale, { day: "numeric", month: "numeric", year: "numeric" });
    return (iso: string) => {
      const d = Date.parse(iso);
      return Number.isNaN(d) ? "" : f.format(new Date(d));
    };
  }, [locale]);
}

/** A price with no receipt behind it. `onDone(true)` once saved. */
export function AddPriceDialog({
  open,
  initial,
  onDone,
}: {
  open: boolean;
  initial?: { name?: string; price?: number | null; unit?: PriceUnit };
  onDone: (saved: boolean) => void;
}) {
  const { t } = useI18n();
  const unitLabel = usePriceUnitLabel();
  const id = useId();
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");
  const [unit, setUnit] = useState<PriceUnit>("unit");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [touched, setTouched] = useState(false);
  useEffect(() => {
    if (!open) return;
    setName(initial?.name ?? "");
    setPrice(initial?.price ? initial.price.toFixed(2) : "");
    setUnit(initial?.unit ?? "unit");
    setError(null);
    setTouched(false);
    setBusy(false);
  }, [open, initial?.name, initial?.price, initial?.unit]);
  const phone = useIsPhone();
  const value = parseAmount(price);
  const nameOk = name.trim().length > 0;
  const submit = async () => {
    setTouched(true);
    if (!nameOk || value === null || busy) return;
    setBusy(true);
    setError(null);
    try {
      await addManualPrice(name.trim(), value, unit);
      onDone(true);
    } catch {
      setError(t("prices.saveFailed"));
      setBusy(false);
    }
  };
  if (phone) {
    // AppDialog.general(sell) with the fields as its content.
    return (
      <AppDialog
        open={open}
        icon="sell"
        title={t("prices.addPrice")}
        message={t("prices.addPriceHint")}
        confirmLabel={t("groceries.common.save")}
        cancelLabel={t("groceries.common.cancel")}
        busy={busy}
        onConfirm={() => void submit()}
        onCancel={() => onDone(false)}
      >
        <form
          className="space-y-3"
          onSubmit={(e) => {
            e.preventDefault();
            void submit();
          }}
        >
          <label htmlFor={`${id}-name`} className="sr-only">
            {t("prices.itemName")}
          </label>
          <input id={`${id}-name`} className="clay-input" placeholder={t("prices.itemName")} value={name} onChange={(e) => setName(e.target.value)} maxLength={120} aria-invalid={touched && !nameOk ? "true" : undefined} />
          {touched && !nameOk ? <p className="text-label-sm text-error" role="alert">{t("prices.nameRequired")}</p> : null}
          <label htmlFor={`${id}-price`} className="sr-only">
            {t("prices.price")}
          </label>
          <input
            id={`${id}-price`}
            className="clay-input"
            inputMode="decimal"
            dir="ltr"
            placeholder={`₪ ${t("prices.price")}`}
            value={price}
            onChange={(e) => setPrice(e.target.value.replace(/[^0-9.,]/g, ""))}
            aria-invalid={touched && value === null ? "true" : undefined}
          />
          {touched && value === null ? <p className="text-label-sm text-error" role="alert">{t("prices.priceInvalid")}</p> : null}
          <div className="flex gap-2" role="radiogroup" aria-label={t("prices.unitLabel")}>
            {PRICE_UNITS.map((u) => (
              <button
                key={u}
                type="button"
                role="radio"
                aria-checked={unit === u}
                onClick={() => setUnit(u)}
                className={`press flex-1 rounded-full border py-2 text-center text-label-md transition-colors duration-[180ms] ${unit === u ? "border-primary bg-primary text-on-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
              >
                {unitLabel(u)}
              </button>
            ))}
          </div>
          {error ? <p className="text-label-md text-error" role="alert">{error}</p> : null}
        </form>
      </AppDialog>
    );
  }
  return (
    <Modal
      open={open}
      onClose={() => !busy && onDone(false)}
      title={t("prices.addPrice")}
      footer={
        <>
          <button type="submit" form={id} className="clay-btn-primary flex-1" disabled={busy} aria-busy={busy || undefined}>
            {t("groceries.common.save")}
          </button>
          <button type="button" className="clay-btn-secondary flex-1 max-lg:hidden" onClick={() => onDone(false)} disabled={busy}>
            {t("groceries.common.cancel")}
          </button>
        </>
      }
    >
      <form
        id={id}
        className="space-y-4"
        onSubmit={(e) => {
          e.preventDefault();
          void submit();
        }}
      >
        <p className="text-body-md text-on-surface-variant">{t("prices.addPriceHint")}</p>
        <div className="space-y-1.5">
          <label htmlFor={`${id}-name`} className="block text-label-md text-on-surface-variant">
            {t("prices.itemName")}
          </label>
          <input id={`${id}-name`} className="clay-input" value={name} onChange={(e) => setName(e.target.value)} maxLength={120} aria-invalid={touched && !nameOk ? "true" : undefined} />
          {touched && !nameOk ? <p className="text-label-sm text-error" role="alert">{t("prices.nameRequired")}</p> : null}
        </div>
        <div className="space-y-1.5">
          <label htmlFor={`${id}-price`} className="block text-label-md text-on-surface-variant">
            {t("prices.price")} (₪)
          </label>
          <input
            id={`${id}-price`}
            className="clay-input"
            inputMode="decimal"
            dir="ltr"
            value={price}
            onChange={(e) => setPrice(e.target.value.replace(/[^0-9.,]/g, ""))}
            aria-invalid={touched && value === null ? "true" : undefined}
          />
          {touched && value === null ? <p className="text-label-sm text-error" role="alert">{t("prices.priceInvalid")}</p> : null}
        </div>
        <fieldset>
          <legend className="mb-1.5 text-label-md text-on-surface-variant">{t("prices.unitLabel")}</legend>
          <div className="flex flex-wrap gap-2">
            {PRICE_UNITS.map((u) => (
              <Chip key={u} selected={unit === u} onClick={() => setUnit(u)}>
                {unitLabel(u)}
              </Chip>
            ))}
          </div>
        </fieldset>
        {error ? <p className="text-label-md text-error" role="alert">{error}</p> : null}
      </form>
    </Modal>
  );
}

/** One product's whole story and which of its prices counts. */
export function ProductPricingDialog({
  product,
  records,
  receipts,
  pricing,
  onClose,
  onStatus,
}: {
  product: PriceRecord | null;
  records: PriceRecord[];
  receipts: Receipt[];
  pricing: Map<string, ProductPricing>;
  onClose: () => void;
  onStatus: (kind: "success" | "error", text: string) => void;
}) {
  const { t } = useI18n();
  const unitLabel = usePriceUnitLabel();
  const date = useShortDate();
  const { ask, element: confirm } = useConfirm();
  const phone = useIsPhone();
  const [busy, setBusy] = useState(false);
  const [adding, setAdding] = useState(false);
  const key = product ? pricingKeyFor(product.normalizedName, product.unit) : "";
  const history = useMemo(
    () => (product ? productRecords(product, records).sort((a, b) => Date.parse(b.purchasedAt) - Date.parse(a.purchasedAt)) : []),
    [product, records],
  );
  const stored = pricing.get(key);
  const [policy, setPolicy] = useState<ProductPricing>({ key, mode: "latest", store: null, receiptIds: [] });
  useEffect(() => {
    setPolicy(stored ?? { key, mode: "latest", store: null, receiptIds: [] });
  }, [key, stored]);
  const receiptById = useMemo(() => new Map(receipts.map((r) => [r.id, r])), [receipts]);
  const stores = useMemo(() => [...new Set(history.map((r) => r.store).filter((s): s is string => !!s))].sort(), [history]);
  const inUse = resolvePricing(policy, history) ?? history[0]?.unitPrice ?? null;

  const save = async (next: ProductPricing) => {
    const before = policy;
    setPolicy(next);
    try {
      await savePricing(next);
    } catch {
      setPolicy(before);
      onStatus("error", t("prices.pricingFailed"));
    }
  };
  const setMode = (mode: PricingMode) => {
    if (mode === "store") void save({ key, mode, store: policy.store ?? stores[0] ?? null, receiptIds: [] });
    else if (mode === "receipts") void save({ key, mode, store: null, receiptIds: policy.receiptIds.length ? policy.receiptIds : history[0] ? [history[0].receiptId] : [] });
    else void save({ key, mode, store: null, receiptIds: [] });
  };
  const receiptLabel = (r: PriceRecord) => {
    if (r.receiptId === MANUAL_RECEIPT_ID) return t("prices.manualSource");
    const receipt = receiptById.get(r.receiptId);
    return receipt ? `${receipt.store ?? t("prices.noStore")} · ${date(receipt.purchasedAt)}` : date(r.purchasedAt);
  };
  const remove = async () => {
    if (!product) return;
    const ok = await ask(t("prices.deleteProduct"), { body: t("prices.deleteProductBody"), confirm: t("groceries.common.delete") });
    if (!ok) return;
    setBusy(true);
    try {
      await deleteProduct(product, records);
      onClose();
    } catch {
      onStatus("error", t("prices.deleteFailed"));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <Modal open={product !== null && !adding} onClose={onClose} title={product?.name ?? ""} wide>
        {product ? (
          <div className="space-y-5">
            <div className="flex flex-wrap items-center gap-2">
              {inUse !== null ? (
                <p className="flex-1 text-label-md text-primary">{t("prices.pricingActive", { price: `${priceLabel(inUse, product.currency)} ${unitLabel(product.unit)}` })}</p>
              ) : (
                <span className="flex-1" />
              )}
              {phone ? (
                <>
                  <button type="button" className="press-icon grid h-12 w-12 place-items-center rounded-full text-primary" onClick={() => setAdding(true)} aria-label={t("prices.addPrice")} title={t("prices.addPrice")}>
                    <Icon name="add_circle_outline" size={24} />
                  </button>
                  <button type="button" className="press-icon grid h-12 w-12 place-items-center rounded-full text-error" onClick={() => void remove()} disabled={busy} aria-label={t("prices.deleteProduct")} title={t("prices.deleteProduct")}>
                    <Icon name="delete_outline" size={24} />
                  </button>
                </>
              ) : (
                <>
              <button type="button" className="clay-btn-tonal" onClick={() => setAdding(true)}>
                <Icon name="add" size={18} /> {t("prices.addPrice")}
              </button>
              <button type="button" className="clay-btn-danger" onClick={() => void remove()} disabled={busy} aria-busy={busy || undefined}>
                <Icon name="trash" size={18} /> {t("prices.deleteProduct")}
              </button>
                </>
              )}
            </div>
            <section aria-labelledby="pricing-title" className="space-y-2">
              <h3 id="pricing-title" className={phone ? "text-headline-md" : "text-body-md font-bold"}>
                {t("prices.pricingTitle")}
              </h3>
              <div className="flex flex-wrap gap-2">
                <Chip selected={policy.mode === "latest"} onClick={() => setMode("latest")}>{t("prices.pricingLatest")}</Chip>
                <Chip selected={policy.mode === "average"} onClick={() => setMode("average")}>{t("prices.pricingAverage")}</Chip>
                <Chip selected={policy.mode === "store"} onClick={() => setMode("store")} disabled={stores.length === 0}>{t("prices.pricingStore")}</Chip>
                <Chip selected={policy.mode === "receipts"} onClick={() => setMode("receipts")} disabled={history.length === 0}>{t("prices.pricingReceipts")}</Chip>
              </div>
              {policy.mode === "store" ? (
                <div className="flex flex-wrap gap-2 pt-1">
                  {stores.map((s) => (
                    <Chip key={s} selected={policy.store === s} onClick={() => void save({ key, mode: "store", store: s, receiptIds: [] })}>
                      {s}
                    </Chip>
                  ))}
                </div>
              ) : null}
            </section>
            <section aria-labelledby="history-title" className="space-y-1">
              <h3 id="history-title" className={phone ? "text-headline-md" : "text-body-md font-bold"}>
                {t("prices.history")}
              </h3>
              <ul className="divide-y divide-outline-variant/40">
                {history.map((r) => {
                  const checked = policy.receiptIds.includes(r.receiptId);
                  return (
                    <li key={r.id} className="flex items-center gap-3 py-2">
                      {policy.mode === "receipts" ? (
                        <input
                          type="checkbox"
                          className="h-5 w-5 accent-[rgb(var(--c-primary))]"
                          checked={checked}
                          aria-label={receiptLabel(r)}
                          onChange={(e) => {
                            const ids = new Set(policy.receiptIds);
                            if (e.target.checked) ids.add(r.receiptId);
                            else ids.delete(r.receiptId);
                            if (ids.size === 0) return;
                            void save({ key, mode: "receipts", store: null, receiptIds: [...ids] });
                          }}
                        />
                      ) : null}
                      <span className="min-w-0 flex-1 text-label-md text-on-surface-variant">{receiptLabel(r)}</span>
                      <span className="text-label-md font-extrabold" dir="ltr">
                        {priceLabel(r.unitPrice, r.currency)}
                      </span>
                    </li>
                  );
                })}
              </ul>
            </section>
          </div>
        ) : null}
      </Modal>
      <AddPriceDialog
        open={adding}
        initial={{ name: product?.name, unit: product?.unit }}
        onDone={(saved) => {
          setAdding(false);
          if (saved) onStatus("success", t("prices.priceSaved"));
        }}
      />
      {confirm}
    </>
  );
}

/** Resolves true = keep the prices, false = delete them too, null = dismissed. */
export function useDeleteReceiptChoice() {
  const { t } = useI18n();
  const phone = useIsPhone();
  const [resolver, setResolver] = useState<((v: boolean | null) => void) | null>(null);
  const ask = () => new Promise<boolean | null>((resolve) => setResolver(() => resolve));
  const done = (v: boolean | null) => {
    resolver?.(v);
    setResolver(null);
  };
  const element = (
    <Modal open={resolver !== null} onClose={() => done(null)} title={t("prices.deleteReceipt")}>
      {phone ? (
        <div className="space-y-2">
          <button type="button" onClick={() => done(true)} className="clay-card press flex w-full items-center gap-3 p-4 text-start" style={{ borderRadius: 24 }}>
            <Icon name="receipt_long" size={24} className="text-primary" />
            <span className="min-w-0 flex-1">
              <span className="block text-body-md">{t("prices.deleteReceiptOnly")}</span>
              <span className="block text-label-sm text-on-surface-variant">{t("prices.deleteReceiptOnlyHint")}</span>
            </span>
          </button>
          <SheetOption icon="delete_sweep" label={t("prices.deleteReceiptAndPrices")} destructive onClick={() => done(false)} />
        </div>
      ) : (
      <div className="space-y-3">
        <button type="button" onClick={() => done(true)} className="clay flex w-full items-center gap-3 p-4 text-start">
          <span className="text-primary" aria-hidden="true">
            <Icon name="file" />
          </span>
          <span className="min-w-0 flex-1">
            <span className="block text-body-md">{t("prices.deleteReceiptOnly")}</span>
            <span className="block text-label-sm text-on-surface-variant">{t("prices.deleteReceiptOnlyHint")}</span>
          </span>
        </button>
        <button type="button" onClick={() => done(false)} className="clay flex w-full items-center gap-3 p-4 text-start text-error">
          <span aria-hidden="true">
            <Icon name="trash" />
          </span>
          <span className="min-w-0 flex-1 text-body-md">{t("prices.deleteReceiptAndPrices")}</span>
        </button>
      </div>
      )}
    </Modal>
  );
  return { ask, element };
}
