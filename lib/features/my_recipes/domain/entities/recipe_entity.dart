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

  /// File name of the recipe photo inside the app's image directory — never an
  /// absolute path, which would not survive a reinstall.
  final String? imageFileName;

  /// Set when this recipe was saved from the community feed. It is what
  /// separates "recipes I saved" from "recipes I wrote", and the copy stays
  /// fully editable — editing it changes only this local copy.
  final String? savedFromSharedId;
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
    this.imageFileName,
    this.savedFromSharedId,
  });

  bool get isSavedFromCommunity => savedFromSharedId != null;

  RecipeEntity copyWith({
    String? title,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<RecipeIngredientEntity>? ingredients,
    List<String>? steps,
    List<DietaryPreference>? dietaryTags,
    String? imageFileName,
    // A null `imageFileName` means "unchanged", so clearing needs its own flag.
    bool removeImage = false,
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
      imageFileName: removeImage ? null : (imageFileName ?? this.imageFileName),
      savedFromSharedId: savedFromSharedId,
      createdAt: createdAt,
    );
  }
}
