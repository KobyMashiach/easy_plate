import '../repositories/forum_repository.dart';

class ToggleForumReplyLikeUseCase {
  final ForumRepository repository;
  ToggleForumReplyLikeUseCase(this.repository);

  Future<bool> call(String postId, String replyId, {required String viewerUid}) =>
      repository.toggleReplyLike(postId, replyId, viewerUid: viewerUid);
}
