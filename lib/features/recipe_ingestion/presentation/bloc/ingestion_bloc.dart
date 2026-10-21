import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/usecases/save_recipe_usecase.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/original_recipe_page_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/paid_call_refusal.dart';
import '../../domain/usecases/build_template_recipe.dart';
import '../../domain/usecases/fetch_original_recipe_page_usecase.dart';
import '../../domain/usecases/generate_recipe_usecase.dart';
import '../../domain/usecases/parse_raw_text_usecase.dart';
import '../../domain/entities/ingestion_file.dart';
import '../../domain/usecases/parse_recipe_from_file_usecase.dart';
import '../../domain/usecases/parse_recipe_from_social_video_usecase.dart';
import '../../domain/usecases/parse_recipe_from_url_usecase.dart';
import '../../domain/usecases/search_web_recipes_usecase.dart';

part 'ingestion_bloc.freezed.dart';

@freezed
sealed class IngestionEvent with _$IngestionEvent {
  const factory IngestionEvent.selectChannel(RecipeIngestionChannel channel) =
      _SelectChannel;
  const factory IngestionEvent.parseRawText(String text) = _ParseRawText;
  const factory IngestionEvent.searchWeb(String query) = _SearchWeb;
  const factory IngestionEvent.parseUrl(String url) = _ParseUrl;
  const factory IngestionEvent.viewOriginal(String url) = _ViewOriginal;
  const factory IngestionEvent.parseSocialVideo(String url) = _ParseSocialVideo;

  /// Recordings and PDFs that together are one recipe, for the model to read.
  const factory IngestionEvent.parseFiles(List<IngestionFile> files) =
      _ParseFiles;

  /// Asks the model to write a recipe from a description of the dish.
  const factory IngestionEvent.generateRecipe(String request) = _GenerateRecipe;
  const factory IngestionEvent.updateRecipe(RecipeEntity recipe) =
      _UpdateRecipe;
  const factory IngestionEvent.saveRecipe(RecipeEntity recipe) = _SaveRecipe;

  /// Saves the unanalysed text as a template, flagged for a later analysis.
  const factory IngestionEvent.saveAsTemplate(
    String text, {
    String? sourceUrl,
  }) = _SaveAsTemplate;

  /// Opens the review on a template so the user structures it by hand.
  const factory IngestionEvent.editManually(String text, {String? sourceUrl}) =
      _EditManually;

  /// Retry from the error screen: the same request again with the same
  /// inputs, or — when opening a search result failed — the paid results
  /// back. Never an empty form.
  const factory IngestionEvent.retry() = _Retry;
}

@freezed
sealed class IngestionState with _$IngestionState {
  const factory IngestionState.idle(RecipeIngestionChannel channel) =
      IngestionIdle;
  const factory IngestionState.parsing(RecipeIngestionChannel channel) =
      IngestionParsing;
  const factory IngestionState.searchResults(
    RecipeIngestionChannel channel,
    List<WebSearchResultEntity> results,
  ) = IngestionSearchResults;

  /// [notice] carries a failed save: the review stays, with what went wrong
  /// said over it.
  const factory IngestionState.review(
    RecipeIngestionChannel channel,
    RecipeEntity recipe, {
    String? notice,
  }) = IngestionReview;

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
    String? notice,

    /// False when the failure was a refusal that stands — out of quota, no
    /// verified phone, a blocked account: the same analysis again would
    /// hit the same wall, so Retry is not offered. The text can still be
    /// saved or edited by hand.
    @Default(true) bool retryable,
  }) = IngestionUnparsed;
  const factory IngestionState.errorMessage(
    RecipeIngestionChannel channel,
    String error,
  ) = IngestionError;
}

class IngestionBloc extends Bloc<IngestionEvent, IngestionState> {
  final ParseRawTextUseCase parseRawTextUseCase;
  final SearchWebRecipesUseCase searchWebRecipesUseCase;
  final ParseRecipeFromUrlUseCase parseRecipeFromUrlUseCase;
  final FetchOriginalRecipePageUseCase fetchOriginalRecipePageUseCase;
  final ParseRecipeFromSocialVideoUseCase parseRecipeFromSocialVideoUseCase;
  final ParseRecipeFromFileUseCase parseRecipeFromFileUseCase;
  final GenerateRecipeUseCase generateRecipeUseCase;
  final SaveRecipeUseCase saveRecipeUseCase;
  final GetUserPreferencesUseCase getUserPreferencesUseCase;

  RecipeIngestionChannel _channel;
  static const _uuid = Uuid();

