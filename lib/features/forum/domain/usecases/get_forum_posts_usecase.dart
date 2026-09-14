import '../entities/forum_post_entity.dart';
import '../repositories/forum_repository.dart';

class GetForumPostsUseCase {
  final ForumRepository repository;
  GetForumPostsUseCase(this.repository);

  Future<List<ForumPostEntity>> call({required String viewerUid, int limit = 50}) =>
      repository.getPosts(viewerUid: viewerUid, limit: limit);
}
