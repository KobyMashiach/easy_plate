import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../dev/fake_recipes.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/original_recipe_page_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/repositories/recipe_ingestion_repository.dart';
import '../datasources/recipe_ai_datasource.dart';
import '../datasources/web_page_datasource.dart';

class RecipeIngestionRepositoryImpl implements RecipeIngestionRepository {
  final RecipeAiDataSource aiDataSource;
  final WebPageDataSource webPageDataSource;

  RecipeIngestionRepositoryImpl({
    required this.aiDataSource,
    required this.webPageDataSource,
  });

  bool get _useFakeData => kDebugMode && !ApiConfig.isConfigured;

  @override
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences) {
    if (_useFakeData) return Future.value(fakeParsedRecipe(RecipeIngestionChannel.rawText));
    return aiDataSource.parseRawText(text, preferences);
  }

  @override
  Future<List<WebSearchResultEntity>> searchWeb(String query, List<DietaryPreference> preferences) {
    if (_useFakeData) return Future.value(fakeWebSearchResults);
    return aiDataSource.searchWeb(query, preferences);
  }

  /// The site's own JSON-LD wins when it exists: it is instant, needs no API
  /// key, and cannot invent anything. The model is the fallback, not the
  /// default. Tried before the fake-data branch on purpose, so a URL import
  /// works even with no key configured.
  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences) async {
    final structured = await _structuredFromPage(url);
    if (structured != null) return structured;

    if (_useFakeData) {
      return fakeParsedRecipe(RecipeIngestionChannel.urlScrape, sourceUrl: url);
    }
    return aiDataSource.parseFromUrl(url, preferences);
  }

  /// Null on any failure — an unreachable page just hands over to the model,
  /// which fetches with its own tooling and may well succeed where we did not.
  Future<RecipeEntity?> _structuredFromPage(String url) async {
    try {
      return (await webPageDataSource.fetch(url)).structured;
    } catch (e) {
      debugPrint('JSON-LD pass skipped for $url: $e');
      return null;
    }
  }

  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences) {
    if (_useFakeData) {
      return Future.value(fakeParsedRecipe(RecipeIngestionChannel.socialVideo, sourceUrl: url));
    }
    return aiDataSource.parseFromSocialVideo(url, preferences);
  }

  /// Deliberately has no fake branch. Sample data stands in for a recipe the
  /// app could not fetch, but a faked correction is indistinguishable from a
  /// correction that found nothing — so with no key this reports the missing
  /// key instead of handing back unchanged text as though it had worked.
  /// No fake branch: this path has no model to be missing a key for.
  @override
  Future<OriginalRecipePageEntity> fetchOriginalPage(String url) =>
      webPageDataSource.fetch(url);

  @override
  Future<RecipeEntity> refineRecipe(RecipeEntity recipe, {required bool timesChanged}) {
    return aiDataSource.refineRecipe(recipe, timesChanged: timesChanged);
  }
}
