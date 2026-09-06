import '../entities/original_recipe_page_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class FetchOriginalRecipePageUseCase {
  final RecipeIngestionRepository repository;
  FetchOriginalRecipePageUseCase(this.repository);

  Future<OriginalRecipePageEntity> call(String url) => repository.fetchOriginalPage(url);
}
