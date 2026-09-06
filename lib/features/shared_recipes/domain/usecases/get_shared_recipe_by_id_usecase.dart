import '../entities/shared_recipe_entity.dart';
import '../repositories/shared_recipes_repository.dart';

class GetSharedRecipeByIdUseCase {
  final SharedRecipesRepository repository;
  GetSharedRecipeByIdUseCase(this.repository);

  Future<SharedRecipeEntity?> call(String id, {required String viewerUid}) =>
      repository.getById(id, viewerUid: viewerUid);
}
