import 'package:flutter/foundation.dart';

import '../../../core/constants/app_enums.dart';
import '../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../recipe_sharing/data/datasources/pending_accepts_store.dart';
import '../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../recipe_sharing/domain/scope_check.dart';
import '../../user_profile/domain/repositories/user_profile_repository.dart';
import 'container_adapter.dart';
import 'entities/collab_container_entity.dart';
import 'repositories/collab_containers_repository.dart';
import 'usecases/container_collab.dart';
import 'usecases/recipe_linker.dart';

/// One door to shared books and plans for the screens and the session:
/// the two [ContainerCollab]s behind it, plus what spans both kinds.
class ContainerSharingService {
  final CollabContainersRepository containers;
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;
  final UserProfileRepository profiles;
  final RecipeBooksRepository booksRepository;
  final MealPlansRepository plansRepository;
  final GroceryListsRepository listsRepository;

  /// The accepts this device still owes a local copy for; the device store
  /// when not given (tests pass their own).
  final PendingAcceptsStore? pending;

  /// Whether a uid is still the account signed in; see [scopedTo]. Handed
  /// to every writer below, so a pull that outlives its account stops.
  final ScopeCheck stillSignedIn;

  late final RecipeLinker _linker = RecipeLinker(
    sharing: sharing,
    recipes: recipes,
    containers: containers,
    pending: pending,
  );
  late final ContainerCollab<RecipeBookEntity> books = ContainerCollab(
    adapter: BookContainerAdapter(booksRepository),
    containers: containers,
    linker: _linker,
    profiles: profiles,
    pending: pending,
    stillSignedIn: stillSignedIn,
  );
  late final ContainerCollab<MealPlanEntity> plans = ContainerCollab(
    adapter: PlanContainerAdapter(plansRepository),
    containers: containers,
    linker: _linker,
    profiles: profiles,
    pending: pending,
    stillSignedIn: stillSignedIn,
  );
  late final ContainerCollab<GroceryListEntity> lists = ContainerCollab(
    adapter: GroceryListContainerAdapter(listsRepository),
    containers: containers,
    linker: _linker,
    profiles: profiles,
    pending: pending,
    stillSignedIn: stillSignedIn,
  );

  ContainerSharingService({
    required this.containers,
    required this.sharing,
    required this.recipes,
    required this.profiles,
    required this.booksRepository,
    required this.plansRepository,
    required this.listsRepository,
    this.pending,
    this.stillSignedIn = scopedTo,
  });

  /// Both queries once, then each kind refreshed from the same answer.
  /// Returns how many local copies were rewritten.
  Future<int> refreshAll({required String uid}) async {
    await repairPending(uid: uid);
    if (!stillSignedIn(uid)) return 0;
    final fetched = await Future.wait([
      containers.ownedBy(uid),
      containers.sharedWith(uid),
    ]);
    // Another account signed in while the queries were out: these are
    // not its documents, and its boxes are not theirs to be written into
    // (each kind's refresh checks again before every copy).
    if (!stillSignedIn(uid)) return 0;
    final all = fetched.expand((list) => list).toList();
    return await books.refresh(all, uid: uid) +
        await plans.refresh(all, uid: uid) +
        await lists.refresh(all, uid: uid);
  }

  /// Finishes the container accepts that timed out (or died) after the
  /// server had them: the copy is written now that the document can be
  /// read; a document gone or refused for a week is given up. Mirrors
  /// RespondToShareInviteUseCase.repairPending for recipes.
  Future<void> repairPending({required String uid, DateTime? now}) async {
    final store = pending ?? HivePendingAcceptsStore.instance;
    final clock = now ?? DateTime.now();
    for (final mark in await store.all()) {
      // The marks are the signed-in account's; another account's pull
      // leaves them for their own.
      if (!stillSignedIn(uid)) return;
      final ContainerCollab<Object> collab;
      switch (mark.kind) {
        case CollabKind.book:
          collab = books;
        case CollabKind.mealPlan:
          collab = plans;
        case CollabKind.groceryList:
          collab = lists;
        case CollabKind.recipe:
        case CollabKind.household:
          continue;
      }
      if (!mark.isDue(clock)) continue;
      try {
        if (mark.isStale(clock) || await collab.holds(mark.collabId)) {
          await store.remove(mark.collabId);
          continue;
        }
        final container = await containers.get(mark.collabId);
        if (container != null) await collab.adopt(container, uid: uid);
        await store.remove(mark.collabId);
      } catch (e) {
        // Refused while the queued join has not landed, or offline again:
        // the next pass looks once more.
        debugPrint('Pending ${mark.kind.name} accept ${mark.collabId}: $e');
      }
    }
  }

  /// Accepts a book or plan invite; returns the local copy, typed by kind.
  Future<Object> accept(ShareInviteEntity invite, {required String uid}) =>
      switch (invite.kind) {
        CollabKind.book => books.accept(invite, uid: uid),
        CollabKind.mealPlan => plans.accept(invite, uid: uid),
        CollabKind.groceryList => lists.accept(invite, uid: uid),
        CollabKind.recipe => throw ArgumentError(
          'recipe invites go through RespondToShareInviteUseCase',
        ),
        CollabKind.household => throw ArgumentError(
          'a household is joined by code, never by invite',
        ),
      };

  Future<void> decline(ShareInviteEntity invite) =>
      containers.declineInvite(invite);

  /// The owner revoking someone, or a member leaving — from the container
  /// and, best effort, from each shared recipe in it this account may
  /// remove them from.
  ///
  /// [revokeInvite] is the owner removing someone (never a member leaving):
  /// their invites to the container and to each of its recipes are deleted
  /// too, or the accepted ones would let them rejoin on their own.
  Future<void> removeMember(
    String containerId,
    String memberUid, {
    bool revokeInvite = false,
  }) async {
    final container = await containers.get(containerId);
    await containers.removeMember(
      containerId,
      memberUid,
      revokeInvite: revokeInvite,
    );
    if (container == null) return;
    // Deliberate, pending a product decision: leaving (or being removed
    // from) a book or plan also removes the member from every recipe in
    // it, including ones they were also invited to directly.
    // All at once: one awaited round trip per recipe made leaving a book
    // of a few hundred take tens of seconds behind the busy spinner.
    await Future.wait([
      for (final recipeCollabId in container.recipeCollabIds)
        sharing
            .removeMember(
              recipeCollabId,
              memberUid,
              revokeInvite: revokeInvite,
            )
            .catchError(
              // Owned by another editor: only they may change its roster.
              (Object e) =>
                  debugPrint('Recipe $recipeCollabId roster untouched: $e'),
            ),
    ]);
  }

  Future<List<CollabContainerEntity>> ownedBy(String uid) =>
      containers.ownedBy(uid);
  Future<List<CollabContainerEntity>> sharedWith(String uid) =>
      containers.sharedWith(uid);
}
