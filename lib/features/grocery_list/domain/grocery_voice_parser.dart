import '../../../core/constants/app_enums.dart';

/// One product heard in a spoken shopping line.
class VoiceGroceryItem {
  final String name;
  final double amount;
  final MeasurementUnit unit;

  const VoiceGroceryItem({
    required this.name,
    this.amount = 1,
    this.unit = MeasurementUnit.unit,
  });

  VoiceGroceryItem copyWith({String? name}) =>
      VoiceGroceryItem(name: name ?? this.name, amount: amount, unit: unit);

  @override
  bool operator ==(Object other) =>
      other is VoiceGroceryItem &&
      other.name == name &&
      other.amount == amount &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(name, amount, unit);

  @override
  String toString() => 'VoiceGroceryItem($name, $amount, ${unit.name})';
}

/// Turns "milk, eggs and two packs of bread" into three lines, on the
/// device and without the model: the shopper is standing in a kitchen and a
/// round trip for three words would be slower than typing them.
///
/// The word tables hold all five app languages at once. They hardly collide,
/// and a Hebrew speaker who says "פטה" or a French one who says "cottage" is
/// still parsed; it also spares the caller from knowing which recognizer
/// language produced the text.
class GroceryVoiceParser {
  const GroceryVoiceParser._();

  static List<VoiceGroceryItem> parse(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return const [];
    final items = <VoiceGroceryItem>[];
    var first = true;
    for (final chunk in normalized.split(_chunkBreak)) {
      var tokens = chunk.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
      if (first) {
        tokens = _dropCommand(tokens.toList());
        first = false;
      }
      for (final segment in _segments(tokens.toList())) {
        final item = _item(segment);
        if (item != null) items.add(item);
      }
    }
    return items;
  }

  // ── Normalizing and splitting ──────────────────────────────────────────

  /// Commas and full stops between items, but not inside "1.5" or "1,5";
  /// the Arabic comma and semicolons too.
  static final _chunkBreak = RegExp(r'(?<!\d)[.,](?!\d)|[.,](?=\s)|[;،\n]');

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('״', '"')
      // Hebrew maqaf joins "ו־" to its word, as a hyphen may.
      .replaceAll('־', ' ')
      // "2kg", "500g": the number and the unit as two words.
      .replaceAllMapped(
        RegExp(r'(\d)([^\d\s.,])'),
        (m) => '${m[1]} ${m[2]}',
      )
      .trim();

  /// Words that join two items.
  static const _andWords = {
    'and',
    'plus',
    'et',
    'и',
    'а',
    'также',
    'ו',
    'וגם',
    'גם',
    'و',
    'وكمان',
  };

  /// "And a half" after a quantity: part of the number, not a new item.
  static const _halfAfterAnd = {'half', 'demi', 'demie', 'חצי', 'نص', 'نصف'};

  /// Grocery words that begin with the letter that also means "and" in
  /// Hebrew (ו) and Arabic (و): never split.
  static const _vavWords = {
    'וניל',
    'ווניל',
    'וופל',
    'וופלים',
    'ופל',
    'ויסקי',
    'וודקה',
    'ודקה',
    'ורד',
    'ורדים',
    'וסאבי',
    'ואסבי',
    'ואקום',
    'ויטמין',
    'ויטמינים',
    'וויפס',
    'ורק',
    'ופלים',
    'ورق',
    'وجبة',
    'وجبات',
    'ورد',
    'وافل',
    'وايت',
    'ويسكي',
    'فانيليا',
  };

  /// "and" written as a letter on the front of the next word.
  static String? _andPrefixed(String token) {
    if (token.length < 3) return null;
    final head = token[0];
    if (head != 'ו' && head != 'و') return null;
    if (_vavWords.contains(token)) return null;
    final rest = token.substring(1);
    // Hebrew doubles the letter to mean "and" + a word that starts with it:
    // "ווניל" is caught above, "וו" + anything else is "and ו…".
    return rest;
  }

  static const _commandWords = [
    ['i', 'need'],
    ['we', 'need'],
    ['add'],
    ['buy'],
    ['please', 'add'],
    ['תוסיף'],
    ['תוסיפי'],
    ['תוסיפו'],
    ['להוסיף'],
    ['תרשום'],
    ['תרשמי'],
    ['צריך'],
    ['צריכה'],
    ['צריכים'],
    ['לקנות'],
    ['קנה'],
    ['תקנה'],
    ['ajoute'],
    ['ajouter'],
    ['acheter'],
    ['il', 'faut'],
    ['achète'],
    ['добавь'],
    ['добавить'],
    ['купить'],
    ['купи'],
    ['нужно'],
    ['надо'],
    ['أضف'],
    ['اضف'],
    ['ضيف'],
    ['اشتري'],
    ['نحتاج'],
    ['بدنا'],
  ];

