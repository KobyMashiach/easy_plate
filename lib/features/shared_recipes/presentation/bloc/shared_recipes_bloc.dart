import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/usecases/get_recipes_usecase.dart';
import '../../../my_recipes/domain/usecases/save_recipe_usecase.dart';
import '../../domain/entities/shared_recipe_entity.dart';
import '../../domain/shared_feed_changes.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../domain/usecases/get_shared_recipes_usecase.dart';
import '../../domain/usecases/import_shared_recipe_usecase.dart';
import '../../domain/usecases/share_recipe_usecase.dart';
import '../../domain/usecases/toggle_shared_recipe_like_usecase.dart';
import '../../domain/usecases/unshare_recipe_usecase.dart';
import '../../domain/usecases/update_shared_recipe_usecase.dart';
import '../widgets/shared_feed_query.dart';

part 'shared_recipes_bloc.freezed.dart';

@freezed
sealed class SharedRecipesEvent with _$SharedRecipesEvent {
  const factory SharedRecipesEvent.init() = _Init;

  /// Carries a completer so the pull-to-refresh spinner is told exactly when the
  /// reload finished. Waiting on the state stream instead would hang whenever
  /// the reloaded data is identical, because bloc skips emitting a state equal
  /// to the current one.
  const factory SharedRecipesEvent.refresh(Completer<void> done) = _Refresh;
  const factory SharedRecipesEvent.share(RecipeEntity recipe) = _Share;
  const factory SharedRecipesEvent.toggleLike(String id) = _ToggleLike;
  const factory SharedRecipesEvent.updateShared(
    String id,
    RecipeEntity recipe,
  ) = _UpdateShared;
  const factory SharedRecipesEvent.unshare(String id) = _Unshare;
  const factory SharedRecipesEvent.importToMyRecipes(
    SharedRecipeEntity shared,
  ) = _Import;

  /// The local recipes changed — a save from a forum link, a removal on the
  /// recipes tab — so which feed entries count as saved has to be re-read.
  const factory SharedRecipesEvent.savedChanged(Set<String> savedIds) =
      _SavedChanged;

  /// The page switched to [scope]. "Mine" and "saved" reach past the
  /// newest-first window: their posts are fetched into
  /// [SharedRecipesLoaded.older] once per load.
  const factory SharedRecipesEvent.scopeOpened(SharedFeedScope scope) =
      _ScopeOpened;

  /// The page has shown [SharedRecipesLoaded.notice]: cleared, so the next
  /// failure — even the same one — is a new state the page hears.
  const factory SharedRecipesEvent.dismissNotice() = _DismissNotice;
}

/// A one-shot word for the page about a write of the viewer's own: what it
/// failed at, or that the post was updated. The page holds the words.
enum SharedFeedNotice {
  shareFailed,
  updateFailed,
  unshareFailed,
  importFailed,
  updated,

  /// A reload (pull, or a re-read after a write) failed; the feed stays.
  loadFailed,
}

@freezed
sealed class SharedRecipesState with _$SharedRecipesState {
  const factory SharedRecipesState.loading() = SharedRecipesLoading;
  const factory SharedRecipesState.loaded(
    List<SharedRecipeEntity> recipes, {

    /// The viewer's own and saved posts older than [recipes] — the newest
    /// window — fetched only for the "mine" and "saved" scopes, which show
    /// them alongside; "all" shows [recipes] alone.
    @Default(<SharedRecipeEntity>[]) List<SharedRecipeEntity> older,
    @Default(false) bool imported,

    /// Feed ids the user already has a local copy of, so the saved filter and
    /// the save button can reflect it.
    @Default(<String>{}) Set<String> savedIds,

    /// A write of the viewer's own that failed. The feed stays: a share
    /// that did not go through is no reason to replace it with the retry
    /// view.
    SharedFeedNotice? notice,
  }) = SharedRecipesLoaded;
  const factory SharedRecipesState.errorMessage(String error) =
      SharedRecipesError;
}

class SharedRecipesBloc extends Bloc<SharedRecipesEvent, SharedRecipesState> {
  final GetSharedRecipesUseCase getSharedRecipesUseCase;
  final ShareRecipeUseCase shareRecipeUseCase;
  final ToggleSharedRecipeLikeUseCase toggleLikeUseCase;
  final UnshareRecipeUseCase unshareRecipeUseCase;
  final UpdateSharedRecipeUseCase updateSharedRecipeUseCase;
  final SaveRecipeUseCase saveRecipeUseCase;
  final GetRecipesUseCase getRecipesUseCase;
  final RecipesRepository recipesRepository;

