import 'dart:typed_data';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../price_book/domain/entities/receipt_scan_entity.dart';
import '../../data/datasources/recipe_ai_datasource.dart' show ReceiptPage;
import '../entities/original_recipe_page_entity.dart';
import '../entities/web_search_result_entity.dart';

abstract class RecipeIngestionRepository {
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences);
  Future<List<WebSearchResultEntity>> searchWeb(String query, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences);

  /// Writes a recipe from a description of the dish — "semolina porridge for
  /// a one-year-old, with fruit" — in the same structure every other channel
  /// produces. The one call where the model is meant to invent.
  Future<RecipeEntity> generateRecipe(String request, List<DietaryPreference> preferences);

  /// The page as written, fetched directly with no model involved. The fast
  /// alternative to [parseFromUrl] for someone who just wants to read it.
  Future<OriginalRecipePageEntity> fetchOriginalPage(String url);

  /// Spelling/grammar pass over the free text of a hand-edited recipe, and —
  /// when [timesChanged] — a rewrite of any time stated inside the steps so it
  /// agrees with the prep and cook times the user just set.
  Future<RecipeEntity> refineRecipe(RecipeEntity recipe, {required bool timesChanged});

  /// Servings and per-serving nutrition for a recipe that has none.
  Future<RecipeEntity> estimateNutrition(RecipeEntity recipe);

  /// A generated picture for [prompt], as JPEG bytes.
  Future<Uint8List> generateImage(String prompt);

  /// Products and prices read off a receipt (photos or a PDF).
  Future<ReceiptScanEntity> scanReceipt(List<ReceiptPage> pages);
}
