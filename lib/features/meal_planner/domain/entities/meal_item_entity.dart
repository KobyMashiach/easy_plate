import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';

class MealItemEntity {
  final String id;
  final String? recipeId;
  final String? freeText;

  /// Products a free-text item is made of, so a quick entry like "omelette"
  /// still feeds eggs, milk and oil into the aggregated grocery list. Empty for
  /// recipe-backed items, which take their ingredients from the recipe.
  final List<RecipeIngredientEntity> ingredients;

  const MealItemEntity({
    required this.id,
    this.recipeId,
    this.freeText,
    this.ingredients = const [],
  });

  String get displayLabel => freeText ?? '';

  MealItemEntity copyWith({
    String? freeText,
    List<RecipeIngredientEntity>? ingredients,
  }) {
    return MealItemEntity(
      id: id,
      recipeId: recipeId,
      freeText: freeText ?? this.freeText,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}
