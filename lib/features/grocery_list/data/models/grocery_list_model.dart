import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/grocery_list_entity.dart';
import 'grocery_item_model.dart';

part 'grocery_list_model.freezed.dart';
part 'grocery_list_model.g.dart';

@freezed
@HiveType(typeId: 11)
sealed class GroceryListModel with _$GroceryListModel {
  static const hiveKey = 'groceryListsBox';

  const factory GroceryListModel({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required List<GroceryItemModel> items,
    @HiveField(3) @Default({}) Map<String, String> collaborators,
    @HiveField(4) required DateTime createdAt,
  }) = _GroceryListModel;

  factory GroceryListModel.fromJson(Map<String, dynamic> json) => _$GroceryListModelFromJson(json);
}

extension GroceryListModelMapper on GroceryListModel {
  GroceryListEntity toEntity() => GroceryListEntity(
        id: id,
        name: name,
        items: items.map((i) => i.toEntity()).toList(),
        collaborators: collaborators.map((k, v) => MapEntry(k, AccessRole.values.firstWhere((r) => r.name == v))),
        createdAt: createdAt,
      );
}

extension GroceryListEntityMapper on GroceryListEntity {
  GroceryListModel toModel() => GroceryListModel(
        id: id,
        name: name,
        items: items.map((i) => i.toModel()).toList(),
        collaborators: collaborators.map((k, v) => MapEntry(k, v.name)),
        createdAt: createdAt,
      );
}