  /// How long an analysis may run before the raw text is offered instead.
  /// Injectable so a test does not have to wait it out.
  ///
  /// A call has to cross the proxy, wait out a model that is thinking, and come
  /// back — and it may have retried a capacity error on the way. At 30s a
  /// perfectly good answer arriving a second late was thrown away and reported
  /// as a timeout, which is what made the feature feel broken rather than slow.
  final Duration analysisTimeout;

  /// A video is fetched and watched before it is read: two to three times
  /// the budget of a text extraction.
  static const socialTimeout = Duration(seconds: 150);

  IngestionBloc({
    this.analysisTimeout = const Duration(seconds: 45),
    RecipeIngestionChannel initialChannel = RecipeIngestionChannel.rawText,
    required this.parseRawTextUseCase,
    required this.searchWebRecipesUseCase,
    required this.parseRecipeFromUrlUseCase,
    required this.fetchOriginalRecipePageUseCase,
    required this.parseRecipeFromSocialVideoUseCase,
    required this.parseRecipeFromFileUseCase,
    required this.generateRecipeUseCase,
    required this.saveRecipeUseCase,
    required this.getUserPreferencesUseCase,
  }) : _channel = initialChannel,
       super(IngestionState.idle(initialChannel)) {
    on<_SelectChannel>(_selectChannel);
    on<_ParseRawText>(_parseRawText);
    on<_SearchWeb>(_searchWeb);
    on<_ParseUrl>(_parseUrl);
    on<_ViewOriginal>(_viewOriginal);
    on<_ParseSocialVideo>(_parseSocialVideo);
    on<_ParseFiles>(_parseFiles);
    on<_GenerateRecipe>(_generateRecipe);
    on<_UpdateRecipe>(_updateRecipe);
    on<_SaveRecipe>(_saveRecipe);
    on<_SaveAsTemplate>(_saveAsTemplate);
    on<_EditManually>(_editManually);
    on<_Retry>(_retry);
  }

  factory IngestionBloc.fromContext(
    BuildContext context, {
    RecipeIngestionChannel initialChannel = RecipeIngestionChannel.rawText,
  }) {
    return IngestionBloc(
      initialChannel: initialChannel,
      parseRecipeFromFileUseCase: ParseRecipeFromFileUseCase(context.read()),
      parseRawTextUseCase: ParseRawTextUseCase(context.read()),
      searchWebRecipesUseCase: SearchWebRecipesUseCase(context.read()),
      parseRecipeFromUrlUseCase: ParseRecipeFromUrlUseCase(context.read()),
      fetchOriginalRecipePageUseCase: FetchOriginalRecipePageUseCase(
        context.read(),
      ),
      parseRecipeFromSocialVideoUseCase: ParseRecipeFromSocialVideoUseCase(
        context.read(),
      ),
      generateRecipeUseCase: GenerateRecipeUseCase(context.read()),
      saveRecipeUseCase: SaveRecipeUseCase(context.read()),
      getUserPreferencesUseCase: GetUserPreferencesUseCase(context.read()),
    );
  }

  /// The last request that reached the model or the network, so Retry runs
  /// it again instead of dropping the user on an empty form.
  IngestionEvent? _lastRequest;

  /// The last web search's results: a grounded call already paid for, kept
  /// so a failure opening one of them returns to the list.
  List<WebSearchResultEntity>? _lastResults;

  /// Set when the last failure was a refusal that stands — the daily
  /// allowance, no verified phone, a blocked account: running the same
  /// request again would only hit the same wall.
  bool _lastRefused = false;

  String? _draftText;
  RecipeIngestionChannel? _draftChannel;
  List<IngestionFile> _draftFiles = const [];

  /// What the form on [channel] last submitted, to start it filled in
  /// again after a failure.
  String? draftText(RecipeIngestionChannel channel) =>
      _draftChannel == channel ? _draftText : null;

  /// The files last submitted on the file channel.
  List<IngestionFile> get draftFiles => _draftFiles;

  void _remember(IngestionEvent request, {String? text}) {
    _lastRequest = request;
    _lastRefused = false;
    if (text != null) {
      _draftText = text;
      _draftChannel = _channel;
    }
  }

  FutureOr<void> _retry(_Retry event, Emitter<IngestionState> emit) {
    final last = _lastRequest;
    // A failure opening a search result goes back to the results.
    if (_channel == RecipeIngestionChannel.webSearch &&
        last is! _SearchWeb &&
        _lastResults != null) {
      emit(.searchResults(_channel, _lastResults!));
      return null;
    }
    if (last == null || _lastRefused) {
      emit(.idle(_channel));
      return null;
    }
    add(last);
    return null;
  }

  Future<List<DietaryPreference>> get _preferences async =>
      (await getUserPreferencesUseCase()).dietaryPreferences;

