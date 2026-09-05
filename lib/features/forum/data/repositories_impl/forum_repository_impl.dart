import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ForumRemoteDataSource remoteDataSource;

  ForumRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ForumPostEntity>> getPosts({int limit = 50}) =>
      remoteDataSource.getPosts(limit: limit);

  @override
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) =>
      remoteDataSource.createPost(
        title: title,
        body: body,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );

  @override
  Future<List<ForumReplyEntity>> getReplies(String postId) =>
      remoteDataSource.getReplies(postId);

  @override
  Future<void> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) =>
      remoteDataSource.addReply(
        postId: postId,
        body: body,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );

  @override
  Future<void> deletePost(String postId) => remoteDataSource.deletePost(postId);
}
