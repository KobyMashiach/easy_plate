import '../entities/forum_reply_entity.dart';
import '../repositories/forum_repository.dart';

class GetForumRepliesUseCase {
  final ForumRepository repository;
  GetForumRepliesUseCase(this.repository);

  Future<List<ForumReplyEntity>> call(String postId) => repository.getReplies(postId);
}
