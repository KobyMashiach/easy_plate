import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/usecases/add_forum_reply_usecase.dart';
import '../../domain/usecases/get_forum_replies_usecase.dart';
import '../../domain/usecases/toggle_forum_post_like_usecase.dart';
import '../../domain/usecases/toggle_forum_reply_like_usecase.dart';
import '../../domain/usecases/watch_forum_replies_usecase.dart';

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
  const factory ForumThreadEvent.toggleReplyLike(String replyId) =
      _ToggleReplyLike;

  /// See [ForumEvent.setLive].
  const factory ForumThreadEvent.setLive(bool live) = _SetLive;

  /// A notification pointed at [replyId] and it is older than the window
  /// the thread loads: fetch it on its own and keep it at the top.
  const factory ForumThreadEvent.reveal(String replyId) = _Reveal;

  /// A new snapshot of the replies from the live listener.
  const factory ForumThreadEvent.synced(List<ForumReplyEntity> replies) =
      _Synced;
}

@freezed
sealed class ForumThreadState with _$ForumThreadState {
  const factory ForumThreadState.loading(ForumPostEntity post) =
      ForumThreadLoading;

  /// [post] travels in the state rather than staying on the page: its like
  /// count is the one part of it that changes while the thread is open.
  ///
  /// [sending] is true from the tap on Send until the server has the reply.
  /// The reply itself is already in [replies] by then — the local SDK
  /// reports it at once, flagged [ForumReplyEntity.pending] — so the only
  /// thing waiting on the round trip is the composer.
  const factory ForumThreadState.loaded(
    ForumPostEntity post,
    List<ForumReplyEntity> replies, {
    @Default(false) bool sending,
    String? sendError,

    /// Bumped when a re-read (pull, resume) failed over replies already
    /// shown: they stay, and the page says so.
    @Default(0) int loadFailures,
  }) = ForumThreadLoaded;
  const factory ForumThreadState.errorMessage(
    ForumPostEntity post,
    String error,
  ) = ForumThreadError;
}

class ForumThreadBloc extends Bloc<ForumThreadEvent, ForumThreadState> {
  final GetForumRepliesUseCase getForumRepliesUseCase;
  final WatchForumRepliesUseCase watchForumRepliesUseCase;
  final AddForumReplyUseCase addForumReplyUseCase;
  final ToggleForumPostLikeUseCase togglePostLikeUseCase;
  final ToggleForumReplyLikeUseCase toggleReplyLikeUseCase;

  /// How long the composer waits for the server before treating the reply
  /// as queued. Offline, the SDK holds the write and sends it when it can;
  /// the reply is already on screen, so the composer need not stay locked.
  static const sendTimeout = Duration(seconds: 8);

  /// The opening post as the list handed it over, then as liked here. Kept
  /// outside the state so a reload never resets a like made in between.
  ForumPostEntity _post;

  StreamSubscription<List<ForumReplyEntity>>? _live;
  bool _wantLive = true;

  /// Likes of the viewer's own still on their way up, by reply id. See
  /// [ForumBloc] for why a snapshot in that window needs them.
  final _likesInFlight = <String, bool>{};

  /// A reply fetched by [ForumThreadEvent.reveal], placed ahead of the window
  /// it fell out of until a later window holds it again.
  ForumReplyEntity? _revealed;

  String get postId => _post.id;

  ForumThreadBloc({
    required ForumPostEntity post,
    required this.getForumRepliesUseCase,
    required this.watchForumRepliesUseCase,
    required this.addForumReplyUseCase,
    required this.togglePostLikeUseCase,
    required this.toggleReplyLikeUseCase,
  }) : _post = post,
       super(ForumThreadState.loading(post)) {
    on<_Init>(_init);
    on<_Refresh>(_refresh);
    on<_AddReply>(_addReply);
    // One at a time per heart: see ForumBloc.
    on<_TogglePostLike>(_togglePostLike, transformer: _sequential());
    on<_ToggleReplyLike>(_toggleReplyLike, transformer: _sequential());
    on<_SetLive>(_setLive);
    on<_Synced>(_synced);
    on<_Reveal>(_reveal);
    add(const ForumThreadEvent.init());
  }

