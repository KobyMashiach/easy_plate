import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/usecases/create_forum_post_usecase.dart';
import '../../domain/usecases/delete_forum_post_usecase.dart';
import '../../domain/usecases/get_forum_posts_usecase.dart';
import '../../domain/usecases/toggle_forum_post_like_usecase.dart';

part 'forum_bloc.freezed.dart';

@freezed
sealed class ForumEvent with _$ForumEvent {
  const factory ForumEvent.init() = _Init;

  /// Carries a completer so the pull-to-refresh spinner is told exactly when the
  /// reload finished. Waiting on the state stream instead would hang whenever
  /// the reloaded data is identical, because bloc skips emitting a state equal
  /// to the current one.
  const factory ForumEvent.refresh(Completer<void> done) = _Refresh;
  const factory ForumEvent.createPost(String title, String body) = _CreatePost;
  const factory ForumEvent.deletePost(String postId) = _DeletePost;
  const factory ForumEvent.toggleLike(String postId) = _ToggleLike;
}

@freezed
sealed class ForumState with _$ForumState {
  const factory ForumState.loading() = ForumLoading;
  const factory ForumState.loaded(List<ForumPostEntity> posts) = ForumLoaded;
  const factory ForumState.errorMessage(String error) = ForumError;
}

class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final GetForumPostsUseCase getForumPostsUseCase;
  final CreateForumPostUseCase createForumPostUseCase;
  final DeleteForumPostUseCase deleteForumPostUseCase;
  final ToggleForumPostLikeUseCase togglePostLikeUseCase;

  ForumBloc({
    required this.getForumPostsUseCase,
    required this.createForumPostUseCase,
    required this.deleteForumPostUseCase,
    required this.togglePostLikeUseCase,
  }) : super(const ForumState.loading()) {
    on<_Init>(_init);
    on<_Refresh>(_refresh);
    on<_CreatePost>(_createPost);
    on<_DeletePost>(_deletePost);
    on<_ToggleLike>(_toggleLike);
    add(const ForumEvent.init());
  }

  factory ForumBloc.fromContext(BuildContext context) {
    return ForumBloc(
      getForumPostsUseCase: GetForumPostsUseCase(context.read()),
      createForumPostUseCase: CreateForumPostUseCase(context.read()),
      deleteForumPostUseCase: DeleteForumPostUseCase(context.read()),
      togglePostLikeUseCase: ToggleForumPostLikeUseCase(context.read()),
    );
  }

  String get _uid => AuthSessionService().user?.uid ?? '';

  Future<void> _init(_Init event, Emitter<ForumState> emit) async {
    try {
      emit(.loaded(await getForumPostsUseCase(viewerUid: _uid)));
    } catch (e) {
      debugPrint('Forum error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _refresh(_Refresh event, Emitter<ForumState> emit) async {
    try {
      await _init(const _Init(), emit);
    } finally {
      if (!event.done.isCompleted) event.done.complete();
    }
  }

  Future<void> _createPost(_CreatePost event, Emitter<ForumState> emit) async {
    final session = AuthSessionService();
    try {
      await createForumPostUseCase(
        title: event.title,
        body: event.body,
        authorUid: session.user?.uid ?? '',
        authorName: session.profile?.fullName ?? '',
        authorPhotoUrl: session.profile?.photoUrl,
      );
      await _init(const _Init(), emit);
    } catch (e) {
      debugPrint('Create post error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _deletePost(_DeletePost event, Emitter<ForumState> emit) async {
    final current = state;
    try {
      await deleteForumPostUseCase(event.postId);
      if (current is ForumLoaded) {
        emit(.loaded(current.posts.where((p) => p.id != event.postId).toList()));
      }
    } catch (e) {
      debugPrint('Delete post error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  /// The row flips before the write lands so the tap feels immediate, and is
  /// put back if the transaction fails — the same as a like on a shared recipe.
  Future<void> _toggleLike(_ToggleLike event, Emitter<ForumState> emit) async {
    final current = state;
    if (current is! ForumLoaded) return;
    final index = current.posts.indexWhere((p) => p.id == event.postId);
    if (index == -1) return;

    final original = current.posts[index];
    emit(.loaded([...current.posts]..[index] = original.withLikeToggled()));

    try {
      await togglePostLikeUseCase(event.postId, viewerUid: _uid);
    } catch (e) {
      debugPrint('Post like failed: $e');
      final latest = state;
      if (latest is! ForumLoaded) return;
      final at = latest.posts.indexWhere((p) => p.id == event.postId);
      if (at != -1) emit(.loaded([...latest.posts]..[at] = original));
    }
  }
}