  List<SharedRecipeEntity> _feed = [];
  Set<String> _savedIds = {};

  /// See [SharedRecipesLoaded.older]. Cleared with every reload.
  List<SharedRecipeEntity> _older = [];
  SharedFeedScope _scope = SharedFeedScope.all;
  bool _mineFetched = false;

  /// Saved ids already asked for since the last reload, found or not, so an
  /// unshared post is not looked up again on every saved-ids change.
  final _savedAskedFor = <String>{};
  StreamSubscription<List<RecipeEntity>>? _recipes;
  StreamSubscription<String>? _feedChanges;

  /// True while one of this bloc's own writes is in flight. The use cases
  /// announce every change to the feed; the ones this bloc made are already
  /// applied in place and need no reload.
  bool _writing = false;

  SharedRecipesBloc({
    required this.getSharedRecipesUseCase,
    required this.shareRecipeUseCase,
    required this.toggleLikeUseCase,
    required this.unshareRecipeUseCase,
    required this.updateSharedRecipeUseCase,
    required this.saveRecipeUseCase,
    required this.getRecipesUseCase,
    required this.recipesRepository,
  }) : super(const SharedRecipesState.loading()) {
    on<_Init>(_init);
    on<_Refresh>(_refresh);
    on<_Share>(_share);
    // One at a time: two quick taps on a heart would both read the row
    // before either write landed and the rollback of one would undo the
    // other.
    on<_ToggleLike>(_toggleLike, transformer: _sequential());
    on<_UpdateShared>(_updateShared);
    on<_Unshare>(_unshare);
    on<_Import>(_import);
    on<_SavedChanged>(_savedChanged);
    on<_ScopeOpened>(_scopeOpened);
    on<_DismissNotice>(_dismissNotice);
    add(const SharedRecipesEvent.init());
    // The feed lives in an IndexedStack and is not rebuilt when the user
    // comes back to it, so a recipe removed on the recipes tab would still
    // read as saved here. Following the box keeps the two in step.
    _recipes = recipesRepository.watchRecipes().listen(
      (local) => add(
        .savedChanged(local.map((r) => r.savedFromSharedId).nonNulls.toSet()),
      ),
      onError: (Object e) => debugPrint('Saved ids stream failed: $e'),
    );
    // A post rewritten from the recipe details page ("update both"), or
    // shared from the recipes tab: re-read so the feed shows it.
    _feedChanges = SharedFeedChanges.instance.stream.listen((_) {
      if (!_writing && state is SharedRecipesLoaded) add(const _Init());
    });
  }