  FutureOr<void> _selectChannel(
    _SelectChannel event,
    Emitter<IngestionState> emit,
  ) {
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
    // One analysis at a time: a second submit while the spinner is up (a
    // double tap, a retry fired twice) would run a second model call and
    // spend a second extraction from the allowance for the same text.
    if (state is IngestionParsing) return;
    emit(.parsing(_channel));
    try {
      final timeout = _channel == RecipeIngestionChannel.socialVideo
          ? socialTimeout
          : analysisTimeout;
      final recipe = await parse(await _preferences).timeout(timeout);
      emit(.review(_channel, recipe));
    } on TimeoutException {
      debugPrint('Ingestion timed out after $analysisTimeout');
      await _offerText(
        emit,
        fallbackText,
        sourceUrl: sourceUrl,
        timedOut: true,
      );
    } catch (e) {
      debugPrint('Ingestion error: $e');
      _lastRefused = isStandingRefusal(e);
      await _offerText(
        emit,
        fallbackText,
        sourceUrl: sourceUrl,
        timedOut: false,
        error: e,
      );
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
      emit(.errorMessage(_channel, _describe(error)));
      return;
    }
    // Out of quota, no phone, blocked, or offline: the text is still
    // offered (it can be saved as it is), but with the reason — a bare
    // "analysis failed" sent the user to a Retry that hits the same wall.
    // Offline may clear on its own; the other three stand, so for them
    // Retry is not offered at all.
    final refused = isStandingRefusal(error);
    final notice =
        refused ||
            error is AppException && error.type == AppErrorType.networkError
        ? _describe(error)
        : null;
    emit(
      .unparsed(
        _channel,
        text,
        sourceUrl: sourceUrl,
        timedOut: timedOut,
        notice: notice,
        retryable: !refused,
      ),
    );
  }

  /// A sentence the user can act on, for the failures that have one. The
  /// rest get [fallback] — the raw text is in the debug log, never on screen.
  String _describe(Object? error, [String? fallback]) {
    if (isAccountDisabled(error)) return t.auth.blockedTitle;
    if (error is AppException) {
      switch (error.type) {
        case AppErrorType.unreadableSource:
          return t.ingestion.socialUnreadable;
        case AppErrorType.quotaExceeded:
          return t.ads.aiQuotaReached;
        case AppErrorType.networkError:
          return t.common.networkError;
        case AppErrorType.phoneRequired:
          return t.auth.phoneGateTitle;
        default:
          break;
      }
    }
    if (error == null) return t.ingestion.analysisTimedOut;
    return fallback ?? t.ingestion.analysisFailed;
  }

  RecipeEntity _template(String text, String? sourceUrl) => buildTemplateRecipe(
    id: _uuid.v4(),
    text: text,
    channel: _channel,
    untitled: t.ingestion.untitledRecipe,
    sourceUrl: sourceUrl,
  );

  /// True while a save is on its way: a second tap would mint a second
  /// template (each gets a new id) or save the same recipe twice.
  bool _saving = false;