  static List<String> _dropCommand(List<String> tokens) {
    for (final words in _commandWords) {
      if (tokens.length > words.length &&
          [
            for (var i = 0; i < words.length; i++) tokens[i] == words[i],
          ].every((b) => b)) {
        return tokens.sublist(words.length);
      }
    }
    return tokens;
  }

  /// Splits a chunk on the "and" words, keeping "one and a half" whole.
  static List<List<String>> _segments(List<String> tokens) {
    final segments = <List<String>>[];
    var current = <String>[];
    void close() {
      if (current.isNotEmpty) segments.add(current);
      current = <String>[];
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (_andWords.contains(token)) {
        // "one and a half", "קילו ו חצי": the half belongs to the quantity.
        final next = i + 1 < tokens.length ? tokens[i + 1] : null;
        final afterA = i + 2 < tokens.length ? tokens[i + 2] : null;
        if (_hasQuantity(current) &&
            (_halfAfterAnd.contains(next) ||
                (next == 'a' && afterA == 'half'))) {
          current.add('+half');
          i += next == 'a' ? 2 : 1;
          continue;
        }
        close();
        continue;
      }
      final rest = _andPrefixed(token);
      if (rest != null) {
        if (_halfAfterAnd.contains(rest) && _hasQuantity(current)) {
          current.add('+half');
          continue;
        }
        close();
        current.add(rest);
        continue;
      }
      current.add(token);
    }
    close();
    return segments;
  }

  static bool _hasQuantity(List<String> tokens) =>
      tokens.any((t) => _number(t) != null || _unitOf(t) != null);

  // ── One item ───────────────────────────────────────────────────────────

  static VoiceGroceryItem? _item(List<String> tokens) {
    double? amount;
    MeasurementUnit? unit;
    final name = <String>[];
    // Particles right after a quantity or a unit ("of", "de", "של") are
    // dropped; anywhere else they are part of the name ("pâte de coing").
    var afterQuantity = false;
    for (final raw in tokens) {
      var token = raw;
      if (token == '+half') {
        amount = (amount ?? 1) + 0.5;
        afterQuantity = true;
        continue;
      }
      // French elision: "d'oeufs", "l'huile".
      if (token.length > 2 &&
          (token.startsWith("d'") || token.startsWith("l'"))) {
        token = token.substring(2);
        if (name.isEmpty) afterQuantity = false;
      }
      final dual = _duals[token];
      if (dual != null && name.isEmpty) {
        amount = (amount ?? 1) * 2;
        unit ??= dual;
        afterQuantity = true;
        continue;
      }
      final number = _number(token);
      if (number != null && name.isEmpty) {
        amount = (amount ?? 1) * number;
        afterQuantity = true;
        continue;
      }
      final u = _unitOf(token);
      if (u != null && unit == null && name.isEmpty) {
        unit = u;
        afterQuantity = true;
        continue;
      }
      if (afterQuantity && name.isEmpty && _particles.contains(token)) continue;
      if (name.isEmpty && _fillers.contains(token)) continue;
      // A number after the name: "לחם אחד", "bread two".
      if (number != null && name.isNotEmpty && amount == null) {
        amount = number;
        continue;
      }
      name.add(token);
    }
    final joined = name.join(' ').trim();
    if (joined.isEmpty) return null;
    return VoiceGroceryItem(
      name: joined,
      amount: amount ?? 1,
      unit: unit ?? MeasurementUnit.unit,
    );
  }

  static const _particles = {
    'of',
    'de',
    'du',
    'des',
    "d'",
    'la',
    'של',
    'من',
  };

  static const _fillers = {
    'some',
    'a',
    'an',
    'the',
    'also',
    'more',
    'please',
    'גם',
    'עוד',
    'קצת',
    'בבקשה',
    'du',
    'de',
    'des',
    'aussi',
    'encore',
    'un',
    'une',
    'ещё',
    'еще',
    'немного',
    'كمان',
    'أيضا',
    'ايضا',
    'شوية',
  };

  // ── Numbers ────────────────────────────────────────────────────────────

