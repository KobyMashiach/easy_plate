import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/image_search_client.dart';
import '../../../../dev/fake_recipes.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../price_book/domain/entities/receipt_scan_entity.dart';
import '../../domain/entities/ingestion_file.dart';
import '../../domain/entities/original_recipe_page_entity.dart';
import '../../domain/entities/recipe_image_candidate.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/repositories/recipe_ingestion_repository.dart';
import '../datasources/recipe_ai_datasource.dart';
import '../datasources/web_page_datasource.dart';

class RecipeIngestionRepositoryImpl implements RecipeIngestionRepository {
  final RecipeAiDataSource aiDataSource;
  final WebPageDataSource webPageDataSource;

  /// Finds each suggested dish's page in Google's web results. Null (and
  /// in a build that talks to Google directly) the model's own links are
  /// used instead, checked.
  final ImageSearchClient? pageSearch;

  RecipeIngestionRepositoryImpl({
    required this.aiDataSource,
    required this.webPageDataSource,
    ImageSearchClient? pageSearch,
  }) : pageSearch =
           pageSearch ??
           (ImageSearchClient.isAvailable ? ImageSearchClient() : null);

  bool get _useFakeData => kDebugMode && !ApiConfig.isConfigured;

  @override
  Future<RecipeEntity> parseRawText(
    String text,
    List<DietaryPreference> preferences,
  ) {
    if (_useFakeData) {
      return Future.value(fakeParsedRecipe(RecipeIngestionChannel.rawText));
    }
    return aiDataSource.parseRawText(text, preferences);
  }

  @override
  Future<List<WebSearchResultEntity>> searchWeb(
    String query,
    List<DietaryPreference> preferences,
  ) {
    if (_useFakeData) return Future.value(fakeWebSearchResults);
    return aiDataSource.searchWeb(query, preferences).then(_onlyLivePages);
  }

  /// [results] without the links that lead nowhere, each at the address it
  /// really opens (a search redirect resolved to the site). The model writes
  /// these links itself, and a grounded answer still came back with whole
  /// lists of invented addresses on a real site (404, checked 2026-11-04).
  /// Checked side by side; a page named twice is listed once.
  Future<List<WebSearchResultEntity>> _onlyLivePages(
    List<WebSearchResultEntity> results,
  ) async {
    final live = await Future.wait([
      for (final result in results) webPageDataSource.liveUrl(result.url),
    ]);
    final seen = <String>{};
    return [
      for (final (index, result) in results.indexed)
        if (live[index] case final url? when seen.add(url))
          WebSearchResultEntity(
            title: result.title,
            url: url,
            snippet: result.snippet,
          ),
    ];
  }

  @override
  Future<List<WebSearchResultEntity>> suggestRecipes(
    List<DietaryPreference> preferences, {
    List<String> knownTitles = const [],
    String topic = '',
    List<Allergen> allergens = const [],
  }) {
    if (_useFakeData) return Future.value(fakeWebSearchResults);
    final search = pageSearch;
    if (search == null) {
      return aiDataSource
          .suggestRecipes(
            preferences,
            knownTitles: knownTitles,
            topic: topic,
            allergens: allergens,
          )
          .then(_onlyLivePages);
    }
    return _dishPages(search, preferences, knownTitles, topic, allergens);
  }

  /// The model names the dishes; Google's results give each its page. The
  /// card reads the dish and the model's reason, with the site under it.
  Future<List<WebSearchResultEntity>> _dishPages(
    ImageSearchClient search,
    List<DietaryPreference> preferences,
    List<String> knownTitles,
    String topic,
    List<Allergen> allergens,
  ) async {
    final dishes = await aiDataSource.suggestDishes(
      preferences,
      knownTitles: knownTitles,
      topic: topic,
      allergens: allergens,
    );
    if (dishes.isEmpty) return const [];
    final pages = await search.recipePages([for (final d in dishes) d.name]);
    final why = {for (final d in dishes) d.name: d.why};
    return _onlyLivePages([
      for (final page in pages)
        WebSearchResultEntity(
          title: page.dish,
          url: page.url,
          snippet: [
            ?why[page.dish],
            if (page.source.isNotEmpty) page.source,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
    ]);
  }

  /// The site's own JSON-LD wins when it exists: it is instant, needs no API
  /// key, and cannot invent anything. The model is the fallback, not the
  /// default. Tried before the fake-data branch on purpose, so a URL import
  /// works even with no key configured.
  @override
  Future<RecipeEntity> parseFromUrl(
    String url,
    List<DietaryPreference> preferences,
  ) async {
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
  Future<RecipeEntity> parseFromFiles(
    List<IngestionFile> files,
    List<DietaryPreference> preferences,
  ) {
    if (_useFakeData) {
      return Future.value(fakeParsedRecipe(RecipeIngestionChannel.file));
    }
    return aiDataSource.parseFromFiles(files, preferences);
  }

  @override
  Future<SocialVideoRecipe> parseFromSocialVideo(
    String url,
    List<DietaryPreference> preferences,
  ) {
    if (_useFakeData) {
      return Future.value(
        SocialVideoRecipe(
          recipe: fakeParsedRecipe(
            RecipeIngestionChannel.socialVideo,
            sourceUrl: url,
          ),
        ),
      );
    }
    return aiDataSource.parseFromSocialVideo(url, preferences);
  }

  @override
  Future<RecipeEntity> generateRecipe(
    String request,
    List<DietaryPreference> preferences,
  ) {
    if (_useFakeData) {
      return Future.value(fakeParsedRecipe(RecipeIngestionChannel.aiRequest));
    }
    return aiDataSource.generateRecipe(request, preferences);
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
  Future<RecipeEntity> refineRecipe(
    RecipeEntity recipe, {
    required bool timesChanged,
  }) {
    return aiDataSource.refineRecipe(recipe, timesChanged: timesChanged);
  }

  @override
  Future<RecipeEntity> estimateNutrition(RecipeEntity recipe) =>
      aiDataSource.estimateNutrition(recipe);

  @override
  Future<Uint8List> generateImage(String prompt) =>
      aiDataSource.generateImage(prompt);

  @override
  Future<ReceiptScanEntity> scanReceipt(List<ReceiptPage> pages) =>
      aiDataSource.scanReceipt(pages);
}
