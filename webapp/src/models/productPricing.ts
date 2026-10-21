// Which of a product's prices counts, exactly as the app stores it in
// users/{uid}/product_pricing/{key} (ProductPricingModel.toJson in
// lib/features/price_book/data/models/product_pricing_model.g.dart). The
// document id is the key itself, `normalizedName|unit`. Absent = "latest"
// (the app deletes the record rather than store "latest").
// Samples: webapp/contract-fixtures/product_pricing/.
import type { PriceRecord, PriceUnit } from "./priceRecord";

export const PRICING_MODES = ["latest", "average", "store", "receipts"] as const;
export type PricingMode = (typeof PRICING_MODES)[number];

export interface ProductPricing {
  key: string;
  mode: PricingMode;
  store: string | null;
  receiptIds: string[];
}

const rec = (v: unknown): Record<string, unknown> => (v && typeof v === "object" ? (v as Record<string, unknown>) : {});

export const pricingKeyFor = (normalizedName: string, unit: PriceUnit): string => `${normalizedName}|${unit}`;

export function normalizeProductPricing(raw: unknown): ProductPricing {
  const r = rec(raw);
  return {
    key: String(r.key ?? ""),
    mode: (PRICING_MODES as readonly string[]).includes(r.mode as string) ? (r.mode as PricingMode) : "latest",
    store: typeof r.store === "string" ? r.store : null,
    receiptIds: Array.isArray(r.receiptIds) ? r.receiptIds.filter((s): s is string => typeof s === "string") : [],
  };
}

/** The exact document the app writes (key order mirrors ProductPricingModel.toJson). */
export function productPricingToDart(p: ProductPricing): Record<string, unknown> {
  return { key: p.key, mode: p.mode, store: p.store, receiptIds: [...p.receiptIds] };
}

function latest(records: PriceRecord[]): PriceRecord | null {
  let best: PriceRecord | null = null;
  for (const r of records) if (!best || Date.parse(r.purchasedAt) > Date.parse(best.purchasedAt)) best = r;
  return best;
}

function mean(records: PriceRecord[]): number | null {
  if (records.length === 0) return null;
  const sum = records.reduce((s, r) => s + r.unitPrice, 0);
  return Number((sum / records.length).toFixed(2));
}

/**
 * The price this policy picks out of one product's records, or null when the
 * choice matches nothing (the caller then falls back to the latest).
 */
export function resolvePricing(p: ProductPricing, records: PriceRecord[]): number | null {
  if (records.length === 0) return null;
  switch (p.mode) {
    case "latest":
      return latest(records)?.unitPrice ?? null;
    case "average":
      return mean(records);
    case "store":
      return latest(records.filter((r) => r.store === p.store))?.unitPrice ?? null;
    case "receipts":
      return mean(records.filter((r) => p.receiptIds.includes(r.receiptId)));
  }
}