  static const _numberWords = <String, double>{
    // English
    'a': 1, 'an': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
    'twelve': 12, 'dozen': 12, 'half': 0.5, 'couple': 2,
    // Hebrew
    'אחד': 1, 'אחת': 1, 'שניים': 2, 'שנים': 2, 'שתיים': 2, 'שתים': 2,
    'שני': 2, 'שתי': 2, 'זוג': 2, 'שלוש': 3, 'שלושה': 3, 'שלושת': 3,
    'ארבע': 4, 'ארבעה': 4, 'ארבעת': 4, 'חמש': 5, 'חמישה': 5, 'חמשת': 5,
    'שש': 6, 'שישה': 6, 'ששת': 6, 'שבע': 7, 'שבעה': 7, 'שבעת': 7,
    'שמונה': 8, 'שמונת': 8, 'תשע': 9, 'תשעה': 9, 'תשעת': 9, 'עשר': 10,
    'עשרה': 10, 'עשרת': 10, 'תריסר': 12, 'חצי': 0.5,
    // French ("un"/"une" are counted only before a unit or a name)
    'un': 1, 'une': 1, 'deux': 2, 'trois': 3, 'quatre': 4, 'cinq': 5,
    'sept': 7, 'huit': 8, 'neuf': 9, 'dix': 10, 'douze': 12,
    'douzaine': 12, 'demi': 0.5, 'demie': 0.5,
    // Russian
    'один': 1, 'одна': 1, 'одно': 1, 'два': 2, 'две': 2, 'три': 3,
    'четыре': 4, 'пять': 5, 'шесть': 6, 'семь': 7, 'восемь': 8,
    'девять': 9, 'десять': 10, 'дюжина': 12, 'пол': 0.5, 'половина': 0.5,
    'полкило': 0.5,
    // Arabic
    'واحد': 1, 'واحدة': 1, 'اثنين': 2, 'اثنان': 2, 'اثنتين': 2,
    'اثنتان': 2, 'إثنين': 2, 'ثلاث': 3, 'ثلاثة': 3, 'تلاتة': 3, 'أربع': 4,
    'أربعة': 4, 'اربعة': 4, 'اربع': 4, 'خمس': 5, 'خمسة': 5, 'ست': 6,
    'ستة': 6, 'سبع': 7, 'سبعة': 7, 'ثمان': 8, 'ثمانية': 8, 'تسع': 9,
    'تسعة': 9, 'عشر': 10, 'عشرة': 10, 'دزينة': 12, 'نصف': 0.5, 'نص': 0.5,
  };

  static double? _number(String token) {
    final digits = double.tryParse(token.replaceAll(',', '.'));
    if (digits != null && digits.isFinite && digits > 0) return digits;
    return _numberWords[token];
  }

  // ── Units ──────────────────────────────────────────────────────────────