  /// Handles each event only after the previous one of its kind finished.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  SharedRecipesState _loaded({
    bool imported = false,
    SharedFeedNotice? notice,
  }) => SharedRecipesState.loaded(
    _feed,
    older: _older,
    savedIds: _savedIds,
    imported: imported,
    notice: notice,
  );

  /// Replaces the post [id] wherever it is shown; false when it is not.
  bool _replace(
    String id,
    SharedRecipeEntity Function(SharedRecipeEntity) change,
  ) {
    final inFeed = _feed.indexWhere((r) => r.id == id);
    if (inFeed != -1) {
      _feed = [..._feed]..[inFeed] = change(_feed[inFeed]);
      return true;
    }
    final inOlder = _older.indexWhere((r) => r.id == id);
    if (inOlder != -1) {
      _older = [..._older]..[inOlder] = change(_older[inOlder]);
      return true;
    }
    return false;
  }

  @override
  Future<void> close() {
    _recipes?.cancel();
    _feedChanges?.cancel();
    return super.close();
  }

  /// A failed write keeps the feed and flags it for the page to word. Only
  /// with no feed to keep does the error view take over.
  void _notify(
    SharedFeedNotice notice,
    Object error,
    Emitter<SharedRecipesState> emit,
  ) {
    if (state is SharedRecipesLoaded) {
      emit(_loaded(notice: notice));
    } else {
      debugPrint('Feed write failed with no feed to keep: $error');
      emit(.errorMessage(t.community.loadFailed));
    }
  }

  void _dismissNotice(
    _DismissNotice event,
    Emitter<SharedRecipesState> emit,
  ) {
    final current = state;
    if (current is! SharedRecipesLoaded || current.notice == null) return;
    emit(_loaded());
  }

  factory SharedRecipesBloc.fromContext(BuildContext context) {
    return SharedRecipesBloc(
      getSharedRecipesUseCase: GetSharedRecipesUseCase(context.read()),
      shareRecipeUseCase: ShareRecipeUseCase(context.read(), context.read()),
      toggleLikeUseCase: ToggleSharedRecipeLikeUseCase(context.read()),
      unshareRecipeUseCase: UnshareRecipeUseCase(context.read()),
      updateSharedRecipeUseCase: UpdateSharedRecipeUseCase(
        context.read(),
        context.read(),
      ),
      saveRecipeUseCase: SaveRecipeUseCase(context.read()),
      getRecipesUseCase: GetRecipesUseCase(context.read()),
      recipesRepository: context.read(),
    );
  }

  String get _uid => AuthSessionService().user?.uid ?? '';

  Future<void> _init(_Init event, Emitter<SharedRecipesState> emit) =>
      _load(emit);

  /// [refresh] (pull to refresh) reads likes and authors past their caches.
  Future<void> _load(
    Emitter<SharedRecipesState> emit, {
    bool refresh = false,
  }) async {
    try {
      _feed = await getSharedRecipesUseCase(viewerUid: _uid, refresh: refresh);
      _older = [];
      _mineFetched = false;
      _savedAskedFor.clear();
      await _refreshSavedIds();
      await _fetchOlder(refresh: refresh);
      emit(_loaded());
    } catch (e) {
      debugPrint('Shared recipes error: $e');
      // A feed already on screen stays, with a word; only a first load
      // with nothing to keep shows the error view.
      _notify(SharedFeedNotice.loadFailed, e, emit);
    }
  }

  /// Which feed entries are already in My Recipes, read from the local copies'
  /// `savedFromSharedId` rather than tracked separately.
  Future<void> _refreshSavedIds() async {
    try {
      final local = await getRecipesUseCase();
      _savedIds = local.map((r) => r.savedFromSharedId).nonNulls.toSet();
    } catch (e) {
      debugPrint('Saved ids lookup failed: $e');
      _savedIds = {};
    }
  }

  Future<void> _refresh(
    _Refresh event,
    Emitter<SharedRecipesState> emit,
  ) async {
    try {
      await _load(emit, refresh: true);
    } finally {
      if (!event.done.isCompleted) event.done.complete();
    }
  }

  Future<void> _share(_Share event, Emitter<SharedRecipesState> emit) async {
    final profile = AuthSessionService().profile;
    _writing = true;
    try {
      final postId = await shareRecipeUseCase(
        event.recipe,
        authorUid: _uid,
        authorName: profile?.fullName ?? '',
        authorPhotoUrl: profile?.photoUrl,
      );
      // Remember the post on the local recipe, so a later edit there can
      // offer to update the community copy too.
      final local = (await recipesRepository.getRecipes())
          .where((r) => r.id == event.recipe.id)
          .firstOrNull;
      if (local != null) {
        await recipesRepository.saveRecipe(
          local.copyWith(sharedRecipeId: postId),
        );
      }
      await _init(const _Init(), emit);
    } catch (e) {
      debugPrint('Share recipe error: $e');
      _notify(SharedFeedNotice.shareFailed, e, emit);
    } finally {
      _writing = false;
    }
  }

  /// The row flips before the write lands so the tap feels immediate, and is
  /// put back if the transaction fails.
  Future<void> _toggleLike(
    _ToggleLike event,
    Emitter<SharedRecipesState> emit,
  ) async {
    final original = [
      ..._feed,
      ..._older,
    ].where((r) => r.id == event.id).firstOrNull;
    if (original == null) return;

    _replace(
      event.id,
      (_) => original.copyWith(
        likedByMe: !original.likedByMe,
        likeCount: original.likeCount + (original.likedByMe ? -1 : 1),
      ),
    );
    emit(_loaded());

    try {
      await toggleLikeUseCase(event.id, viewerUid: _uid);
    } catch (e) {
      debugPrint('Like failed: $e');
      // Looked up again: a reload or an unshare may have moved the rows
      // while the write was out. Only the like is undone, on the row as it
      // is now (an edit or a reload in between stays), and only if the row
      // still shows this tap.
      if (_replace(
        event.id,
        (row) => row.likedByMe == original.likedByMe
            ? row
            : row.copyWith(
                likedByMe: original.likedByMe,
                likeCount: row.likeCount + (row.likedByMe ? -1 : 1),
              ),
      )) {
        emit(_loaded());
      }
    }
  }

  /// The edited recipe replaces the row in place rather than reloading the
  /// feed, so the list does not jump while the user is looking at it.
  Future<void> _updateShared(
    _UpdateShared event,
    Emitter<SharedRecipesState> emit,
  ) async {
    _writing = true;
    try {
      // The recipe *is* the post, not a local recipe: a photo picked for it
      // is uploaded but nothing is saved to My Recipes under the post's id.
      await updateSharedRecipeUseCase(event.id, event.recipe, persist: false);
      // Looked up after the write, not before: the feed may have been
      // reloaded meanwhile. A row no longer shown is re-read instead.
      final shown = _replace(
        event.id,
        (row) => row.copyWith(recipe: event.recipe),
      );
      if (!shown) await _init(const _Init(), emit);
      // Said by the state, so a refused write is not also called a success
      // by the page, which only knows the bloc moved on.
      if (state is SharedRecipesLoaded) {
        emit(_loaded(notice: SharedFeedNotice.updated));
      }
    } catch (e) {
      debugPrint('Update shared recipe error: $e');
      _notify(SharedFeedNotice.updateFailed, e, emit);
    } finally {
      _writing = false;
    }
  }

  Future<void> _unshare(
    _Unshare event,
    Emitter<SharedRecipesState> emit,
  ) async {
    _writing = true;
    try {
      await unshareRecipeUseCase(event.id);
      for (final local in await recipesRepository.getRecipes()) {
        if (local.sharedRecipeId == event.id) {
          await recipesRepository.saveRecipe(
            local.copyWith(clearSharedRecipeId: true),
          );
        }
      }
      _feed = _feed.where((r) => r.id != event.id).toList();
      _older = _older.where((r) => r.id != event.id).toList();
      emit(_loaded());
    } catch (e) {
      debugPrint('Unshare error: $e');
      _notify(SharedFeedNotice.unshareFailed, e, emit);
    } finally {
      _writing = false;
    }
  }

  /// Delegates to the shared import so the feed and a forum reply's recipe
  /// link save exactly the same way — and neither makes a second copy.
  Future<void> _savedChanged(
    _SavedChanged event,
    Emitter<SharedRecipesState> emit,
  ) async {
    if (setEquals(event.savedIds, _savedIds)) return;
    _savedIds = event.savedIds;
    if (state is! SharedRecipesLoaded) return;
    // A post saved from a forum link may be older than the window.
    await _fetchOlder();
    emit(_loaded());
  }

  Future<void> _scopeOpened(
    _ScopeOpened event,
    Emitter<SharedRecipesState> emit,
  ) async {
    _scope = event.scope;
    if (state is! SharedRecipesLoaded) return;
    final before = _older;
    await _fetchOlder();
    if (!identical(before, _older)) emit(_loaded());
  }

  /// Fills [_older] for the open scope: the viewer's posts for "mine" (one
  /// equality query, once per load), and the saved posts the window does
  /// not hold for "saved" (by id, 30 to a query). "All" fetches nothing.
  /// A failure keeps what is shown — the window is still right, only
  /// shorter.
  Future<void> _fetchOlder({bool refresh = false}) async {
    var askedForMine = false;
    try {
      final shown = {
        for (final r in [..._feed, ..._older]) r.id,
      };
      final List<SharedRecipeEntity> fetched;
      switch (_scope) {
        case SharedFeedScope.all:
          return;
        case SharedFeedScope.mine:
          if (_mineFetched) return;
          // Marked before the read: a scope tap during a pull (or two quick
          // taps) started a second read and listed the posts twice.
          _mineFetched = askedForMine = true;
          fetched = await getSharedRecipesUseCase.mine(
            viewerUid: _uid,
            refresh: refresh,
          );
        case SharedFeedScope.saved:
          final missing = _savedIds
              .where((id) => !shown.contains(id))
              .where(_savedAskedFor.add)
              .toSet();
          if (missing.isEmpty) return;
          fetched = await getSharedRecipesUseCase.byIds(
            missing,
            viewerUid: _uid,
            refresh: refresh,
          );
      }
      // Read again: another fetch may have landed during this one.
      final nowShown = {
        for (final r in [..._feed, ..._older]) r.id,
      };
      final added = [
        for (final r in fetched)
          if (!nowShown.contains(r.id)) r,
      ];
      if (added.isNotEmpty) _older = [..._older, ...added];
    } catch (e) {
      debugPrint('Older shared recipes unavailable: $e');
      // Asked again next time the scope opens.
      if (askedForMine) _mineFetched = false;
    }
  }

  Future<void> _import(_Import event, Emitter<SharedRecipesState> emit) async {
    try {
      await ImportSharedRecipeUseCase(recipesRepository)(event.shared);
      await _refreshSavedIds();
      emit(_loaded(imported: true));
    } catch (e) {
      // Something has to be emitted: the page waits on the next state.
      debugPrint('Import shared recipe error: $e');
      _notify(SharedFeedNotice.importFailed, e, emit);
    }
  }
}
