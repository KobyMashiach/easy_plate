import 'dart:async';

import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/forum/domain/usecases/create_forum_post_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/delete_forum_post_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/get_forum_posts_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/toggle_forum_post_like_usecase.dart';
import 'package:easy_plate/features/forum/presentation/bloc/forum_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForumRepository implements ForumRepository {
  List<ForumPostEntity> posts = [];
  bool throwsOnRead = false;
  bool throwsOnLike = false;
  int reads = 0;
  final likedPostIds = <String>[];

  @override
  Future<List<ForumPostEntity>> getPosts({required String viewerUid, int limit = 50}) async {
    reads++;
    if (throwsOnRead) throw Exception('offline');
    return posts;
  }

  @override
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async {}

  @override
  Future<List<ForumReplyEntity>> getReplies(String postId, {required String viewerUid}) async =>
      const [];

  @override
  Future<void> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) async {}

  @override
  Future<bool> togglePostLike(String postId, {required String viewerUid}) async {
    if (throwsOnLike) throw Exception('offline');
    likedPostIds.add(postId);
    return true;
  }

  @override
  Future<bool> toggleReplyLike(String postId, String replyId, {required String viewerUid}) =>
      throw UnimplementedError();

  @override
  Future<void> deletePost(String postId) async =>
      posts = posts.where((p) => p.id != postId).toList();
}

ForumPostEntity buildPost({String id = 'p1', int likeCount = 0, bool likedByMe = false}) =>
    ForumPostEntity(
      id: id,
      title: 'איך מכינים קובה?',
      body: 'מחפש מתכון',
      authorUid: 'someone',
      authorName: 'דנה',
      createdAt: DateTime(2026, 1, 1),
      likeCount: likeCount,
      likedByMe: likedByMe,
    );

void main() {
  late _FakeForumRepository repository;

  ForumBloc buildBloc() => ForumBloc(
        getForumPostsUseCase: GetForumPostsUseCase(repository),
        createForumPostUseCase: CreateForumPostUseCase(repository),
        deleteForumPostUseCase: DeleteForumPostUseCase(repository),
        togglePostLikeUseCase: ToggleForumPostLikeUseCase(repository),
      );

  setUp(() => repository = _FakeForumRepository());

  test('loads posts on construction', () async {
    repository.posts = [buildPost()];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    expect((bloc.state as ForumLoaded).posts, hasLength(1));
  });

  group('pull to refresh', () {
    test('re-reads the posts and completes the indicator\'s future', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);
      final readsBefore = repository.reads;

      repository.posts = [buildPost(id: 'p1'), buildPost(id: 'p2')];
      final done = Completer<void>();
      bloc.add(ForumEvent.refresh(done));
      await done.future;

      expect(repository.reads, readsBefore + 1);
      expect((bloc.state as ForumLoaded).posts, hasLength(2));
    });

    test('completes even when nothing changed', () async {
      // Bloc skips emitting a state equal to the current one, so a future built
      // from the state stream would hang and leave the spinner turning.
      repository.posts = [buildPost()];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      final done = Completer<void>();
      bloc.add(ForumEvent.refresh(done));

      await done.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('refresh future never completed'),
      );
    });

    test('completes even when the reload fails', () async {
      repository.posts = [buildPost()];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      repository.throwsOnRead = true;
      final done = Completer<void>();
      bloc.add(ForumEvent.refresh(done));

      await done.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('refresh future never completed'),
      );
      expect(bloc.state, isA<ForumError>());
    });
  });

  group('likes', () {
    test('a tap flips the heart and the count before the write lands', () async {
      repository.posts = [buildPost(likeCount: 2)];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ForumEvent.toggleLike('p1'));
      // Bloc handlers start on the next microtask; the flip is the very first
      // thing the handler does, before it awaits the repository.
      await Future<void>.delayed(Duration.zero);

      final post = (bloc.state as ForumLoaded).posts.single;
      expect(post.likedByMe, isTrue);
      expect(post.likeCount, 3);
      expect(repository.likedPostIds, ['p1']);
    });

    test('a second tap takes the like back', () async {
      repository.posts = [buildPost(likeCount: 3, likedByMe: true)];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ForumEvent.toggleLike('p1'));
      await Future<void>.delayed(Duration.zero);

      final post = (bloc.state as ForumLoaded).posts.single;
      expect(post.likedByMe, isFalse);
      expect(post.likeCount, 2);
    });

    test('a failed write puts the row back as it was', () async {
      repository.posts = [buildPost(likeCount: 2)];
      repository.throwsOnLike = true;
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ForumEvent.toggleLike('p1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final post = (bloc.state as ForumLoaded).posts.single;
      expect(post.likedByMe, isFalse);
      expect(post.likeCount, 2);
    });
  });
}
