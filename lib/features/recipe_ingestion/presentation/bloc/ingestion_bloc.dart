import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/usecases/save_recipe_usecase.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/web_search_result_entity.dart';
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
  const factory IngestionEvent.parseSocialVideo(String url) = _ParseSocialVideo;
  const factory IngestionEvent.updateRecipe(RecipeEntity recipe) = _UpdateRecipe;
  const factory IngestionEvent.saveRecipe(RecipeEntity recipe) = _SaveRecipe;
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
  const factory IngestionState.saved() = IngestionSaved;
  const factory IngestionState.errorMessage(RecipeIngestionChannel channel, String error) =
      IngestionError;
}

class IngestionBloc extends Bloc<IngestionEvent, IngestionState> {
  final ParseRawTextUseCase parseRawTextUseCase;
  final SearchWebRecipesUseCase searchWebRecipesUseCase;
  final ParseRecipeFromUrlUseCase parseRecipeFromUrlUseCase;
  final ParseRecipeFromSocialVideoUseCase parseRecipeFromSocialVideoUseCase;
  final SaveRecipeUseCase saveRecipeUseCase;
  final GetUserPreferencesUseCase getUserPreferencesUseCase;

  RecipeIngestionChannel _channel = RecipeIngestionChannel.rawText;

  IngestionBloc({
    required this.parseRawTextUseCase,
    required this.searchWebRecipesUseCase,
    required this.parseRecipeFromUrlUseCase,
    required this.parseRecipeFromSocialVideoUseCase,
    required this.saveRecipeUseCase,
    required this.getUserPreferencesUseCase,
  }) : super(const IngestionState.idle(RecipeIngestionChannel.rawText)) {
    on<_SelectChannel>(_selectChannel);
    on<_ParseRawText>(_parseRawText);
    on<_SearchWeb>(_searchWeb);
    on<_ParseUrl>(_parseUrl);
    on<_ParseSocialVideo>(_parseSocialVideo);
    on<_UpdateRecipe>(_updateRecipe);
    on<_SaveRecipe>(_saveRecipe);
  }

  factory IngestionBloc.fromContext(BuildContext context) {
    return IngestionBloc(
      parseRawTextUseCase: ParseRawTextUseCase(context.read()),
      searchWebRecipesUseCase: SearchWebRecipesUseCase(context.read()),
      parseRecipeFromUrlUseCase: ParseRecipeFromUrlUseCase(context.read()),
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

  Future<void> _runParse(
    Emitter<IngestionState> emit,
    Future<RecipeEntity> Function(List<DietaryPreference> preferences) parse,
  ) async {
    emit(.parsing(_channel));
    try {
      final recipe = await parse(await _preferences);
      emit(.review(_channel, recipe));
    } catch (e) {
      debugPrint('Ingestion error: $e');
      emit(.errorMessage(_channel, e.toString()));
    }
  }

  Future<void> _parseRawText(_ParseRawText event, Emitter<IngestionState> emit) {
    return _runParse(emit, (prefs) => parseRawTextUseCase(event.text, preferences: prefs));
  }

  Future<void> _parseUrl(_ParseUrl event, Emitter<IngestionState> emit) {
    return _runParse(emit, (prefs) => parseRecipeFromUrlUseCase(event.url, preferences: prefs));
  }

  Future<void> _parseSocialVideo(_ParseSocialVideo event, Emitter<IngestionState> emit) {
    return _runParse(
      emit,
      (prefs) => parseRecipeFromSocialVideoUseCase(event.url, preferences: prefs),
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
