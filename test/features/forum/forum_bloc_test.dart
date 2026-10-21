import 'dart:async';

import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/forum/domain/usecases/create_forum_post_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/delete_forum_post_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/get_forum_posts_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/toggle_forum_post_like_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/watch_forum_posts_usecase.dart';
import 'package:easy_plate/features/forum/presentation/bloc/forum_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForumRepository implements ForumRepository {
  List<ForumPostEntity> posts = [];
  bool throwsOnRead = false;
  bool throwsOnLike = false;
  bool throwsOnCreate = false;

  /// Set, a like write waits on it — to test a snapshot landing mid-flight.
  Completer<void>? likeGate;
  int reads = 0;
  final refreshes = <bool>[];
  final likedPostIds = <String>[];

  /// The live window, pushed by the tests as Firestore would.
  final live = StreamController<List<ForumPostEntity>>.broadcast();
  int watches = 0;

  @override
  Future<List<ForumPostEntity>> getPosts({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) async {
    reads++;
    refreshes.add(refresh);
    if (throwsOnRead) throw Exception('offline');
    return posts;
  }

  @override
  Stream<List<ForumPostEntity>> watchPosts({
    required String viewerUid,
    int limit = 50,
  }) {
    watches++;
    return live.stream;
  }

  @override
  Future<ForumPostEntity?> getPost(
    String postId, {
    required String viewerUid,
  }) async => posts.where((p) => p.id == postId).firstOrNull;

  @override
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  }) => const Stream.empty();

  @override
  Future<ForumReplyEntity?> getReply(
    String postId,
    String replyId, {
    required String viewerUid,
  }) async => null;

  @override
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async {
    if (throwsOnCreate) throw Exception('offline');
  }

  @override
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
    bool refresh = false,
  }) async => const [];

  @override
  Future<String> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) async => 'r-new';

  @override
  Future<bool> togglePostLike(
    String postId, {
    required String viewerUid,
  }) async {
    if (likeGate case final gate?) await gate.future;
    if (throwsOnLike) throw Exception('offline');
    likedPostIds.add(postId);
    return true;
  }

  @override
  Future<bool> toggleReplyLike(
    String postId,
    String replyId, {
    required String viewerUid,
  }) => throw UnimplementedError();

  @override
  Future<void> deletePost(String postId) async =>
      posts = posts.where((p) => p.id != postId).toList();
}

ForumPostEntity buildPost({
  String id = 'p1',
  int likeCount = 0,
  int replyCount = 0,
  bool likedByMe = false,
  DateTime? createdAt,
}) => ForumPostEntity(
  id: id,
  title: 'איך מכינים קובה?',
  body: 'מחפש מתכון',
  authorUid: 'someone',
  authorName: 'דנה',
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  likeCount: likeCount,
  replyCount: replyCount,
  likedByMe: likedByMe,
);