  factory ForumThreadBloc.fromContext(
    BuildContext context,
    ForumPostEntity post,
  ) {
    return ForumThreadBloc(
      post: post,
      getForumRepliesUseCase: GetForumRepliesUseCase(context.read()),
      watchForumRepliesUseCase: WatchForumRepliesUseCase(context.read()),
      addForumReplyUseCase: AddForumReplyUseCase(context.read()),
      togglePostLikeUseCase: ToggleForumPostLikeUseCase(context.read()),
      toggleReplyLikeUseCase: ToggleForumReplyLikeUseCase(context.read()),
    );
  }

  /// Handles each event only after the previous one of its kind finished.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  @override
  Future<void> close() {
    _live?.cancel();
    return super.close();
  }

  String get _uid => AuthSessionService().user?.uid ?? '';

  bool get _sending => switch (state) {
    ForumThreadLoaded(sending: final sending) => sending,
    _ => false,
  };

  int _loadFailures = 0;

  Future<void> _init(_Init event, Emitter<ForumThreadState> emit) =>
      _load(emit);

  /// [refresh] (pull to refresh) reads authors past the profile cache.
  Future<void> _load(
    Emitter<ForumThreadState> emit, {
    bool refresh = false,
  }) async {
    try {
      emit(
        .loaded(
          _post,
          _withRevealed(
            await getForumRepliesUseCase(
              postId,
              viewerUid: _uid,
              refresh: refresh,
            ),
          ),
          sending: _sending,
        ),
      );
      _listen();
    } catch (e) {
      debugPrint('Thread error: $e');
      final current = state;
      if (current is ForumThreadLoaded) {
        emit(current.copyWith(loadFailures: ++_loadFailures));
      } else {
        emit(.errorMessage(_post, t.community.loadFailed));
      }
    }
  }

  void _listen() {
    if (!_wantLive || _live != null || isClosed) return;
    try {
      _live = watchForumRepliesUseCase(postId, viewerUid: _uid).listen(
        (replies) {
          if (!isClosed) add(ForumThreadEvent.synced(replies));
        },
        onError: (Object e) => debugPrint('Thread live stream error: $e'),
      );
    } catch (e) {
      debugPrint('Thread live stream unavailable: $e');
    }
  }

  Future<void> _setLive(_SetLive event, Emitter<ForumThreadState> emit) async {
    _wantLive = event.live;
    if (event.live) {
      // See ForumBloc: a thread that failed to load is re-read on resume too.
      if (state is ForumThreadLoaded || state is ForumThreadError) {
        await _init(const _Init(), emit);
      }
    } else {
      final live = _live;
      _live = null;
      await live?.cancel();
    }
  }

  Future<void> _refresh(_Refresh event, Emitter<ForumThreadState> emit) async {
    try {
      // The opening post too: its likes and its author's name were the
      // ones the list handed over, and a pull never moved them.
      try {
        final fresh = await getForumRepliesUseCase.repository.getPost(
          postId,
          viewerUid: _uid,
        );
        if (fresh != null) _post = fresh;
      } catch (e) {
        debugPrint('Thread post re-read failed: $e');
      }
      await _load(emit, refresh: true);
    } finally {
      if (!event.done.isCompleted) event.done.complete();
    }
  }

  /// [replies] with the revealed reply ahead of them when the window does
  /// not already hold it.
  List<ForumReplyEntity> _withRevealed(List<ForumReplyEntity> replies) {
    final revealed = _revealed;
    if (revealed == null || replies.any((r) => r.id == revealed.id)) {
      return replies;
    }
    return [revealed, ...replies];
  }

  Future<void> _reveal(_Reveal event, Emitter<ForumThreadState> emit) async {
    try {
      final reply = await getForumRepliesUseCase.repository.getReply(
        postId,
        event.replyId,
        viewerUid: _uid,
      );
      if (reply == null) return;
      _revealed = reply;
      if (state case final ForumThreadLoaded current) {
        emit(current.copyWith(replies: _withRevealed(current.replies)));
      }
    } catch (e) {
      debugPrint('Reply ${event.replyId} unavailable: $e');
    }
  }

