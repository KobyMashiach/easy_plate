import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
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

  /// The page has shown [ForumLoaded.notice]: cleared, so the next failure
  /// — even the same one — is a new state the page hears.
  const factory ForumEvent.dismissNotice() = _DismissNotice;
}

/// What a write of the viewer's own failed at; the page holds the words.
/// What failed while a list was on screen; the page holds the words.
/// [loadFailed]: a pull or a resume re-read — the list stays.
enum ForumNotice { createFailed, deleteFailed, loadFailed }

@freezed
sealed class ForumState with _$ForumState {
  const factory ForumState.loading() = ForumLoading;

  /// [incoming] are threads that arrived while the reader was scrolled down:
  /// counted on a pill rather than pushed into the list, until they either
  /// scroll back to the top or tap it.
  const factory ForumState.loaded(
    List<ForumPostEntity> posts, {
    @Default(<ForumPostEntity>[]) List<ForumPostEntity> incoming,

    /// A write of the viewer's own that failed. The list stays: a thread
    /// that could not be posted or deleted is no reason to take the forum
    /// away and show the retry view in its place.
    ForumNotice? notice,
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
  final _likesInFlight = <String, ({bool liked, int countBefore})>{};

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
    // One at a time: two quick taps on a heart would both read the row
    // before either write landed, and the second would undo the first's
    // in-flight mark while its write was still out.
    on<_ToggleLike>(_toggleLike, transformer: _sequential());
    on<_ViewportAtTop>(_viewportAtTop);
    on<_RevealIncoming>(_revealIncoming);
    on<_SetLive>(_setLive);
    on<_Synced>(_synced);
    on<_DismissNotice>(_dismissNotice);
    add(const ForumEvent.init());
  }

  /// Handles each event only after the previous one of its kind finished.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

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
  Future<void> _init(_Init event, Emitter<ForumState> emit) => _load(emit);

  /// [refresh] (pull to refresh) reads authors past the profile cache.
  Future<void> _load(Emitter<ForumState> emit, {bool refresh = false}) async {
    try {
      emit(
        .loaded(
          await getForumPostsUseCase(viewerUid: _uid, refresh: refresh),
        ),
      );
      _listen();
    } catch (e) {
      debugPrint('Forum error: $e');
      // A list already on screen stays, with a word; only a first load
      // with nothing to keep shows the error view.
      _notify(ForumNotice.loadFailed, e, emit);
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
      // re-read once, then listen again from there. A list that failed to
      // load (offline when it was opened) gets that read too, so coming
      // back brings it up without a pull. Only a read still in progress is
      // left alone.
      if (state is ForumLoaded || state is ForumError) {
        await _init(const _Init(), emit);
      }
    } else {
      await _stopListening();
    }
  }

  Future<void> _refresh(_Refresh event, Emitter<ForumState> emit) async {
    try {
      await _load(emit, refresh: true);
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
        if (_likesInFlight[post.id] case final pending?)
          _reconcileLike(post, pending.liked, pending.countBefore)
        else
          post,
    ];
  }

  /// The server's row, with the viewer's pending like on it: the flag as
  /// the app knows it, and the counter one step along if the server has
  /// not counted it yet.
  ///
  /// The datasource flips its flag before the transaction commits, so a
  /// snapshot can carry the new flag with the old counter ([countBefore],
  /// the row's count at the tap): the counter is moved here then, or the
  /// heart showed liked with the count one short until the commit landed.
  static ForumPostEntity _reconcileLike(
    ForumPostEntity post,
    bool liked,
    int countBefore,
  ) {
    if (post.likedByMe != liked) return post.withLikeToggled();
    if (post.likeCount == countBefore) {
      return post.withViewerLike(!liked).withLikeToggled();
    }
    return post;
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
      _notify(ForumNotice.createFailed, e, emit);
    }
  }

  Future<void> _deletePost(_DeletePost event, Emitter<ForumState> emit) async {
    try {
      await deleteForumPostUseCase(event.postId);
      // The state as it is now, not as it was before the write: a snapshot
      // may have landed meanwhile.
      final current = state;
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
      _notify(ForumNotice.deleteFailed, e, emit);
    }
  }

  /// A failed write keeps the list and flags it for the page to word. Only
  /// with no list to keep does the error view take over.
  void _notify(ForumNotice notice, Object error, Emitter<ForumState> emit) {
    final current = state;
    if (current is ForumLoaded) {
      emit(.loaded(current.posts, incoming: current.incoming, notice: notice));
    } else {
      debugPrint('Forum write failed with no list to keep: $error');
      emit(.errorMessage(t.community.loadFailed));
    }
  }

  void _dismissNotice(_DismissNotice event, Emitter<ForumState> emit) {
    final current = state;
    if (current is! ForumLoaded || current.notice == null) return;
    emit(.loaded(current.posts, incoming: current.incoming));
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
    _likesInFlight[event.postId] = (
      liked: flipped.likedByMe,
      countBefore: original.likeCount,
    );
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
      // Only the like is undone, on the row as it is now: a reply count or
      // an edit that arrived meanwhile stays.
      final row = at == -1 ? null : latest.posts[at];
      if (row != null && row.likedByMe == flipped.likedByMe) {
        emit(
          .loaded(
            [...latest.posts]..[at] = row.withLikeToggled(),
            incoming: latest.incoming,
          ),
        );
      }
    } finally {
      _likesInFlight.remove(event.postId);
    }
  }
}
