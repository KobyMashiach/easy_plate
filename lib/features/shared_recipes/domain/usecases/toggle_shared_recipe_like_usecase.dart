import '../repositories/shared_recipes_repository.dart';

class ToggleSharedRecipeLikeUseCase {
  final SharedRecipesRepository repository;
  ToggleSharedRecipeLikeUseCase(this.repository);

  Future<bool> call(String sharedRecipeId, {required String viewerUid}) =>
      repository.toggleLike(sharedRecipeId, viewerUid: viewerUid);
}
