import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../recipe_sharing/data/datasources/pending_accepts_store.dart';
import '../../../recipe_sharing/domain/entities/share_invite_entity.dart';
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

  /// How long a recipe's photo upload may hold a save up. Offline it would
  /// not complete at all, and the save of the whole book or plan with it;
  /// past this the recipe is left out this time and picked up by the next
  /// save (the upload itself finishes and is persisted on its own).
  final Duration remoteTimeout;

  /// Where the recipe accepts inside a container leave their marks (see
  /// [PendingAcceptsStore]); the device store when not given.
  final PendingAcceptsStore? pending;

  const RecipeLinker({
    required this.sharing,
    required this.recipes,
    required this.containers,
    this.remoteTimeout = const Duration(seconds: 8),
    this.pending,
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
      // Deliberate, pending a product decision: a copy saved from the
      // community (not this account's own) is shared on as this account's
      // collab when its book or plan is, like any other recipe in it.
      try {
        final ready = await recipes
            .readyForSharing(recipe)
            .timeout(remoteTimeout);
        final collabId = await sharing.ensureCollab(ready, ownerUid: uid);
        // Only the sharing marks, onto the recipe as stored now: the upload
        // and the document write took a while, and an edit or a translation
        // saved meanwhile must not be undone.
        final current = await recipes.getRecipeById(id) ?? ready;
        await recipes.saveRecipe(
          current.copyWith(collabId: collabId, collabRole: CollabRole.owner),
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
    final missing = {
      for (final collabId in collabIds)
        if (!byCollabId.containsKey(collabId)) collabId,
    };
    if (missing.isEmpty) return byCollabId;
    // One read for every invite still needed, not one per recipe: a book
    // of a hundred recipes waited out a hundred round trips here before
    // its first copy was written.
    final Map<String, ShareInviteEntity> invites;
    try {
      invites = await containers.recipeInvites(collabIds: missing, uid: uid);
    } catch (e) {
      debugPrint('Recipe invites could not be read: $e');
      return byCollabId;
    }
    for (final collabId in missing) {
      try {
        final invite = invites[collabId];
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
            pending: pending,
          ).accept(invite);
          byCollabId[collabId] = local.id;
          continue;
        }
        await recipes.saveRecipe(local);
        byCollabId[collabId] = local.id;
      } catch (e) {
        debugPrint('Shared recipe $collabId could not be fetched: $e');
        // The network went away: every accept left would wait out its own
        // timeout for the same answer. The rest is picked up by the next
        // refresh of the container, like this one's mark.
        if (RecipeSharingRepository.isAcceptQueued(e)) break;
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
