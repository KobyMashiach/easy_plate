import '../repositories/shared_recipes_repository.dart';

class UnshareRecipeUseCase {
  final SharedRecipesRepository repository;
  UnshareRecipeUseCase(this.repository);

  Future<void> call(String sharedRecipeId) => repository.unshare(sharedRecipeId);
}
