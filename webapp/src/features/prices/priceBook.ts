// The price book on the web: the live records, receipts and pricing choices
// (the same collections the app mirrors), the estimator the grocery list asks
// (price_estimator.dart + price_book_service.dart), the community median
// (price_stats/{sha256}, read only when the account opted in), and every
// write the app's PriceBookRepositoryImpl makes.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { deleteRecord, firestore, newId, nowIso, putRecord, updateRecord, useCollection, useRecord } from "../../lib/cloud";
import { callFunction } from "../../lib/functions";
import { ApiError } from "../../lib/api";
import type { GroceryItem } from "../../models/groceryList";
import { totalAmount } from "../../models/groceryList";
import type { MeasurementUnit } from "../../models/recipe";
import {
  MANUAL_RECEIPT_ID,
  PRICE_UNITS,
  normalizePriceRecord,
  normalizeProductName,
  priceRecordToDart,
  productMatchScore,
  type PriceRecord,
  type PriceUnit,
} from "../../models/priceRecord";
import { normalizeReceipt, receiptToDart, type Receipt } from "../../models/receipt";
import { normalizeProductPricing, pricingKeyFor, productPricingToDart, resolvePricing, type ProductPricing } from "../../models/productPricing";

// ---------------------------------------------------------------------------
// Estimating (pure)

export type PriceBasis = "personal" | "community" | "none";

export interface PriceEstimate {
  unitPrice: number | null;
  unit: PriceUnit;
  basis: PriceBasis;
  matchedName: string | null;
  sampleCount: number;
  currency: string;
}

export const NO_ESTIMATE: PriceEstimate = { unitPrice: null, unit: "unit", basis: "none", matchedName: null, sampleCount: 0, currency: "ILS" };

export interface CommunityPrice {
  normalizedName: string;
  /** What the median is per: the keyed document's unit, "unit" for the legacy one. */
  unit: PriceUnit;
  currency: string;
  median: number;
  average: number;
  count: number;
}

/** The currency most records are in; shekels on a tie or an empty book. */
export function dominantCurrency(records: PriceRecord[]): string {
  const counts = new Map<string, number>();
  for (const r of records) counts.set(r.currency, (counts.get(r.currency) ?? 0) + 1);
  let best = "ILS";
  let bestCount = counts.get("ILS") ?? 0;
  for (const [c, n] of counts) if (n > bestCount) [best, bestCount] = [c, n];
  return best;
}

const ms = (iso: string) => Date.parse(iso) || 0;

/** Highest name score, most recent among ties; below minScore is a coincidence. */
export function bestPersonalMatch(itemName: string, records: PriceRecord[], minScore = 0.3): PriceRecord | null {
  let best: PriceRecord | null = null;
  let bestScore = 0;
  const query = normalizeProductName(itemName);
  for (const r of records) {
    const score = productMatchScore(query, r.normalizedName);
    if (score < minScore) continue;
    if (!best || score > bestScore || (score === bestScore && ms(r.purchasedAt) > ms(best.purchasedAt))) {
      best = r;
      bestScore = score;
    }
  }
  return best;
}

export const productRecords = (match: { normalizedName: string; unit: PriceUnit }, records: PriceRecord[]) =>
  records.filter((r) => r.normalizedName === match.normalizedName && r.unit === match.unit);

export function estimate(itemName: string, records: PriceRecord[], pricing: Map<string, ProductPricing>, community: CommunityPrice | null = null): PriceEstimate {
  const currency = dominantCurrency(records);
  const same = records.filter((r) => r.currency === currency);
  const personal = bestPersonalMatch(itemName, same);
  if (personal) {
    const group = productRecords(personal, same);
    const policy = pricing.get(pricingKeyFor(personal.normalizedName, personal.unit));
    const chosen = (policy ? resolvePricing(policy, group) : null) ?? personal.unitPrice;
    return { unitPrice: chosen, unit: personal.unit, basis: "personal", matchedName: personal.name, sampleCount: group.length, currency: personal.currency };
  }
  if (community) return { unitPrice: community.median, unit: community.unit, basis: "community", matchedName: community.normalizedName, sampleCount: community.count, currency: community.currency };
  return NO_ESTIMATE;
}

