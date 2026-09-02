import '../repositories/recipes_repository.dart';

class DeleteRecipeUseCase {
  final RecipesRepository repository;
  DeleteRecipeUseCase(this.repository);

  Future<void> call(String id) => repository.deleteRecipe(id);
}
