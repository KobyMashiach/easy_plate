import '../../../../core/constants/app_enums.dart';
import '../../../../core/utils/amount_format.dart';

class RecipeIngredientEntity {
  final String name;
  final double? amount;
  final MeasurementUnit unit;

  /// The part of the dish this ingredient belongs to ("לרוטב", "לבשר"),
  /// when the recipe splits its list. Drawn as a heading above the run of
  /// ingredients that share it; never an ingredient itself, so it cannot
  /// reach a grocery list. Null for an undivided list.
  final String? section;

  const RecipeIngredientEntity({
    required this.name,
    required this.amount,
    this.unit = MeasurementUnit.unspecified,
    this.section,
  });

  RecipeIngredientEntity copyWith({
    String? name,
    double? amount,
    MeasurementUnit? unit,
    String? section,
  }) => RecipeIngredientEntity(
    name: name ?? this.name,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    section: section ?? this.section,
  );

  bool get isAmountMissing => amount == null;

  /// The amount as a cook reads it; see [formatAmount].
  String get displayAmount => formatAmount(amount);
}

/// A stored or model-given section name as the entity keeps it: trimmed,
/// capped, and null when there is none (or it is not text).
String? ingredientSection(Object? raw) {
  if (raw is! String) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;
  return text.length > 60 ? text.substring(0, 60).trim() : text;
}

/// The distinct section names of [ingredients], in the order they first
/// appear.
List<String> ingredientSections(List<RecipeIngredientEntity> ingredients) => [
  ...{
    for (final i in ingredients) ?i.section,
  },
];

final _headingLead = RegExp(
  r'^(?:(?:מצרכים|רכיבים)\s+(?:עבור\s+)?ל?|ingredients\s+for\s+(?:the\s+)?)',
  caseSensitive: false,
);
final _forThe = RegExp(r'^for\s+the\s+', caseSensitive: false);
final _wholeList = RegExp(
  r'^(?:מצרכים|רכיבים|ingredients)$',
  caseSensitive: false,
);

/// Whether [line] is a heading rather than an ingredient ("מצרכים לרוטב:",
/// "For the sauce:", a bare "מצרכים:"). Only a line with no amount: a
/// heading never carries one.
bool isSectionHeading(RecipeIngredientEntity line) {
  if (line.amount != null) return false;
  final name = line.name.trim();
  // "for the …" without a colon is too common inside real ingredient names.
  return name.endsWith(':') ||
      name.endsWith('：') ||
      _headingLead.hasMatch(name);
}

/// The section a heading line names, or null for one that names the whole
/// list ("מצרכים:").
String? sectionOfHeading(RecipeIngredientEntity line) {
  var text = line.name.trim().replaceFirst(RegExp(r'[:：]\s*$'), '').trim();
  if (_wholeList.hasMatch(text)) return null;
  final lead = _headingLead.firstMatch(text) ?? _forThe.firstMatch(text);
  if (lead != null && lead.end < text.length) {
    text = text.substring(lead.end).trim();
  }
  return ingredientSection(text);
}

/// [lines] with every heading line taken out and laid, as the section, on
/// the ingredients under it that do not name one of their own — so a source
/// that wrote "מצרכים לרוטב" as a line of its own still gets a heading, and
/// the heading never reaches a grocery list.
List<RecipeIngredientEntity> sectionHeadingsLifted(
  List<RecipeIngredientEntity> lines,
) {
  String? current;
  final out = <RecipeIngredientEntity>[];
  for (final line in lines) {
    if (isSectionHeading(line)) {
      current = sectionOfHeading(line);
    } else if (line.section == null && current != null) {
      out.add(line.copyWith(section: current));
    } else {
      out.add(line);
    }
  }
  return out;
}

/// The section heading to draw above `ingredients[index]`: its section when
/// that differs from the line before it, otherwise null.
String? sectionStartingAt(List<RecipeIngredientEntity> ingredients, int index) {
  final section = ingredients[index].section;
  if (section == null) return null;
  if (index > 0 && ingredients[index - 1].section == section) return null;
  return section;
}
