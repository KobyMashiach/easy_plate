import '../entities/forum_reply_entity.dart';
import '../repositories/forum_repository.dart';

class WatchForumRepliesUseCase {
  final ForumRepository repository;
  WatchForumRepliesUseCase(this.repository);

  Stream<List<ForumReplyEntity>> call(
    String postId, {
    required String viewerUid,
  }) => repository.watchReplies(postId, viewerUid: viewerUid);
}
