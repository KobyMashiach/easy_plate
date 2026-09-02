import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/grocery_item_source_entity.dart';

part 'grocery_item_source_model.freezed.dart';
part 'grocery_item_source_model.g.dart';

@freezed
@HiveType(typeId: 9)
sealed class GroceryItemSourceModel with _$GroceryItemSourceModel {
  const factory GroceryItemSourceModel({
    @HiveField(0) String? recipeId,
    @HiveField(1) required String label,
    @HiveField(2) required double amount,
  }) = _GroceryItemSourceModel;

  factory GroceryItemSourceModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemSourceModelFromJson(json);
}

extension GroceryItemSourceModelMapper on GroceryItemSourceModel {
  GroceryItemSourceEntity toEntity() =>
      GroceryItemSourceEntity(recipeId: recipeId, label: label, amount: amount);
}

extension GroceryItemSourceEntityMapper on GroceryItemSourceEntity {
  GroceryItemSourceModel toModel() =>
      GroceryItemSourceModel(recipeId: recipeId, label: label, amount: amount);
}
