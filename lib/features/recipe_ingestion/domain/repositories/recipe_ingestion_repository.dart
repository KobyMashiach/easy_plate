import 'dart:typed_data';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../price_book/domain/entities/receipt_scan_entity.dart';
import '../../data/datasources/recipe_ai_datasource.dart' show ReceiptPage;
import '../entities/ingestion_file.dart';
import '../entities/original_recipe_page_entity.dart';
import '../entities/recipe_image_candidate.dart';
import '../entities/web_search_result_entity.dart';

abstract class RecipeIngestionRepository {
  Future<RecipeEntity> parseRawText(
    String text,
    List<DietaryPreference> preferences,
  );
  Future<List<WebSearchResultEntity>> searchWeb(
    String query,
    List<DietaryPreference> preferences,
  );

  /// Recipes on the web picked for this account rather than for a query:
  /// its dietary preferences, and something new next to [knownTitles] (the
  /// recipes it already keeps). Each is opened, and paid for, one at a time.
  Future<List<WebSearchResultEntity>> suggestRecipes(
    List<DietaryPreference> preferences, {
    List<String> knownTitles = const [],
    String topic = '',
  });
  Future<RecipeEntity> parseFromUrl(
    String url,
    List<DietaryPreference> preferences,
  );

  /// Recordings and PDFs that together make one recipe, read by the model
  /// directly, in order.
  Future<RecipeEntity> parseFromFiles(
    List<IngestionFile> files,
    List<DietaryPreference> preferences,
  );

  /// The recipe read from a TikTok / Instagram / YouTube / Facebook video,
  /// with the pictures the server offers for it (the post's cover, stills
  /// of the food) — none when there is no server to cut them.
  Future<SocialVideoRecipe> parseFromSocialVideo(
    String url,
    List<DietaryPreference> preferences,
  );

  /// Writes a recipe from a description of the dish — "semolina porridge for
  /// a one-year-old, with fruit" — in the same structure every other channel
  /// produces. The one call where the model is meant to invent.
  Future<RecipeEntity> generateRecipe(
    String request,
    List<DietaryPreference> preferences,
  );

  /// The page as written, fetched directly with no model involved. The fast
  /// alternative to [parseFromUrl] for someone who just wants to read it.
  Future<OriginalRecipePageEntity> fetchOriginalPage(String url);

  /// Spelling/grammar pass over the free text of a hand-edited recipe, and —
  /// when [timesChanged] — a rewrite of any time stated inside the steps so it
  /// agrees with the prep and cook times the user just set.
  Future<RecipeEntity> refineRecipe(
    RecipeEntity recipe, {
    required bool timesChanged,
  });

  /// Servings and per-serving nutrition for a recipe that has none.
  Future<RecipeEntity> estimateNutrition(RecipeEntity recipe);

  /// A generated picture for [prompt], as JPEG bytes.
  Future<Uint8List> generateImage(String prompt);

  /// Products and prices read off a receipt (photos or a PDF).
  Future<ReceiptScanEntity> scanReceipt(List<ReceiptPage> pages);
}