/** price_unit.dart multiplierFor: how many of the price unit a line amounts to, or null when they do not convert. */
export function unitMultiplier(priceUnit: PriceUnit, groceryUnit: MeasurementUnit, amount: number): number | null {
  if (amount <= 0) return null;
  switch (priceUnit) {
    case "unit":
      return groceryUnit === "unit" ? amount : null;
    case "kg":
      return groceryUnit === "kilogram" ? amount : groceryUnit === "gram" ? amount / 1000 : null;
    case "liter":
      return groceryUnit === "liter" ? amount : groceryUnit === "milliliter" ? amount / 1000 : null;
  }
}

export const multiplierFor = (item: GroceryItem, e: PriceEstimate): number => unitMultiplier(e.unit, item.unit, totalAmount(item)) ?? 1;

export interface CostSummary {
  knownTotal: number;
  pricedItems: number;
  unpricedItems: number;
  currency: string;
}

/** GroceryCostSummary.of: the lines in the majority currency, the rest counted as unpriced. */
export function summarize(lines: { estimate: PriceEstimate; multiplier: number }[]): CostSummary {
  const known = lines.filter((l) => l.estimate.unitPrice !== null);
  const counts = new Map<string, number>();
  for (const l of known) counts.set(l.estimate.currency, (counts.get(l.estimate.currency) ?? 0) + 1);
  let currency = "ILS";
  let bestCount = counts.get("ILS") ?? 0;
  for (const [c, n] of counts) if (n > bestCount) [currency, bestCount] = [c, n];
  let total = 0;
  let priced = 0;
  for (const l of known) {
    if (l.estimate.currency !== currency) continue;
    priced++;
    total += (l.estimate.unitPrice ?? 0) * l.multiplier;
  }
  return { knownTotal: total, pricedItems: priced, unpricedItems: lines.length - priced, currency };
}

/** The unit a grocery line should take for a product priced per `unit` (the app's product picker). */
export const groceryUnitFor = (u: PriceUnit): MeasurementUnit => (u === "kg" ? "kilogram" : u === "liter" ? "liter" : "unit");

// ---------------------------------------------------------------------------
// Community (read-only for clients). price_stats/{sha256(name|unit|CURRENCY)}
// when the price is per a known unit (functions/priceStats.js keyFor), else
// the legacy price_stats/{sha256(normalizedName)}, which mixes units.

const communityCache = new Map<string, Promise<CommunityPrice | null>>();

