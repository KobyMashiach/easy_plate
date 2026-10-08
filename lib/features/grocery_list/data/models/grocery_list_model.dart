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
    // Appended, never reordered: lists written before this existed decode with
    // the default and keep meaning "all plans".
    @HiveField(5) @Default(<String>[]) List<String> selectedPlanIds,

    /// The language the list name and the item names are written in.
    @HiveField(6) String? contentLang,

    /// See [RecipeModel.contentVersion].
    @HiveField(7) @Default(0) int contentVersion,

    // Appended for multiple lists. A list written before them decodes as a
    // meal-plan list, which is what the one list there was always was.
    /// A [GroceryListSource] name.
    @HiveField(8) @Default('plans') String source,
    @HiveField(9) String? recipeId,
    @HiveField(10) @Default(1.0) double recipeScale,
    @HiveField(11) int? recipeServings,
    @HiveField(12) String? recipeTitle,

    // Appended for sharing, as on MealPlanModel: the shared document's id
    // and this account's role name.
    @HiveField(13) String? collabId,
    @HiveField(14) String? collabRole,
  }) = _GroceryListModel;

  factory GroceryListModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryListModelFromJson(json);
}

extension GroceryListModelMapper on GroceryListModel {
  GroceryListEntity toEntity() => GroceryListEntity(
    id: id,
    name: name,
    items: items.map((i) => i.toEntity()).toList(),
    collaborators: collaborators.map(
      (k, v) => MapEntry(k, AccessRole.values.firstWhere((r) => r.name == v)),
    ),
    selectedPlanIds: selectedPlanIds,
    createdAt: createdAt,
    contentLang: contentLang,
    source: GroceryListSource.fromName(source),
    recipeId: recipeId,
    recipeScale: recipeScale,
    recipeServings: recipeServings,
    recipeTitle: recipeTitle,
    collabId: collabId,
    collabRole: CollabRole.values
        .where((r) => r.name == collabRole)
        .firstOrNull,
  );
}

extension GroceryListEntityMapper on GroceryListEntity {
  GroceryListModel toModel() => GroceryListModel(
    id: id,
    name: name,
    items: items.map((i) => i.toModel()).toList(),
    collaborators: collaborators.map((k, v) => MapEntry(k, v.name)),
    selectedPlanIds: selectedPlanIds,
    createdAt: createdAt,
    contentLang: contentLang,
    source: source.name,
    recipeId: recipeId,
    recipeScale: recipeScale,
    recipeServings: recipeServings,
    recipeTitle: recipeTitle,
    collabId: collabId,
    collabRole: collabRole?.name,
  );
}