  /// Saves [recipe] once; a failure keeps the screen as it was, with the
  /// reason on it, instead of leaving the user on it with no word.
  Future<void> _saveOnce(
    RecipeEntity recipe,
    Emitter<IngestionState> emit,
  ) async {
    if (_saving) return;
    _saving = true;
    try {
      await saveRecipeUseCase(recipe);
      emit(const IngestionState.saved());
    } catch (e) {
      debugPrint('Saving the recipe failed: $e');
      final current = state;
      final notice = t.ingestion.saveFailed;
      // Cleared first, so a second failure in a row is still a change.
      switch (current) {
        case IngestionReview(:final channel, recipe: final shown):
          emit(.review(channel, shown));
          emit(.review(channel, shown, notice: notice));
        case IngestionUnparsed(
          :final channel,
          :final text,
          :final sourceUrl,
          :final timedOut,
          :final retryable,
        ):
          emit(
            .unparsed(
              channel,
              text,
              sourceUrl: sourceUrl,
              timedOut: timedOut,
              retryable: retryable,
            ),
          );
          emit(
            .unparsed(
              channel,
              text,
              sourceUrl: sourceUrl,
              timedOut: timedOut,
              notice: notice,
              retryable: retryable,
            ),
          );
        default:
          // Saved from the form (a hand-written recipe from the blank
          // editor): an error screen would lose it, and its Retry would run
          // some earlier request instead. The recipe stays up to save again.
          emit(.review(_channel, recipe, notice: notice));
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> _saveAsTemplate(
    _SaveAsTemplate event,
    Emitter<IngestionState> emit,
  ) => _saveOnce(_template(event.text, event.sourceUrl), emit);

  FutureOr<void> _editManually(
    _EditManually event,
    Emitter<IngestionState> emit,
  ) {
    emit(.review(_channel, _template(event.text, event.sourceUrl)));
  }

  Future<void> _parseRawText(
    _ParseRawText event,
    Emitter<IngestionState> emit,
  ) {
    _remember(event, text: event.text);
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

  /// False, with the "not a link" error shown, for anything that is not an
  /// http(s) address: the backstop behind the form's own check, and the
  /// only check for a link that came from a search result or a share.
  bool _acceptUrl(String url, Emitter<IngestionState> emit) {
    if (IngestionLaunch.isWebUrl(url)) return true;
    emit(.errorMessage(_channel, t.ingestion.invalidUrl));
    return false;
  }

  Future<void> _parseUrl(_ParseUrl event, Emitter<IngestionState> emit) {
    if (!_acceptUrl(event.url, emit)) return Future.value();
    // From a search result the form's query stays the draft, not the link.
    _remember(
      event,
      text: _channel == RecipeIngestionChannel.webSearch ? null : event.url,
    );
    return _runParse(
      emit,
      (prefs) => parseRecipeFromUrlUseCase(event.url, preferences: prefs),
      fallbackText: () => _pageText(event.url),
      sourceUrl: event.url,
    );
  }

  /// Reuses the parsing spinner while the page loads — it is the same "hold
  /// on" from the user's side, just much shorter.
  Future<void> _viewOriginal(
    _ViewOriginal event,
    Emitter<IngestionState> emit,
  ) async {
    if (!_acceptUrl(event.url, emit)) return;
    _remember(
      event,
      text: _channel == RecipeIngestionChannel.webSearch ? null : event.url,
    );
    emit(.parsing(_channel));
    try {
      emit(
        .original(_channel, await fetchOriginalRecipePageUseCase(event.url)),
      );
    } catch (e) {
      debugPrint('Original page error: $e');
      emit(.errorMessage(_channel, _describe(e, t.ingestion.fetchFailed)));
    }
  }

  Future<void> _parseSocialVideo(
    _ParseSocialVideo event,
    Emitter<IngestionState> emit,
  ) {
    if (!_acceptUrl(event.url, emit)) return Future.value();
    _remember(event, text: event.url);
    return _runParse(
      emit,
      (prefs) =>
          parseRecipeFromSocialVideoUseCase(event.url, preferences: prefs),
      fallbackText: () => _pageText(event.url),
      sourceUrl: event.url,
    );
  }

  /// A recording or a PDF has no text to fall back on: a failure is an
  /// error with a retry, not a template.
  Future<void> _parseFiles(_ParseFiles event, Emitter<IngestionState> emit) {
    _remember(event);
    _draftFiles = List.unmodifiable(event.files);
    return _runParse(
      emit,
      (prefs) => parseRecipeFromFileUseCase(event.files, preferences: prefs),
      fallbackText: () async => null,
    );
  }

  /// The request itself is the fallback: kept as a template it can be run
  /// again later from the details screen, the same as pasted text.
  Future<void> _generateRecipe(
    _GenerateRecipe event,
    Emitter<IngestionState> emit,
  ) {
    _remember(event, text: event.request);
    return _runParse(
      emit,
      (prefs) => generateRecipeUseCase(event.request, preferences: prefs),
      fallbackText: () async => event.request,
    );
  }

  Future<void> _searchWeb(
    _SearchWeb event,
    Emitter<IngestionState> emit,
  ) async {
    // Same rule as [_runParse]: a search is a grounded model call, and a
    // second submit while the first is running would pay for it twice.
    if (state is IngestionParsing) return;
    _remember(event, text: event.query);
    emit(.parsing(_channel));
    try {
      final results = await searchWebRecipesUseCase(
        event.query,
        preferences: await _preferences,
      );
      _lastResults = results;
      emit(.searchResults(_channel, results));
    } catch (e) {
      debugPrint('Web search error: $e');
      _lastRefused = isStandingRefusal(e);
      emit(.errorMessage(_channel, _describe(e, t.common.loadFailed)));
    }
  }

  /// The editor hands back the whole recipe, so the review simply re-renders
  /// what came out of it — nothing is persisted until the user saves.
  FutureOr<void> _updateRecipe(
    _UpdateRecipe event,
    Emitter<IngestionState> emit,
  ) {
    emit(.review(_channel, event.recipe));
  }

  Future<void> _saveRecipe(
    _SaveRecipe event,
    Emitter<IngestionState> emit,
  ) => _saveOnce(event.recipe, emit);
}
