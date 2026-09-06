import 'dart:async';

import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/forum/domain/usecases/create_forum_post_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/delete_forum_post_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/get_forum_posts_usecase.dart';
import 'package:easy_plate/features/forum/presentation/bloc/forum_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForumRepository implements ForumRepository {
  List<ForumPostEntity> posts = [];
  bool throwsOnRead = false;
  int reads = 0;

  @override
  Future<List<ForumPostEntity>> getPosts({int limit = 50}) async {
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
  Future<List<ForumReplyEntity>> getReplies(String postId) async => const [];

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
  Future<void> deletePost(String postId) async =>
      posts = posts.where((p) => p.id != postId).toList();
}

ForumPostEntity buildPost({String id = 'p1'}) => ForumPostEntity(
      id: id,
      title: 'איך מכינים קובה?',
      body: 'מחפש מתכון',
      authorUid: 'someone',
      authorName: 'דנה',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeForumRepository repository;

  ForumBloc buildBloc() => ForumBloc(
        getForumPostsUseCase: GetForumPostsUseCase(repository),
        createForumPostUseCase: CreateForumPostUseCase(repository),
        deleteForumPostUseCase: DeleteForumPostUseCase(repository),
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
}
