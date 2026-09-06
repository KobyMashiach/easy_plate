import '../repositories/forum_repository.dart';

class AddForumReplyUseCase {
  final ForumRepository repository;
  AddForumReplyUseCase(this.repository);

  Future<void> call({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) =>
      repository.addReply(
        postId: postId,
        body: body,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        sharedRecipeId: sharedRecipeId,
        sharedRecipeTitle: sharedRecipeTitle,
      );
}
