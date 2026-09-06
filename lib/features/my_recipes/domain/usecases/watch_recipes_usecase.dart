import '../entities/recipe_entity.dart';
import '../repositories/recipes_repository.dart';

class WatchRecipesUseCase {
  final RecipesRepository repository;
  WatchRecipesUseCase(this.repository);

  Stream<List<RecipeEntity>> call() => repository.watchRecipes();
}
