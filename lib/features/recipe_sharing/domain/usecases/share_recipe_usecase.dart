import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../repositories/recipe_sharing_repository.dart';

/// Reasons a share cannot go ahead, surfaced by code so the sheet can word
/// each one.
class ShareFailure implements Exception {
  final String code;
  const ShareFailure(this.code);

  static const notFound = 'contact-not-found';
  static const self = 'cannot-share-with-self';
  static const invalid = 'invalid-contact';

  @override
  String toString() => 'ShareFailure($code)';
}

/// Look the contact up, make the recipe shared if it is not yet, invite.
///
/// The owner's local copy is updated with the collab id and the owner role
/// before the invite goes out, so a crash between the two leaves a shareable
/// recipe rather than an orphaned shared document.
class ShareRecipeUseCase {
  final RecipeSharingRepository sharing;
  final UserProfileRepository profiles;
  final RecipesRepository recipes;

  ShareRecipeUseCase({
    required this.sharing,
    required this.profiles,
    required this.recipes,
  });

  Future<RecipeEntity> call(
    RecipeEntity recipe, {
    required String contact,
    required CollabRole role,
    required String ownerUid,
  }) async {
    assert(role != CollabRole.owner, 'an invite grants viewer or editor only');

    String? targetUid;
    try {
      targetUid = await profiles.findUidByContact(contact);
    } on AppException {
      rethrow;
    }
    if (targetUid == null) throw const ShareFailure(ShareFailure.notFound);
    if (targetUid == ownerUid) throw const ShareFailure(ShareFailure.self);

    final collabId = await sharing.ensureCollab(recipe, ownerUid: ownerUid);
    final owned = recipe.copyWith(collabId: collabId, collabRole: CollabRole.owner);
    if (recipe.collabId == null) await recipes.saveRecipe(owned);

    await sharing.invite(
      collabId: collabId,
      recipeTitle: recipe.title,
      ownerUid: ownerUid,
      targetUid: targetUid,
      role: role,
    );
    return owned;
  }
}
