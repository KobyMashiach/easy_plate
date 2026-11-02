/// What goes on the grocery list for a recipe's ingredient line: the product
/// itself, without how the recipe treats it. "שמן שומשום מבושל קלוי כמו שאני
/// אוהבת" is bought as "שמן שומשום". Null for a line nobody shops for —
/// plain water.
///
/// Words that change what is bought stay: fresh, pickled, frozen, ground,
/// smoked, whole, coarse. Words about the cooking (toasted, chopped, melted), the size, the
/// cut, and everything after a comma, a bracket, "or", "like", "to taste",
/// "optional" or "for serving" go.
///
/// The website builds the same lines with the same rules
/// (`webapp/src/models/groceryProductName.ts`); a line's id comes from this
/// name, so the two must agree.
String? groceryProductName(String raw) {
  final cut = _cutClauses(raw);
  final words = cut.split(_spaces).where((w) => w.isNotEmpty).toList();
  final kept = [
    for (final word in words)
      if (!_isPreparationWord(word)) word,
  ];
  final name = (kept.isEmpty ? cut : kept.join(' ')).trim();
  final result = name.isEmpty ? raw.trim() : name;
  if (_water.contains(result.toLowerCase())) return null;
  return result;
}

final _spaces = RegExp(r'\s+');

/// Everything from the first of these on is about the recipe, not the
/// product. Matched on a word boundary, in lower case.
const _clauseMarkers = [
  // Hebrew
  'כמו', 'לפי', 'לא חובה', 'אופציונלי', 'רשות', 'או', 'בערך', 'להגשה',
  'לקישוט', 'לטיגון', 'למריחה', 'לציפוי', 'להברשה', 'לפיזור', 'לשימון',
  'לבישול', 'לאפייה', 'לרוטב', 'לתבול', 'לתיבול', 'בטמפרטורת', 'לקוביות',
  'לרצועות', 'לטבעות', 'לפרוסות', 'לחצאים', 'לרבעים', 'שאני', 'שאת', 'שאתם',
  'שאוהבים', 'בתוספת',
  // English
  'or', 'like', 'such as', 'to taste', 'optional', 'for serving',
  'for garnish', 'for frying', 'for greasing', 'for brushing', 'as needed',
  'at room temperature', 'divided', 'plus more', 'about',
  // French
  'ou', 'comme', 'facultatif', 'au goût', 'selon le goût', 'pour servir',
  'pour la décoration', 'pour la friture', 'environ',
  // Russian
  'или', 'как', 'по вкусу', 'по желанию', 'для подачи', 'для украшения',
  'для жарки', 'примерно',
  // Arabic
  'أو', 'مثل', 'حسب الرغبة', 'حسب الذوق', 'اختياري', 'للتقديم', 'للتزيين',
  'للقلي', 'تقريبا',
];

String _cutClauses(String raw) {
  var text = raw.trim();
  // Brackets, then the first separator: "בצל (גדול), קצוץ" → "בצל".
  text = text.replaceAll(RegExp(r'\([^)]*\)?|\[[^\]]*\]?'), ' ');
  final separator = RegExp(r'[,;:/|]|\s[-–—]\s').firstMatch(text);
  if (separator != null && separator.start > 0) {
    text = text.substring(0, separator.start);
  }
  final lower = text.toLowerCase();
  var end = text.length;
  for (final marker in _clauseMarkers) {
    final match = RegExp(
      '(^|\\s)${RegExp.escape(marker)}(?=\\s|\$)',
      unicode: true,
    ).firstMatch(lower);
    // Never the whole line: "או" alone is not a product, but neither is
    // an empty name.
    if (match != null && match.start > 0 && match.start < end) {
      end = match.start;
    }
  }
  return text.substring(0, end).trim();
}

