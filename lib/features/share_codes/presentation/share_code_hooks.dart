import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/monetization/share_gates.dart';
import '../../../core/monetization/share_usage_service.dart';
import '../../collab_containers/domain/container_sharing_service.dart';
import '../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import '../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../domain/share_code_entity.dart';
import '../domain/share_code_service.dart';

/// What the share sheet needs from the item behind it, for the code mode
/// and the free-tier allowance: the sheet stays one widget for recipes,
/// books and plans.
class ShareCodeHooks {
  /// The free-tier allowance, asked before a contact invite or a new code.
  /// Explains and offers Premium itself; false means do not go on.
  final Future<bool> Function(BuildContext context, String uid) gate;

  /// A share went out (an invite or a new code); the recipe counter moves.
  final Future<void> Function() recordShare;

  final Future<ShareCodeEntity> Function({
    required CollabRole role,
    required String uid,
  })
  create;
  final Future<List<ShareCodeEntity>> Function(String uid) active;
  final Future<void> Function(ShareCodeEntity code) revoke;

  const ShareCodeHooks({
    required this.gate,
    required this.recordShare,
    required this.create,
    required this.active,
    required this.revoke,
  });

  factory ShareCodeHooks.recipe(BuildContext context, RecipeEntity recipe) {
    final service = context.read<ShareCodeService>();
    return ShareCodeHooks(
      gate: (context, _) => ShareGates.recipe(context),
      recordShare: ShareUsageService().recordRecipeShare,
      create: ({required role, required uid}) =>
          service.createForRecipe(recipe, role: role, uid: uid),
      active: (uid) => service.activeFor(recipe.collabId, uid: uid),
      revoke: service.revoke,
    );
  }

  factory ShareCodeHooks.book(BuildContext context, RecipeBookEntity book) {
    final service = context.read<ShareCodeService>();
    final containers = context.read<ContainerSharingService>();
    return ShareCodeHooks(
      gate: (context, uid) async {
        // An already shared book holds its slot; only a new one is counted.
        // Asked of the stored copy: the sheet holds the book as it opened,
        // before its first code or invite made it shared.
        if (await _shared(() => containers.books.adapter.byId(book.id), book)) {
          return true;
        }
        final shared = await _ownedCount(containers, uid, CollabKind.book);
        if (!context.mounted) return false;
        return ShareGates.book(context, sharedNow: shared);
      },
      recordShare: () async {},
      create: ({required role, required uid}) =>
          service.createForBook(book, role: role, uid: uid),
      active: (uid) => service.activeFor(book.collabId, uid: uid),
      revoke: service.revoke,
    );
  }

  factory ShareCodeHooks.plan(BuildContext context, MealPlanEntity plan) {
    final service = context.read<ShareCodeService>();
    final containers = context.read<ContainerSharingService>();
    return ShareCodeHooks(
      gate: (context, uid) async {
        if (await _shared(() => containers.plans.adapter.byId(plan.id), plan)) {
          return true;
        }
        final shared = await _ownedCount(containers, uid, CollabKind.mealPlan);
        if (!context.mounted) return false;
        return ShareGates.plan(context, sharedNow: shared);
      },
      recordShare: () async {},
      create: ({required role, required uid}) =>
          service.createForPlan(plan, role: role, uid: uid),
      active: (uid) => service.activeFor(plan.collabId, uid: uid),
      revoke: service.revoke,
    );
  }

  factory ShareCodeHooks.list(BuildContext context, GroceryListEntity list) {
    final service = context.read<ShareCodeService>();
    final containers = context.read<ContainerSharingService>();
    return ShareCodeHooks(
      gate: (context, uid) async {
        if (await _shared(() => containers.lists.adapter.byId(list.id), list)) {
          return true;
        }
        final shared = await _ownedCount(
          containers,
          uid,
          CollabKind.groceryList,
        );
        if (!context.mounted) return false;
        return ShareGates.list(context, sharedNow: shared);
      },
      recordShare: () async {},
      create: ({required role, required uid}) =>
          service.createForList(list, role: role, uid: uid),
      active: (uid) => service.activeFor(list.collabId, uid: uid),
      revoke: service.revoke,
    );
  }

  /// Whether [held] (as the sheet opened with it) or its stored copy is
  /// already shared.
  static Future<bool> _shared(
    Future<Object?> Function() stored,
    Object held,
  ) async {
    String? collabOf(Object? item) => switch (item) {
      RecipeBookEntity(:final collabId) => collabId,
      MealPlanEntity(:final collabId) => collabId,
      GroceryListEntity(:final collabId) => collabId,
      _ => null,
    };
    if (collabOf(held) != null) return true;
    // Read only when needed: started up front, a held copy that was
    // already shared left the read unawaited, and its error unhandled.
    return collabOf(await stored()) != null;
  }

  static Future<int> _ownedCount(
    ContainerSharingService containers,
    String uid,
    CollabKind kind,
  ) async {
    final owned = await containers.ownedBy(uid);
    return owned.where((c) => c.kind == kind).length;
  }
}
