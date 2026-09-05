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
  }) =>
      repository.addReply(
        postId: postId,
        body: body,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );
}
