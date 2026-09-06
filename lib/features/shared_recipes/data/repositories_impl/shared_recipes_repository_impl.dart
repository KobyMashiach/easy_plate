import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/shared_recipe_entity.dart';
import '../../domain/repositories/shared_recipes_repository.dart';
import '../datasources/shared_recipes_remote_datasource.dart';

class SharedRecipesRepositoryImpl implements SharedRecipesRepository {
  final SharedRecipesRemoteDataSource remoteDataSource;

  SharedRecipesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<SharedRecipeEntity>> getFeed({required String viewerUid, int limit = 50}) =>
      remoteDataSource.getFeed(viewerUid: viewerUid, limit: limit);

  @override
  Future<SharedRecipeEntity?> getById(String id, {required String viewerUid}) =>
      remoteDataSource.getById(id, viewerUid: viewerUid);

  @override
  Future<void> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) =>
      remoteDataSource.share(
        recipe,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
      );

  @override
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid}) =>
      remoteDataSource.toggleLike(sharedRecipeId, viewerUid: viewerUid);

  @override
  Future<void> updateShared(String sharedRecipeId, RecipeEntity recipe) =>
      remoteDataSource.updateShared(sharedRecipeId, recipe);

  @override
  Future<void> unshare(String sharedRecipeId) => remoteDataSource.unshare(sharedRecipeId);
}
