import '../../../core/constants/app_enums.dart';
import '../../collab_containers/domain/container_sharing_service.dart';
import '../../household/domain/household_entity.dart';
import '../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import '../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import '../../recipe_sharing/domain/usecases/share_recipe_usecase.dart';
import '../../user_profile/domain/repositories/user_profile_repository.dart';
import 'share_code_entity.dart';
import 'share_codes_repository.dart';

/// What joining by code ended with, for the screen to word.
class JoinResult {
  final String title;
  final CollabKind kind;
  final bool alreadyMember;
  const JoinResult({
    required this.title,
    required this.kind,
    this.alreadyMember = false,
  });
}

/// Codes on top of the invite machinery: creating one makes the item
/// shareable exactly as inviting a contact would, and redeeming one accepts
/// the invite the server wrote, so the copy lands like any other.
class ShareCodeService {
  final ShareCodesRepository codes;
  final ContainerSharingService containers;
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;
  final UserProfileRepository profiles;

  ShareCodeService({
    required this.codes,
    required this.containers,
    required this.sharing,
    required this.recipes,
    required this.profiles,
  });

  late final ShareRecipeUseCase _recipeShare = ShareRecipeUseCase(
    sharing: sharing,
    profiles: profiles,
    recipes: recipes,
  );

  Future<ShareCodeEntity> createForRecipe(
    RecipeEntity recipe, {
    required CollabRole role,
    required String uid,
  }) async {
    final (owned, collabId) = await _recipeShare.prepare(recipe, ownerUid: uid);
    return codes.create(
      kind: CollabKind.recipe,
      targetId: collabId,
      ownerUid: uid,
      role: role,
      title: owned.title,
    );
  }

  Future<ShareCodeEntity> createForBook(
    RecipeBookEntity book, {
    required CollabRole role,
    required String uid,
  }) async {
    final prepared = await containers.books.ensureContainer(
      book,
      ownerUid: uid,
    );
    return codes.create(
      kind: CollabKind.book,
      targetId: prepared.container.id,
      ownerUid: uid,
      role: role,
      title: prepared.container.title,
    );
  }

  Future<ShareCodeEntity> createForPlan(
    MealPlanEntity plan, {
    required CollabRole role,
    required String uid,
  }) async {
    final prepared = await containers.plans.ensureContainer(
      plan,
      ownerUid: uid,
    );
    return codes.create(
      kind: CollabKind.mealPlan,
      targetId: prepared.container.id,
      ownerUid: uid,
      role: role,
      title: prepared.container.title,
    );
  }

  /// The owner's live codes for an item that is already shared; an item
  /// without a collab id has none.
  Future<List<ShareCodeEntity>> activeFor(
    String? targetId, {
    required String uid,
  }) => targetId == null
      ? Future.value(const [])
      : codes.activeCodesFor(targetId, ownerUid: uid);

  Future<void> revoke(ShareCodeEntity code) => codes.revoke(code.code);

  /// Redeems whatever was typed, pasted or scanned and accepts the invite,
  /// so the recipe, book or plan is on the device when this returns.
  /// Throws [ShareCodeRefused].
  Future<JoinResult> join(String raw, {required String uid}) async {
    final code = ShareCodeEntity.parse(raw);
    if (code == null) throw const ShareCodeRefused(ShareCodeRefused.invalid);
    final outcome = await codes.redeem(code);
    if (outcome.householdTitle case final title?) {
      return JoinResult(title: title, kind: CollabKind.household);
    }
    final invite = outcome.invite;
    if (outcome.alreadyMember || invite == null) {
      return const JoinResult(
        title: '',
        kind: CollabKind.recipe,
        alreadyMember: true,
      );
    }
    switch (invite.kind) {
      case CollabKind.recipe:
        final local = await RespondToShareInviteUseCase(
          sharing: sharing,
          recipes: recipes,
        ).accept(invite);
        return JoinResult(title: local.title, kind: invite.kind);
      case CollabKind.book:
      case CollabKind.mealPlan:
        await containers.accept(invite, uid: uid);
        return JoinResult(title: invite.recipeTitle, kind: invite.kind);
      case CollabKind.household:
        // The server answers a household code with `household`, never an
        // invite; reaching here means an older server.
        throw const ShareCodeRefused(ShareCodeRefused.invalid);
    }
  }

  /// An invitation into the owner's household: whoever redeems it takes a
  /// seat. One code per household is enough, so a live one is reused.
  Future<ShareCodeEntity> createForHousehold(
    HouseholdEntity household, {
    required String uid,
  }) async {
    final live = await codes.activeCodesFor(household.id, ownerUid: uid);
    if (live.isNotEmpty) return live.first;
    return codes.create(
      kind: CollabKind.household,
      targetId: household.id,
      ownerUid: uid,
      role: CollabRole.viewer,
      title: household.title,
    );
  }
}
