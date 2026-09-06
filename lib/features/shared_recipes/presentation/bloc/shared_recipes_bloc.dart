import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/usecases/get_recipes_usecase.dart';
import '../../../my_recipes/domain/usecases/save_recipe_usecase.dart';
import '../../domain/entities/shared_recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../domain/usecases/get_shared_recipes_usecase.dart';
import '../../domain/usecases/import_shared_recipe_usecase.dart';
import '../../domain/usecases/share_recipe_usecase.dart';
import '../../domain/usecases/toggle_shared_recipe_like_usecase.dart';
import '../../domain/usecases/unshare_recipe_usecase.dart';
import '../../domain/usecases/update_shared_recipe_usecase.dart';

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
  const factory SharedRecipesEvent.updateShared(String id, RecipeEntity recipe) =
      _UpdateShared;
  const factory SharedRecipesEvent.unshare(String id) = _Unshare;
  const factory SharedRecipesEvent.importToMyRecipes(SharedRecipeEntity shared) = _Import;
}

@freezed
sealed class SharedRecipesState with _$SharedRecipesState {
  const factory SharedRecipesState.loading() = SharedRecipesLoading;
  const factory SharedRecipesState.loaded(
    List<SharedRecipeEntity> recipes, {
    @Default(false) bool imported,
    /// Feed ids the user already has a local copy of, so the saved filter and
    /// the save button can reflect it.
    @Default(<String>{}) Set<String> savedIds,
  }) = SharedRecipesLoaded;
  const factory SharedRecipesState.errorMessage(String error) = SharedRecipesError;
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
    on<_ToggleLike>(_toggleLike);
    on<_UpdateShared>(_updateShared);
    on<_Unshare>(_unshare);
    on<_Import>(_import);
    add(const SharedRecipesEvent.init());
  }

  factory SharedRecipesBloc.fromContext(BuildContext context) {
    return SharedRecipesBloc(
      getSharedRecipesUseCase: GetSharedRecipesUseCase(context.read()),
      shareRecipeUseCase: ShareRecipeUseCase(context.read()),
      toggleLikeUseCase: ToggleSharedRecipeLikeUseCase(context.read()),
      unshareRecipeUseCase: UnshareRecipeUseCase(context.read()),
      updateSharedRecipeUseCase: UpdateSharedRecipeUseCase(context.read()),
      saveRecipeUseCase: SaveRecipeUseCase(context.read()),
      getRecipesUseCase: GetRecipesUseCase(context.read()),
      recipesRepository: context.read(),
    );
  }

  String get _uid => AuthSessionService().user?.uid ?? '';

  Future<void> _init(_Init event, Emitter<SharedRecipesState> emit) async {
    try {
      _feed = await getSharedRecipesUseCase(viewerUid: _uid);
      await _refreshSavedIds();
      emit(.loaded(_feed, savedIds: _savedIds));
    } catch (e) {
      debugPrint('Shared recipes error: $e');
      emit(.errorMessage(e.toString()));
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

  Future<void> _refresh(_Refresh event, Emitter<SharedRecipesState> emit) async {
    try {
      await _init(const _Init(), emit);
    } finally {
      if (!event.done.isCompleted) event.done.complete();
    }
  }

  Future<void> _share(_Share event, Emitter<SharedRecipesState> emit) async {
    final profile = AuthSessionService().profile;
    try {
      await shareRecipeUseCase(
        event.recipe,
        authorUid: _uid,
        authorName: profile?.fullName ?? '',
        authorPhotoUrl: profile?.photoUrl,
      );
      await _init(const _Init(), emit);
    } catch (e) {
      debugPrint('Share recipe error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  /// The row flips before the write lands so the tap feels immediate, and is
  /// put back if the transaction fails.
  Future<void> _toggleLike(_ToggleLike event, Emitter<SharedRecipesState> emit) async {
    final index = _feed.indexWhere((r) => r.id == event.id);
    if (index == -1) return;

    final original = _feed[index];
    final optimistic = original.copyWith(
      likedByMe: !original.likedByMe,
      likeCount: original.likeCount + (original.likedByMe ? -1 : 1),
    );
    _feed = [..._feed]..[index] = optimistic;
    emit(.loaded(_feed, savedIds: _savedIds));

    try {
      await toggleLikeUseCase(event.id, viewerUid: _uid);
    } catch (e) {
      debugPrint('Like failed: $e');
      _feed = [..._feed]..[index] = original;
      emit(.loaded(_feed, savedIds: _savedIds));
    }
  }

  /// The edited recipe replaces the row in place rather than reloading the
  /// feed, so the list does not jump while the user is looking at it.
  Future<void> _updateShared(_UpdateShared event, Emitter<SharedRecipesState> emit) async {
    final index = _feed.indexWhere((r) => r.id == event.id);
    if (index == -1) return;

    try {
      await updateSharedRecipeUseCase(event.id, event.recipe);
      _feed = [..._feed]..[index] = _feed[index].copyWith(recipe: event.recipe);
      emit(.loaded(_feed, savedIds: _savedIds));
    } catch (e) {
      debugPrint('Update shared recipe error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _unshare(_Unshare event, Emitter<SharedRecipesState> emit) async {
    try {
      await unshareRecipeUseCase(event.id);
      _feed = _feed.where((r) => r.id != event.id).toList();
      emit(.loaded(_feed, savedIds: _savedIds));
    } catch (e) {
      debugPrint('Unshare error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  /// Delegates to the shared import so the feed and a forum reply's recipe
  /// link save exactly the same way — and neither makes a second copy.
  Future<void> _import(_Import event, Emitter<SharedRecipesState> emit) async {
    await ImportSharedRecipeUseCase(recipesRepository)(event.shared);
    await _refreshSavedIds();
    emit(.loaded(_feed, imported: true, savedIds: _savedIds));
  }
}
