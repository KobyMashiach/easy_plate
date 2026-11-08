import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../entities/web_search_result_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

/// Recipes from the web chosen by the account's preferences instead of a
/// query: its diet, and the dishes it already keeps — newest first, as the
/// taste to build on and the list not to repeat.
class SuggestRecipesUseCase {
  final RecipeIngestionRepository repository;
  final RecipesRepository recipes;

  /// How many of the account's own titles go into the request.
  static const knownTitleLimit = 30;

  SuggestRecipesUseCase(this.repository, this.recipes);

  /// [topic] narrows the list to what was asked for ("קינוחים"); empty, it
  /// is the preferences alone.
  Future<List<WebSearchResultEntity>> call({
    List<DietaryPreference> preferences = const [],
    String topic = '',
    List<Allergen> allergens = const [],
  }) async {
    final mine = [...await recipes.getRecipes()]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final titles = <String>{
      for (final recipe in mine)
        if (recipe.title.trim().isNotEmpty) recipe.title.trim(),
    }.take(knownTitleLimit).toList();
    return repository.suggestRecipes(
      preferences,
      knownTitles: titles,
      topic: topic.trim(),
      // Only with the allergy diet on: the list stays saved when it is off.
      allergens: preferences.contains(DietaryPreference.allergy)
          ? allergens
          : const [],
    );
  }
}
