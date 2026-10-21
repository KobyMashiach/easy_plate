// One price this account paid for one product, exactly as the app stores it in
// users/{uid}/price_records/{id} (PriceRecordModel.toJson in
// lib/features/price_book/data/models/price_record_model.g.dart).
// Read through `normalizePriceRecord`; write only `priceRecordToDart`.
// Samples: webapp/contract-fixtures/price_records/.

/** What a price is per (price_unit.dart), stored by name. */
export const PRICE_UNITS = ["unit", "kg", "liter"] as const;
export type PriceUnit = (typeof PRICE_UNITS)[number];

/** The receipt id of a price typed in without a receipt. */
export const MANUAL_RECEIPT_ID = "manual";

export interface PriceRecord {
  id: string;
  /** The generic product name, what a grocery line is matched on. */
  name: string;
  /** `name` through normalizeProductName. */
  normalizedName: string;
  /** Per one `unit`. */
  unitPrice: number;
  quantity: number;
  currency: string;
  store: string | null;
  /** ISO-8601. */
  purchasedAt: string;
  receiptId: string;
  /** The line as the till printed it; null on older records (reads as `name`). */
  printedName: string | null;
  unit: PriceUnit;
}

const rec = (v: unknown): Record<string, unknown> => (v && typeof v === "object" ? (v as Record<string, unknown>) : {});
const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

export const priceUnitOf = (v: unknown): PriceUnit => ((PRICE_UNITS as readonly string[]).includes(v as string) ? (v as PriceUnit) : "unit");

export function normalizePriceRecord(raw: unknown): PriceRecord {
  const r = rec(raw);
  const name = String(r.name ?? "");
  return {
    id: String(r.id ?? ""),
    name,
    normalizedName: str(r.normalizedName) ?? normalizeProductName(name),
    unitPrice: num(r.unitPrice) ?? 0,
    quantity: num(r.quantity) ?? 1,
    currency: str(r.currency) ?? "ILS",
    store: str(r.store),
    purchasedAt: str(r.purchasedAt) ?? new Date(0).toISOString(),
    receiptId: str(r.receiptId) ?? MANUAL_RECEIPT_ID,
    printedName: str(r.printedName),
    unit: priceUnitOf(r.unit),
  };
}

/** The exact document the app writes (key order mirrors PriceRecordModel.toJson). */
export function priceRecordToDart(p: PriceRecord): Record<string, unknown> {
  return {
    id: p.id,
    name: p.name,
    normalizedName: p.normalizedName,
    unitPrice: p.unitPrice,
    quantity: p.quantity,
    currency: p.currency,
    store: p.store,
    purchasedAt: p.purchasedAt,
    receiptId: p.receiptId,
    printedName: p.printedName,
    unit: p.unit,
  };
}

export const printedNameOf = (p: PriceRecord): string => p.printedName ?? p.name;

/**
 * One spelling for one product (product_name.dart, and normalizeName in
 * functions/priceStats.js — change all three together): lower-case, niqqud
 * and punctuation gone, spaces collapsed.
 */
export function normalizeProductName(raw: string): string {
  return raw
    .toLowerCase()
    .replace(/[֑-ׇ]/g, "")
    .replace(/[^\p{L}\p{N}%\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export const productTokens = (normalized: string): string[] => normalized.split(" ").filter((t) => t.length > 1);

/** productMatchScoreNormalized: 1 for the same name, a fraction for containment, 0 otherwise. */
export function productMatchScore(q: string, c: string): number {
  if (!q || !c) return 0;
  if (q === c) return 1;
  const qt = new Set(productTokens(q));
  const ct = new Set(productTokens(c));
  if (qt.size === 0 || ct.size === 0) return 0;
  const [short, long] = qt.size <= ct.size ? [qt, ct] : [ct, qt];
  for (const t of short) if (!long.has(t)) return 0;
  return short.size / long.size;
}
