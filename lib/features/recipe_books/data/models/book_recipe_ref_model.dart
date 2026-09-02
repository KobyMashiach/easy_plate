import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/book_recipe_ref_entity.dart';

part 'book_recipe_ref_model.freezed.dart';
part 'book_recipe_ref_model.g.dart';

@freezed
@HiveType(typeId: 4)
sealed class BookRecipeRefModel with _$BookRecipeRefModel {
  const factory BookRecipeRefModel({
    @HiveField(0) required String recipeId,
    @HiveField(1) required int order,
  }) = _BookRecipeRefModel;

  factory BookRecipeRefModel.fromJson(Map<String, dynamic> json) =>
      _$BookRecipeRefModelFromJson(json);
}

extension BookRecipeRefModelMapper on BookRecipeRefModel {
  BookRecipeRefEntity toEntity() => BookRecipeRefEntity(recipeId: recipeId, order: order);
}

extension BookRecipeRefEntityMapper on BookRecipeRefEntity {
  BookRecipeRefModel toModel() => BookRecipeRefModel(recipeId: recipeId, order: order);
}