/// Hebrew participles in their masculine singular; every gender and number
/// is derived below.
const _hebrewStems = [
  'מבושל',
  'קלוי',
  'מטוגן',
  'אפוי',
  'צלוי',
  'קצוץ',
  'פרוס',
  'מגורר',
  'מרוסק',
  'מקולף',
  'מסונן',
  'מושרה',
  'מופשר',
  'מומס',
  'חתוך',
  'מעוך',
  'מוקפץ',
  'מאודה',
  'כתוש',
  'סחוט',
  'מוקצף',
  'טרוף',
  'מחומם',
  'מצונן',
  'מנוקה',
  'שטוף',
  'רך',
  'קר',
  'חם',
  'פושר',
  'רותח',
  'גדול',
  'קטן',
  'בינוני',
  'דק',
  'היטב',
  'דק-דק',
];

const _finalLetters = {'ך': 'כ', 'ם': 'מ', 'ן': 'נ', 'ף': 'פ', 'ץ': 'צ'};

final Set<String> _hebrewWords = {
  for (final stem in _hebrewStems) ..._hebrewForms(stem),
};

Iterable<String> _hebrewForms(String stem) sync* {
  yield stem;
  final last = stem[stem.length - 1];
  final base = _finalLetters.containsKey(last)
      ? stem.substring(0, stem.length - 1) + _finalLetters[last]!
      : stem;
  for (final suffix in ['ה', 'ת', 'ים', 'ות']) {
    yield '$base$suffix';
  }
}

const _otherWords = {
  // English
  'chopped', 'diced', 'minced', 'sliced', 'toasted', 'cooked', 'roasted',
  'grated', 'melted', 'softened', 'peeled', 'large', 'small', 'medium',
  'finely', 'roughly', 'thinly', 'coarsely', 'crushed', 'beaten', 'boiled',
  'fried', 'baked', 'shredded', 'mashed', 'halved', 'quartered', 'drained',
  'rinsed', 'warm', 'cold', 'lukewarm', 'packed', 'sifted', 'cubed',
  'trimmed', 'squeezed', 'whisked', 'heaped',
  // Arabic
  'مفروم', 'مفرومة', 'مقطع', 'مقطعة', 'مطبوخ', 'مطبوخة', 'محمص', 'محمصة',
  'مبشور', 'مبشورة', 'مذاب', 'مذابة', 'مقشر', 'مقشرة', 'كبير', 'كبيرة',
  'صغير', 'صغيرة', 'متوسط', 'متوسطة', 'ناعم', 'ناعمة', 'مسلوق', 'مسلوقة',
};

/// French and Russian adjectives agree in too many endings to list; their
/// stems are matched as word prefixes instead (all long enough not to cut
/// into a product's name).
const _stemPrefixes = [
  'haché',
  'émincé',
  'coupé',
  'râpé',
  'grillé',
  'cuit',
  'fondu',
  'pelé',
  'tranché',
  'écrasé',
  'battu',
  'ramolli',
  'égoutté',
  'finement',
  'grossièr',
  'нарезан',
  'измельч',
  'жарен',
  'варены',
  'варена',
  'варёны',
  'варёна',
  'тёрт',
  'терт',
  'растоплен',
  'очищен',
  'мелко',
  'крупно',
  'нашинков',
  'размягч',
  'отвар',
  'обжарен',
];

bool _isPreparationWord(String word) {
  final lower = word.toLowerCase();
  if (_otherWords.contains(lower)) return true;
  // "וקלוי", "וקצוץ": the joined "and" of Hebrew.
  if (_hebrewWords.contains(lower)) return true;
  if (lower.startsWith('ו') && _hebrewWords.contains(lower.substring(1))) {
    return true;
  }
  for (final stem in _stemPrefixes) {
    if (lower.startsWith(stem)) return true;
  }
  return false;
}

/// Lines that are never bought.
const _water = {
  'מים',
  'מי ברז',
  'מים מהברז',
  'water',
  'tap water',
  'eau',
  "l'eau",
  'вода',
  'воды',
  'ماء',
  'مياه',
  'الماء',
};
