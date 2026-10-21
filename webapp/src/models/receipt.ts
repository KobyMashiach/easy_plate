// One scanned receipt, exactly as the app stores it in
// users/{uid}/receipts/{id} (ReceiptModel.toJson in
// lib/features/price_book/data/models/receipt_model.g.dart). Its lines are the
// price_records that share its id. Samples: webapp/contract-fixtures/receipts/.

export interface Receipt {
  id: string;
  store: string | null;
  /** ISO-8601. */
  purchasedAt: string;
  currency: string;
  /** As printed; else the sum of the lines. */
  total: number;
  itemCount: number;
  /** ISO-8601. */
  createdAt: string;
  /**
   * The photos / PDF the receipt was read from, as file names in the phone's
   * own image directory — local to the device that scanned it. The web keeps
   * no copy, so a receipt scanned here writes [].
   */
  imageFileNames: string[];
}

const rec = (v: unknown): Record<string, unknown> => (v && typeof v === "object" ? (v as Record<string, unknown>) : {});
const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

export function normalizeReceipt(raw: unknown): Receipt {
  const r = rec(raw);
  return {
    id: String(r.id ?? ""),
    store: str(r.store),
    purchasedAt: str(r.purchasedAt) ?? new Date(0).toISOString(),
    currency: str(r.currency) ?? "ILS",
    total: num(r.total) ?? 0,
    itemCount: Math.trunc(num(r.itemCount) ?? 0),
    createdAt: str(r.createdAt) ?? new Date(0).toISOString(),
    imageFileNames: Array.isArray(r.imageFileNames) ? r.imageFileNames.filter((f): f is string => typeof f === "string") : [],
  };
}

/** The exact document the app writes (key order mirrors ReceiptModel.toJson). */
export function receiptToDart(r: Receipt): Record<string, unknown> {
  return {
    id: r.id,
    store: r.store,
    purchasedAt: r.purchasedAt,
    currency: r.currency,
    total: r.total,
    itemCount: Math.trunc(r.itemCount),
    createdAt: r.createdAt,
    imageFileNames: [...r.imageFileNames],
  };
}

export const receiptHasImages = (r: Receipt): boolean => r.imageFileNames.length > 0;
