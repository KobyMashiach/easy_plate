import '../../../../core/constants/app_enums.dart';
import 'book_recipe_ref_entity.dart';
import 'book_spine.dart';

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

  /// The spine colour the owner picked; null until they do.
  final BookSpine? spine;

  /// The shared document this book is a cache of, when it is shared between
  /// accounts, and what this account may do with it. Same pair as on a recipe.
  final String? collabId;
  final CollabRole? collabRole;
  final DateTime createdAt;

  const RecipeBookEntity({
    required this.id,
    required this.title,
    required this.recipeRefs,
    required this.createdAt,
    this.collaborators = const {},
    this.coverImageFileName,
    this.coverImageStoragePath,
    this.spine,
    this.collabId,
    this.collabRole,
  });

  bool get isShared => collabId != null;
  bool get canEdit => collabRole != CollabRole.viewer;

  /// Only the owner may share a book on; a member cannot hand it further.
  bool get isMine => collabRole == null || collabRole == CollabRole.owner;

  List<BookRecipeRefEntity> get orderedRefs => [...recipeRefs]..sort((a, b) => a.order.compareTo(b.order));

  RecipeBookEntity copyWith({
    String? title,
    List<BookRecipeRefEntity>? recipeRefs,
    Map<String, AccessRole>? collaborators,
    String? coverImageFileName,
    // A null `coverImageFileName` means "unchanged", so clearing needs a flag.
    bool removeCoverImage = false,
    String? coverImageStoragePath,
    BookSpine? spine,
    String? collabId,
    CollabRole? collabRole,
    // Both are null for "unchanged", so dropping the share needs a flag.
    bool clearCollab = false,
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
      spine: spine ?? this.spine,
      collabId: clearCollab ? null : (collabId ?? this.collabId),
      collabRole: clearCollab ? null : (collabRole ?? this.collabRole),
      createdAt: createdAt,
    );
  }
}
