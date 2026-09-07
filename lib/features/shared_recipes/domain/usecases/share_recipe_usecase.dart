import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/shared_recipes_repository.dart';

class ShareRecipeUseCase {
  final SharedRecipesRepository repository;

  /// Only for [RecipesRepository.readyForSharing]. A save uploads the photo in
  /// the background, so a recipe published moments after the picture was picked
  /// would go into the feed with no image path — and the post is a snapshot,
  /// so it would stay pictureless even once the upload finished.
  final RecipesRepository recipes;

  ShareRecipeUseCase(this.repository, this.recipes);

  Future<void> call(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async {
    final ready = await recipes.readyForSharing(recipe);
    return repository.share(
      ready,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
    );
  }
}
