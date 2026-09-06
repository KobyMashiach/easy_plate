import '../../../my_recipes/domain/entities/recipe_entity.dart';

/// A recipe someone published to the community feed.
///
/// Carries a *copy* of the recipe rather than a reference: the author editing
/// or deleting their own copy must not change or break what everyone else
/// already sees in the feed.
class SharedRecipeEntity {
  final String id;
  final RecipeEntity recipe;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final int likeCount;

  /// Whether the signed-in user has liked this one. Resolved per viewer, so it
  /// is not part of the stored document.
  final bool likedByMe;

  const SharedRecipeEntity({
    required this.id,
    required this.recipe,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.authorPhotoUrl,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  SharedRecipeEntity copyWith({
    int? likeCount,
    bool? likedByMe,
    RecipeEntity? recipe,
    String? authorName,
    String? authorPhotoUrl,
  }) {
    return SharedRecipeEntity(
      id: id,
      recipe: recipe ?? this.recipe,
      authorUid: authorUid,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}
