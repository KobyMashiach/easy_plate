import '../repositories/forum_repository.dart';

class DeleteForumPostUseCase {
  final ForumRepository repository;
  DeleteForumPostUseCase(this.repository);

  Future<void> call(String postId) => repository.deletePost(postId);
}
