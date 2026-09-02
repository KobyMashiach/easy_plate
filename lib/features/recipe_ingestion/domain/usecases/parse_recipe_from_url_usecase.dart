import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class ParseRecipeFromUrlUseCase {
  final RecipeIngestionRepository repository;
  ParseRecipeFromUrlUseCase(this.repository);

  Future<RecipeEntity> call(String url, {List<DietaryPreference> preferences = const []}) =>
      repository.parseFromUrl(url, preferences);
}
