import '../../../../core/constants/app_enums.dart';
import '../entities/recipe_image_candidate.dart';
import '../repositories/recipe_ingestion_repository.dart';

class ParseRecipeFromSocialVideoUseCase {
  final RecipeIngestionRepository repository;
  ParseRecipeFromSocialVideoUseCase(this.repository);

  Future<SocialVideoRecipe> call(
    String url, {
    List<DietaryPreference> preferences = const [],
  }) => repository.parseFromSocialVideo(url, preferences);
}
