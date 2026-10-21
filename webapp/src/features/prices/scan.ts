// Reading a receipt with Gemini, through the proxy: the exact request the app
// sends (GeminiRecipeAiDataSource.scanReceipt in
// lib/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart) —
// same model, system prompt, schema, thinking level and feature header — and
// the same parsing of the answer (_receiptFrom).
import { interactions } from "../../lib/functions";
import { priceUnitOf, type PriceUnit } from "../../models/priceRecord";

/** ApiConfig.model's default. */
const MODEL = "gemini-3.8-flash";
/** IngestionFile.maxBytes: a PDF above this is refused before upload. */
export const MAX_PDF_BYTES = 10 * 1024 * 1024;
export const MAX_PAGES = 10;
/** A photo above this is refused before it is decoded (a phone photo is far below it). */
export const MAX_IMAGE_MB = 25;
export const MAX_IMAGE_BYTES = MAX_IMAGE_MB * 1024 * 1024;
/** The base64 the proxy accepts in one request (aiProxy MAX_BODY_BYTES is 16 MB, less the prompt and schema). */
export const MAX_ENCODED_CHARS = 15 * 1024 * 1024;

export interface ReceiptPage {
  /** base64, no data: prefix. */
  data: string;
  mimeType: string;
}

export interface ReceiptLine {
  name: string;
  printedName: string;
  quantity: number;
  unitPrice: number;
  unit: PriceUnit;
}

export interface ReceiptScan {
  store: string | null;
  /** "YYYY-MM-DD" as read, or null. */
  date: string | null;
  currency: string;
  total: number | null;
  items: ReceiptLine[];
  unreadable: string[];
}

const RECEIPT_SCHEMA = {
  type: "object",
  properties: {
    store: { type: "string", description: "Store or chain name as printed. Omit if absent" },
    date: { type: "string", description: "Purchase date as YYYY-MM-DD. Omit if absent" },
    currency: { type: "string", description: "ISO 4217 code, e.g. ILS. Default ILS" },
    total: { type: "number", description: "The receipt total as printed. Omit if absent" },
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: {
            type: "string",
            description:
              'The GENERIC product, 1-3 words, as a shopper would write it on a list: "אנטריקוט", "חלב 3%", "עגבניות". Drop brand, cut, freshness, packaging, size and codes',
          },
          printed_name: { type: "string", description: "The line exactly as printed on the receipt" },
          unit: {
            type: "string",
            enum: ["unit", "kg", "liter"],
            description: 'What unit_price is per: "kg" for weighed lines (shown as ק"ג / קג / KG), "liter" for volume-priced lines, else "unit"',
          },
          quantity: { type: "number", description: 'How many of that unit: 0.85 for 0.850 ק"ג, 3 for three packages. 1 when not shown' },
          unit_price: { type: "number", description: "Price per one unit, after any discount line that applies to this item" },
          line_total: { type: "number", description: "The amount paid for the line as printed, after discounts" },
        },
        required: ["name", "printed_name", "unit", "quantity", "unit_price", "line_total"],
      },
    },
    unreadable: {
      type: "array",
      items: { type: "string" },
      description:
        'Short notes, in Hebrew, about product lines that could NOT be read — where they are and why, e.g. "מתחת לבצל מיובש: שורה מטושטשת". Never list deposits, credits, totals or discounts here',
    },
  },
  required: ["items", "unreadable"],
};

const RECEIPT_SYSTEM_PROMPT = `אתה קורא קבלות מסופרמרקטים בישראל בדיוק מלא. המשתמש מצלם קבלה — לפעמים בכמה תמונות חופפות — או שולח PDF.

איך קבלה ישראלית בנויה:
- כל שורת מוצר: שם המוצר, ולידו כמות × מחיר ליחידה = סכום השורה. לעיתים הכמות והמחיר ליחידה בשורה נפרדת מתחת לשם.
- מוצר שקול: "0.850 ק"ג × 119.00" — אז unit="kg", quantity=0.85, unit_price=119.00, line_total=101.15.
- מוצר ביחידות: "3 × 5.90" — unit="unit", quantity=3, unit_price=5.90, line_total=17.70. בלי כמות מודפסת: quantity=1 ו-unit_price שווה לסכום השורה.
- שורת הנחה ("הנחה", "מבצע", מספר שלילי) מתייחסת למוצר שמעליה: הפחת אותה מסכום השורה של אותו מוצר וחשב unit_price מחדש. אל תרשום את ההנחה כמוצר.
- שורות סה"כ, מע"מ, עודף, מזומן, אשראי, קופון, מועדון, ברקוד — אינן מוצרים. השמט אותן לגמרי.
- גם פיקדון בקבוק, זיכוי אריזה, החזר פיקדון, שקית/שקיות, דמי משלוח — אינם מוצרים. השמט אותם לגמרי, לא ב-items ולא ב-unreadable.

כללי דיוק:
- קרא מספרים בדיוק כפי שהם מודפסים, עם הנקודה העשרונית במקום הנכון. 119.00 ולא 11900 ולא 1190.
- בדוק את עצמך: סכום כל line_total צריך להתקרב ל-total המודפס. אם יש פער גדול, חזור וקרא שוב את השורות.
- name הוא שם המוצר הכללי כפי שאדם יכתוב ברשימת קניות: "אנטריקוט" ולא "אנטריקוט ח. טרי מיושן"; "חלב 3%" ולא "חלב תנובה 3% 1 ליטר"; "עגבניות" ולא "עגבניה שרי מגש". printed_name הוא השורה כפי שהודפסה.
- כשיש כמה תמונות של אותה קבלה: אחד אותן, מוצר שמופיע בשתי תמונות בגלל חפיפה נספר פעם אחת.
- שורת מוצר שלא ניתן לקרוא בביטחון: אל תנחש. רשום ב-unreadable הערה קצרה — איפה השורה ומה הבעיה ("מתחת לבצל מיובש: מטושטש"). זו הערה למשתמש, לא מוצר.
החזר JSON בלבד.`;

