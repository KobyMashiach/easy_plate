import 'dart:typed_data';

import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/features/price_book/domain/entities/receipt_scan_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart'
    show ReceiptPage;
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/save_recipe_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/original_recipe_page_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/web_search_result_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/ingestion_file.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/fetch_original_recipe_page_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/generate_recipe_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_raw_text_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_recipe_from_file_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_recipe_from_social_video_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/parse_recipe_from_url_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/usecases/search_web_recipes_usecase.dart';
import 'package:easy_plate/features/recipe_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
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
  Future<List<WebSearchResultEntity>> Function(String query)? onSearch;

  @override
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> p) =>
      onParse!(text);

  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> p) =>
      onParse!(url);

  @override
  Future<RecipeEntity> parseFromFiles(
    List<IngestionFile> files,
    List<DietaryPreference> p,
  ) => onParse!(files.map((f) => f.name).join(','));

  @override
  Future<RecipeEntity> parseFromSocialVideo(
    String url,
    List<DietaryPreference> p,
  ) => onParse!(url);

  @override
  Future<RecipeEntity> generateRecipe(
    String request,
    List<DietaryPreference> p,
  ) => onParse!(request);

  @override
  Future<OriginalRecipePageEntity> fetchOriginalPage(String url) async {
    if (pageThrows) throw Exception('bot wall');
    return OriginalRecipePageEntity(url: url, text: pageText ?? '');
  }

  @override
  Future<List<WebSearchResultEntity>> searchWeb(
    String q,
    List<DietaryPreference> p,
  ) => onSearch!(q);

  @override
  Future<RecipeEntity> refineRecipe(
    RecipeEntity r, {
    required bool timesChanged,
  }) => throw UnimplementedError();
  @override
  Future<RecipeEntity> estimateNutrition(RecipeEntity r) =>
      throw UnimplementedError();
  @override
  Future<Uint8List> generateImage(String prompt) => throw UnimplementedError();
  @override
  Future<ReceiptScanEntity> scanReceipt(List<ReceiptPage> pages) =>
      throw UnimplementedError();
}

class _FakeRecipes implements RecipesRepository {
  final saved = <RecipeEntity>[];
  Duration delay = Duration.zero;
  bool fail = false;

  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw StateError('disk full');
    saved.add(recipe);
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakePreferences implements UserPreferencesRepository {
  @override
  Future<UserPreferencesEntity> getPreferences() async =>
      const UserPreferencesEntity(
        shoppingDay: ShoppingDay.sunday,
        dietaryPreferences: [],
      );

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
    parseRecipeFromFileUseCase: ParseRecipeFromFileUseCase(ingestion),
    parseRecipeFromSocialVideoUseCase: ParseRecipeFromSocialVideoUseCase(
      ingestion,
    ),
    generateRecipeUseCase: GenerateRecipeUseCase(ingestion),
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

  test(
    'an analysis past the cap hands the pasted text back, marked timed out',
    () async {
      // The model never answers. Without the cap this spinner would turn forever.
      ingestion.onParse = (_) => Completer<RecipeEntity>().future;
      final bloc = buildBloc();

      bloc.add(const IngestionEvent.parseRawText('4 ביצים\nמטגנים'));
      final state = await settle(bloc);

      expect(state, isA<IngestionUnparsed>());
      final unparsed = state as IngestionUnparsed;
      expect(unparsed.text, '4 ביצים\nמטגנים');
      expect(unparsed.timedOut, isTrue);
    },
  );

  test(
    'a failed analysis hands the text back too, marked as a failure',
    () async {
      ingestion.onParse = (_) async => throw Exception('overloaded');
      final bloc = buildBloc();

      bloc.add(const IngestionEvent.parseRawText('טקסט'));
      final state = await settle(bloc);

      expect(state, isA<IngestionUnparsed>());
      expect((state as IngestionUnparsed).timedOut, isFalse);
    },
  );

  test('pass 8: out of quota, the text comes back with the reason', () async {
    ingestion.onParse = (_) async =>
        throw const AppException(AppErrorType.quotaExceeded);
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.parseRawText('טקסט'));
    final state = await settle(bloc);

    expect(state, isA<IngestionUnparsed>());
    expect((state as IngestionUnparsed).notice, t.ads.aiQuotaReached);
  });

