import '../../../user_profile/domain/entities/public_profile_entity.dart';
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

  /// How long a fetched profile is trusted before the next live emission
  /// re-reads it. A one-shot read (pull to refresh) always re-reads.
  static const profileTtl = Duration(minutes: 5);

  /// Profiles already resolved, with when. The live streams re-emit on every
  /// change in the window; re-reading every author's profile each time would
  /// turn one reply into a fan-out of profile reads on every open device.
  final _profiles = <String, _CachedProfile>{};

  ForumRepositoryImpl({
    required this.remoteDataSource,
    required this.userProfileRepository,
  });

  Future<Map<String, PublicProfileEntity>> _profilesFor(
    Iterable<String> uids, {
    required bool refresh,
  }) async {
    final now = DateTime.now();
    final wanted = uids.toSet();
    final stale = {
      for (final uid in wanted)
        if (refresh ||
            _profiles[uid] == null ||
            now.difference(_profiles[uid]!.fetchedAt) > profileTtl)
          uid,
    };
    if (stale.isNotEmpty) {
      final fetched = await userProfileRepository.getPublicProfiles(stale);
      for (final uid in stale) {
        // An account without a public profile is remembered as such, so it
        // is not looked up again on every emission.
        _profiles[uid] = _CachedProfile(fetched[uid], now);
      }
    }
    return {for (final uid in wanted) uid: ?_profiles[uid]?.profile};
  }

  Future<List<ForumPostEntity>> _withAuthors(
    List<ForumPostEntity> posts, {
    required bool refresh,
  }) async {
    if (posts.isEmpty) return posts;
    final profiles = await _profilesFor(
      posts.map((p) => p.authorUid),
      refresh: refresh,
    );
    return [
      for (final post in posts)
        if (profiles[post.authorUid] case final profile?)
          post.withAuthor(name: profile.fullName, photoUrl: profile.photoUrl)
        else
          post,
    ];
  }

  Future<List<ForumReplyEntity>> _repliesWithAuthors(
    List<ForumReplyEntity> replies, {
    required bool refresh,
  }) async {
    if (replies.isEmpty) return replies;
    final profiles = await _profilesFor(
      replies.map((r) => r.authorUid),
      refresh: refresh,
    );
    return [
      for (final reply in replies)
        if (profiles[reply.authorUid] case final profile?)
          reply.withAuthor(name: profile.fullName, photoUrl: profile.photoUrl)
        else
          reply,
    ];
  }

  @override
  Future<List<ForumPostEntity>> getPosts({
    required String viewerUid,
    int limit = 50,
  }) async {
    final posts = await remoteDataSource.getPosts(
      viewerUid: viewerUid,
      limit: limit,
    );
    return _withAuthors(posts, refresh: true);
  }

  @override
  Stream<List<ForumPostEntity>> watchPosts({
    required String viewerUid,
    int limit = 50,
  }) {
    return remoteDataSource
        .watchPosts(viewerUid: viewerUid, limit: limit)
        .asyncMap((posts) => _withAuthors(posts, refresh: false));
  }

  @override
  Future<ForumPostEntity?> getPost(
    String postId, {
    required String viewerUid,
  }) async {
    final post = await remoteDataSource.getPost(postId, viewerUid: viewerUid);
    if (post == null) return null;
    return (await _withAuthors([post], refresh: true)).first;
  }

  @override
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) => remoteDataSource.createPost(
    title: title,
    body: body,
    authorUid: authorUid,
    authorName: authorName,
    authorPhotoUrl: authorPhotoUrl,
  );

  @override
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
  }) async {
    final replies = await remoteDataSource.getReplies(
      postId,
      viewerUid: viewerUid,
    );
    return _repliesWithAuthors(replies, refresh: true);
  }

  @override
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  }) {
    return remoteDataSource
        .watchReplies(postId, viewerUid: viewerUid)
        .asyncMap((replies) => _repliesWithAuthors(replies, refresh: false));
  }

  @override
  Future<String> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) => remoteDataSource.addReply(
    postId: postId,
    body: body,
    authorUid: authorUid,
    authorName: authorName,
    authorPhotoUrl: authorPhotoUrl,
    sharedRecipeId: sharedRecipeId,
    sharedRecipeTitle: sharedRecipeTitle,
  );

  @override
  Future<bool> togglePostLike(String postId, {required String viewerUid}) =>
      remoteDataSource.togglePostLike(postId, viewerUid: viewerUid);

  @override
  Future<bool> toggleReplyLike(
    String postId,
    String replyId, {
    required String viewerUid,
  }) => remoteDataSource.toggleReplyLike(postId, replyId, viewerUid: viewerUid);

  @override
  Future<void> deletePost(String postId) => remoteDataSource.deletePost(postId);
}

class _CachedProfile {
  final PublicProfileEntity? profile;
  final DateTime fetchedAt;
  const _CachedProfile(this.profile, this.fetchedAt);
}
