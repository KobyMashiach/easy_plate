import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/usecases/add_forum_reply_usecase.dart';
import '../../domain/usecases/get_forum_replies_usecase.dart';

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
}

@freezed
sealed class ForumThreadState with _$ForumThreadState {
  const factory ForumThreadState.loading() = ForumThreadLoading;
  const factory ForumThreadState.loaded(
    List<ForumReplyEntity> replies, {
    @Default(false) bool sending,
  }) = ForumThreadLoaded;
  const factory ForumThreadState.errorMessage(String error) = ForumThreadError;
}

class ForumThreadBloc extends Bloc<ForumThreadEvent, ForumThreadState> {
  final String postId;
  final GetForumRepliesUseCase getForumRepliesUseCase;
  final AddForumReplyUseCase addForumReplyUseCase;

  ForumThreadBloc({
    required this.postId,
    required this.getForumRepliesUseCase,
    required this.addForumReplyUseCase,
  }) : super(const ForumThreadState.loading()) {
    on<_Init>(_init);
    on<_Refresh>(_refresh);
    on<_AddReply>(_addReply);
    add(const ForumThreadEvent.init());
  }

  factory ForumThreadBloc.fromContext(BuildContext context, String postId) {
    return ForumThreadBloc(
      postId: postId,
      getForumRepliesUseCase: GetForumRepliesUseCase(context.read()),
      addForumReplyUseCase: AddForumReplyUseCase(context.read()),
    );
  }

  Future<void> _init(_Init event, Emitter<ForumThreadState> emit) async {
    try {
      emit(.loaded(await getForumRepliesUseCase(postId)));
    } catch (e) {
      debugPrint('Thread error: $e');
      emit(.errorMessage(e.toString()));
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
    if (current is ForumThreadLoaded) emit(.loaded(current.replies, sending: true));

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
        emit(.loaded(current.replies));
      } else {
        emit(.errorMessage(e.toString()));
      }
    }
  }
}
