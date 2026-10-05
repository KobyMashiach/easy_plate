import 'dart:async';

import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/forum/domain/usecases/add_forum_reply_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/get_forum_replies_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/toggle_forum_post_like_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/toggle_forum_reply_like_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/watch_forum_replies_usecase.dart';
import 'package:easy_plate/features/forum/presentation/bloc/forum_thread_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForumRepository implements ForumRepository {
  List<ForumReplyEntity> replies = [];
  bool throwsOnLike = false;
  bool throwsOnReply = false;

  /// Null completes the reply write at once; set, the write waits on it.
  Completer<void>? replyGate;

  /// Same, for a like.
  Completer<void>? likeGate;
  final likedPosts = <String>[];
  final likedReplies = <(String, String)>[];
  final added = <String>[];

  /// The live replies, pushed by the tests as Firestore would.
  final live = StreamController<List<ForumReplyEntity>>.broadcast();

  @override
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
  }) async => replies;

  @override
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  }) => live.stream;

  @override
  Future<String> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) async {
    if (throwsOnReply) throw Exception('rules');
    if (replyGate case final gate?) await gate.future;
    added.add(body);
    return 'r-new';
  }

  @override
  Future<bool> togglePostLike(
    String postId, {
    required String viewerUid,
  }) async {
    if (throwsOnLike) throw Exception('offline');
    likedPosts.add(postId);
    return true;
  }

  @override
  Future<bool> toggleReplyLike(
    String postId,
    String replyId, {
    required String viewerUid,
  }) async {
    if (throwsOnLike) throw Exception('offline');
    if (likeGate case final gate?) await gate.future;
    likedReplies.add((postId, replyId));
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final post = ForumPostEntity(
  id: 'p1',
  title: 'איך מכינים קובה?',
  body: 'מחפש מתכון',
  authorUid: 'someone',
  authorName: 'דנה',
  createdAt: DateTime(2026, 1, 1),
  likeCount: 1,
);

ForumReplyEntity buildReply(
  String id, {
  int likeCount = 0,
  bool likedByMe = false,
  bool pending = false,
  String body = 'ככה',
}) => ForumReplyEntity(
  id: id,
  body: body,
  authorUid: 'other',
  authorName: 'יוסי',
  createdAt: DateTime(2026, 1, 2),
  likeCount: likeCount,
  likedByMe: likedByMe,
  pending: pending,
);

void main() {
  late _FakeForumRepository repository;

  ForumThreadBloc buildBloc() => ForumThreadBloc(
    post: post,
    getForumRepliesUseCase: GetForumRepliesUseCase(repository),
    watchForumRepliesUseCase: WatchForumRepliesUseCase(repository),
    addForumReplyUseCase: AddForumReplyUseCase(repository),
    togglePostLikeUseCase: ToggleForumPostLikeUseCase(repository),
    toggleReplyLikeUseCase: ToggleForumReplyLikeUseCase(repository),
  );

  setUp(() => repository = _FakeForumRepository());
  tearDown(() => repository.live.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  group('live replies', () {
    test('a reply from someone else appears without a reload', () async {
      repository.replies = [buildReply('r1')];
      final bloc = buildBloc();
      await settle();

      repository.live.add([buildReply('r1'), buildReply('r2')]);
      await settle();

      expect(
        (bloc.state as ForumThreadLoaded).replies.map((r) => r.id),
        ['r1', 'r2'],
      );
      await bloc.close();
    });

    test('the composer is busy only until the server has the reply; the '
        'reply itself comes through the stream at once', () async {
      repository.replies = [buildReply('r1')];
      repository.replyGate = Completer<void>();
      final bloc = buildBloc();
      await settle();

      bloc.add(const ForumThreadEvent.addReply('שלום'));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as ForumThreadLoaded).sending, isTrue);

      // The SDK reports the local write before the server acknowledges it.
      repository.live.add([
        buildReply('r1'),
        buildReply('r-new', body: 'שלום', pending: true),
      ]);
      await settle();
      var state = bloc.state as ForumThreadLoaded;
      expect(state.replies.last.pending, isTrue);
      expect(state.sending, isTrue);

      repository.replyGate!.complete();
      await settle();
      state = bloc.state as ForumThreadLoaded;
      expect(state.sending, isFalse);
      expect(state.replies, hasLength(2));
      expect(repository.added, ['שלום']);
      await bloc.close();
    });

    test(
      'a refused reply reports the error and unlocks the composer',
      () async {
        repository.replies = [buildReply('r1')];
        repository.throwsOnReply = true;
        final bloc = buildBloc();
        await settle();

        bloc.add(const ForumThreadEvent.addReply('שלום'));
        await settle();

        final state = bloc.state as ForumThreadLoaded;
        expect(state.sending, isFalse);
        expect(state.sendError, isNotNull);
        expect(state.replies, hasLength(1));
        await bloc.close();
      },
    );

    test('a snapshot during a like in flight keeps the tapped heart', () async {
      repository.replies = [buildReply('r1', likeCount: 1)];
      repository.likeGate = Completer<void>();
      final bloc = buildBloc();
      await settle();

      bloc.add(const ForumThreadEvent.toggleReplyLike('r1'));
      await Future<void>.delayed(Duration.zero);
      repository.live.add([buildReply('r1', likeCount: 1)]);
      await settle();

      final reply = (bloc.state as ForumThreadLoaded).replies.single;
      expect(reply.likedByMe, isTrue);
      expect(reply.likeCount, 2);
      repository.likeGate!.complete();
      await settle();
      await bloc.close();
    });

    test('closing the bloc closes the listener', () async {
      final bloc = buildBloc();
      await settle();
      expect(repository.live.hasListener, isTrue);
      await bloc.close();
      expect(repository.live.hasListener, isFalse);
    });
  });

  test(
    'the opening post travels in the state, so its like can change',
    () async {
      repository.replies = [buildReply('r1')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ForumThreadEvent.togglePostLike());
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state as ForumThreadLoaded;
      expect(state.post.likedByMe, isTrue);
      expect(state.post.likeCount, 2);
      expect(state.replies, hasLength(1));
      expect(repository.likedPosts, ['p1']);
    },
  );

  test('a like on a reply flips only that reply', () async {
    repository.replies = [buildReply('r1'), buildReply('r2', likeCount: 4)];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ForumThreadEvent.toggleReplyLike('r2'));
    await Future<void>.delayed(Duration.zero);

    final replies = (bloc.state as ForumThreadLoaded).replies;
    expect(replies[0].likedByMe, isFalse);
    expect(replies[1].likedByMe, isTrue);
    expect(replies[1].likeCount, 5);
    expect(repository.likedReplies, [('p1', 'r2')]);
  });

  test('a reload keeps a like given on the post in the meantime', () async {
    repository.replies = [buildReply('r1')];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ForumThreadEvent.togglePostLike());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const ForumThreadEvent.init());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect((bloc.state as ForumThreadLoaded).post.likedByMe, isTrue);
  });

  test('a failed reply like is put back', () async {
    repository.replies = [buildReply('r1', likeCount: 2, likedByMe: true)];
    repository.throwsOnLike = true;
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ForumThreadEvent.toggleReplyLike('r1'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final reply = (bloc.state as ForumThreadLoaded).replies.single;
    expect(reply.likedByMe, isTrue);
    expect(reply.likeCount, 2);
  });
}
