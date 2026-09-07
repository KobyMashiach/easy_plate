import 'dart:async';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/recipe_sharing_repository.dart';

/// A save on a shared recipe goes to the shared document first, then to the
/// local cache — so a rejected remote write never leaves the cache ahead of
/// the truth. Viewers are refused here as well as in the UI and the rules.
class SaveCollabRecipeUseCase {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;

  /// How long the shared write is waited on before the local save goes ahead
  /// anyway.
  ///
  /// Firestore queues a write made offline and does not complete its future
  /// until a server acknowledges it, so an unbounded await leaves the editor
  /// spinning for as long as the device has no connection. The queued write
  /// still lands once it does — which is why a timeout is allowed through,
  /// while any other failure is a real refusal (a viewer, a revoked member)
  /// and must not be cached.
  ///
  /// A parameter rather than a constant so a test can exercise the timeout
  /// without waiting out the real one.
  final Duration remoteWriteTimeout;

  SaveCollabRecipeUseCase({
    required this.sharing,
    required this.recipes,
    this.remoteWriteTimeout = const Duration(seconds: 8),
  });

  /// Returns the recipe as it was actually stored: [readyForSharing] fills in
  /// the photo's Storage path, and a caller holding the pre-upload entity
  /// would hand it back on the next save and upload the same picture again.
  Future<RecipeEntity> call(RecipeEntity recipe, {required String byUid}) async {
    final collabId = recipe.collabId;
    if (collabId == null) {
      await recipes.saveRecipe(recipe);
      return recipe;
    }
    if (recipe.collabRole == CollabRole.viewer) {
      throw const AppException(AppErrorType.unauthorized, message: 'viewer-cannot-edit');
    }
    // A photo added or replaced in the editor has to be uploaded before the
    // shared document is written, or the co-editors get a recipe pointing at a
    // picture that was never sent.
    final ready = await recipes.readyForSharing(recipe);
    try {
      await sharing.writeCollab(collabId, ready, byUid: byUid).timeout(remoteWriteTimeout);
    } on TimeoutException {
      // Queued, not refused. Fall through to the local save.
    }
    await recipes.saveRecipe(ready);
    return ready;
  }
}
