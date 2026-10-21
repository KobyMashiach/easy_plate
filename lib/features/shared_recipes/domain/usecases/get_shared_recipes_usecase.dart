import '../entities/shared_recipe_entity.dart';
import '../repositories/shared_recipes_repository.dart';

class GetSharedRecipesUseCase {
  final SharedRecipesRepository repository;
  GetSharedRecipesUseCase(this.repository);

  Future<List<SharedRecipeEntity>> call({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) =>
      repository.getFeed(viewerUid: viewerUid, limit: limit, refresh: refresh);

  /// The viewer's own posts, beyond the feed window.
  Future<List<SharedRecipeEntity>> mine({
    required String viewerUid,
    bool refresh = false,
  }) => repository.getMine(viewerUid: viewerUid, refresh: refresh);

  /// The posts among [ids] that still exist.
  Future<List<SharedRecipeEntity>> byIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  }) => repository.getByIds(ids, viewerUid: viewerUid, refresh: refresh);
}
