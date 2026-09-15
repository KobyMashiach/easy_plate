import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/recipe_entity.dart';
import 'nutrition_model.dart';
import 'recipe_ingredient_model.dart';

part 'recipe_model.freezed.dart';
part 'recipe_model.g.dart';

@freezed
@HiveType(typeId: 3)
sealed class RecipeModel with _$RecipeModel {
  static const hiveKey = 'recipesBox';

  const factory RecipeModel({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) int? prepTimeMinutes,
    @HiveField(3) int? cookTimeMinutes,
    @HiveField(4) required List<RecipeIngredientModel> ingredients,
    @HiveField(5) required List<String> steps,
    @HiveField(6) @Default([]) List<DietaryPreference> dietaryTags,
    @HiveField(7) String? sourceChannel,
    @HiveField(8) String? sourceUrl,
    @HiveField(9) required DateTime createdAt,
    @HiveField(10) String? imageFileName,
    // Appended, never reordered: recipes written before this existed decode
    // as null, which correctly reads as "mine".
    @HiveField(11) String? savedFromSharedId,
    @HiveField(12) @Default(false) bool pendingAnalysis,
    @HiveField(13) String? collabId,
    // Enum name as a string, like `sourceChannel`, so no adapter is needed.
    @HiveField(14) String? collabRole,
    // Appended like the fields above it: a recipe stored before photos could
    // travel decodes as null, which correctly reads as "never uploaded".
    @HiveField(15) String? imageStoragePath,
    // Allergen names as strings, like `collabRole`. Recipes stored before
    // these existed decode as null, which the adapter reads as empty.
    @HiveField(16) @Default([]) List<String> allergens,
    @HiveField(17) @Default([]) List<String> mayContain,
    // Servings and per-serving nutrition, appended like everything above:
    // older recipes decode as null and show as "not estimated yet".
    @HiveField(18) int? servings,
    @HiveField(19) NutritionModel? nutrition,
  }) = _RecipeModel;

  factory RecipeModel.fromJson(Map<String, dynamic> json) => _$RecipeModelFromJson(json);
}

extension RecipeModelMapper on RecipeModel {
  RecipeEntity toEntity() => RecipeEntity(
        id: id,
        title: title,
        prepTimeMinutes: prepTimeMinutes,
        cookTimeMinutes: cookTimeMinutes,
        ingredients: ingredients.map((i) => i.toEntity()).toList(),
        steps: steps,
        dietaryTags: dietaryTags,
        servings: servings,
        nutrition: nutrition?.toEntity(),
        allergens: Allergen.fromNames(allergens),
        mayContain: Allergen.fromNames(mayContain),
        sourceChannel: sourceChannel == null
            ? null
            : RecipeIngestionChannel.values.firstWhere((c) => c.name == sourceChannel),
        sourceUrl: sourceUrl,
        imageFileName: imageFileName,
        imageStoragePath: imageStoragePath,
        savedFromSharedId: savedFromSharedId,
        pendingAnalysis: pendingAnalysis,
        collabId: collabId,
        collabRole: collabRole == null
            ? null
            : CollabRole.values.where((r) => r.name == collabRole).firstOrNull,
        createdAt: createdAt,
      );
}

extension RecipeEntityMapper on RecipeEntity {
  RecipeModel toModel() => RecipeModel(
        id: id,
        title: title,
        prepTimeMinutes: prepTimeMinutes,
        cookTimeMinutes: cookTimeMinutes,
        ingredients: ingredients.map((i) => i.toModel()).toList(),
        steps: steps,
        dietaryTags: dietaryTags,
        servings: servings,
        nutrition: nutrition?.toModel(),
        allergens: allergens.names,
        mayContain: mayContain.names,
        sourceChannel: sourceChannel?.name,
        sourceUrl: sourceUrl,
        imageFileName: imageFileName,
        imageStoragePath: imageStoragePath,
        savedFromSharedId: savedFromSharedId,
        pendingAnalysis: pendingAnalysis,
        collabId: collabId,
        collabRole: collabRole?.name,
        createdAt: createdAt,
      );
}