async function sha256Hex(text: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * "No data" is an answer and is kept; a failed read is not (the app's lookup
 * rethrows): it rejects and leaves the cache, so the next estimate asks again.
 */
export function communityPrice(normalizedName: string, unit: PriceUnit | null = null, currency = "ILS"): Promise<CommunityPrice | null> {
  const cur = currency.toUpperCase();
  const cacheKey = `${normalizedName}|${unit ?? ""}|${cur}`;
  let hit = communityCache.get(cacheKey);
  if (!hit) {
    hit = (async () => {
      const { fs, db } = await firestore();
      const read = async (source: string, keyed: boolean): Promise<CommunityPrice | null> => {
        const snap = await fs.getDoc(fs.doc(db, "price_stats", await sha256Hex(source)));
        const data = snap.exists() ? (snap.data() as Record<string, unknown>) : null;
        if (!data) return null;
        const count = typeof data.count === "number" ? Math.trunc(data.count) : 0;
        const median = typeof data.median === "number" ? data.median : null;
        if (count === 0 || median === null) return null;
        return {
          normalizedName,
          unit: keyed && unit ? unit : "unit",
          currency: keyed ? cur : "ILS",
          median,
          average: typeof data.avg === "number" ? data.avg : median,
          count,
        };
      };
      const legacy = !unit && cur === "ILS";
      if (legacy) return read(normalizedName, false);
      // The per-unit aggregate first; the legacy one (shekels only) until it fills.
      return (await read(`${normalizedName}|${unit ?? ""}|${cur}`, true)) ?? (cur === "ILS" ? read(normalizedName, false) : null);
    })();
    communityCache.set(cacheKey, hit);
    hit.catch(() => {
      if (communityCache.get(cacheKey) === hit) communityCache.delete(cacheKey);
    });
  }
  return hit;
}

/** The price unit a grocery line's unit is priced per, or null when none fits. */
export const priceUnitForGrocery = (u: MeasurementUnit): PriceUnit | null =>
  u === "kilogram" || u === "gram" ? "kg" : u === "liter" || u === "milliliter" ? "liter" : u === "unit" ? "unit" : null;

/** Adds these prices to the community aggregates: names and prices only. */
export async function sharePrices(records: PriceRecord[]): Promise<void> {
  if (records.length === 0) return;
  // With what the price is per and its currency, so the server folds it into
  // the matching aggregate (an unknown unit or currency is left out).
  await callFunction("priceStats", {
    records: records.map((r) => ({
      name: r.name,
      price: r.unitPrice,
      ...((PRICE_UNITS as readonly string[]).includes(r.unit) ? { unit: r.unit } : {}),
      ...(/^[A-Za-z]{3}$/.test(r.currency) ? { currency: r.currency.toUpperCase() } : {}),
    })),
  });
  for (const key of [...communityCache.keys()]) if (records.some((r) => key.startsWith(`${r.normalizedName}|`))) communityCache.delete(key);
}

export const isQuotaError = (e: unknown): boolean => e instanceof ApiError && e.status === 429;

// ---------------------------------------------------------------------------
// Live data

export interface PriceBook {
  records: PriceRecord[] | null;
  receipts: Receipt[] | null;
  pricing: Map<string, ProductPricing>;
  error: Error | null;
  /** The preference (users/{uid}/preferences/current.communityPricesEnabled), default off. */
  communityEnabled: boolean;
}

export function usePriceBook(uid: string | null | undefined, { receipts: withReceipts = true }: { receipts?: boolean } = {}): PriceBook {
  const records = useCollection<unknown>("price_records", uid);
  // The grocery list only estimates: it needs records and rules, not every receipt.
  const receipts = useCollection<unknown>("receipts", withReceipts ? uid : null);
  const pricing = useCollection<unknown>("product_pricing", uid);
  const prefs = useRecord<Record<string, unknown>>("preferences", uid, "current");
  return useMemo(
    () => ({
      records: records.items ? records.items.map(normalizePriceRecord) : null,
      receipts: receipts.items ? receipts.items.map(normalizeReceipt) : null,
      pricing: new Map((pricing.items ?? []).map(normalizeProductPricing).map((p) => [p.key, p])),
      error: records.error || receipts.error || pricing.error,
      communityEnabled: prefs.item?.communityPricesEnabled === true,
    }),
    [records, receipts, pricing, prefs.item],
  );
}

/**
 * The grocery list's view of the price book: a synchronous estimate per line;
 * a community lookup in flight reads as "no data" and the line re-renders
 * when it lands (PriceBookService.estimateFor).
 */
export function useEstimator(book: PriceBook) {
  const [community, setCommunity] = useState<Map<string, CommunityPrice | null>>(new Map());
  const pending = useRef(new Set<string>());
  const live = useRef(true);
  useEffect(() => {
    live.current = true;
    return () => {
      live.current = false;
    };
  }, []);
  const records = useMemo(() => book.records ?? [], [book.records]);
  // One answer per product name and unit while the inputs stay the same: a
  // list draws each line and the total, and every estimate scans the book.
  const memo = useMemo(() => new Map<string, PriceEstimate>(), [records, book.pricing, book.communityEnabled, community]);
  const estimateFor = useCallback(
    (item: GroceryItem): PriceEstimate => {
      const memoKey = `${item.name}\u0000${item.unit}`;
      const known = memo.get(memoKey);
      if (known) return known;
      const result = estimateUncached(item);
      if (result !== NO_ESTIMATE || !book.communityEnabled) memo.set(memoKey, result);
      return result;
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [memo],
  );
  const estimateUncached = (item: GroceryItem): PriceEstimate => {
      const personal = estimate(item.name, records, book.pricing);
      if (personal.unitPrice !== null || !book.communityEnabled) return personal;
      const name = normalizeProductName(item.name);
      const unit = priceUnitForGrocery(item.unit);
      const key = `${name}|${unit ?? ""}`;
      if (community.has(key)) return estimate(item.name, records, book.pricing, community.get(key) ?? null);
      if (name && !pending.current.has(key)) {
        pending.current.add(key);
        void communityPrice(name, unit, "ILS").then(
          (result) => {
            pending.current.delete(key);
            if (live.current) setCommunity((m) => new Map(m).set(key, result));
          },
          // Not recorded: the next estimate for this product asks again.
          () => pending.current.delete(key),
        );
      }
      return NO_ESTIMATE;
  };
  return estimateFor;
}

// ---------------------------------------------------------------------------
// Writes (PriceBookRepositoryImpl)

export async function saveRecords(records: PriceRecord[]): Promise<void> {
  await Promise.all(records.map((r) => putRecord("price_records", r.id, priceRecordToDart(r))));
}

export async function saveReceipt(r: Receipt): Promise<void> {
  await putRecord("receipts", r.id, receiptToDart(r));
}

/** A price with no receipt behind it (add_price_dialog.dart). */
export async function addManualPrice(name: string, unitPrice: number, unit: PriceUnit): Promise<PriceRecord> {
  const record: PriceRecord = {
    id: newId(),
    name,
    normalizedName: normalizeProductName(name),
    unitPrice,
    quantity: 1,
    currency: "ILS",
    store: null,
    purchasedAt: nowIso(),
    receiptId: MANUAL_RECEIPT_ID,
    printedName: null,
    unit,
  };
  await saveRecords([record]);
  return record;
}

/** The receipt a change was meant for is gone — deleted on another device. */
export class ReceiptGoneError extends Error {
  constructor() {
    super("receipt-gone");
  }
}

/**
 * Changes the store on a receipt and on every price read from it — each onto
 * the record as stored now, and never writing back one deleted meanwhile.
 */
export async function renameReceiptStore(receipt: Receipt, store: string | null, records: PriceRecord[]): Promise<void> {
  const saved = await updateRecord("receipts", receipt.id, (raw) => (raw === null ? null : receiptToDart({ ...normalizeReceipt(raw), store })));
  if (saved === null) throw new ReceiptGoneError();
  await Promise.all(
    records
      .filter((r) => r.receiptId === receipt.id)
      .map((r) => updateRecord("price_records", r.id, (raw) => (raw === null ? null : priceRecordToDart({ ...normalizePriceRecord(raw), store })))),
  );
}

/** The receipt, and unless keepRecords every price read from it. */
export async function deleteReceipt(receipt: Receipt, records: PriceRecord[], keepRecords: boolean): Promise<void> {
  if (!keepRecords) await Promise.all(records.filter((r) => r.receiptId === receipt.id).map((r) => deleteRecord("price_records", r.id)));
  await deleteRecord("receipts", receipt.id);
}

/** Every record of one product (name + unit), and its pricing choice. */
export async function deleteProduct(product: { normalizedName: string; unit: PriceUnit }, records: PriceRecord[]): Promise<void> {
  await Promise.all(productRecords(product, records).map((r) => deleteRecord("price_records", r.id)));
  await deleteRecord("product_pricing", pricingKeyFor(product.normalizedName, product.unit));
}

export async function deleteAll(book: PriceBook): Promise<void> {
  await Promise.all([
    ...(book.records ?? []).map((r) => deleteRecord("price_records", r.id)),
    ...(book.receipts ?? []).map((r) => deleteRecord("receipts", r.id)),
    ...[...book.pricing.keys()].map((k) => deleteRecord("product_pricing", k)),
  ]);
}

/** "latest" is the absence of a choice: the app deletes the record rather than store it. */
export async function savePricing(p: ProductPricing): Promise<void> {
  if (p.mode === "latest") await deleteRecord("product_pricing", p.key);
  else await putRecord("product_pricing", p.key, productPricingToDart(p));
}
