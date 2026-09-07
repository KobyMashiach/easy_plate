import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/recipe_book_entity.dart';
import 'book_recipe_ref_model.dart';

part 'recipe_book_model.freezed.dart';
part 'recipe_book_model.g.dart';

@freezed
@HiveType(typeId: 5)
sealed class RecipeBookModel with _$RecipeBookModel {
  static const hiveKey = 'recipeBooksBox';

  const factory RecipeBookModel({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required List<BookRecipeRefModel> recipeRefs,
    @HiveField(3) @Default({}) Map<String, String> collaborators,
    @HiveField(4) required DateTime createdAt,
    @HiveField(5) String? coverImageFileName,
    @HiveField(6) String? coverImageStoragePath,
  }) = _RecipeBookModel;

  factory RecipeBookModel.fromJson(Map<String, dynamic> json) => _$RecipeBookModelFromJson(json);
}

extension RecipeBookModelMapper on RecipeBookModel {
  RecipeBookEntity toEntity() => RecipeBookEntity(
        id: id,
        title: title,
        recipeRefs: recipeRefs.map((r) => r.toEntity()).toList(),
        collaborators: collaborators.map((k, v) => MapEntry(k, AccessRole.values.firstWhere((r) => r.name == v))),
        coverImageFileName: coverImageFileName,
        coverImageStoragePath: coverImageStoragePath,
        createdAt: createdAt,
      );
}

extension RecipeBookEntityMapper on RecipeBookEntity {
  RecipeBookModel toModel() => RecipeBookModel(
        id: id,
        title: title,
        recipeRefs: recipeRefs.map((r) => r.toModel()).toList(),
        collaborators: collaborators.map((k, v) => MapEntry(k, v.name)),
        coverImageFileName: coverImageFileName,
        coverImageStoragePath: coverImageStoragePath,
        createdAt: createdAt,
      );
}
