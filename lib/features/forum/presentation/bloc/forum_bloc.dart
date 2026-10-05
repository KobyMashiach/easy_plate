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
import '../../domain/usecases/watch_forum_posts_usecase.dart';

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

  /// The page reports whether the list is scrolled to its top. While it is
  /// not, threads that arrive from other people are held back (see
  /// [ForumLoaded.incoming]) so the rows under the reader's thumb stay put.
  const factory ForumEvent.viewportAtTop(bool atTop) = _ViewportAtTop;

  /// Moves the held-back threads into the list.
  const factory ForumEvent.revealIncoming() = _RevealIncoming;

  /// Whether the live listener should be open. The page closes it while the
  /// app is in the background and reopens it on return; the reopened stream
  /// delivers everything that changed in between.
  const factory ForumEvent.setLive(bool live) = _SetLive;

  /// A new snapshot from the live listener.
  const factory ForumEvent.synced(List<ForumPostEntity> posts) = _Synced;
}

@freezed
sealed class ForumState with _$ForumState {
  const factory ForumState.loading() = ForumLoading;

  /// [incoming] are threads that arrived while the reader was scrolled down:
  /// counted on a pill rather than pushed into the list, until they either
  /// scroll back to the top or tap it.
  const factory ForumState.loaded(
    List<ForumPostEntity> posts, {
    @Default(<ForumPostEntity>[]) List<ForumPostEntity> incoming,
  }) = ForumLoaded;
  const factory ForumState.errorMessage(String error) = ForumError;
}

