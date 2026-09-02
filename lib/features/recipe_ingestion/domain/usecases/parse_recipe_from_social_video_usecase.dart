import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class ParseRecipeFromSocialVideoUseCase {
  final RecipeIngestionRepository repository;
  ParseRecipeFromSocialVideoUseCase(this.repository);

  Future<RecipeEntity> call(String url, {List<DietaryPreference> preferences = const []}) =>
      repository.parseFromSocialVideo(url, preferences);
}
