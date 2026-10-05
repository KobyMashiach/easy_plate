import '../entities/forum_post_entity.dart';
import '../repositories/forum_repository.dart';

class WatchForumPostsUseCase {
  final ForumRepository repository;
  WatchForumPostsUseCase(this.repository);

  Stream<List<ForumPostEntity>> call({required String viewerUid}) =>
      repository.watchPosts(viewerUid: viewerUid);
}
