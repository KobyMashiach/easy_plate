import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/usecases/save_recipe_usecase.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/original_recipe_page_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/usecases/build_template_recipe.dart';
import '../../domain/usecases/fetch_original_recipe_page_usecase.dart';
import '../../domain/usecases/parse_raw_text_usecase.dart';
import '../../domain/usecases/parse_recipe_from_social_video_usecase.dart';
import '../../domain/usecases/parse_recipe_from_url_usecase.dart';
import '../../domain/usecases/search_web_recipes_usecase.dart';

part 'ingestion_bloc.freezed.dart';

@freezed
sealed class IngestionEvent with _$IngestionEvent {
  const factory IngestionEvent.selectChannel(RecipeIngestionChannel channel) = _SelectChannel;
  const factory IngestionEvent.parseRawText(String text) = _ParseRawText;
  const factory IngestionEvent.searchWeb(String query) = _SearchWeb;
  const factory IngestionEvent.parseUrl(String url) = _ParseUrl;
  const factory IngestionEvent.viewOriginal(String url) = _ViewOriginal;
  const factory IngestionEvent.parseSocialVideo(String url) = _ParseSocialVideo;
  const factory IngestionEvent.updateRecipe(RecipeEntity recipe) = _UpdateRecipe;
  const factory IngestionEvent.saveRecipe(RecipeEntity recipe) = _SaveRecipe;

  /// Saves the unanalysed text as a template, flagged for a later analysis.
  const factory IngestionEvent.saveAsTemplate(String text, {String? sourceUrl}) =
      _SaveAsTemplate;

  /// Opens the review on a template so the user structures it by hand.
  const factory IngestionEvent.editManually(String text, {String? sourceUrl}) =
      _EditManually;
}

@freezed
sealed class IngestionState with _$IngestionState {
  const factory IngestionState.idle(RecipeIngestionChannel channel) = IngestionIdle;
  const factory IngestionState.parsing(RecipeIngestionChannel channel) = IngestionParsing;
  const factory IngestionState.searchResults(
    RecipeIngestionChannel channel,
    List<WebSearchResultEntity> results,
  ) = IngestionSearchResults;
  const factory IngestionState.review(RecipeIngestionChannel channel, RecipeEntity recipe) =
      IngestionReview;

  /// The page as written, for reading. No model was involved in reaching it.
  const factory IngestionState.original(
    RecipeIngestionChannel channel,
    OriginalRecipePageEntity page,
  ) = IngestionOriginal;
  const factory IngestionState.saved() = IngestionSaved;

  /// The analysis did not produce a recipe, but the text is safe. [timedOut]
  /// separates "too slow" from "broke" in the wording only; the options
  /// offered are the same.
  const factory IngestionState.unparsed(
    RecipeIngestionChannel channel,
    String text, {
    String? sourceUrl,
    required bool timedOut,
  }) = IngestionUnparsed;
  const factory IngestionState.errorMessage(RecipeIngestionChannel channel, String error) =
      IngestionError;
}

class IngestionBloc extends Bloc<IngestionEvent, IngestionState> {
  final ParseRawTextUseCase parseRawTextUseCase;
  final SearchWebRecipesUseCase searchWebRecipesUseCase;
  final ParseRecipeFromUrlUseCase parseRecipeFromUrlUseCase;
  final FetchOriginalRecipePageUseCase fetchOriginalRecipePageUseCase;
  final ParseRecipeFromSocialVideoUseCase parseRecipeFromSocialVideoUseCase;
  final SaveRecipeUseCase saveRecipeUseCase;
  final GetUserPreferencesUseCase getUserPreferencesUseCase;

  RecipeIngestionChannel _channel = RecipeIngestionChannel.rawText;
  static const _uuid = Uuid();

  /// How long an analysis may run before the raw text is offered instead.
  /// Injectable so a test does not have to wait it out.
  final Duration analysisTimeout;

  IngestionBloc({
    this.analysisTimeout = const Duration(seconds: 30),
    required this.parseRawTextUseCase,
    required this.searchWebRecipesUseCase,
    required this.parseRecipeFromUrlUseCase,
    required this.fetchOriginalRecipePageUseCase,
    required this.parseRecipeFromSocialVideoUseCase,
    required this.saveRecipeUseCase,
    required this.getUserPreferencesUseCase,
  }) : super(const IngestionState.idle(RecipeIngestionChannel.rawText)) {
    on<_SelectChannel>(_selectChannel);
    on<_ParseRawText>(_parseRawText);
    on<_SearchWeb>(_searchWeb);
    on<_ParseUrl>(_parseUrl);
    on<_ViewOriginal>(_viewOriginal);
    on<_ParseSocialVideo>(_parseSocialVideo);
    on<_UpdateRecipe>(_updateRecipe);
    on<_SaveRecipe>(_saveRecipe);
    on<_SaveAsTemplate>(_saveAsTemplate);
    on<_EditManually>(_editManually);
  }

  factory IngestionBloc.fromContext(BuildContext context) {
    return IngestionBloc(
      parseRawTextUseCase: ParseRawTextUseCase(context.read()),
      searchWebRecipesUseCase: SearchWebRecipesUseCase(context.read()),
      parseRecipeFromUrlUseCase: ParseRecipeFromUrlUseCase(context.read()),
      fetchOriginalRecipePageUseCase: FetchOriginalRecipePageUseCase(context.read()),
      parseRecipeFromSocialVideoUseCase: ParseRecipeFromSocialVideoUseCase(context.read()),
      saveRecipeUseCase: SaveRecipeUseCase(context.read()),
      getUserPreferencesUseCase: GetUserPreferencesUseCase(context.read()),
    );
  }

