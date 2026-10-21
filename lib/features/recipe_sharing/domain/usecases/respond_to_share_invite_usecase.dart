import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../data/datasources/pending_accepts_store.dart';
import '../entities/collab_recipe_entity.dart';
import '../entities/share_invite_entity.dart';
import '../repositories/recipe_sharing_repository.dart';
import '../scope_check.dart';
import 'sync_collab_recipe_usecase.dart';

/// Accepting creates the local cache of the shared recipe under a fresh id,
/// tagged with the collab id and the granted role — or, when this account
/// already holds a copy of that document (accepted on another device, or
/// re-invited after being removed), lays the document over that copy so
/// the recipe never appears twice. Declining only marks the invite; nothing
/// is written locally.
class RespondToShareInviteUseCase {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;
  final PendingAcceptsStore pending;

  /// How long the server is given for the accept (two writes and a read).
  /// Offline, Firestore queues the writes and never completes them, and the
  /// inbox spun for as long as the device had no connection. Past this the
  /// accept is reported as queued; the mark in [pending] has the copy
  /// written by the next refresh.
  final Duration remoteTimeout;
  static const _uuid = Uuid();

  RespondToShareInviteUseCase({
    required this.sharing,
    required this.recipes,
    PendingAcceptsStore? pending,
    this.remoteTimeout = const Duration(seconds: 15),
  }) : pending = pending ?? HivePendingAcceptsStore.instance;

  Future<RecipeEntity> accept(ShareInviteEntity invite) async {
    // Before the server is asked: a kill or a dropped connection between
    // the roster write and the local save must leave something to finish.
    await pending.add(
      PendingAccept(
        collabId: invite.collabId,
        kind: CollabKind.recipe,
        at: DateTime.now(),
      ),
    );
    final CollabRecipeEntity collab;
    try {
      collab = await sharing.acceptInvite(invite).timeout(remoteTimeout);
    } on TimeoutException {
      throw const AppException(
        AppErrorType.networkError,
        message: RecipeSharingRepository.acceptQueued,
      );
    } catch (e) {
      // Gone for good: the repository closed the invite, nothing to finish.
      if (RecipeSharingRepository.isCollabMissing(e)) {
        await pending.remove(invite.collabId);
      }
      rethrow;
    }
    final existing = (await recipes.getRecipes())
        .where((r) => r.collabId == collab.id)
        .firstOrNull;
    // The role comes from the invite, not the roster: the document read
    // back a moment after joining may not show the new member yet.
    final local = existing == null
        ? localCopy(collab, role: invite.role)
        : SyncCollabRecipeUseCase.merged(
            existing,
            collab,
            uid: invite.targetUid,
          ).copyWith(collabRole: invite.role);
    await recipes.saveRecipe(local);
    await pending.remove(invite.collabId);
    return local;
  }

  /// Writes the copies the marks in [pending] still owe: the accepts that
  /// timed out (or died) after the server had them. One that can be read
  /// now — the roster write landed — gets its copy; one refused or gone is
  /// dropped; one still unreadable waits for the next pass, up to
  /// [PendingAccept.giveUpAfter]. Only recipe marks; the container kinds are
  /// finished by `ContainerSharingService`.
  static Future<void> repairPending({
    required RecipeSharingRepository sharing,
    required RecipesRepository recipes,
    required PendingAcceptsStore pending,
    required String uid,
    DateTime? now,
    ScopeCheck stillSignedIn = scopedTo,
  }) async {
    final clock = now ?? DateTime.now();
    if (!stillSignedIn(uid)) return;
    final due = [
      for (final mark in await pending.all())
        if (mark.kind == CollabKind.recipe && mark.isDue(clock)) mark,
    ];
    if (due.isEmpty) return;
    final cached = await recipes.getRecipes();
    for (final mark in due) {
      // The copy is there after all: a retry of the accept, or the mirror
      // carrying another device's copy in.
      if (cached.any((r) => r.collabId == mark.collabId) ||
          mark.isStale(clock)) {
        await pending.remove(mark.collabId);
        continue;
      }
      try {
        final collab = await sharing.getCollab(mark.collabId);
        // Another account signed in meanwhile: its boxes are not this
        // mark's to write, and the mark itself waits for its own account.
        if (!stillSignedIn(uid)) return;
        if (collab != null) {
          await recipes.saveRecipe(
            localCopy(collab, role: collab.roleOf(uid)),
          );
        }
        // Null: deleted by the owner. Either way the mark is done.
        await pending.remove(mark.collabId);
      } catch (e) {
        // The rules refuse the read while the queued join has not landed
        // (or because the owner removed this account since), or the
        // network is away again: the next pass looks once more.
        debugPrint('Pending accept ${mark.collabId} not finished: $e');
      }
    }
  }

  /// This account's cache of [collab], under a fresh id. Shared with the
  /// book and plan flows, which let a member into every recipe inside.
  static RecipeEntity localCopy(
    CollabRecipeEntity collab, {
    required CollabRole role,
  }) {
    return RecipeEntity(
      id: _uuid.v4(),
      title: collab.recipe.title,
      prepTimeMinutes: collab.recipe.prepTimeMinutes,
      cookTimeMinutes: collab.recipe.cookTimeMinutes,
      ingredients: collab.recipe.ingredients,
      steps: collab.recipe.steps,
      dietaryTags: collab.recipe.dietaryTags,
      allergens: collab.recipe.allergens,
      mayContain: collab.recipe.mayContain,
      // The owner's photo comes across as a Storage path; the file lands on
      // this device the first time the recipe is drawn, and is read from disk
      // after that.
      imageFileName: collab.recipe.imageFileName,
      imageStoragePath: collab.recipe.imageStoragePath,
      servings: collab.recipe.servings,
      nutrition: collab.recipe.nutrition,
      collabId: collab.id,
      collabRole: role,
      createdAt: DateTime.now(),
    );
  }

  Future<void> decline(ShareInviteEntity invite) =>
      sharing.declineInvite(invite);
}
