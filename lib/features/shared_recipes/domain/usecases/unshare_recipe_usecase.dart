import '../repositories/shared_recipes_repository.dart';
import '../shared_feed_changes.dart';

class UnshareRecipeUseCase {
  final SharedRecipesRepository repository;
  UnshareRecipeUseCase(this.repository);

  Future<void> call(String sharedRecipeId) async {
    await repository.unshare(sharedRecipeId);
    SharedFeedChanges.instance.notify(sharedRecipeId);
  }
}
