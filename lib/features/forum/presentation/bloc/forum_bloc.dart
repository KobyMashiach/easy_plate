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

part 'forum_bloc.freezed.dart';

@freezed
sealed class ForumEvent with _$ForumEvent {
  const factory ForumEvent.init() = _Init;
  const factory ForumEvent.createPost(String title, String body) = _CreatePost;
  const factory ForumEvent.deletePost(String postId) = _DeletePost;
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

  ForumBloc({
    required this.getForumPostsUseCase,
    required this.createForumPostUseCase,
    required this.deleteForumPostUseCase,
  }) : super(const ForumState.loading()) {
    on<_Init>(_init);
    on<_CreatePost>(_createPost);
    on<_DeletePost>(_deletePost);
    add(const ForumEvent.init());
  }

  factory ForumBloc.fromContext(BuildContext context) {
    return ForumBloc(
      getForumPostsUseCase: GetForumPostsUseCase(context.read()),
      createForumPostUseCase: CreateForumPostUseCase(context.read()),
      deleteForumPostUseCase: DeleteForumPostUseCase(context.read()),
    );
  }

  Future<void> _init(_Init event, Emitter<ForumState> emit) async {
    try {
      emit(.loaded(await getForumPostsUseCase()));
    } catch (e) {
      debugPrint('Forum error: $e');
      emit(.errorMessage(e.toString()));
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
}
