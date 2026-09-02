import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/meal_entity.dart';
import 'meal_item_model.dart';

part 'meal_model.freezed.dart';
part 'meal_model.g.dart';

@freezed
@HiveType(typeId: 7)
sealed class MealModel with _$MealModel {
  const factory MealModel({
    @HiveField(0) required String id,
    @HiveField(1) required int weekday,
    @HiveField(2) required String name,
    @HiveField(3) required int order,
    @HiveField(4) required List<MealItemModel> items,
  }) = _MealModel;

  factory MealModel.fromJson(Map<String, dynamic> json) => _$MealModelFromJson(json);
}

extension MealModelMapper on MealModel {
  MealEntity toEntity() => MealEntity(
        id: id,
        weekday: weekday,
        name: name,
        order: order,
        items: items.map((i) => i.toEntity()).toList(),
      );
}

extension MealEntityMapper on MealEntity {
  MealModel toModel() => MealModel(
        id: id,
        weekday: weekday,
        name: name,
        order: order,
        items: items.map((i) => i.toModel()).toList(),
      );
}
