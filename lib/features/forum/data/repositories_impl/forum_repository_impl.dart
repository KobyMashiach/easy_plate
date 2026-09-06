import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ForumRemoteDataSource remoteDataSource;

  /// Author display info is read live from the public profiles rather than
  /// taken from the copy stored on each post, so renaming an account updates
  /// everything it ever wrote.
  final UserProfileRepository userProfileRepository;

  ForumRepositoryImpl({
    required this.remoteDataSource,
    required this.userProfileRepository,
  });

  @override
  Future<List<ForumPostEntity>> getPosts({int limit = 50}) async {
    final posts = await remoteDataSource.getPosts(limit: limit);
    if (posts.isEmpty) return posts;

    final profiles = await userProfileRepository
        .getPublicProfiles(posts.map((p) => p.authorUid).toSet());

    return [
      for (final post in posts)
        if (profiles[post.authorUid] case final profile?)
          post.withAuthor(name: profile.fullName, photoUrl: profile.photoUrl)
        else
          post,
    ];
  }

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
  Future<List<ForumReplyEntity>> getReplies(String postId) async {
    final replies = await remoteDataSource.getReplies(postId);
    if (replies.isEmpty) return replies;

    final profiles = await userProfileRepository
        .getPublicProfiles(replies.map((r) => r.authorUid).toSet());

    return [
      for (final reply in replies)
        if (profiles[reply.authorUid] case final profile?)
          reply.withAuthor(name: profile.fullName, photoUrl: profile.photoUrl)
        else
          reply,
    ];
  }

  @override
  Future<void> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) =>
      remoteDataSource.addReply(
        postId: postId,
        body: body,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        sharedRecipeId: sharedRecipeId,
        sharedRecipeTitle: sharedRecipeTitle,
      );

  @override
  Future<void> deletePost(String postId) => remoteDataSource.deletePost(postId);
}
