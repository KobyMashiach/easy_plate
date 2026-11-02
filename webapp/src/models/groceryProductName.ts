// What goes on the grocery list for a recipe's ingredient line: the product
// itself, without how the recipe treats it. A port of the app's
// lib/features/grocery_list/domain/grocery_product_name.dart — a line's id
// is built from this name, so the two must agree word for word.

const CLAUSE_MARKERS = [
  // Hebrew
  "כמו", "לפי", "לא חובה", "אופציונלי", "רשות", "או", "בערך", "להגשה",
  "לקישוט", "לטיגון", "למריחה", "לציפוי", "להברשה", "לפיזור", "לשימון",
  "לבישול", "לאפייה", "לרוטב", "לתבול", "לתיבול", "בטמפרטורת", "לקוביות",
  "לרצועות", "לטבעות", "לפרוסות", "לחצאים", "לרבעים", "שאני", "שאת", "שאתם",
  "שאוהבים", "בתוספת",
  // English
  "or", "like", "such as", "to taste", "optional", "for serving",
  "for garnish", "for frying", "for greasing", "for brushing", "as needed",
  "at room temperature", "divided", "plus more", "about",
  // French
  "ou", "comme", "facultatif", "au goût", "selon le goût", "pour servir",
  "pour la décoration", "pour la friture", "environ",
  // Russian
  "или", "как", "по вкусу", "по желанию", "для подачи", "для украшения",
  "для жарки", "примерно",
  // Arabic
  "أو", "مثل", "حسب الرغبة", "حسب الذوق", "اختياري", "للتقديم", "للتزيين",
  "للقلي", "تقريبا",
];

const HEBREW_STEMS = [
  "מבושל", "קלוי", "מטוגן", "אפוי", "צלוי", "קצוץ", "פרוס", "מגורר", "מרוסק",
  "מקולף", "מסונן", "מושרה", "מופשר", "מומס", "חתוך", "מעוך", "מוקפץ",
  "מאודה", "כתוש", "סחוט", "מוקצף", "טרוף", "מחומם", "מצונן", "מנוקה", "שטוף",
  "רך", "קר", "חם", "פושר", "רותח", "גדול", "קטן", "בינוני", "דק", "היטב",
  "דק-דק",
];

const FINAL_LETTERS: Record<string, string> = { "ך": "כ", "ם": "מ", "ן": "נ", "ף": "פ", "ץ": "צ" };

const HEBREW_WORDS = new Set<string>(
  HEBREW_STEMS.flatMap((stem) => {
    const last = stem[stem.length - 1];
    const base = FINAL_LETTERS[last] ? stem.slice(0, -1) + FINAL_LETTERS[last] : stem;
    return [stem, ...["ה", "ת", "ים", "ות"].map((suffix) => base + suffix)];
  }),
);

const OTHER_WORDS = new Set<string>([
  // English
  "chopped", "diced", "minced", "sliced", "toasted", "cooked", "roasted",
  "grated", "melted", "softened", "peeled", "large", "small", "medium",
  "finely", "roughly", "thinly", "coarsely", "crushed", "beaten", "boiled",
  "fried", "baked", "shredded", "mashed", "halved", "quartered", "drained",
  "rinsed", "warm", "cold", "lukewarm", "packed", "sifted", "cubed",
  "trimmed", "squeezed", "whisked", "heaped",
  // Arabic
  "مفروم", "مفرومة", "مقطع", "مقطعة", "مطبوخ", "مطبوخة", "محمص", "محمصة",
  "مبشور", "مبشورة", "مذاب", "مذابة", "مقشر", "مقشرة", "كبير", "كبيرة",
  "صغير", "صغيرة", "متوسط", "متوسطة", "ناعم", "ناعمة", "مسلوق", "مسلوقة",
]);

const STEM_PREFIXES = [
  "haché", "émincé", "coupé", "râpé", "grillé", "cuit", "fondu", "pelé",
  "tranché", "écrasé", "battu", "ramolli", "égoutté", "finement", "grossièr",
  "нарезан", "измельч", "жарен", "варены", "варена", "варёны", "варёна", "тёрт", "терт", "растоплен",
  "очищен", "мелко", "крупно", "нашинков", "размягч", "отвар", "обжарен",
];

const WATER = new Set<string>([
  "מים", "מי ברז", "מים מהברז", "water", "tap water", "eau", "l'eau",
  "вода", "воды", "ماء", "مياه", "الماء",
]);

const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

function cutClauses(raw: string): string {
  let text = raw.trim();
  text = text.replace(/\([^)]*\)?|\[[^\]]*\]?/g, " ");
  const separator = /[,;:/|]|\s[-–—]\s/.exec(text);
  if (separator && separator.index > 0) text = text.slice(0, separator.index);
  const lower = text.toLowerCase();
  let end = text.length;
  for (const marker of CLAUSE_MARKERS) {
    const match = new RegExp(`(^|\\s)${escape(marker)}(?=\\s|$)`, "u").exec(lower);
    if (match && match.index > 0 && match.index < end) end = match.index;
  }
  return text.slice(0, end).trim();
}

function isPreparationWord(word: string): boolean {
  const lower = word.toLowerCase();
  if (OTHER_WORDS.has(lower) || HEBREW_WORDS.has(lower)) return true;
  if (lower.startsWith("ו") && HEBREW_WORDS.has(lower.slice(1))) return true;
  return STEM_PREFIXES.some((stem) => lower.startsWith(stem));
}

/** The product an ingredient line is bought as; null for plain water. */
export function groceryProductName(raw: string): string | null {
  const cut = cutClauses(raw);
  const words = cut.split(/\s+/).filter((w) => w.length > 0);
  const kept = words.filter((w) => !isPreparationWord(w));
  const name = (kept.length === 0 ? cut : kept.join(" ")).trim();
  const result = name.length === 0 ? raw.trim() : name;
  return WATER.has(result.toLowerCase()) ? null : result;
}