void main() {
  late _FakeForumRepository repository;

  ForumBloc buildBloc() => ForumBloc(
    getForumPostsUseCase: GetForumPostsUseCase(repository),
    watchForumPostsUseCase: WatchForumPostsUseCase(repository),
    createForumPostUseCase: CreateForumPostUseCase(repository),
    deleteForumPostUseCase: DeleteForumPostUseCase(repository),
    togglePostLikeUseCase: ToggleForumPostLikeUseCase(repository),
  );

  setUp(() => repository = _FakeForumRepository());
  tearDown(() => repository.live.close());

  /// Lets the bloc's first read land and its listener open.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  group('live updates', () {
    test('the first read opens the listener, once', () async {
      repository.posts = [buildPost()];
      final bloc = buildBloc();
      await settle();

      expect(repository.watches, 1);
      await bloc.close();
    });

    test('a changed row is replaced in place', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();

      repository.live.add([buildPost(id: 'p1', replyCount: 3)]);
      await settle();

      final state = bloc.state as ForumLoaded;
      expect(state.posts.single.replyCount, 3);
      expect(state.incoming, isEmpty);
      await bloc.close();
    });

    test('a new thread joins the top while the reader is at the top', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();

      final newer = buildPost(id: 'p2', createdAt: DateTime(2026, 1, 2));
      repository.live.add([newer, buildPost(id: 'p1')]);
      await settle();

      final state = bloc.state as ForumLoaded;
      expect(state.posts.map((p) => p.id), ['p2', 'p1']);
      expect(state.incoming, isEmpty);
      await bloc.close();
    });

    test('a new thread waits on the pill while the reader is scrolled down, '
        'and joins on reveal', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();

      bloc.add(const ForumEvent.viewportAtTop(false));
      final newer = buildPost(id: 'p2', createdAt: DateTime(2026, 1, 2));
      repository.live.add([newer, buildPost(id: 'p1', replyCount: 1)]);
      await settle();

      var state = bloc.state as ForumLoaded;
      // The row already on screen still updates; only the new one waits.
      expect(state.posts.map((p) => p.id), ['p1']);
      expect(state.posts.single.replyCount, 1);
      expect(state.incoming.map((p) => p.id), ['p2']);

      bloc.add(const ForumEvent.revealIncoming());
      await settle();
      state = bloc.state as ForumLoaded;
      expect(state.posts.map((p) => p.id), ['p2', 'p1']);
      expect(state.incoming, isEmpty);
      await bloc.close();
    });

    test('scrolling back to the top reveals what was waiting', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();

      bloc.add(const ForumEvent.viewportAtTop(false));
      repository.live.add([
        buildPost(id: 'p2', createdAt: DateTime(2026, 1, 2)),
        buildPost(id: 'p1'),
      ]);
      await settle();
      bloc.add(const ForumEvent.viewportAtTop(true));
      await settle();

      final state = bloc.state as ForumLoaded;
      expect(state.posts.map((p) => p.id), ['p2', 'p1']);
      expect(state.incoming, isEmpty);
      await bloc.close();
    });

    test('a thread deleted elsewhere drops out', () async {
      repository.posts = [buildPost(id: 'p1'), buildPost(id: 'p2')];
      final bloc = buildBloc();
      await settle();

      repository.live.add([buildPost(id: 'p2')]);
      await settle();

      expect((bloc.state as ForumLoaded).posts.map((p) => p.id), ['p2']);
      await bloc.close();
    });

    test('an identical snapshot does not emit a new state', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();
      var emissions = 0;
      final sub = bloc.stream.listen((_) => emissions++);

      repository.live.add([buildPost(id: 'p1')]);
      await settle();

      expect(emissions, 0);
      await sub.cancel();
      await bloc.close();
    });

    test('a snapshot during a like in flight keeps the tapped heart', () async {
      repository.posts = [buildPost(id: 'p1', likeCount: 2)];
      repository.likeGate = Completer<void>();
      final bloc = buildBloc();
      await settle();

      bloc.add(const ForumEvent.toggleLike('p1'));
      await Future<void>.delayed(Duration.zero);
      // The server has not counted the like yet when this snapshot lands.
      repository.live.add([buildPost(id: 'p1', likeCount: 2)]);
      await settle();

      final post = (bloc.state as ForumLoaded).posts.single;
      expect(post.likedByMe, isTrue);
      expect(post.likeCount, 3);
      repository.likeGate!.complete();
      await settle();
      await bloc.close();
    });

    test(
      'a snapshot with the new flag but the old count shows the count moved',
      () async {
        repository.posts = [buildPost(id: 'p1', likeCount: 2)];
        repository.likeGate = Completer<void>();
        final bloc = buildBloc();
        await settle();

        bloc.add(const ForumEvent.toggleLike('p1'));
        await Future<void>.delayed(Duration.zero);
        // The datasource's flag already flipped; the counter not yet.
        repository.live.add([
          buildPost(id: 'p1', likeCount: 2, likedByMe: true),
        ]);
        await settle();

        final post = (bloc.state as ForumLoaded).posts.single;
        expect(post.likedByMe, isTrue);
        expect(post.likeCount, 3);
        repository.likeGate!.complete();
        await settle();
        await bloc.close();
      },
    );

    test('going to the background closes the listener; coming back re-reads '
        'and reopens it', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();
      final readsBefore = repository.reads;

      bloc.add(const ForumEvent.setLive(false));
      await settle();
      expect(repository.live.hasListener, isFalse);

      bloc.add(const ForumEvent.setLive(true));
      await settle();
      expect(repository.reads, readsBefore + 1);
      // A resume is not a pull: authors come from the profile cache.
      expect(repository.refreshes.last, isFalse);
      expect(repository.live.hasListener, isTrue);
      await bloc.close();
    });

    test('coming back from a failed first load re-reads and opens the '
        'listener without a pull', () async {
      repository.throwsOnRead = true;
      final bloc = buildBloc();
      await settle();
      expect(bloc.state, isA<ForumError>());
      expect(repository.live.hasListener, isFalse);

      repository.throwsOnRead = false;
      repository.posts = [buildPost(id: 'p1')];
      bloc.add(const ForumEvent.setLive(true));
      await settle();
      expect((bloc.state as ForumLoaded).posts, hasLength(1));
      expect(repository.live.hasListener, isTrue);
      await bloc.close();
    });

    test('closing the bloc closes the listener', () async {
      repository.posts = [buildPost(id: 'p1')];
      final bloc = buildBloc();
      await settle();

      await bloc.close();
      expect(repository.live.hasListener, isFalse);
    });
  });

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
      expect(repository.refreshes.last, isTrue);
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
      // The list on screen stays, flagged for the page to say so.
      final state = bloc.state as ForumLoaded;
      expect(state.posts, hasLength(1));
      expect(state.notice, ForumNotice.loadFailed);
    });
  });

  group('likes', () {
    test(
      'a tap flips the heart and the count before the write lands',
      () async {
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
      },
    );

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

    test(
      'a failed write undoes only the like, keeping what changed meanwhile',
      () async {
        repository.posts = [buildPost(likeCount: 2)];
        final gate = repository.likeGate = Completer<void>();
        final bloc = buildBloc();
        await settle();

        bloc.add(const ForumEvent.toggleLike('p1'));
        await Future<void>.delayed(Duration.zero);
        // A reply lands while the like is out.
        repository.live.add([buildPost(likeCount: 2, replyCount: 5)]);
        await settle();

        repository.throwsOnLike = true;
        gate.complete();
        await settle();

        final post = (bloc.state as ForumLoaded).posts.single;
        expect(post.replyCount, 5);
        expect(post.likedByMe, isFalse);
        expect(post.likeCount, 2);
        await bloc.close();
      },
    );

    test('two quick taps are handled one after the other', () async {
      repository.posts = [buildPost(likeCount: 2)];
      final gate = repository.likeGate = Completer<void>();
      final bloc = buildBloc();
      await settle();

      bloc.add(const ForumEvent.toggleLike('p1'));
      bloc.add(const ForumEvent.toggleLike('p1'));
      await Future<void>.delayed(Duration.zero);
      // Only the first has flipped the row; the second waits for its write.
      final midway = (bloc.state as ForumLoaded).posts.single;
      expect(midway.likedByMe, isTrue);
      expect(midway.likeCount, 3);
      expect(repository.likedPostIds, isEmpty);

      gate.complete();
      await settle();

      expect(repository.likedPostIds, ['p1', 'p1']);
      final post = (bloc.state as ForumLoaded).posts.single;
      expect(post.likedByMe, isFalse);
      expect(post.likeCount, 2);
    });
  });

  group('a write of the viewer\'s own that failed', () {
    test(
      'keeps the list and flags it, until the page says it was shown',
      () async {
        repository.posts = [buildPost()];
        repository.throwsOnCreate = true;
        final bloc = buildBloc();
        await settle();

        bloc.add(const ForumEvent.createPost('כותרת', 'תוכן'));
        await settle();

        var state = bloc.state as ForumLoaded;
        expect(state.posts, hasLength(1), reason: 'the list stays');
        expect(state.notice, ForumNotice.createFailed);

        bloc.add(const ForumEvent.dismissNotice());
        await settle();
        state = bloc.state as ForumLoaded;
        expect(state.notice, isNull);

        // The same failure again is a new state, not swallowed as a repeat.
        final emitted = <ForumState>[];
        final sub = bloc.stream.listen(emitted.add);
        bloc.add(const ForumEvent.createPost('כותרת', 'תוכן'));
        await settle();
        await sub.cancel();
        expect(
          emitted.whereType<ForumLoaded>().map((s) => s.notice),
          contains(ForumNotice.createFailed),
        );
      },
    );

    test(
      'with no list to keep, the error view carries a worded message',
      () async {
        repository.throwsOnRead = true;
        repository.throwsOnCreate = true;
        final bloc = buildBloc();
        await settle();

        bloc.add(const ForumEvent.createPost('כותרת', 'תוכן'));
        await settle();

        final state = bloc.state as ForumError;
        expect(state.error, isNot(contains('Exception')));
      },
    );
  });
}
