import '../entities/forum_post_entity.dart';
import '../repositories/forum_repository.dart';

class GetForumPostsUseCase {
  final ForumRepository repository;
  GetForumPostsUseCase(this.repository);

  Future<List<ForumPostEntity>> call({int limit = 50}) => repository.getPosts(limit: limit);
}
