import 'package:flutter/foundation.dart';

import '../../../core/constants/app_enums.dart';
import '../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
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

  late final RecipeLinker _linker = RecipeLinker(
    sharing: sharing,
    recipes: recipes,
    containers: containers,
  );
  late final ContainerCollab<RecipeBookEntity> books = ContainerCollab(
    adapter: BookContainerAdapter(booksRepository),
    containers: containers,
    linker: _linker,
    profiles: profiles,
  );
  late final ContainerCollab<MealPlanEntity> plans = ContainerCollab(
    adapter: PlanContainerAdapter(plansRepository),
    containers: containers,
    linker: _linker,
    profiles: profiles,
  );

  ContainerSharingService({
    required this.containers,
    required this.sharing,
    required this.recipes,
    required this.profiles,
    required this.booksRepository,
    required this.plansRepository,
  });

  /// Both queries once, then each kind refreshed from the same answer.
  /// Returns how many local copies were rewritten.
  Future<int> refreshAll({required String uid}) async {
    final fetched = await Future.wait([
      containers.ownedBy(uid),
      containers.sharedWith(uid),
    ]);
    final all = fetched.expand((list) => list).toList();
    return await books.refresh(all, uid: uid) +
        await plans.refresh(all, uid: uid);
  }

  /// Accepts a book or plan invite; returns the local copy, typed by kind.
  Future<Object> accept(ShareInviteEntity invite, {required String uid}) =>
      switch (invite.kind) {
        CollabKind.book => books.accept(invite, uid: uid),
        CollabKind.mealPlan => plans.accept(invite, uid: uid),
        CollabKind.recipe => throw ArgumentError(
          'recipe invites go through RespondToShareInviteUseCase',
        ),
      };

  Future<void> decline(ShareInviteEntity invite) =>
      containers.declineInvite(invite);

  /// The owner revoking someone, or a member leaving — from the container
  /// and, best effort, from each shared recipe in it this account may
  /// remove them from.
  Future<void> removeMember(String containerId, String memberUid) async {
    final container = await containers.get(containerId);
    await containers.removeMember(containerId, memberUid);
    if (container == null) return;
    for (final recipeCollabId in container.recipeCollabIds) {
      try {
        await sharing.removeMember(recipeCollabId, memberUid);
      } catch (e) {
        // Owned by another editor: only they may change its roster.
        debugPrint('Recipe $recipeCollabId roster untouched: $e');
      }
    }
  }

  Future<List<CollabContainerEntity>> ownedBy(String uid) =>
      containers.ownedBy(uid);
  Future<List<CollabContainerEntity>> sharedWith(String uid) =>
      containers.sharedWith(uid);
}
