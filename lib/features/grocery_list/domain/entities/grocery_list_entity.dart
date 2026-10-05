import '../../../../core/constants/app_enums.dart';
import 'grocery_item_entity.dart';

/// What a list is built from, and so what "rebuild" means for it.
enum GroceryListSource {
  /// Aggregated from the meal plans in [GroceryListEntity.selectedPlanIds]
  /// (all of them when empty). Every list stored before lists had a source
  /// reads back as this.
  plans,

  /// The ingredients of one recipe, scaled by [GroceryListEntity.recipeScale].
  recipe,

  /// Filled by hand only; there is nothing to rebuild it from.
  manual
  ;

  static GroceryListSource fromName(String? name) =>
      values.where((s) => s.name == name).firstOrNull ?? plans;
}

class GroceryListEntity {
  final String id;
  final String name;
  final List<GroceryItemEntity> items;
  final Map<String, AccessRole> collaborators;

  /// Which meal plans feed the aggregation. Empty means every plan — the
  /// default, and what an existing list stored before this field existed reads
  /// back as. Only meaningful for [GroceryListSource.plans].
  final List<String> selectedPlanIds;
  final DateTime createdAt;

  /// The language this record's text is written in, as an [AppLanguage]
  /// name. Null for records saved before translation existed.
  final String? contentLang;

  /// Bumped when the text is edited; see the model's field of the same
  /// name. A translation made from this version stays good until it moves.
  final int contentVersion;

  final GroceryListSource source;

  /// For a [GroceryListSource.recipe] list: the recipe it was built from,
  /// how many times over, and — copied at creation, so the card reads
  /// without a lookup and still makes sense if the recipe is later deleted
  /// or was a community post that never lived on this device — its title
  /// and the servings it makes.
  final String? recipeId;
  final double recipeScale;
  final int? recipeServings;
  final String? recipeTitle;

  const GroceryListEntity({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.collaborators = const {},
    this.selectedPlanIds = const [],
    this.contentLang,
    this.contentVersion = 0,
    this.source = GroceryListSource.plans,
    this.recipeId,
    this.recipeScale = 1,
    this.recipeServings,
    this.recipeTitle,
  });

  bool get includesAllPlans => selectedPlanIds.isEmpty;

  /// Whether "rebuild" has anything to rebuild from.
  bool get canRegenerate => source != GroceryListSource.manual;

  int get checkedCount => items.where((i) => i.isChecked).length;

  GroceryListEntity copyWith({
    String? name,
    List<GroceryItemEntity>? items,
    List<String>? selectedPlanIds,
    String? contentLang,
    int? contentVersion,
    double? recipeScale,
  }) {
    return GroceryListEntity(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      collaborators: collaborators,
      selectedPlanIds: selectedPlanIds ?? this.selectedPlanIds,
      createdAt: createdAt,
      contentLang: contentLang ?? this.contentLang,
      contentVersion: contentVersion ?? this.contentVersion,
      source: source,
      recipeId: recipeId,
      recipeScale: recipeScale ?? this.recipeScale,
      recipeServings: recipeServings,
      recipeTitle: recipeTitle,
    );
  }
}
