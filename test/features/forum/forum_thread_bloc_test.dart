import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/forum/domain/usecases/add_forum_reply_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/get_forum_replies_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/toggle_forum_post_like_usecase.dart';
import 'package:easy_plate/features/forum/domain/usecases/toggle_forum_reply_like_usecase.dart';
import 'package:easy_plate/features/forum/presentation/bloc/forum_thread_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForumRepository implements ForumRepository {
  List<ForumReplyEntity> replies = [];
  bool throwsOnLike = false;
  final likedPosts = <String>[];
  final likedReplies = <(String, String)>[];

  @override
  Future<List<ForumReplyEntity>> getReplies(String postId, {required String viewerUid}) async =>
      replies;

  @override
  Future<bool> togglePostLike(String postId, {required String viewerUid}) async {
    if (throwsOnLike) throw Exception('offline');
    likedPosts.add(postId);
    return true;
  }

  @override
  Future<bool> toggleReplyLike(String postId, String replyId, {required String viewerUid}) async {
    if (throwsOnLike) throw Exception('offline');
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

ForumReplyEntity buildReply(String id, {int likeCount = 0, bool likedByMe = false}) =>
    ForumReplyEntity(
      id: id,
      body: 'ככה',
      authorUid: 'other',
      authorName: 'יוסי',
      createdAt: DateTime(2026, 1, 2),
      likeCount: likeCount,
      likedByMe: likedByMe,
    );

void main() {
  late _FakeForumRepository repository;

  ForumThreadBloc buildBloc() => ForumThreadBloc(
        post: post,
        getForumRepliesUseCase: GetForumRepliesUseCase(repository),
        addForumReplyUseCase: AddForumReplyUseCase(repository),
        togglePostLikeUseCase: ToggleForumPostLikeUseCase(repository),
        toggleReplyLikeUseCase: ToggleForumReplyLikeUseCase(repository),
      );

  setUp(() => repository = _FakeForumRepository());

  test('the opening post travels in the state, so its like can change', () async {
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
  });

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