/** The request body, field for field as the app's _body builds it. */
export function receiptRequestBody(pages: ReceiptPage[]): Record<string, unknown> {
  const blocks: Record<string, unknown>[] = [
    ...pages.map((p) => ({ type: p.mimeType === "application/pdf" ? "document" : "image", mime_type: p.mimeType, data: p.data })),
    {
      type: "text",
      text: pages.length > 1 ? `אלה ${pages.length} תמונות של אותה קבלה, אולי חופפות. חלץ את המוצרים והמחירים.` : "חלץ את המוצרים והמחירים מהקבלה.",
    },
  ];
  return {
    model: MODEL,
    system_instruction: RECEIPT_SYSTEM_PROMPT,
    input: blocks,
    generation_config: { thinking_level: "high" },
    response_format: { type: "text", mime_type: "application/json", schema: RECEIPT_SCHEMA },
  };
}

/** Every text block of every step, then the JSON object in it (_extractText + _decodeRecipe). */
function jsonOf(data: unknown): Record<string, unknown> {
  let text = "";
  const steps = (data as { steps?: unknown })?.steps;
  for (const step of Array.isArray(steps) ? steps : []) {
    const content = (step as { content?: unknown })?.content;
    for (const block of Array.isArray(content) ? content : []) {
      const t = (block as { text?: unknown })?.text;
      if (typeof t === "string") text += t;
    }
  }
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) throw new Error("no-json");
  return JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
}

const n = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

/** _receiptFrom: drops lines with no name or price, recovers a missing unit price from the line total. */
export function receiptFrom(data: Record<string, unknown>): ReceiptScan {
  const items: ReceiptLine[] = [];
  for (const raw of Array.isArray(data.items) ? data.items : []) {
    if (!raw || typeof raw !== "object") continue;
    const r = raw as Record<string, unknown>;
    const name = typeof r.name === "string" ? r.name.trim() : "";
    const printed = typeof r.printed_name === "string" ? r.printed_name.trim() : "";
    let price = n(r.unit_price);
    let quantity = n(r.quantity) ?? 1;
    const lineTotal = n(r.line_total);
    if ((price === null || price <= 0) && lineTotal !== null && lineTotal > 0) price = quantity > 0 ? lineTotal / quantity : lineTotal;
    if (!name || price === null || price <= 0) continue;
    if (quantity <= 0) quantity = 1;
    items.push({ name, printedName: printed || name, quantity, unitPrice: price, unit: priceUnitOf(r.unit) });
  }
  const date = typeof data.date === "string" && /^\d{4}-\d{2}-\d{2}/.test(data.date) && !Number.isNaN(Date.parse(data.date.slice(0, 10))) ? data.date.slice(0, 10) : null;
  return {
    store: typeof data.store === "string" && data.store.trim() ? data.store.trim() : null,
    date,
    currency: typeof data.currency === "string" && data.currency.trim() ? data.currency.trim().toUpperCase() : "ILS",
    total: n(data.total),
    items,
    unreadable: Array.isArray(data.unreadable) ? data.unreadable.filter((s): s is string => typeof s === "string") : [],
  };
}

export async function scanReceipt(pages: ReceiptPage[], signal?: AbortSignal): Promise<ReceiptScan> {
  const data = await interactions<unknown>(receiptRequestBody(pages), { feature: "receipt", signal });
  return receiptFrom(jsonOf(data));
}

/** A file → its base64 body (images are downscaled first, as the app's picker does at 1600×2400, quality 80). */
export async function pageOf(file: File, toJpeg: (f: Blob, maxSide: number, q: number) => Promise<Blob>): Promise<ReceiptPage> {
  const isPdf = file.type === "application/pdf";
  const blob = isPdf ? file : await toJpeg(file, 2400, 0.8);
  const buf = new Uint8Array(await blob.arrayBuffer());
  let bin = "";
  for (let i = 0; i < buf.length; i += 0x8000) bin += String.fromCharCode(...buf.subarray(i, i + 0x8000));
  return { data: btoa(bin), mimeType: isPdf ? "application/pdf" : "image/jpeg" };
}
