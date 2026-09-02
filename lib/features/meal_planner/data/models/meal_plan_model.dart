import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/meal_plan_entity.dart';
import 'meal_model.dart';

part 'meal_plan_model.freezed.dart';
part 'meal_plan_model.g.dart';

@freezed
@HiveType(typeId: 8)
sealed class MealPlanModel with _$MealPlanModel {
  static const hiveKey = 'mealPlansBox';

  const factory MealPlanModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required List<MealModel> meals,
    @HiveField(3) required DateTime createdAt,
  }) = _MealPlanModel;

  factory MealPlanModel.fromJson(Map<String, dynamic> json) => _$MealPlanModelFromJson(json);
}

extension MealPlanModelMapper on MealPlanModel {
  MealPlanEntity toEntity() => MealPlanEntity(
        id: id,
        name: name,
        meals: meals.map((m) => m.toEntity()).toList(),
        createdAt: createdAt,
      );
}

extension MealPlanEntityMapper on MealPlanEntity {
  MealPlanModel toModel() => MealPlanModel(
        id: id,
        name: name,
        meals: meals.map((m) => m.toModel()).toList(),
        createdAt: createdAt,
      );
}
