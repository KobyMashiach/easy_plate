import 'dart:convert';

import '../constants/app_enums.dart';
import 'readable_text.dart';

/// A recipe as a site published it in schema.org JSON-LD.
///
/// Most recipe sites embed one for search engines, and it is the site's own
/// structured statement of the recipe — no model involved, nothing invented.
/// Ingredients stay as the lines the site wrote; [parseIngredientLine] splits
/// them separately so the split is a visible, testable heuristic rather than
/// something buried in here.
class JsonLdRecipe {
  final String title;
  final int? prepMinutes;
  final int? cookMinutes;
  final List<String> ingredientLines;
  final List<String> steps;
  final List<DietaryPreference> diets;

  const JsonLdRecipe({
    required this.title,
    required this.ingredientLines,
    required this.steps,
    this.prepMinutes,
    this.cookMinutes,
    this.diets = const [],
  });
}

/// Finds a schema.org `Recipe` in the page's `ld+json` blocks, or null.
///
/// Tolerant of the shapes seen in the wild: a bare object, an array of
/// objects, a `@graph` wrapper, and `@type` given as a list. A block that is
/// not valid JSON is skipped rather than failing the whole page — one broken
/// script tag must not hide a good recipe in the next one.
JsonLdRecipe? parseJsonLdRecipe(String html) {
  final blocks = RegExp(
    r'<script[^>]*type\s*=\s*["\x27]application/ld\+json["\x27][^>]*>(.*?)</script>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html);

  for (final match in blocks) {
    final raw = match.group(1);
    if (raw == null) continue;

    Object? decoded;
    try {
      decoded = jsonDecode(raw.trim());
    } on FormatException {
      continue;
    }

    final recipe = _findRecipe(decoded);
    if (recipe != null) return _toRecipe(recipe);
  }
  return null;
}

/// Depth-first search for the first object whose `@type` is (or includes)
/// `Recipe`. Walks arrays and `@graph` wrappers.
Map<String, dynamic>? _findRecipe(Object? node) {
  if (node is List) {
    for (final item in node) {
      final found = _findRecipe(item);
      if (found != null) return found;
    }
    return null;
  }
  if (node is! Map<String, dynamic>) return null;

  if (_isType(node['@type'], 'Recipe')) return node;

  return _findRecipe(node['@graph']) ?? _findRecipe(node['mainEntity']);
}

bool _isType(Object? type, String wanted) {
  if (type is String) return type.toLowerCase() == wanted.toLowerCase();
  if (type is List) return type.any((t) => _isType(t, wanted));
  return false;
}

JsonLdRecipe? _toRecipe(Map<String, dynamic> node) {
  final title = _text(node['name']) ?? _text(node['headline']);
  if (title == null || title.isEmpty) return null;

  final ingredients = _stringList(node['recipeIngredient'] ?? node['ingredients']);
  final steps = _steps(node['recipeInstructions']);
  // A "recipe" with neither is a stub; the model does better with the page.
  if (ingredients.isEmpty && steps.isEmpty) return null;

  return JsonLdRecipe(
    title: title,
    ingredientLines: ingredients,
    steps: steps,
    prepMinutes: parseIso8601DurationMinutes(_text(node['prepTime'])),
    cookMinutes: parseIso8601DurationMinutes(_text(node['cookTime'])),
    diets: _diets(node['suitableForDiet']),
  );
}

/// `recipeInstructions` is the least consistent field on the schema: a single
/// string, a list of strings, a list of `HowToStep`, or `HowToSection`s that
/// each hold a list of steps. All of them end up as one flat ordered list.
List<String> _steps(Object? node) {
  if (node == null) return const [];

  if (node is String) {
    // One blob: split on line breaks and strip any HTML the site left in.
    return decodeHtmlEntities(node)
        .replaceAll(RegExp(r'<br\s*/?>|</p>|</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  if (node is Map<String, dynamic>) {
    if (_isType(node['@type'], 'HowToSection')) {
      return _steps(node['itemListElement']);
    }
    final text = _text(node['text']) ?? _text(node['name']);
    return text == null || text.isEmpty ? const [] : [text];
  }

  if (node is List) {
    return [for (final item in node) ..._steps(item)];
  }

  return const [];
}

List<String> _stringList(Object? node) {
  if (node is String) return [_clean(node)].where((s) => s.isNotEmpty).toList();
  if (node is List) {
    return node
        .map((item) => item is String ? _clean(item) : _text(item) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return const [];
}

String? _text(Object? node) {
  if (node is String) return _clean(node);
  if (node is List && node.isNotEmpty) return _text(node.first);
  if (node is Map<String, dynamic>) return _text(node['@value'] ?? node['name'] ?? node['text']);
  return null;
}

String _clean(String value) => decodeHtmlEntities(value)
    .replaceAll(RegExp(r'<[^>]+>'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// schema.org names its diets `https://schema.org/VeganDiet` and so on; only
/// the ones the app has a chip for are mapped.
List<DietaryPreference> _diets(Object? node) {
  final names = _stringList(node).map((s) => s.split('/').last.toLowerCase());
  // A set literal, so a site listing the same diet twice yields one chip.
  return {
    for (final name in names)
      if (name.contains('vegan'))
        DietaryPreference.vegan
      else if (name.contains('vegetarian'))
        DietaryPreference.vegetarian
      else if (name.contains('glutenfree'))
        DietaryPreference.glutenFree
      else if (name.contains('kosher'))
        DietaryPreference.kosher,
  }.toList();
}

/// ISO 8601 duration → minutes: `PT30M`, `PT1H15M`, `P0DT2H`. Anything else —
/// including the free text some sites put here — is null rather than a guess.
int? parseIso8601DurationMinutes(String? value) {
  if (value == null) return null;
  final match = RegExp(
    r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;

  final days = int.tryParse(match.group(1) ?? '') ?? 0;
  final hours = int.tryParse(match.group(2) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(3) ?? '') ?? 0;
  final seconds = int.tryParse(match.group(4) ?? '') ?? 0;

  final total = days * 24 * 60 + hours * 60 + minutes + (seconds >= 30 ? 1 : 0);
  // A duration that matched but adds up to nothing was "P" or "PT" — unstated.
  return total == 0 && match.group(0) == value.trim() && !value.contains(RegExp(r'\d')) ? null : total;
}

typedef ParsedIngredient = ({double? amount, MeasurementUnit unit, String name});

/// Splits "2 כוסות קמח" into amount 2, unit cup, name קמח.
///
/// A number with no unit word means pieces ("2 ביצים"). A line with no leading
/// number is kept whole as the name with no amount — the same "unstated" the
/// model reports, and nothing is thrown away.
ParsedIngredient parseIngredientLine(String line) {
  var rest = _clean(line);

  // Mixed number, then bare fraction, then decimal — most specific first.
  // With the decimal first, "1/2" matched as "1" and left "/2" in the name.
  final amountMatch = RegExp(
    r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?|[½¼¾⅓⅔⅛]|שלושת רבעי|חצי|רבע)\s*',
  ).firstMatch(rest);

  double? amount;
  if (amountMatch != null) {
    amount = _amount(amountMatch.group(1)!);
    rest = rest.substring(amountMatch.end).trim();
  }

  var unit = MeasurementUnit.unspecified;
  if (amount != null) {
    unit = MeasurementUnit.unit;
    final word = RegExp(r'^(\S+)\s*').firstMatch(rest)?.group(1);
    final mapped = word == null ? null : _unitFor(word);
    if (mapped != null) {
      unit = mapped;
      rest = rest.substring(word!.length).trim();
      // "2 כוסות של קמח" — the connective is not part of the name.
      rest = rest.replaceFirst(RegExp(r'^(של|of)\s+'), '');
    }
  }

  return (amount: amount, unit: unit, name: rest.isEmpty ? _clean(line) : rest);
}

double? _amount(String token) {
  const words = {'חצי': 0.5, 'רבע': 0.25, 'שלושת רבעי': 0.75};
  const glyphs = {'½': 0.5, '¼': 0.25, '¾': 0.75, '⅓': 1 / 3, '⅔': 2 / 3, '⅛': 0.125};
  if (words[token] case final w?) return w;
  if (glyphs[token] case final g?) return g;

  // "1 1/2" is one and a half; "1/2" alone is a half.
  final parts = token.split(RegExp(r'\s+'));
  var total = 0.0;
  for (final part in parts) {
    if (part.contains('/')) {
      final f = part.split('/');
      final n = double.tryParse(f[0]);
      final d = double.tryParse(f[1]);
      if (n == null || d == null || d == 0) return null;
      total += n / d;
    } else {
      final v = double.tryParse(part.replaceAll(',', '.'));
      if (v == null) return null;
      total += v;
    }
  }
  return total;
}

MeasurementUnit? _unitFor(String raw) {
  final word = raw.toLowerCase().replaceAll(RegExp(r'[.,;:]+$'), '');
  const map = <String, MeasurementUnit>{
    // Hebrew
    'כוס': MeasurementUnit.cup, 'כוסות': MeasurementUnit.cup,
    'כף': MeasurementUnit.tablespoon, 'כפות': MeasurementUnit.tablespoon,
    'כפית': MeasurementUnit.teaspoon, 'כפיות': MeasurementUnit.teaspoon,
    'גרם': MeasurementUnit.gram, "גר'": MeasurementUnit.gram, "ג'": MeasurementUnit.gram,
    'ק"ג': MeasurementUnit.kilogram, 'קילו': MeasurementUnit.kilogram,
    'קילוגרם': MeasurementUnit.kilogram,
    'מ"ל': MeasurementUnit.milliliter, 'מל': MeasurementUnit.milliliter,
    'ליטר': MeasurementUnit.liter,
    'קורט': MeasurementUnit.pinch, 'קמצוץ': MeasurementUnit.pinch,
    'יחידה': MeasurementUnit.unit, 'יחידות': MeasurementUnit.unit, "יח'": MeasurementUnit.unit,
    // English
    'cup': MeasurementUnit.cup, 'cups': MeasurementUnit.cup,
    'tbsp': MeasurementUnit.tablespoon, 'tablespoon': MeasurementUnit.tablespoon,
    'tablespoons': MeasurementUnit.tablespoon,
    'tsp': MeasurementUnit.teaspoon, 'teaspoon': MeasurementUnit.teaspoon,
    'teaspoons': MeasurementUnit.teaspoon,
    'g': MeasurementUnit.gram, 'gram': MeasurementUnit.gram, 'grams': MeasurementUnit.gram,
    'kg': MeasurementUnit.kilogram, 'kilogram': MeasurementUnit.kilogram,
    'kilograms': MeasurementUnit.kilogram,
    'ml': MeasurementUnit.milliliter, 'milliliter': MeasurementUnit.milliliter,
    'milliliters': MeasurementUnit.milliliter, 'millilitre': MeasurementUnit.milliliter,
    'millilitres': MeasurementUnit.milliliter,
    'l': MeasurementUnit.liter, 'liter': MeasurementUnit.liter, 'liters': MeasurementUnit.liter,
    'litre': MeasurementUnit.liter, 'litres': MeasurementUnit.liter,
    'pinch': MeasurementUnit.pinch,
    'unit': MeasurementUnit.unit, 'units': MeasurementUnit.unit,
    'piece': MeasurementUnit.unit, 'pieces': MeasurementUnit.unit, 'pcs': MeasurementUnit.unit,
  };
  return map[word];
}
