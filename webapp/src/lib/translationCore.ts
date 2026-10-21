// The pure half of content translation — the app's
// lib/core/translation/content_translation.dart, content_translation_service.dart
// and content_translation_datasource.dart, rule for rule. No imports, so
// scripts/test-translation.mjs can load it in plain Node.
//
// What a record sends to the model (`fields`), how a stored variant is
// recognised as current (`version` == the record's contentVersion), how the
// calls are cut (≤120 records, ≤2500 lines, records over 200 lines left out),
// and how a quota refusal shrinks the last call — all as the app does it, so
// the variants the website files under users/{uid}/i18n/{lang}/{type}/{id}
// are the ones the phone reads, and the other way round.

export type ContentType = "recipe" | "book" | "mealPlan" | "groceryList";
export const CONTENT_TYPES: ContentType[] = ["recipe", "book", "mealPlan", "groceryList"];
export type LangCode = "he" | "en" | "ar" | "fr" | "ru";

/** One record handed to the translator (TranslatableItem). */
export interface TranslatableItem {
  type: ContentType;
  id: string;
  version: number;
  fields: Record<string, string | string[]>;
}

/** A stored variant: the translated fields plus `version` (and `updatedAt`). */
export type Variant = Record<string, unknown>;

// Records per call (ContentTranslationRemoteDataSource.batchSize …).
export const BATCH_SIZE = 120;
export const MAX_LINES_PER_CALL = 2500;
export const MAX_LINES_PER_ITEM = 200;

// -- the shapes this reads (structural, so the models need not be imported) --

export interface RecipeShape { id: string; title: string; ingredients: { name: string }[]; steps: string[]; contentLang: string | null; contentVersion: number }
export interface BookShape { id: string; title: string; contentLang: string | null; contentVersion: number }
export interface PlanShape { id: string; name: string; meals: { name: string; items: { freeText: string | null }[] }[]; contentLang: string | null; contentVersion: number }
export interface ListShape { id: string; name: string; items: { name: string }[]; contentLang: string | null; contentVersion: number }

// -- languages ---------------------------------------------------------------

export function langFromCode(code: string | null | undefined): LangCode | null {
  return code === "he" || code === "en" || code === "ar" || code === "fr" || code === "ru" ? code : null;
}

/**
 * What a record's text is written in when nothing was recorded (guessLanguage):
 * the script, with French and English told apart only by the fallback.
 */
export function guessLanguage(text: string, fallback: LangCode): LangCode {
  let hebrew = 0;
  let arabic = 0;
  let cyrillic = 0;
  let latin = 0;
  for (const ch of text) {
    const rune = ch.codePointAt(0) ?? 0;
    if (rune >= 0x0590 && rune <= 0x05ff) hebrew++;
    else if (rune >= 0x0600 && rune <= 0x06ff) arabic++;
    else if (rune >= 0x0400 && rune <= 0x04ff) cyrillic++;
    else if ((rune >= 0x41 && rune <= 0x5a) || (rune >= 0x61 && rune <= 0x7a)) latin++;
  }
  const best = Math.max(hebrew, arabic, cyrillic, latin);
  if (best === 0) return fallback;
  if (best === hebrew) return "he";
  if (best === arabic) return "ar";
  if (best === cyrillic) return "ru";
  return fallback === "fr" ? "fr" : "en";
}

/** A record is left alone when its text is already in the target (_needs). */
export function needsTranslation(contentLang: string | null | undefined, sample: string, target: LangCode): boolean {
  const current = langFromCode(contentLang) ?? guessLanguage(sample, target);
  return current !== target;
}

/** Which language a record's own text is in, for filing the original (_sourceLanguageOf). */
export function sourceLanguageOf(contentLang: string | null | undefined, sample: string): LangCode {
  return langFromCode(contentLang) ?? guessLanguage(sample, "en");
}

// -- what goes to the model --------------------------------------------------

export function planFreeText(p: PlanShape): string[] {
  const out: string[] = [];
  for (const meal of p.meals) for (const item of meal.items) if (item.freeText != null && item.freeText.trim() !== "") out.push(item.freeText);
  return out;
}

export function recipeItem(r: RecipeShape): TranslatableItem {
  return { type: "recipe", id: r.id, version: r.contentVersion, fields: { title: r.title, ingredients: r.ingredients.map((i) => i.name), steps: [...r.steps] } };
}
export function bookItem(b: BookShape): TranslatableItem {
  return { type: "book", id: b.id, version: b.contentVersion, fields: { title: b.title } };
}
export function planItem(p: PlanShape): TranslatableItem {
  return { type: "mealPlan", id: p.id, version: p.contentVersion, fields: { name: p.name, meals: p.meals.map((m) => m.name), items: planFreeText(p) } };
}
export function listItem(l: ListShape): TranslatableItem {
  return { type: "groceryList", id: l.id, version: l.contentVersion, fields: { name: l.name, items: l.items.map((i) => i.name) } };
}

/** The text a record is judged by (title or name). */
export function sampleOf(type: ContentType, record: { title?: string; name?: string }): string {
  return (type === "recipe" || type === "book" ? record.title : record.name) ?? "";
}

