import 'package:uuid/uuid.dart';

import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
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
    final local = RecipeEntity(
      id: _uuid.v4(),
      title: collab.recipe.title,
      prepTimeMinutes: collab.recipe.prepTimeMinutes,
      cookTimeMinutes: collab.recipe.cookTimeMinutes,
      ingredients: collab.recipe.ingredients,
      steps: collab.recipe.steps,
      dietaryTags: collab.recipe.dietaryTags,
      // The owner's photo comes across as a Storage path; the file lands on
      // this device the first time the recipe is drawn, and is read from disk
      // after that.
      imageFileName: collab.recipe.imageFileName,
      imageStoragePath: collab.recipe.imageStoragePath,
      collabId: collab.id,
      collabRole: invite.role,
      createdAt: DateTime.now(),
    );
    await recipes.saveRecipe(local);
    return local;
  }

  Future<void> decline(ShareInviteEntity invite) => sharing.declineInvite(invite);
}
