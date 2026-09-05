import '../entities/shared_recipe_entity.dart';
import '../repositories/shared_recipes_repository.dart';

class GetSharedRecipesUseCase {
  final SharedRecipesRepository repository;
  GetSharedRecipesUseCase(this.repository);

  Future<List<SharedRecipeEntity>> call({required String viewerUid, int limit = 50}) =>
      repository.getFeed(viewerUid: viewerUid, limit: limit);
}
