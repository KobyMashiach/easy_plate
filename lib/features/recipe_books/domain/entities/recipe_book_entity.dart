import '../../../../core/constants/app_enums.dart';
import 'book_recipe_ref_entity.dart';

class RecipeBookEntity {
  final String id;
  final String title;
  final List<BookRecipeRefEntity> recipeRefs;
  final Map<String, AccessRole> collaborators;

  /// File name of the cover photo inside the app's image directory.
  final String? coverImageFileName;

  /// Firebase Storage path of that cover, once uploaded — the same reason
  /// `RecipeEntity.imageStoragePath` exists: the file name alone is meaningless
  /// on any device but the one that picked the photo.
  final String? coverImageStoragePath;
  final DateTime createdAt;

  const RecipeBookEntity({
    required this.id,
    required this.title,
    required this.recipeRefs,
    required this.createdAt,
    this.collaborators = const {},
    this.coverImageFileName,
    this.coverImageStoragePath,
  });

  List<BookRecipeRefEntity> get orderedRefs => [...recipeRefs]..sort((a, b) => a.order.compareTo(b.order));

  RecipeBookEntity copyWith({
    String? title,
    List<BookRecipeRefEntity>? recipeRefs,
    Map<String, AccessRole>? collaborators,
    String? coverImageFileName,
    // A null `coverImageFileName` means "unchanged", so clearing needs a flag.
    bool removeCoverImage = false,
    String? coverImageStoragePath,
  }) {
    return RecipeBookEntity(
      id: id,
      title: title ?? this.title,
      recipeRefs: recipeRefs ?? this.recipeRefs,
      collaborators: collaborators ?? this.collaborators,
      coverImageFileName:
          removeCoverImage ? null : (coverImageFileName ?? this.coverImageFileName),
      // A replaced cover invalidates the uploaded one, as with a recipe photo.
      coverImageStoragePath: removeCoverImage
          ? null
          : (coverImageStoragePath ??
              (coverImageFileName != null ? null : this.coverImageStoragePath)),
      createdAt: createdAt,
    );
  }
}
