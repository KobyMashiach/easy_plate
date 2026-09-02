import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../my_recipes/data/models/recipe_ingredient_model.dart';
import '../../domain/entities/meal_item_entity.dart';

part 'meal_item_model.freezed.dart';
part 'meal_item_model.g.dart';

@freezed
@HiveType(typeId: 6)
sealed class MealItemModel with _$MealItemModel {
  const factory MealItemModel({
    @HiveField(0) required String id,
    @HiveField(1) String? recipeId,
    @HiveField(2) String? freeText,
    @HiveField(3) @Default([]) List<RecipeIngredientModel> ingredients,
  }) = _MealItemModel;

  factory MealItemModel.fromJson(Map<String, dynamic> json) => _$MealItemModelFromJson(json);
}

extension MealItemModelMapper on MealItemModel {
  MealItemEntity toEntity() => MealItemEntity(
        id: id,
        recipeId: recipeId,
        freeText: freeText,
        ingredients: ingredients.map((i) => i.toEntity()).toList(),
      );
}

extension MealItemEntityMapper on MealItemEntity {
  MealItemModel toModel() => MealItemModel(
        id: id,
        recipeId: recipeId,
        freeText: freeText,
        ingredients: ingredients.map((i) => i.toModel()).toList(),
      );
}