class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final GetForumPostsUseCase getForumPostsUseCase;
  final WatchForumPostsUseCase watchForumPostsUseCase;
  final CreateForumPostUseCase createForumPostUseCase;
  final DeleteForumPostUseCase deleteForumPostUseCase;
  final ToggleForumPostLikeUseCase togglePostLikeUseCase;

  StreamSubscription<List<ForumPostEntity>>? _live;
  bool _wantLive = true;
  bool _atTop = true;

  /// Likes of the viewer's own still on their way to the server, by thread.
  /// A snapshot that lands in that window carries the old value; without
  /// this the heart would flick back for a beat and then forward again.
  final _likesInFlight = <String, bool>{};

  ForumBloc({
    required this.getForumPostsUseCase,
    required this.watchForumPostsUseCase,
    required this.createForumPostUseCase,
    required this.deleteForumPostUseCase,
    required this.togglePostLikeUseCase,
  }) : super(const ForumState.loading()) {
    on<_Init>(_init);
    on<_Refresh>(_refresh);
    on<_CreatePost>(_createPost);
    on<_DeletePost>(_deletePost);
    on<_ToggleLike>(_toggleLike);
    on<_ViewportAtTop>(_viewportAtTop);
    on<_RevealIncoming>(_revealIncoming);
    on<_SetLive>(_setLive);
    on<_Synced>(_synced);
    add(const ForumEvent.init());
  }

  factory ForumBloc.fromContext(BuildContext context) {
    return ForumBloc(
      getForumPostsUseCase: GetForumPostsUseCase(context.read()),
      watchForumPostsUseCase: WatchForumPostsUseCase(context.read()),
      createForumPostUseCase: CreateForumPostUseCase(context.read()),
      deleteForumPostUseCase: DeleteForumPostUseCase(context.read()),
      togglePostLikeUseCase: ToggleForumPostLikeUseCase(context.read()),
    );
  }

  @override
  Future<void> close() {
    _live?.cancel();
    return super.close();
  }

  String get _uid => AuthSessionService().user?.uid ?? '';

  /// First a one-shot read — it refreshes the viewer's like cache and turns
  /// the spinner into a list at once — then the live listener behind it.
  Future<void> _init(_Init event, Emitter<ForumState> emit) async {
    try {
      emit(.loaded(await getForumPostsUseCase(viewerUid: _uid)));
      _listen();
    } catch (e) {
      debugPrint('Forum error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  void _listen() {
    if (!_wantLive || _live != null || isClosed) return;
    try {
      _live = watchForumPostsUseCase(viewerUid: _uid).listen(
        (posts) {
          if (!isClosed) add(ForumEvent.synced(posts));
        },
        // A dropped listener is not an error the reader can act on: the
        // list stays as it is, and the next resume or pull reopens it.
        onError: (Object e) => debugPrint('Forum live stream error: $e'),
      );
    } catch (e) {
      debugPrint('Forum live stream unavailable: $e');
    }
  }

  Future<void> _stopListening() async {
    final live = _live;
    _live = null;
    await live?.cancel();
  }

  Future<void> _setLive(_SetLive event, Emitter<ForumState> emit) async {
    _wantLive = event.live;
    if (event.live) {
      // Whatever changed while the listener was closed is not in memory:
      // re-read once, then listen again from there.
      if (state is ForumLoaded) await _init(const _Init(), emit);
    } else {
      await _stopListening();
    }
  }

  Future<void> _refresh(_Refresh event, Emitter<ForumState> emit) async {
    try {
      await _init(const _Init(), emit);
    } finally {
      if (!event.done.isCompleted) event.done.complete();
    }
  }

  void _viewportAtTop(_ViewportAtTop event, Emitter<ForumState> emit) {
    _atTop = event.atTop;
    if (_atTop) _revealIncoming(const _RevealIncoming(), emit);
  }

  void _revealIncoming(_RevealIncoming event, Emitter<ForumState> emit) {
    final current = state;
    if (current is! ForumLoaded || current.incoming.isEmpty) return;
    emit(.loaded(_newestFirst([...current.incoming, ...current.posts])));
  }

  static List<ForumPostEntity> _newestFirst(List<ForumPostEntity> posts) =>
      posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Folds a snapshot into what is shown. Threads already on screen are
  /// replaced in place (a reply count, a like), deleted ones drop out, and
  /// new ones either join the top or wait in [ForumLoaded.incoming].
  void _synced(_Synced event, Emitter<ForumState> emit) {
    final current = state;
    if (current is! ForumLoaded) {
      emit(.loaded(_withViewerLikes(event.posts)));
      return;
    }
    final visibleIds = {for (final p in current.posts) p.id};
    final heldIds = {for (final p in current.incoming) p.id};
    final visible = <ForumPostEntity>[];
    final held = <ForumPostEntity>[];
    for (final post in _withViewerLikes(event.posts)) {
      if (visibleIds.contains(post.id)) {
        visible.add(post);
      } else if (heldIds.contains(post.id) || !_atTop) {
        held.add(post);
      } else {
        visible.add(post);
      }
    }
    emit(.loaded(_newestFirst(visible), incoming: _newestFirst(held)));
  }

  List<ForumPostEntity> _withViewerLikes(List<ForumPostEntity> posts) {
    if (_likesInFlight.isEmpty) return posts;
    return [
      for (final post in posts)
        if (_likesInFlight[post.id] case final liked?)
          _reconcileLike(post, liked)
        else
          post,
    ];
  }

  /// The server's row, with the viewer's pending like on it: the flag as
  /// the app knows it, and the counter one step along if the server has
  /// not counted it yet.
  static ForumPostEntity _reconcileLike(ForumPostEntity post, bool liked) {
    if (post.likedByMe == liked) return post;
    return post.withLikeToggled();
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
      // The author expects to see their thread at the top whatever the
      // scroll position: a full re-read lands it there and empties the pill.
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
        emit(
          .loaded(
            current.posts.where((p) => p.id != event.postId).toList(),
            incoming: current.incoming
                .where((p) => p.id != event.postId)
                .toList(),
          ),
        );
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
    final flipped = original.withLikeToggled();
    _likesInFlight[event.postId] = flipped.likedByMe;
    emit(
      .loaded(
        [...current.posts]..[index] = flipped,
        incoming: current.incoming,
      ),
    );

    try {
      await togglePostLikeUseCase(event.postId, viewerUid: _uid);
    } catch (e) {
      debugPrint('Post like failed: $e');
      final latest = state;
      if (latest is! ForumLoaded) return;
      final at = latest.posts.indexWhere((p) => p.id == event.postId);
      if (at != -1) {
        emit(
          .loaded(
            [...latest.posts]..[at] = original,
            incoming: latest.incoming,
          ),
        );
      }
    } finally {
      _likesInFlight.remove(event.postId);
    }
  }
}