  test('no verified phone: the text comes back saying so', () async {
    ingestion.onParse = (_) async =>
        throw const AppException(AppErrorType.phoneRequired);
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.parseRawText('טקסט'));
    final state = await settle(bloc);

    expect(state, isA<IngestionUnparsed>());
    expect((state as IngestionUnparsed).notice, t.auth.phoneGateTitle);
  });

  group('pass 10: a refusal that stands offers no Retry', () {
    Future<IngestionUnparsed> unparsedAfter(Object error) async {
      ingestion.onParse = (_) async => throw error;
      final bloc = buildBloc();
      bloc.add(const IngestionEvent.parseRawText('טקסט'));
      return await settle(bloc) as IngestionUnparsed;
    }

    test(
      'out of quota, no phone, blocked: the text stays, Retry goes',
      () async {
        for (final type in [
          AppErrorType.quotaExceeded,
          AppErrorType.phoneRequired,
          AppErrorType.accountDisabled,
        ]) {
          final state = await unparsedAfter(AppException(type));
          expect(state.retryable, isFalse, reason: '$type');
          expect(state.notice, isNotNull, reason: '$type');
          expect(state.text, 'טקסט');
        }
      },
    );

    test(
      'a blocked account reads as blocked, also on the generic path',
      () async {
        expect(
          (await unparsedAfter(
            const AppException(AppErrorType.accountDisabled),
          )).notice,
          t.auth.blockedTitle,
        );
        // The same refusal filed under the generic 401/403 type, with the
        // server's body: still told apart from a missing key.
        final generic = await unparsedAfter(
          const AppException(
            AppErrorType.unauthorized,
            data: {
              'error': {'code': 'account_disabled'},
            },
          ),
        );
        expect(generic.notice, t.auth.blockedTitle);
        expect(generic.retryable, isFalse);
      },
    );

    test('a passing failure (offline, a timeout) keeps Retry', () async {
      final offline = await unparsedAfter(
        const AppException(AppErrorType.networkError),
      );
      expect(offline.retryable, isTrue);
      expect(offline.notice, t.common.networkError);
      final broke = await unparsedAfter(Exception('overloaded'));
      expect(broke.retryable, isTrue);
      expect(broke.notice, isNull);
    });

    test('Retry from the error screen after a phone refusal re-opens the '
        'form instead of running the same request', () async {
      var searches = 0;
      ingestion.onSearch = (_) async {
        searches++;
        throw const AppException(AppErrorType.phoneRequired);
      };
      final bloc = buildBloc()
        ..add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.webSearch),
        );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const IngestionEvent.searchWeb('shakshuka'));
      expect(await settle(bloc), isA<IngestionError>());

      final next = bloc.stream.first;
      bloc.add(const IngestionEvent.retry());
      expect(await next, isA<IngestionIdle>());
      expect(searches, 1);
      expect(bloc.draftText(RecipeIngestionChannel.webSearch), 'shakshuka');
    });
  });

  test(
    'for a link, the fallback is the page text fetched without the model',
    () async {
      ingestion.onParse = (_) => Completer<RecipeEntity>().future;
      ingestion.pageText = 'המתכון כפי שהוא באתר';
      final bloc = buildBloc()
        ..add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.urlScrape),
        );
      await Future<void>.delayed(Duration.zero);

      bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
      final state = await settle(bloc);

      expect(state, isA<IngestionUnparsed>());
      final unparsed = state as IngestionUnparsed;
      expect(unparsed.text, 'המתכון כפי שהוא באתר');
      expect(unparsed.sourceUrl, 'https://example.com/r');
    },
  );

  test('when even the page cannot be fetched, it is a plain error', () async {
    // Nothing to offer back — an empty "unparsed" screen would be worse.
    ingestion.onParse = (_) => Completer<RecipeEntity>().future;
    ingestion.pageThrows = true;
    final bloc = buildBloc()
      ..add(
        const IngestionEvent.selectChannel(RecipeIngestionChannel.urlScrape),
      );
    await Future<void>.delayed(Duration.zero);

    bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
    expect(await settle(bloc), isA<IngestionError>());
  });

  test(
    'a failure is shown as a sentence, never as the raw exception',
    () async {
      ingestion.onParse = (_) async => throw Exception('socket 42 reset');
      ingestion.pageThrows = true;
      final bloc = buildBloc()
        ..add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.urlScrape),
        );
      await Future<void>.delayed(Duration.zero);

      bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
      final failed = await settle(bloc);
      expect(failed, isA<IngestionError>());
      expect((failed as IngestionError).error, t.ingestion.analysisFailed);

      bloc.add(const IngestionEvent.viewOriginal('https://example.com/r'));
      final unreadable = await settle(bloc);
      expect(unreadable, isA<IngestionError>());
      expect((unreadable as IngestionError).error, t.ingestion.fetchFailed);
      expect(unreadable.error, isNot(contains('Exception')));
    },
  );

  test(
    'a link that is not an http(s) address is refused before any call',
    () async {
      var calls = 0;
      ingestion.onParse = (_) async {
        calls++;
        return parsed('x');
      };
      ingestion.pageText = 'page';
      final bloc = buildBloc();

      // Back to idle between attempts: two identical error states in a
      // row would be one emission.
      Future<void> reset() async {
        bloc.add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.urlScrape),
        );
        await bloc.stream.first;
      }

      for (final bad in [
        'javascript:alert(1)',
        'www.example.com/recipe',
        'file:///etc/passwd',
        'https://',
        'not a link',
      ]) {
        await reset();
        bloc.add(IngestionEvent.parseUrl(bad));
        final state = await bloc.stream.first;
        expect(state, isA<IngestionError>(), reason: bad);
        expect((state as IngestionError).error, t.ingestion.invalidUrl);
      }
      await reset();
      bloc.add(const IngestionEvent.parseSocialVideo('tiktok.com/@a/video/1'));
      expect(await bloc.stream.first, isA<IngestionError>());
      await reset();
      bloc.add(const IngestionEvent.viewOriginal('ftp://example.com/r'));
      expect(await bloc.stream.first, isA<IngestionError>());
      await reset();
      expect(calls, 0, reason: 'nothing reached the model or the fetch');

      // A proper address still goes through.
      bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
      expect(await settle(bloc), isA<IngestionReview>());
      expect(calls, 1);
    },
  );

  test(
    'save for later stores a pending template holding the full text',
    () async {
      final bloc = buildBloc();

      bloc.add(const IngestionEvent.saveAsTemplate('שקשוקה\n4 ביצים'));
      final state = await bloc.stream.first;

      expect(state, isA<IngestionSaved>());
      final saved = recipes.saved.single;
      expect(saved.pendingAnalysis, isTrue);
      expect(saved.title, 'שקשוקה');
      expect(saved.rawText, 'שקשוקה\n4 ביצים');
    },
  );

  test(
    'edit manually opens the review on the template without saving yet',
    () async {
      final bloc = buildBloc();

      bloc.add(const IngestionEvent.editManually('שקשוקה\n4 ביצים'));
      final state = await bloc.stream.first;

      expect(state, isA<IngestionReview>());
      expect((state as IngestionReview).recipe.pendingAnalysis, isTrue);
      expect(
        recipes.saved,
        isEmpty,
        reason: 'nothing persists until the user saves',
      );
    },
  );

  test('a second search while the first runs is not sent', () async {
    var calls = 0;
    final gate = Completer<void>();
    ingestion.onSearch = (_) async {
      calls++;
      await gate.future;
      return const [];
    };
    final bloc = buildBloc();

    bloc.add(const IngestionEvent.searchWeb('שקשוקה'));
    bloc.add(const IngestionEvent.searchWeb('שקשוקה'));
    await bloc.stream.firstWhere((s) => s is IngestionParsing);
    gate.complete();
    expect(await settle(bloc), isA<IngestionSearchResults>());
    expect(calls, 1);
  });

  group('recipe request', () {
    test('a request lands on review with the recipe the model wrote', () async {
      ingestion.onParse = (request) async {
        expect(request, contains('דייסת סולת'));
        return parsed('דייסת סולת לתינוקות');
      };
      final bloc = buildBloc();

      // Selecting the channel emits idle, which would satisfy [settle] on its
      // own — so wait it out before asking for the recipe.
      bloc.add(
        const IngestionEvent.selectChannel(RecipeIngestionChannel.aiRequest),
      );
      await bloc.stream.first;
      bloc.add(
        const IngestionEvent.generateRecipe('מתכון לדייסת סולת לתינוקת בת שנה'),
      );
      final state = await settle(bloc);

      expect(state, isA<IngestionReview>());
      expect((state as IngestionReview).recipe.title, 'דייסת סולת לתינוקות');
    });

    test(
      'a request the model never answers is handed back on its own channel',
      () async {
        // So the retry re-asks for a recipe rather than parsing the request as one.
        ingestion.onParse = (_) => Completer<RecipeEntity>().future;
        final bloc = buildBloc();

        bloc.add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.aiRequest),
        );
        await bloc.stream.first;
        bloc.add(const IngestionEvent.generateRecipe('דייסת סולת'));
        final state = await settle(bloc);

        expect(state, isA<IngestionUnparsed>());
        final unparsed = state as IngestionUnparsed;
        expect(unparsed.channel, RecipeIngestionChannel.aiRequest);
        expect(unparsed.text, 'דייסת סולת');
        expect(unparsed.timedOut, isTrue);
      },
    );
  });

  test('save for later tapped twice stores one template', () async {
    final bloc = buildBloc();
    recipes.delay = const Duration(milliseconds: 30);
    bloc
      ..add(const IngestionEvent.saveAsTemplate('שקשוקה'))
      ..add(const IngestionEvent.saveAsTemplate('שקשוקה'));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(recipes.saved, hasLength(1));
    await bloc.close();
  });

  test('a failed save keeps the review and says why', () async {
    final bloc = buildBloc();
    bloc.add(const IngestionEvent.editManually('שקשוקה\n4 ביצים'));
    final review = await bloc.stream.first as IngestionReview;
    recipes.fail = true;
    bloc.add(IngestionEvent.saveRecipe(review.recipe));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final state = bloc.state as IngestionReview;
    expect(state.recipe, same(review.recipe));
    expect(state.notice, t.ingestion.saveFailed);
    expect(recipes.saved, isEmpty);
    await bloc.close();
  });

  group('pass 9: Retry keeps the inputs', () {
    test('a failed file read runs again with the same files', () async {
      final seen = <String>[];
      ingestion.onParse = (input) async {
        seen.add(input);
        throw Exception('overloaded');
      };
      final bloc = buildBloc()
        ..add(const IngestionEvent.selectChannel(RecipeIngestionChannel.file));
      await Future<void>.delayed(Duration.zero);
      final files = [
        IngestionFile(
          name: 'a.mp3',
          bytes: Uint8List(3),
          mimeType: 'audio/mpeg',
        ),
      ];
      bloc.add(IngestionEvent.parseFiles(files));
      expect(await settle(bloc), isA<IngestionError>());
      expect(bloc.draftFiles.map((f) => f.name), ['a.mp3']);

      bloc.add(const IngestionEvent.retry());
      await bloc.stream.firstWhere((s) => s is IngestionParsing);
      expect(await settle(bloc), isA<IngestionError>());
      expect(seen, ['a.mp3', 'a.mp3']);
      await bloc.close();
    });

    test('a failed result opens back onto the paid search results', () async {
      final results = [
        const WebSearchResultEntity(
          title: 'שקשוקה',
          url: 'https://example.com/r',
          snippet: '',
        ),
      ];
      var searches = 0;
      ingestion.onSearch = (_) async {
        searches++;
        return results;
      };
      ingestion.pageThrows = true;
      final bloc = buildBloc()
        ..add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.webSearch),
        );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const IngestionEvent.searchWeb('שקשוקה'));
      expect(await settle(bloc), isA<IngestionSearchResults>());
      bloc.add(const IngestionEvent.viewOriginal('https://example.com/r'));
      expect(await settle(bloc), isA<IngestionError>());

      bloc.add(const IngestionEvent.retry());
      final back = await bloc.stream.first;
      expect(back, isA<IngestionSearchResults>());
      expect(
        (back as IngestionSearchResults).results.single.url,
        results.single.url,
      );
      expect(searches, 1);
      // The query is still the form's draft, not the link.
      expect(bloc.draftText(RecipeIngestionChannel.webSearch), 'שקשוקה');
      await bloc.close();
    });

    test(
      'out of quota, Retry returns to the form with the link kept',
      () async {
        ingestion.onParse = (_) async =>
            throw const AppException(AppErrorType.quotaExceeded);
        ingestion.pageThrows = true;
        final bloc = buildBloc()
          ..add(
            const IngestionEvent.selectChannel(
              RecipeIngestionChannel.urlScrape,
            ),
          );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IngestionEvent.parseUrl('https://example.com/r'));
        expect(await settle(bloc), isA<IngestionError>());

        bloc.add(const IngestionEvent.retry());
        expect(await bloc.stream.first, isA<IngestionIdle>());
        expect(
          bloc.draftText(RecipeIngestionChannel.urlScrape),
          'https://example.com/r',
        );
        expect(bloc.draftText(RecipeIngestionChannel.rawText), isNull);
        await bloc.close();
      },
    );
  });

  test(
    'pass 9: a hand-written recipe whose save fails stays on screen',
    () async {
      final bloc = buildBloc()
        ..add(
          const IngestionEvent.selectChannel(RecipeIngestionChannel.manual),
        );
      await Future<void>.delayed(Duration.zero);
      recipes.fail = true;
      final recipe = parsed('My recipe');
      bloc.add(IngestionEvent.saveRecipe(recipe));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final state = bloc.state as IngestionReview;
      expect(state.recipe, same(recipe));
      expect(state.notice, t.ingestion.saveFailed);
      await bloc.close();
    },
  );
}
