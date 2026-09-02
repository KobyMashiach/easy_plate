import '../../../../core/constants/app_enums.dart';
import '../entities/web_search_result_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class SearchWebRecipesUseCase {
  final RecipeIngestionRepository repository;
  SearchWebRecipesUseCase(this.repository);

  Future<List<WebSearchResultEntity>> call(
    String query, {
    List<DietaryPreference> preferences = const [],
  }) =>
      repository.searchWeb(query, preferences);
}
