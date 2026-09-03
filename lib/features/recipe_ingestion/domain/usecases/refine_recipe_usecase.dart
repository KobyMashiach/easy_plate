import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class RefineRecipeUseCase {
  final RecipeIngestionRepository repository;
  RefineRecipeUseCase(this.repository);

  Future<RecipeEntity> call(RecipeEntity recipe, {bool timesChanged = false}) =>
      repository.refineRecipe(recipe, timesChanged: timesChanged);
}
