import '../entities/collab_recipe_entity.dart';
import '../repositories/recipe_sharing_repository.dart';

class GetMyCollabsUseCase {
  final RecipeSharingRepository repository;
  GetMyCollabsUseCase(this.repository);

  Future<List<CollabRecipeEntity>> owned(String uid) => repository.collabsOwnedBy(uid);
  Future<List<CollabRecipeEntity>> sharedWithMe(String uid) => repository.collabsSharedWith(uid);
}
