import '../../../../core/constants/app_enums.dart';
import 'recipe_ingredient_entity.dart';

class RecipeEntity {
  final String id;
  final String title;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final List<RecipeIngredientEntity> ingredients;
  final List<String> steps;
  final List<DietaryPreference> dietaryTags;
  final RecipeIngestionChannel? sourceChannel;
  final String? sourceUrl;
  final DateTime createdAt;

  const RecipeEntity({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.createdAt,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.dietaryTags = const [],
    this.sourceChannel,
    this.sourceUrl,
  });

  RecipeEntity copyWith({
    String? title,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<RecipeIngredientEntity>? ingredients,
    List<String>? steps,
    List<DietaryPreference>? dietaryTags,
  }) {
    return RecipeEntity(
      id: id,
      title: title ?? this.title,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      sourceChannel: sourceChannel,
      sourceUrl: sourceUrl,
      createdAt: createdAt,
    );
  }
}
