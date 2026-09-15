import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../../recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import '../repositories/collab_containers_repository.dart';

/// The recipes behind a shared book or plan, in both directions.
///
/// Outbound, every recipe this account can share becomes a shared recipe
/// (if it is not one yet) so the container can refer to it. Inbound, every
/// shared recipe a container refers to is let in and cached locally, so
/// the container resolves to real recipes on this side.
class RecipeLinker {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;
  final CollabContainersRepository containers;

  const RecipeLinker({
    required this.sharing,
    required this.recipes,
    required this.containers,
  });

  /// Local id → collab id for every recipe in [recipeIds] that is, or can be
  /// made, shared; plus the ones this account owns (the only ones it may
  /// invite others into) and every title, for the encoded plan.
  Future<LinkedRecipes> ensureCollabs(
    List<String> recipeIds, {
    required String uid,
  }) async {
    final byRecipeId = <String, String>{};
    final owned = <RecipeInvite>[];
    final titles = <String, String>{};
    for (final id in recipeIds.toSet()) {
      final recipe = await recipes.getRecipeById(id);
      if (recipe == null) continue;
      titles[id] = recipe.title;
      if (recipe.collabId case final existing?) {
        byRecipeId[id] = existing;
        if (recipe.collabRole == CollabRole.owner) {
          owned.add((collabId: existing, title: recipe.title));
        }
        continue;
      }
      try {
        final ready = await recipes.readyForSharing(recipe);
        final collabId = await sharing.ensureCollab(ready, ownerUid: uid);
        await recipes.saveRecipe(
          ready.copyWith(collabId: collabId, collabRole: CollabRole.owner),
        );
        byRecipeId[id] = collabId;
        owned.add((collabId: collabId, title: recipe.title));
      } catch (e) {
        // Offline, or refused. The recipe stays out of the shared document
        // this time and is picked up by the next save.
        debugPrint('Recipe ${recipe.id} could not be shared: $e');
      }
    }
    return LinkedRecipes(byRecipeId: byRecipeId, owned: owned, titles: titles);
  }

  /// Collab id → local id for every shared recipe in [collabIds] this account
  /// holds or can be let into. A recipe it was never invited to (one an
  /// editor brought in and could not invite it to yet) is left out.
  Future<Map<String, String>> materialize(
    Set<String> collabIds, {
    required String uid,
  }) async {
    final byCollabId = <String, String>{
      for (final recipe in await recipes.getRecipes())
        ?recipe.collabId: recipe.id,
    };
    for (final collabId in collabIds) {
      if (byCollabId.containsKey(collabId)) continue;
      try {
        final invite = await containers.recipeInvite(
          collabId: collabId,
          uid: uid,
        );
        if (invite == null) continue;
        final RecipeEntity local;
        if (invite.status == ShareInviteStatus.accepted) {
          // Joined before, on another device perhaps, but not cached here.
          final collab = await sharing.getCollab(collabId);
          if (collab == null) continue;
          local = RespondToShareInviteUseCase.localCopy(
            collab,
            role: collab.roleOf(uid),
          );
        } else {
          local = await RespondToShareInviteUseCase(
            sharing: sharing,
            recipes: recipes,
          ).accept(invite);
          byCollabId[collabId] = local.id;
          continue;
        }
        await recipes.saveRecipe(local);
        byCollabId[collabId] = local.id;
      } catch (e) {
        debugPrint('Shared recipe $collabId could not be fetched: $e');
      }
    }
    return byCollabId;
  }
}

class LinkedRecipes {
  final Map<String, String> byRecipeId;
  final List<RecipeInvite> owned;
  final Map<String, String> titles;
  const LinkedRecipes({
    required this.byRecipeId,
    required this.owned,
    required this.titles,
  });
}
