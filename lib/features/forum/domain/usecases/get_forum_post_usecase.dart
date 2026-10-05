import '../entities/forum_post_entity.dart';
import '../repositories/forum_repository.dart';

class GetForumPostUseCase {
  final ForumRepository repository;
  GetForumPostUseCase(this.repository);

  Future<ForumPostEntity?> call(String postId, {required String viewerUid}) =>
      repository.getPost(postId, viewerUid: viewerUid);
}
