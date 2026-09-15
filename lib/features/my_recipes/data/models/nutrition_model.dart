import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/nutrition_entity.dart';

part 'nutrition_model.freezed.dart';
part 'nutrition_model.g.dart';

/// Per-serving nutrition, nested inside [RecipeModel]. Type id 13 was the
/// next free one (see the registry note in app_enums.dart).
@freezed
@HiveType(typeId: 13)
sealed class NutritionModel with _$NutritionModel {
  const factory NutritionModel({
    @HiveField(0) required int calories,
    @HiveField(1) @Default(0) double proteinGrams,
    @HiveField(2) @Default(0) double carbsGrams,
    @HiveField(3) @Default(0) double fatGrams,
  }) = _NutritionModel;

  factory NutritionModel.fromJson(Map<String, dynamic> json) => _$NutritionModelFromJson(json);
}

extension NutritionModelMapper on NutritionModel {
  NutritionEntity toEntity() => NutritionEntity(
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      );
}

extension NutritionEntityMapper on NutritionEntity {
  NutritionModel toModel() => NutritionModel(
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      );
}
