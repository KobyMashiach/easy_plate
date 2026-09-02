import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';

part 'recipe_ingredient_model.freezed.dart';
part 'recipe_ingredient_model.g.dart';

@freezed
@HiveType(typeId: 2)
sealed class RecipeIngredientModel with _$RecipeIngredientModel {
  const factory RecipeIngredientModel({
    @HiveField(0) required String name,
    @HiveField(1) double? amount,
    @HiveField(2) @Default(MeasurementUnit.unspecified) MeasurementUnit unit,
  }) = _RecipeIngredientModel;

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientModelFromJson(json);
}

extension RecipeIngredientModelMapper on RecipeIngredientModel {
  RecipeIngredientEntity toEntity() => RecipeIngredientEntity(name: name, amount: amount, unit: unit);
}

extension RecipeIngredientEntityMapper on RecipeIngredientEntity {
  RecipeIngredientModel toModel() => RecipeIngredientModel(name: name, amount: amount, unit: unit);
}
