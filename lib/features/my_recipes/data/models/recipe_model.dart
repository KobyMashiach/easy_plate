import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/recipe_entity.dart';
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
        sourceChannel: sourceChannel == null
            ? null
            : RecipeIngestionChannel.values.firstWhere((c) => c.name == sourceChannel),
        sourceUrl: sourceUrl,
        imageFileName: imageFileName,
        savedFromSharedId: savedFromSharedId,
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
        sourceChannel: sourceChannel?.name,
        sourceUrl: sourceUrl,
        imageFileName: imageFileName,
        savedFromSharedId: savedFromSharedId,
        createdAt: createdAt,
      );
}
