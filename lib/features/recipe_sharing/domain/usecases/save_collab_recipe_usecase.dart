import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/recipe_sharing_repository.dart';

/// A save on a shared recipe goes to the shared document first, then to the
/// local cache — so a rejected remote write never leaves the cache ahead of
/// the truth. Viewers are refused here as well as in the UI and the rules.
class SaveCollabRecipeUseCase {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;

  SaveCollabRecipeUseCase({required this.sharing, required this.recipes});

  Future<void> call(RecipeEntity recipe, {required String byUid}) async {
    final collabId = recipe.collabId;
    if (collabId == null) {
      await recipes.saveRecipe(recipe);
      return;
    }
    if (recipe.collabRole == CollabRole.viewer) {
      throw const AppException(AppErrorType.unauthorized, message: 'viewer-cannot-edit');
    }
    await sharing.writeCollab(collabId, recipe, byUid: byUid);
    await recipes.saveRecipe(recipe);
  }
}
