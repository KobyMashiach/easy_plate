import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../entities/web_search_result_entity.dart';

abstract class RecipeIngestionRepository {
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences);
  Future<List<WebSearchResultEntity>> searchWeb(String query, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences);

  /// Spelling/grammar pass over the free text of a hand-edited recipe, and —
  /// when [timesChanged] — a rewrite of any time stated inside the steps so it
  /// agrees with the prep and cook times the user just set.
  Future<RecipeEntity> refineRecipe(RecipeEntity recipe, {required bool timesChanged});
}