  /// Replies are chronological and only ever appended, so a snapshot can
  /// replace the list wholesale: rows above the reader do not move.
  void _synced(_Synced event, Emitter<ForumThreadState> emit) {
    final current = state;
    final replies = [
      for (final reply in _withRevealed(event.replies))
        if (_likesInFlight[reply.id] case final liked?
            when liked != reply.likedByMe)
          reply.withLikeToggled()
        else
          reply,
    ];
    if (current is ForumThreadLoaded) {
      emit(
        .loaded(
          _post,
          replies,
          sending: current.sending,
          sendError: current.sendError,
        ),
      );
    } else {
      emit(.loaded(_post, replies));
    }
  }

  Future<void> _addReply(
    _AddReply event,
    Emitter<ForumThreadState> emit,
  ) async {
    final current = state;
    if (current is ForumThreadLoaded) {
      emit(.loaded(_post, current.replies, sending: true));
    }

    final session = AuthSessionService();
    try {
      // The SDK applies the write locally first, so the live listener draws
      // the reply before this future completes; the wait is for the ack.
      await addForumReplyUseCase(
        postId: postId,
        body: event.body,
        authorUid: session.user?.uid ?? '',
        authorName: session.profile?.fullName ?? '',
        authorPhotoUrl: session.profile?.photoUrl,
        sharedRecipeId: event.sharedRecipeId,
        sharedRecipeTitle: event.sharedRecipeTitle,
      ).timeout(sendTimeout);
      // Without a live listener (offline start, app in the background) the
      // reply has to be read back; _init keeps the composer locked while it
      // does, so the unlock below is needed on both paths. With a listener
      // the emission is a no-op and the stream wins.
      if (_live == null) await _init(const _Init(), emit);
      if (state case ForumThreadLoaded(replies: final replies)) {
        emit(.loaded(_post, replies));
      }
    } on TimeoutException {
      // Queued, not lost: the SDK sends it when the connection returns.
      if (state case ForumThreadLoaded(replies: final replies)) {
        emit(.loaded(_post, replies));
      }
    } catch (e) {
      debugPrint('Reply error: $e');
      if (state case ForumThreadLoaded(replies: final replies)) {
        emit(.loaded(_post, replies, sendError: e.toString()));
      } else {
        emit(.errorMessage(_post, t.community.replyFailed));
      }
    }
  }

  /// Optimistic, like everywhere else a heart is tapped: flipped at once, put
  /// back if the write fails.
  Future<void> _togglePostLike(
    _TogglePostLike event,
    Emitter<ForumThreadState> emit,
  ) async {
    final current = state;
    if (current is! ForumThreadLoaded) return;

    final flipped = _post.withLikeToggled();
    _post = flipped;
    emit(.loaded(_post, current.replies, sending: current.sending));

    try {
      await togglePostLikeUseCase(postId, viewerUid: _uid);
    } catch (e) {
      debugPrint('Post like failed: $e');
      // Only the like is undone, on the post as it is now.
      if (_post.likedByMe == flipped.likedByMe) _post = _post.withLikeToggled();
      final latest = state;
      if (latest is ForumThreadLoaded) {
        emit(.loaded(_post, latest.replies, sending: latest.sending));
      }
    }
  }

  Future<void> _toggleReplyLike(
    _ToggleReplyLike event,
    Emitter<ForumThreadState> emit,
  ) async {
    final current = state;
    if (current is! ForumThreadLoaded) return;
    final index = current.replies.indexWhere((r) => r.id == event.replyId);
    if (index == -1) return;

    final original = current.replies[index];
    final flipped = original.withLikeToggled();
    _likesInFlight[event.replyId] = flipped.likedByMe;
    emit(
      .loaded(
        _post,
        [...current.replies]..[index] = flipped,
        sending: current.sending,
      ),
    );

    try {
      await toggleReplyLikeUseCase(postId, event.replyId, viewerUid: _uid);
    } catch (e) {
      debugPrint('Reply like failed: $e');
      final latest = state;
      if (latest is! ForumThreadLoaded) return;
      final at = latest.replies.indexWhere((r) => r.id == event.replyId);
      // Only the like is undone, on the row as it is now.
      final row = at == -1 ? null : latest.replies[at];
      if (row != null && row.likedByMe == flipped.likedByMe) {
        emit(
          .loaded(
            _post,
            [...latest.replies]..[at] = row.withLikeToggled(),
            sending: latest.sending,
          ),
        );
      }
    } finally {
      _likesInFlight.remove(event.replyId);
    }
  }
}
