// The pass of content translation (the app's ContentTranslationService.switchTo,
// without the record rewrite): see contentTranslation.tsx. Loaded on first
// use, so the record readers stay out of the main bundle.
import { firestore } from "./firebase";
import { listRecords } from "./cloud";
import { callFunction, quotaOf } from "./functions";
import { normalizeRecipe } from "../models/recipe";
import { normalizeBook } from "../models/book";
import { normalizeMealPlan } from "../models/mealPlan";
import { normalizeGroceryList } from "../models/groceryList";
import {
  CONTENT_TYPES,
  batchesOf,
  bookItem,
  fitting,
  listItem,
  needsTranslation,
  planItem,
  recipeItem,
  sourceLanguageOf,
  variantVersion,
  type LangCode,
  type TranslatableItem,
  type Variant,
} from "./translationCore";


export interface TranslationOutcome {
  translated: number;
  reused: number;
  failed: number;
}

async function readVariants(uid: string, lang: string): Promise<Map<string, Variant>> {
  const { fs, db } = await firestore();
  const out = new Map<string, Variant>();
  await Promise.all(
    CONTENT_TYPES.map(async (type) => {
      try {
        const snap = await fs.getDocs(fs.collection(db, "users", uid, "i18n", lang, type));
        for (const d of snap.docs) out.set(`${type}/${d.id}`, d.data() as Variant);
      } catch (_) {
        // A missing folder is the normal first switch; anything else only
        // means the model is asked for more than it had to be.
      }
    }),
  );
  return out;
}

async function writeSource(uid: string, lang: string, item: TranslatableItem): Promise<void> {
  try {
    const { fs, db } = await firestore();
    await fs.setDoc(fs.doc(db, "users", uid, "i18n", lang, item.type, item.id), { ...item.fields, version: item.version, updatedAt: fs.serverTimestamp() });
  } catch (_) {
    // Only means this record is translated again if it ever comes back.
  }
}

/** translateContent in the app's batches; what came back keyed `type/id`. */
async function translate(lang: string, items: TranslatableItem[]): Promise<Set<string>> {
  const out = new Set<string>();
  const queue = batchesOf(items);
  for (let i = 0; i < queue.length; i++) {
    const slice = queue[i];
    let data: { translations?: Record<string, { fields?: unknown }> } | null;
    try {
      data = await callFunction<{ translations?: Record<string, { fields?: unknown }> }>("translateContent", {
        targetLang: lang,
        items: slice.map((it) => ({ type: it.type, id: it.id, version: it.version, fields: it.fields })),
      });
    } catch (err) {
      const quota = quotaOf(err);
      if (!quota) throw err;
      // A call larger than what is left of the day is refused whole: send
      // the part that fits, then stop.
      const fits = fitting(slice, quota);
      if (fits) {
        queue.splice(i + 1, queue.length - i - 1, fits);
        continue;
      }
      if (out.size > 0) return out;
      throw err;
    }
    const translations = data?.translations;
    if (!translations || typeof translations !== "object") continue;
    for (const it of slice) {
      const record = translations[it.id];
      if (record && typeof record === "object" && record.fields && typeof record.fields === "object") out.add(`${it.type}/${it.id}`);
    }
  }
  return out;
}

export async function translateAccountContent(uid: string, target: LangCode, onModel?: () => void): Promise<TranslationOutcome> {
  const [recipes, books, plans, lists] = await Promise.all([
    listRecords<unknown>("recipes").then((a) => a.map(normalizeRecipe)),
    listRecords<unknown>("books").then((a) => a.map(normalizeBook)),
    listRecords<unknown>("meal_plans").then((a) => a.map(normalizeMealPlan)),
    listRecords<unknown>("grocery_lists").then((a) => a.map(normalizeGroceryList)),
  ]);
  const sources = new Map<string, LangCode>();
  const items: TranslatableItem[] = [];
  const add = (item: TranslatableItem, contentLang: string | null, sample: string) => {
    items.push(item);
    sources.set(`${item.type}/${item.id}`, sourceLanguageOf(contentLang, sample));
  };
  for (const r of recipes) if (needsTranslation(r.contentLang, r.title, target)) add(recipeItem(r), r.contentLang, r.title);
  for (const b of books) if (needsTranslation(b.contentLang, b.title, target)) add(bookItem(b), b.contentLang, b.title);
  for (const p of plans) if (needsTranslation(p.contentLang, p.name, target)) add(planItem(p), p.contentLang, p.name);
  for (const l of lists) if (needsTranslation(l.contentLang, l.name, target)) add(listItem(l), l.contentLang, l.name);
  if (items.length === 0) return { translated: 0, reused: 0, failed: 0 };

  const known = await readVariants(uid, target);
  const wanted = items.filter((it) => {
    const v = known.get(`${it.type}/${it.id}`);
    return !v || variantVersion(v) !== it.version;
  });
  const reused = items.length - wanted.length;
  if (wanted.length === 0) return { translated: 0, reused, failed: 0 };

  // Each record's own words, filed under its own language before anything is
  // translated away, so coming back to it is a read rather than a call.
  await Promise.all(
    wanted.map((it) => {
      const source = sources.get(`${it.type}/${it.id}`);
      return source ? writeSource(uid, source, it) : Promise.resolve();
    }),
  );

  // Only now is there something to wait for (the app's loading card).
  onModel?.();
  try {
    const made = await translate(target, wanted);
    return { translated: made.size, reused, failed: wanted.filter((it) => !made.has(`${it.type}/${it.id}`)).length };
  } catch (_) {
    // Whatever the folder already held is shown; the rest stays as written.
    return { translated: 0, reused, failed: wanted.length };
  }
}

