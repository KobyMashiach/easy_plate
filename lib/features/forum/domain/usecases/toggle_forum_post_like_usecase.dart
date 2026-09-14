import '../repositories/forum_repository.dart';

class ToggleForumPostLikeUseCase {
  final ForumRepository repository;
  ToggleForumPostLikeUseCase(this.repository);

  Future<bool> call(String postId, {required String viewerUid}) =>
      repository.togglePostLike(postId, viewerUid: viewerUid);
}