  static const _unitWords = <String, MeasurementUnit>{
    // Weight
    'kg': MeasurementUnit.kilogram, 'kilo': MeasurementUnit.kilogram,
    'kilos': MeasurementUnit.kilogram, 'kilogram': MeasurementUnit.kilogram,
    'kilograms': MeasurementUnit.kilogram,
    'kilogramme': MeasurementUnit.kilogram,
    'kilogrammes': MeasurementUnit.kilogram,
    'קילו': MeasurementUnit.kilogram, 'קילוגרם': MeasurementUnit.kilogram,
    'ק"ג': MeasurementUnit.kilogram, 'кг': MeasurementUnit.kilogram,
    'кило': MeasurementUnit.kilogram, 'килограмм': MeasurementUnit.kilogram,
    'килограмма': MeasurementUnit.kilogram,
    'килограммов': MeasurementUnit.kilogram,
    'كيلو': MeasurementUnit.kilogram, 'كيلوغرام': MeasurementUnit.kilogram,
    'كغ': MeasurementUnit.kilogram,
    'g': MeasurementUnit.gram, 'gr': MeasurementUnit.gram,
    'gram': MeasurementUnit.gram, 'grams': MeasurementUnit.gram,
    'gramme': MeasurementUnit.gram, 'grammes': MeasurementUnit.gram,
    'גרם': MeasurementUnit.gram, 'גרמים': MeasurementUnit.gram,
    'г': MeasurementUnit.gram, 'грамм': MeasurementUnit.gram,
    'грамма': MeasurementUnit.gram, 'граммов': MeasurementUnit.gram,
    'غرام': MeasurementUnit.gram, 'جرام': MeasurementUnit.gram,
    'غم': MeasurementUnit.gram,
    // Volume
    'l': MeasurementUnit.liter, 'liter': MeasurementUnit.liter,
    'liters': MeasurementUnit.liter, 'litre': MeasurementUnit.liter,
    'litres': MeasurementUnit.liter, 'ליטר': MeasurementUnit.liter,
    'ליטרים': MeasurementUnit.liter, 'л': MeasurementUnit.liter,
    'литр': MeasurementUnit.liter, 'литра': MeasurementUnit.liter,
    'литров': MeasurementUnit.liter, 'لتر': MeasurementUnit.liter,
    'ليتر': MeasurementUnit.liter,
    'ml': MeasurementUnit.milliliter, 'מ"ל': MeasurementUnit.milliliter,
    'מיליליטר': MeasurementUnit.milliliter, 'мл': MeasurementUnit.milliliter,
    'مل': MeasurementUnit.milliliter,
    // Packages: counted as units, the package word itself dropped.
    'pack': MeasurementUnit.unit, 'packs': MeasurementUnit.unit,
    'package': MeasurementUnit.unit, 'packages': MeasurementUnit.unit,
    'packet': MeasurementUnit.unit, 'packets': MeasurementUnit.unit,
    'bottle': MeasurementUnit.unit, 'bottles': MeasurementUnit.unit,
    'can': MeasurementUnit.unit, 'cans': MeasurementUnit.unit,
    'box': MeasurementUnit.unit, 'boxes': MeasurementUnit.unit,
    'bag': MeasurementUnit.unit, 'bags': MeasurementUnit.unit,
    'jar': MeasurementUnit.unit, 'jars': MeasurementUnit.unit,
    'carton': MeasurementUnit.unit, 'cartons': MeasurementUnit.unit,
    'loaf': MeasurementUnit.unit, 'loaves': MeasurementUnit.unit,
    'חבילה': MeasurementUnit.unit, 'חבילות': MeasurementUnit.unit,
    'חבילת': MeasurementUnit.unit, 'בקבוק': MeasurementUnit.unit,
    'בקבוקים': MeasurementUnit.unit, 'בקבוקי': MeasurementUnit.unit,
    'קופסה': MeasurementUnit.unit, 'קופסא': MeasurementUnit.unit,
    'קופסת': MeasurementUnit.unit, 'קופסאות': MeasurementUnit.unit,
    'קופסות': MeasurementUnit.unit, 'שקית': MeasurementUnit.unit,
    'שקיות': MeasurementUnit.unit, 'קרטון': MeasurementUnit.unit,
    'קרטוני': MeasurementUnit.unit, 'צנצנת': MeasurementUnit.unit,
    'כיכר': MeasurementUnit.unit, 'כיכרות': MeasurementUnit.unit,
    'מארז': MeasurementUnit.unit, 'מארזים': MeasurementUnit.unit,
    'paquet': MeasurementUnit.unit, 'paquets': MeasurementUnit.unit,
    'bouteille': MeasurementUnit.unit, 'bouteilles': MeasurementUnit.unit,
    'boîte': MeasurementUnit.unit, 'boîtes': MeasurementUnit.unit,
    'boite': MeasurementUnit.unit, 'boites': MeasurementUnit.unit,
    'sachet': MeasurementUnit.unit, 'sachets': MeasurementUnit.unit,
    'pot': MeasurementUnit.unit, 'pots': MeasurementUnit.unit,
    'brique': MeasurementUnit.unit, 'briques': MeasurementUnit.unit,
    'пачка': MeasurementUnit.unit, 'пачки': MeasurementUnit.unit,
    'пачек': MeasurementUnit.unit, 'упаковка': MeasurementUnit.unit,
    'упаковки': MeasurementUnit.unit, 'упаковок': MeasurementUnit.unit,
    'бутылка': MeasurementUnit.unit, 'бутылки': MeasurementUnit.unit,
    'бутылок': MeasurementUnit.unit, 'банка': MeasurementUnit.unit,
    'банки': MeasurementUnit.unit, 'банок': MeasurementUnit.unit,
    'пакет': MeasurementUnit.unit, 'пакета': MeasurementUnit.unit,
    'пакетов': MeasurementUnit.unit, 'коробка': MeasurementUnit.unit,
    'коробки': MeasurementUnit.unit, 'буханка': MeasurementUnit.unit,
    'буханки': MeasurementUnit.unit,
    'علبة': MeasurementUnit.unit, 'علب': MeasurementUnit.unit,
    'كيس': MeasurementUnit.unit, 'أكياس': MeasurementUnit.unit,
    'اكياس': MeasurementUnit.unit, 'زجاجة': MeasurementUnit.unit,
    'زجاجات': MeasurementUnit.unit, 'عبوة': MeasurementUnit.unit,
    'عبوات': MeasurementUnit.unit, 'رغيف': MeasurementUnit.unit,
    'أرغفة': MeasurementUnit.unit, 'ربطة': MeasurementUnit.unit,
    'باكيت': MeasurementUnit.unit,
  };

  /// Arabic duals: one word that means two of a unit ("علبتين" = two cans).
  static const _duals = <String, MeasurementUnit>{
    'علبتين': MeasurementUnit.unit,
    'كيسين': MeasurementUnit.unit,
    'رغيفين': MeasurementUnit.unit,
    'زجاجتين': MeasurementUnit.unit,
    'لترين': MeasurementUnit.liter,
    'كيلوين': MeasurementUnit.kilogram,
  };

  static MeasurementUnit? _unitOf(String token) => _unitWords[token];
}
