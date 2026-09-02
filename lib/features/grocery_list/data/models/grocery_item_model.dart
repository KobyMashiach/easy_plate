import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/grocery_item_entity.dart';
import 'grocery_item_source_model.dart';

part 'grocery_item_model.freezed.dart';
part 'grocery_item_model.g.dart';

@freezed
@HiveType(typeId: 10)
sealed class GroceryItemModel with _$GroceryItemModel {
  const factory GroceryItemModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) @Default(MeasurementUnit.unspecified) MeasurementUnit unit,
    @HiveField(3) required List<GroceryItemSourceModel> sources,
    @HiveField(4) @Default(false) bool isChecked,
    @HiveField(5) @Default('כללי') String category,
    @HiveField(6) @Default(false) bool isAdHoc,
  }) = _GroceryItemModel;

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) => _$GroceryItemModelFromJson(json);
}

extension GroceryItemModelMapper on GroceryItemModel {
  GroceryItemEntity toEntity() => GroceryItemEntity(
        id: id,
        name: name,
        unit: unit,
        sources: sources.map((s) => s.toEntity()).toList(),
        isChecked: isChecked,
        category: category,
        isAdHoc: isAdHoc,
      );
}

extension GroceryItemEntityMapper on GroceryItemEntity {
  GroceryItemModel toModel() => GroceryItemModel(
        id: id,
        name: name,
        unit: unit,
        sources: sources.map((s) => s.toModel()).toList(),
        isChecked: isChecked,
        category: category,
        isAdHoc: isAdHoc,
      );
}