  Future<List<DietaryPreference>> get _preferences async =>
      (await getUserPreferencesUseCase()).dietaryPreferences;

  FutureOr<void> _selectChannel(_SelectChannel event, Emitter<IngestionState> emit) {
    _channel = event.channel;
    emit(.idle(event.channel));
  }

  /// Runs an analysis under [analysisTimeout]. When it runs out — or fails —
  /// the text it was working from is offered back instead of an error, so a
  /// slow model never costs the user what they pasted or found.
  Future<void> _runParse(
    Emitter<IngestionState> emit,
    Future<RecipeEntity> Function(List<DietaryPreference> preferences) parse, {
    required Future<String?> Function() fallbackText,
    String? sourceUrl,
  }) async {
    emit(.parsing(_channel));
    try {
      final recipe = await parse(await _preferences).timeout(analysisTimeout);
      emit(.review(_channel, recipe));
    } on TimeoutException {
      debugPrint('Ingestion timed out after $analysisTimeout');
      await _offerText(emit, fallbackText, sourceUrl: sourceUrl, timedOut: true);
    } catch (e) {
      debugPrint('Ingestion error: $e');
      await _offerText(emit, fallbackText, sourceUrl: sourceUrl, timedOut: false, error: e);
    }
  }

  Future<void> _offerText(
    Emitter<IngestionState> emit,
    Future<String?> Function() fallbackText, {
    required String? sourceUrl,
    required bool timedOut,
    Object? error,
  }) async {
    String? text;
    try {
      text = await fallbackText();
    } catch (e) {
      debugPrint('Fallback text unavailable: $e');
    }
    if (text == null || text.trim().isEmpty) {
      emit(.errorMessage(_channel, (error ?? 'timeout').toString()));
      return;
    }
    emit(.unparsed(_channel, text, sourceUrl: sourceUrl, timedOut: timedOut));
  }

  RecipeEntity _template(String text, String? sourceUrl) => buildTemplateRecipe(
        id: _uuid.v4(),
        text: text,
        channel: _channel,
        untitled: t.ingestion.untitledRecipe,
        sourceUrl: sourceUrl,
      );

  Future<void> _saveAsTemplate(_SaveAsTemplate event, Emitter<IngestionState> emit) async {
    await saveRecipeUseCase(_template(event.text, event.sourceUrl));
    emit(const IngestionState.saved());
  }

  FutureOr<void> _editManually(_EditManually event, Emitter<IngestionState> emit) {
    emit(.review(_channel, _template(event.text, event.sourceUrl)));
  }

  Future<void> _parseRawText(_ParseRawText event, Emitter<IngestionState> emit) {
    return _runParse(
      emit,
      (prefs) => parseRawTextUseCase(event.text, preferences: prefs),
      // The pasted text is the fallback; nothing to fetch.
      fallbackText: () async => event.text,
    );
  }

  /// For a link, the fallback is the page itself, fetched without the model —
  /// the same fast path the "view original" option uses.
  Future<String?> _pageText(String url) async =>
      (await fetchOriginalRecipePageUseCase(url)).text;

  Future<void> _parseUrl(_ParseUrl event, Emitter<IngestionState> emit) {
    return _runParse(
      emit,
      (prefs) => parseRecipeFromUrlUseCase(event.url, preferences: prefs),
      fallbackText: () => _pageText(event.url),
      sourceUrl: event.url,
    );
  }

  /// Reuses the parsing spinner while the page loads — it is the same "hold
  /// on" from the user's side, just much shorter.
  Future<void> _viewOriginal(_ViewOriginal event, Emitter<IngestionState> emit) async {
    emit(.parsing(_channel));
    try {
      emit(.original(_channel, await fetchOriginalRecipePageUseCase(event.url)));
    } catch (e) {
      debugPrint('Original page error: $e');
      emit(.errorMessage(_channel, e.toString()));
    }
  }

  Future<void> _parseSocialVideo(_ParseSocialVideo event, Emitter<IngestionState> emit) {
    return _runParse(
      emit,
      (prefs) => parseRecipeFromSocialVideoUseCase(event.url, preferences: prefs),
      fallbackText: () => _pageText(event.url),
      sourceUrl: event.url,
    );
  }

  Future<void> _searchWeb(_SearchWeb event, Emitter<IngestionState> emit) async {
    emit(.parsing(_channel));
    try {
      final results = await searchWebRecipesUseCase(event.query, preferences: await _preferences);
      emit(.searchResults(_channel, results));
    } catch (e) {
      debugPrint('Web search error: $e');
      emit(.errorMessage(_channel, e.toString()));
    }
  }

  /// The editor hands back the whole recipe, so the review simply re-renders
  /// what came out of it — nothing is persisted until the user saves.
  FutureOr<void> _updateRecipe(_UpdateRecipe event, Emitter<IngestionState> emit) {
    emit(.review(_channel, event.recipe));
  }

  Future<void> _saveRecipe(_SaveRecipe event, Emitter<IngestionState> emit) async {
    await saveRecipeUseCase(event.recipe);
    emit(const IngestionState.saved());
  }
}
