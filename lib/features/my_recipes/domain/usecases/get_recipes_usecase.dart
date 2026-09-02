import '../entities/recipe_entity.dart';
import '../repositories/recipes_repository.dart';

class GetRecipesUseCase {
  final RecipesRepository repository;
  GetRecipesUseCase(this.repository);

  Future<List<RecipeEntity>> call() => repository.getRecipes();
}
