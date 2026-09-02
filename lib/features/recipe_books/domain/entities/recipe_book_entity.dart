import '../../../../core/constants/app_enums.dart';
import 'book_recipe_ref_entity.dart';

class RecipeBookEntity {
  final String id;
  final String title;
  final List<BookRecipeRefEntity> recipeRefs;
  final Map<String, AccessRole> collaborators;
  final DateTime createdAt;

  const RecipeBookEntity({
    required this.id,
    required this.title,
    required this.recipeRefs,
    required this.createdAt,
    this.collaborators = const {},
  });

  List<BookRecipeRefEntity> get orderedRefs => [...recipeRefs]..sort((a, b) => a.order.compareTo(b.order));

  RecipeBookEntity copyWith({
    String? title,
    List<BookRecipeRefEntity>? recipeRefs,
    Map<String, AccessRole>? collaborators,
  }) {
    return RecipeBookEntity(
      id: id,
      title: title ?? this.title,
      recipeRefs: recipeRefs ?? this.recipeRefs,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt,
    );
  }
}
