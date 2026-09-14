import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class GenerateRecipeUseCase {
  final RecipeIngestionRepository repository;
  GenerateRecipeUseCase(this.repository);

  Future<RecipeEntity> call(String request, {List<DietaryPreference> preferences = const []}) =>
      repository.generateRecipe(request, preferences);
}
