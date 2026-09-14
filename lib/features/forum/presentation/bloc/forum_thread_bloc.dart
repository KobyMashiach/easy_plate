import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/usecases/add_forum_reply_usecase.dart';
import '../../domain/usecases/get_forum_replies_usecase.dart';
import '../../domain/usecases/toggle_forum_post_like_usecase.dart';
import '../../domain/usecases/toggle_forum_reply_like_usecase.dart';

part 'forum_thread_bloc.freezed.dart';

@freezed
sealed class ForumThreadEvent with _$ForumThreadEvent {
  const factory ForumThreadEvent.init() = _Init;

  /// Carries a completer so the pull-to-refresh spinner is told exactly when the
  /// reload finished. Waiting on the state stream instead would hang whenever
  /// the reloaded data is identical, because bloc skips emitting a state equal
  /// to the current one.
  const factory ForumThreadEvent.refresh(Completer<void> done) = _Refresh;
  const factory ForumThreadEvent.addReply(
    String body, {
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) = _AddReply;

  /// A like on the thread's opening post.
  const factory ForumThreadEvent.togglePostLike() = _TogglePostLike;
  const factory ForumThreadEvent.toggleReplyLike(String replyId) = _ToggleReplyLike;
}

@freezed
sealed class ForumThreadState with _$ForumThreadState {
  const factory ForumThreadState.loading(ForumPostEntity post) = ForumThreadLoading;

  /// [post] travels in the state rather than staying on the page: its like
  /// count is the one part of it that changes while the thread is open.
  const factory ForumThreadState.loaded(
    ForumPostEntity post,
    List<ForumReplyEntity> replies, {
    @Default(false) bool sending,
  }) = ForumThreadLoaded;
  const factory ForumThreadState.errorMessage(ForumPostEntity post, String error) =
      ForumThreadError;
}

class ForumThreadBloc extends Bloc<ForumThreadEvent, ForumThreadState> {
  final GetForumRepliesUseCase getForumRepliesUseCase;
  final AddForumReplyUseCase addForumReplyUseCase;
  final ToggleForumPostLikeUseCase togglePostLikeUseCase;
  final ToggleForumReplyLikeUseCase toggleReplyLikeUseCase;

  /// The opening post as the list handed it over, then as liked here. Kept
  /// outside the state so a reload never resets a like made in between.
  ForumPostEntity _post;

  String get postId => _post.id;

  ForumThreadBloc({
    required ForumPostEntity post,
    required this.getForumRepliesUseCase,
    required this.addForumReplyUseCase,
    required this.togglePostLikeUseCase,
    required this.toggleReplyLikeUseCase,
  })  : _post = post,
        super(ForumThreadState.loading(post)) {
    on<_Init>(_init);
    on<_Refresh>(_refresh);
    on<_AddReply>(_addReply);
    on<_TogglePostLike>(_togglePostLike);
    on<_ToggleReplyLike>(_toggleReplyLike);
    add(const ForumThreadEvent.init());
  }

  factory ForumThreadBloc.fromContext(BuildContext context, ForumPostEntity post) {
    return ForumThreadBloc(
      post: post,
      getForumRepliesUseCase: GetForumRepliesUseCase(context.read()),
      addForumReplyUseCase: AddForumReplyUseCase(context.read()),
      togglePostLikeUseCase: ToggleForumPostLikeUseCase(context.read()),
      toggleReplyLikeUseCase: ToggleForumReplyLikeUseCase(context.read()),
    );
  }

  String get _uid => AuthSessionService().user?.uid ?? '';

  Future<void> _init(_Init event, Emitter<ForumThreadState> emit) async {
    try {
      emit(.loaded(_post, await getForumRepliesUseCase(postId, viewerUid: _uid)));
    } catch (e) {
      debugPrint('Thread error: $e');
      emit(.errorMessage(_post, e.toString()));
    }
  }

  Future<void> _refresh(_Refresh event, Emitter<ForumThreadState> emit) async {
    try {
      await _init(const _Init(), emit);
    } finally {
      if (!event.done.isCompleted) event.done.complete();
    }
  }

  Future<void> _addReply(_AddReply event, Emitter<ForumThreadState> emit) async {
    final current = state;
    if (current is ForumThreadLoaded) emit(.loaded(_post, current.replies, sending: true));

    final session = AuthSessionService();
    try {
      await addForumReplyUseCase(
        postId: postId,
        body: event.body,
        authorUid: session.user?.uid ?? '',
        authorName: session.profile?.fullName ?? '',
        authorPhotoUrl: session.profile?.photoUrl,
        sharedRecipeId: event.sharedRecipeId,
        sharedRecipeTitle: event.sharedRecipeTitle,
      );
      await _init(const _Init(), emit);
    } catch (e) {
      debugPrint('Reply error: $e');
      if (current is ForumThreadLoaded) {
        emit(.loaded(_post, current.replies));
      } else {
        emit(.errorMessage(_post, e.toString()));
      }
    }
  }

  /// Optimistic, like everywhere else a heart is tapped: flipped at once, put
  /// back if the write fails.
  Future<void> _togglePostLike(_TogglePostLike event, Emitter<ForumThreadState> emit) async {
    final current = state;
    if (current is! ForumThreadLoaded) return;

    final original = _post;
    _post = original.withLikeToggled();
    emit(.loaded(_post, current.replies, sending: current.sending));

    try {
      await togglePostLikeUseCase(postId, viewerUid: _uid);
    } catch (e) {
      debugPrint('Post like failed: $e');
      _post = original;
      final latest = state;
      if (latest is ForumThreadLoaded) {
        emit(.loaded(_post, latest.replies, sending: latest.sending));
      }
    }
  }

  Future<void> _toggleReplyLike(_ToggleReplyLike event, Emitter<ForumThreadState> emit) async {
    final current = state;
    if (current is! ForumThreadLoaded) return;
    final index = current.replies.indexWhere((r) => r.id == event.replyId);
    if (index == -1) return;

    final original = current.replies[index];
    emit(.loaded(
      _post,
      [...current.replies]..[index] = original.withLikeToggled(),
      sending: current.sending,
    ));

    try {
      await toggleReplyLikeUseCase(postId, event.replyId, viewerUid: _uid);
    } catch (e) {
      debugPrint('Reply like failed: $e');
      final latest = state;
      if (latest is! ForumThreadLoaded) return;
      final at = latest.replies.indexWhere((r) => r.id == event.replyId);
      if (at != -1) {
        emit(.loaded(_post, [...latest.replies]..[at] = original, sending: latest.sending));
      }
    }
  }
}