// -- batching (batchesOf / linesIn / fitting) ---------------------------------

/** One per text field, one per list entry — the way the server counts. */
export function linesIn(item: TranslatableItem): number {
  let n = 0;
  for (const value of Object.values(item.fields)) {
    if (typeof value === "string") n += 1;
    else if (Array.isArray(value)) n += value.length;
  }
  return n;
}

// The daily budget is spent in units, not lines: a line costs one unit per
// started UNIT_CHARS characters of its trimmed text (translateContent's
// unitsOf), so a long step costs what it costs.
export const UNIT_CHARS = 300;
export function unitsOf(line: string): number {
  return Math.max(1, Math.ceil(line.trim().length / UNIT_CHARS));
}
/** The budget units a record costs at most (the server skips cached lines). */
export function unitsIn(item: TranslatableItem): number {
  let n = 0;
  for (const value of Object.values(item.fields)) {
    if (typeof value === "string") n += unitsOf(value);
    else if (Array.isArray(value)) for (const line of value) n += unitsOf(line);
  }
  return n;
}

/** ≤ BATCH_SIZE records and ≤ MAX_LINES_PER_CALL lines per call; records over MAX_LINES_PER_ITEM are left out. */
export function batchesOf(items: TranslatableItem[]): TranslatableItem[][] {
  const out: TranslatableItem[][] = [];
  let current: TranslatableItem[] = [];
  let lines = 0;
  for (const item of items) {
    const n = linesIn(item);
    if (n > MAX_LINES_PER_ITEM) continue;
    if (current.length > 0 && (current.length >= BATCH_SIZE || lines + n > MAX_LINES_PER_CALL)) {
      out.push(current);
      current = [];
      lines = 0;
    }
    current.push(item);
    lines += n;
  }
  if (current.length > 0) out.push(current);
  return out;
}

/**
 * The leading part of `slice` that fits in what a quota refusal says is left,
 * or null when nothing smaller can be sent (not a sized refusal, nothing
 * left, or even the first record does not fit). Counted in the server's
 * units (unitsIn): a refusal is sized in units, so counting lines here let a
 * batch of long lines be re-sent once more than it had to be.
 */
export function fitting(slice: TranslatableItem[], quota: { used: number; limit: number; requested?: number } | null): TranslatableItem[] | null {
  if (!quota || quota.requested == null) return null;
  const left = quota.limit - quota.used;
  const fits: TranslatableItem[] = [];
  let units = 0;
  for (const item of slice) {
    const n = unitsIn(item);
    if (units + n > left) break;
    fits.push(item);
    units += n;
  }
  // Strictly smaller, or a refusal counted differently would loop forever.
  if (fits.length === 0 || fits.length >= slice.length) return null;
  return fits;
}

// -- reading a variant (TranslatedFields) ------------------------------------

/** The version a variant was made from; -1 (matches nothing) when absent. */
export function variantVersion(v: Variant): number {
  const value = v.version;
  return typeof value === "number" && Number.isFinite(value) ? Math.trunc(value) : -1;
}
function text(v: Variant, field: string): string | null {
  const value = v[field];
  return typeof value === "string" && value.trim() !== "" ? value : null;
}
function listOfLength(v: Variant, field: string, length: number): string[] | null {
  const value = v[field];
  if (!Array.isArray(value)) return null;
  const list = value.filter((x): x is string => typeof x === "string");
  return list.length === length ? list : null;
}

// -- laying a variant over a record (for display only) ------------------------
// The app writes these into the record; the website only shows them, so the
// stored record (and every edit made from it) keeps its own words.

export function applyRecipe<T extends RecipeShape>(r: T, v: Variant): T {
  const names = listOfLength(v, "ingredients", r.ingredients.length);
  return {
    ...r,
    title: text(v, "title") ?? r.title,
    ingredients: names ? r.ingredients.map((ing, i) => ({ ...ing, name: names[i] })) : r.ingredients,
    steps: listOfLength(v, "steps", r.steps.length) ?? r.steps,
  };
}
export function applyBook<T extends BookShape>(b: T, v: Variant): T {
  return { ...b, title: text(v, "title") ?? b.title };
}
export function applyPlan<T extends PlanShape>(p: T, v: Variant): T {
  const mealNames = listOfLength(v, "meals", p.meals.length);
  const freeText = listOfLength(v, "items", planFreeText(p).length);
  let cursor = 0;
  return {
    ...p,
    name: text(v, "name") ?? p.name,
    meals: p.meals.map((meal, index) => ({
      ...meal,
      name: mealNames ? mealNames[index] : meal.name,
      items: meal.items.map((item) =>
        item.freeText != null && item.freeText.trim() !== "" ? { ...item, freeText: freeText ? freeText[cursor++] : item.freeText } : item,
      ),
    })),
  };
}
export function applyList<T extends ListShape>(l: T, v: Variant): T {
  const names = listOfLength(v, "items", l.items.length);
  return { ...l, name: text(v, "name") ?? l.name, items: names ? l.items.map((it, i) => ({ ...it, name: names[i] })) : l.items };
}
