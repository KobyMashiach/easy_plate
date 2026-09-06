import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/save_recipe_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/original_recipe_page_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/web_search_result_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/fetch_original_recipe_page_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_raw_text_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_recipe_from_social_video_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_recipe_from_url_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/search_web_recipes_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity parsed(String title) => RecipeEntity(
      id: 'p',
      title: title,
      ingredients: const [],
      steps: const ['שלב'],
      createdAt: DateTime(2026, 1, 1),
    );

class _FakeIngestion implements RecipeIngestionRepository {
  /// What the model does: completes, hangs, or throws — the caller decides.
  Future<RecipeEntity> Function(String input)? onParse;
  String? pageText;
  bool pageThrows = false;

  @override
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> p) => onParse!(text);

  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> p) => onParse!(url);

  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> p) =>
      onParse!(url);

  @override
  Future<OriginalRecipePageEntity> fetchOriginalPage(String url) async {
    if (pageThrows) throw Exception('bot wall');
    return OriginalRecipePageEntity(url: url, text: pageText ?? '');
  }

  @override
  Future<List<WebSearchResultEntity>> searchWeb(String q, List<DietaryPreference> p) =>
      throw UnimplementedError();

  @override
  Future<RecipeEntity> refineRecipe(RecipeEntity r, {required bool timesChanged}) =>
      throw UnimplementedError();
}

class _FakeRecipes implements RecipesRepository {
  final saved = <RecipeEntity>[];

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakePreferences implements UserPreferencesRepository {
  @override
  Future<UserPreferencesEntity> getPreferences() async =>
      const UserPreferencesEntity(shoppingDay: ShoppingDay.sunday, dietaryPreferences: []);

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeIngestion ingestion;
  late _FakeRecipes recipes;

  IngestionBloc buildBloc() => IngestionBloc(
        analysisTimeout: const Duration(milliseconds: 50),
        parseRawTextUseCase: ParseRawTextUseCase(ingestion),
        searchWebRecipesUseCase: SearchWebRecipesUseCase(ingestion),
        parseRecipeFromUrlUseCase: ParseRecipeFromUrlUseCase(ingestion),
        parseRecipeFromSocialVideoUseCase: ParseRecipeFromSocialVideoUseCase(ingestion),
        fetchOriginalRecipePageUseCase: FetchOriginalRecipePageUseCase(ingestion),
        saveRecipeUseCase: SaveRecipeUseCase(recipes),
        getUserPreferencesUseCase: GetUserPreferencesUseCase(_FakePreferences()),
      );

  Future<IngestionState> settle(IngestionBloc bloc) =>
      bloc.stream.firstWhere((s) => s is! IngestionParsing);

  setUp(() {
    ingestion = _FakeIngestion();
    recipes = _FakeRecipes();
  });

  test('a fast analysis lands on review as before', () async {
    ingestion.onParse = (_) async => parsed('שקשוקה');
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.parseRawText('טקסט'));
    final state = await settle(bloc);

    expect(state, isA<IngestionReview>());
    expect((state as IngestionReview).recipe.title, 'שקשוקה');
  });

  test('an analysis past the cap hands the pasted text back, marked timed out', () async {
    // The model never answers. Without the cap this spinner would turn forever.
    ingestion.onParse = (_) => Completer<RecipeEntity>().future;
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.parseRawText('4 ביצים\nמטגנים'));
    final state = await settle(bloc);

    expect(state, isA<IngestionUnparsed>());
    final unparsed = state as IngestionUnparsed;
    expect(unparsed.text, '4 ביצים\nמטגנים');
    expect(unparsed.timedOut, isTrue);
  });

  test('a failed analysis hands the text back too, marked as a failure', () async {
    ingestion.onParse = (_) async => throw Exception('overloaded');
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.parseRawText('טקסט'));
    final state = await settle(bloc);

    expect(state, isA<IngestionUnparsed>());
    expect((state as IngestionUnparsed).timedOut, isFalse);
  });

  test('for a link, the fallback is the page text fetched without the model', () async {
    ingestion.onParse = (_) => Completer<RecipeEntity>().future;
    ingestion.pageText = 'המתכון כפי שהוא באתר';
    final bloc = buildBloc()
      ..add(const IngestionEvent.selectChannel(RecipeIngestionChannel.urlScrape));
    await Future<void>.delayed(Duration.zero);

    bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
    final state = await settle(bloc);

    expect(state, isA<IngestionUnparsed>());
    final unparsed = state as IngestionUnparsed;
    expect(unparsed.text, 'המתכון כפי שהוא באתר');
    expect(unparsed.sourceUrl, 'https://example.com/r');
  });

  test('when even the page cannot be fetched, it is a plain error', () async {
    // Nothing to offer back — an empty "unparsed" screen would be worse.
    ingestion.onParse = (_) => Completer<RecipeEntity>().future;
    ingestion.pageThrows = true;
    final bloc = buildBloc()
      ..add(const IngestionEvent.selectChannel(RecipeIngestionChannel.urlScrape));
    await Future<void>.delayed(Duration.zero);

    bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
    expect(await settle(bloc), isA<IngestionError>());
  });

  test('save for later stores a pending template holding the full text', () async {
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.saveAsTemplate('שקשוקה\n4 ביצים'));
    final state = await bloc.stream.first;

    expect(state, isA<IngestionSaved>());
    final saved = recipes.saved.single;
    expect(saved.pendingAnalysis, isTrue);
    expect(saved.title, 'שקשוקה');
    expect(saved.rawText, 'שקשוקה\n4 ביצים');
  });

  test('edit manually opens the review on the template without saving yet', () async {
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.editManually('שקשוקה\n4 ביצים'));
    final state = await bloc.stream.first;

    expect(state, isA<IngestionReview>());
    expect((state as IngestionReview).recipe.pendingAnalysis, isTrue);
    expect(recipes.saved, isEmpty, reason: 'nothing persists until the user saves');
  });
}
