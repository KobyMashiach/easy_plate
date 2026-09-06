class ForumReplyEntity {
  final String id;
  final String body;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;

  /// Optional pointer to a recipe in the community feed. The title is stored
  /// alongside the id so the chip renders without a second read — and still
  /// reads sensibly if the recipe has since been unshared.
  final String? sharedRecipeId;
  final String? sharedRecipeTitle;

  const ForumReplyEntity({
    required this.id,
    required this.body,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.authorPhotoUrl,
    this.sharedRecipeId,
    this.sharedRecipeTitle,
  });

  bool get hasRecipe => sharedRecipeId != null;

  /// Replaces the display fields with the author's live profile. Kept as a
  /// dedicated method rather than a general copyWith: the author's *identity*
  /// (`authorUid`) is never rewritten, only how it is shown.
  ForumReplyEntity withAuthor({required String name, String? photoUrl}) {
    return ForumReplyEntity(
      id: id,
      body: body,
      authorUid: authorUid,
      authorName: name,
      authorPhotoUrl: photoUrl,
      createdAt: createdAt,
      sharedRecipeId: sharedRecipeId,
      sharedRecipeTitle: sharedRecipeTitle,
    );
  }
}
