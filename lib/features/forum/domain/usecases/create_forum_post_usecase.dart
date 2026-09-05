import '../repositories/forum_repository.dart';

class CreateForumPostUseCase {
  final ForumRepository repository;
  CreateForumPostUseCase(this.repository);

  Future<void> call({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) =>
      repository.createPost(
        title: title,
        body: body,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );
}
