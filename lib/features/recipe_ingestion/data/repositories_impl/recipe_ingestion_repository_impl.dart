import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../dev/fake_recipes.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/repositories/recipe_ingestion_repository.dart';
import '../datasources/recipe_ai_datasource.dart';

class RecipeIngestionRepositoryImpl implements RecipeIngestionRepository {
  final RecipeAiDataSource aiDataSource;

  RecipeIngestionRepositoryImpl({required this.aiDataSource});

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

  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences) {
    if (_useFakeData) {
      return Future.value(fakeParsedRecipe(RecipeIngestionChannel.urlScrape, sourceUrl: url));
    }
    return aiDataSource.parseFromUrl(url, preferences);
  }

  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences) {
    if (_useFakeData) {
      return Future.value(fakeParsedRecipe(RecipeIngestionChannel.socialVideo, sourceUrl: url));
    }
    return aiDataSource.parseFromSocialVideo(url, preferences);
  }
}
