import '../../domain/entities/recipe_entity.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../datasources/recipes_local_datasource.dart';
import '../models/recipe_model.dart';

class RecipesRepositoryImpl implements RecipesRepository {
  final RecipesLocalDataSource localDataSource;

  RecipesRepositoryImpl({required this.localDataSource});

  @override
  Future<List<RecipeEntity>> getRecipes() async {
    final models = await localDataSource.getRecipes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<RecipeEntity?> getRecipeById(String id) async {
    final model = await localDataSource.getRecipeById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveRecipe(RecipeEntity recipe) {
    return localDataSource.saveRecipe(recipe.toModel());
  }

  @override
  Future<void> deleteRecipe(String id) {
    return localDataSource.deleteRecipe(id);
  }
}
