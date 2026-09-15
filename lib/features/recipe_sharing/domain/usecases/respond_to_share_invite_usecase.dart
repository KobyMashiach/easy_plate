import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../entities/collab_recipe_entity.dart';
import '../entities/share_invite_entity.dart';
import '../repositories/recipe_sharing_repository.dart';

/// Accepting creates the local cache of the shared recipe under a fresh id,
/// tagged with the collab id and the granted role. Declining only marks the
/// invite; nothing is written locally.
class RespondToShareInviteUseCase {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;
  static const _uuid = Uuid();

  RespondToShareInviteUseCase({required this.sharing, required this.recipes});

  Future<RecipeEntity> accept(ShareInviteEntity invite) async {
    final collab = await sharing.acceptInvite(invite);
    final local = localCopy(collab, role: invite.role);
    await recipes.saveRecipe(local);
    return local;
  }

  /// This account's cache of [collab], under a fresh id. Shared with the
  /// book and plan flows, which let a member into every recipe inside.
  static RecipeEntity localCopy(CollabRecipeEntity collab, {required CollabRole role}) {
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

  Future<void> decline(ShareInviteEntity invite) => sharing.declineInvite(invite);
}
