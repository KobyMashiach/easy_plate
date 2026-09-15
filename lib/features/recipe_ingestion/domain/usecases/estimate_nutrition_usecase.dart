import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class EstimateNutritionUseCase {
  final RecipeIngestionRepository repository;
  EstimateNutritionUseCase(this.repository);

  Future<RecipeEntity> call(RecipeEntity recipe) => repository.estimateNutrition(recipe);
}
