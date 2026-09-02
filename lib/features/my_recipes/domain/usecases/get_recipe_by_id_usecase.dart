import '../entities/recipe_entity.dart';
import '../repositories/recipes_repository.dart';

class GetRecipeByIdUseCase {
  final RecipesRepository repository;
  GetRecipeByIdUseCase(this.repository);

  Future<RecipeEntity?> call(String id) => repository.getRecipeById(id);
}
