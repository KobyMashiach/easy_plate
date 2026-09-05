import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/shared_recipes_repository.dart';

class ShareRecipeUseCase {
  final SharedRecipesRepository repository;
  ShareRecipeUseCase(this.repository);

  Future<void> call(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) =>
      repository.share(
        recipe,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );
}
