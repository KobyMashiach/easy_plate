import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/http_calls.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';

abstract class RecipeAiDataSource {
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences);
  Future<List<WebSearchResultEntity>> searchWeb(String query, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences);
}

/// Calls the Claude Messages API over raw HTTP (there is no official Anthropic
/// Dart SDK). Structured extraction uses a strict tool schema so the model's
/// output validates exactly against the recipe shape.
class ClaudeRecipeAiDataSource implements RecipeAiDataSource {
  final HttpCalls httpCalls;
  static const _uuid = Uuid();

  ClaudeRecipeAiDataSource({HttpCalls? httpCalls})
      : httpCalls = httpCalls ??
            HttpCalls(
              baseUrl: ApiConfig.aiBaseUrl,
              headers: {
                'x-api-key': ApiConfig.anthropicApiKey,
                'anthropic-version': ApiConfig.anthropicVersion,
              },
            );

  static const _systemPrompt = '''
אתה מנתח מתכונים. החזר אך ורק מידע שמופיע במקור.
מדיניות אפס הזיות: אסור להמציא מצרכים, כמויות, יחידות מידה או שלבים שאינם מופיעים במקור.
אם כמות, יחידה או זמן חסרים במקור — החזר null עבורם. אל תנחש.
המר כמויות ליחידות מטריות כאשר המקור מציין יחידה ברורה.
שמור על סדר השלבים כפי שהוא במקור.''';

  static final _saveRecipeTool = {
    'name': 'save_recipe',
    'description': 'Records the recipe exactly as it appears in the source material.',
    'strict': true,
    'input_schema': {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'title': {'type': 'string', 'description': 'Dish title as written in the source'},
        'prep_time_minutes': {
          'type': ['integer', 'null'],
          'description': 'Preparation time in minutes, or null if the source does not state it',
        },
        'cook_time_minutes': {
          'type': ['integer', 'null'],
          'description': 'Cook time in minutes, or null if the source does not state it',
        },
        'ingredients': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              'name': {'type': 'string'},
              'amount': {
                'type': ['number', 'null'],
                'description': 'Numeric amount, or null if the source omits it',
              },
              'unit': {
                'type': 'string',
                'enum': [
                  'gram',
                  'kilogram',
                  'milliliter',
                  'liter',
                  'teaspoon',
                  'tablespoon',
                  'cup',
                  'unit',
                  'pinch',
                  'unspecified',
                ],
              },
            },
            'required': ['name', 'amount', 'unit'],
          },
        },
        'steps': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Ordered preparation steps, without numbering prefixes',
        },
      },
      'required': ['title', 'prep_time_minutes', 'cook_time_minutes', 'ingredients', 'steps'],
    },
  };

  Map<String, dynamic> _baseBody({
    required String userContent,
    List<Map<String, dynamic>> extraTools = const [],
    bool forceSaveRecipe = true,
  }) {
    return {
      'model': ApiConfig.model,
      'max_tokens': ApiConfig.maxTokens,
      'output_config': {'effort': 'low'},
      'system': _systemPrompt,
      'tools': [...extraTools, _saveRecipeTool],
      if (forceSaveRecipe) 'tool_choice': {'type': 'tool', 'name': 'save_recipe'},
      'messages': [
        {'role': 'user', 'content': userContent},
      ],
    };
  }

  void _assertConfigured() {
    if (!ApiConfig.isConfigured) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'ANTHROPIC_API_KEY is not configured',
      );
    }
  }

  Future<Map<String, dynamic>> _callToolUse(Map<String, dynamic> body) async {
    _assertConfigured();
    var request = Map<String, dynamic>.from(body);

    // Server tools (web_search / web_fetch) can hand back a pause_turn; resume
    // by echoing the assistant content until the model reaches save_recipe.
    for (var attempt = 0; attempt < 4; attempt++) {
      final response = await httpCalls.post(ApiConfig.messagesPath, data: request);
      final data = response?.data as Map<String, dynamic>?;
      if (data == null) throw const AppException(AppErrorType.parsingFailed);

      final content = (data['content'] as List?) ?? const [];
      final toolUse = content.cast<Map<String, dynamic>>().firstWhere(
            (block) => block['type'] == 'tool_use' && block['name'] == 'save_recipe',
            orElse: () => const {},
          );
      if (toolUse.isNotEmpty) return toolUse['input'] as Map<String, dynamic>;

      if (data['stop_reason'] != 'pause_turn') break;

      final messages = [...request['messages'] as List];
      messages.add({'role': 'assistant', 'content': content});
      request = {...request, 'messages': messages};
    }

    throw const AppException(AppErrorType.parsingFailed, message: 'No recipe returned by the model');
  }

  RecipeEntity _toEntity(
    Map<String, dynamic> input, {
    required RecipeIngestionChannel channel,
    String? sourceUrl,
    List<DietaryPreference> dietaryTags = const [],
  }) {
    final ingredients = ((input['ingredients'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((raw) => RecipeIngredientEntity(
              name: raw['name'] as String,
              amount: (raw['amount'] as num?)?.toDouble(),
              unit: MeasurementUnit.values.firstWhere(
                (u) => u.name == raw['unit'],
                orElse: () => MeasurementUnit.unspecified,
              ),
            ))
        .toList();

    return RecipeEntity(
      id: _uuid.v4(),
      title: input['title'] as String,
      prepTimeMinutes: (input['prep_time_minutes'] as num?)?.toInt(),
      cookTimeMinutes: (input['cook_time_minutes'] as num?)?.toInt(),
      ingredients: ingredients,
      steps: ((input['steps'] as List?) ?? const []).cast<String>(),
      dietaryTags: dietaryTags,
      sourceChannel: channel,
      sourceUrl: sourceUrl,
      createdAt: DateTime.now(),
    );
  }

  String _dietaryHint(List<DietaryPreference> preferences) {
    if (preferences.isEmpty) return '';
    return '\nהעדפות תזונתיות של המשתמש: ${preferences.map((p) => p.name).join(', ')}.';
  }

  @override
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences) async {
    final input = await _callToolUse(
      _baseBody(userContent: 'נתח את המתכון הבא לפורמט מובנה:\n\n$text'),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.rawText);
  }

  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences) async {
    final input = await _callToolUse(
      _baseBody(
        userContent:
            'שלוף את המתכון מהכתובת הבאה והחזר אותו בפורמט מובנה. התעלם מפרסומות ותוכן שאינו חלק מהמתכון.\n$url',
        extraTools: [
          {'type': 'web_fetch_20260209', 'name': 'web_fetch', 'max_uses': 3},
        ],
        forceSaveRecipe: false,
      ),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.urlScrape, sourceUrl: url);
  }

  /// Tier 1 of the social pipeline: title, caption and visible page text.
  /// Tier 2 (audio transcription + on-screen OCR) needs a video-processing
  /// service that this client does not have access to.
  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences) async {
    final input = await _callToolUse(
      _baseBody(
        userContent:
            'שלוף את המתכון מהכותרת, מהתיאור ומהתגובות בעמוד הסרטון הבא. אם אין מספיק מידע למתכון מלא, החזר את מה שקיים בלבד.\n$url',
        extraTools: [
          {'type': 'web_fetch_20260209', 'name': 'web_fetch', 'max_uses': 3},
        ],
        forceSaveRecipe: false,
      ),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.socialVideo, sourceUrl: url);
  }

  @override
  Future<List<WebSearchResultEntity>> searchWeb(
    String query,
    List<DietaryPreference> preferences,
  ) async {
    _assertConfigured();
    final body = {
      'model': ApiConfig.model,
      'max_tokens': ApiConfig.maxTokens,
      'output_config': {'effort': 'low'},
      'tools': [
        {'type': 'web_search_20260209', 'name': 'web_search', 'max_uses': 3},
        {
          'name': 'return_results',
          'description': 'Returns the recipe pages found for the query.',
          'strict': true,
          'input_schema': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              'results': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'additionalProperties': false,
                  'properties': {
                    'title': {'type': 'string'},
                    'url': {'type': 'string'},
                    'snippet': {'type': 'string'},
                  },
                  'required': ['title', 'url', 'snippet'],
                },
              },
            },
            'required': ['results'],
          },
        },
      ],
      'messages': [
        {
          'role': 'user',
          'content':
              'חפש 3 עד 5 מתכונים באינטרנט עבור: $query.${_dietaryHint(preferences)}\nהחזר את התוצאות באמצעות return_results.',
        },
      ],
    };

    var request = Map<String, dynamic>.from(body);
    for (var attempt = 0; attempt < 4; attempt++) {
      final response = await httpCalls.post(ApiConfig.messagesPath, data: request);
      final data = response?.data as Map<String, dynamic>?;
      if (data == null) throw const AppException(AppErrorType.parsingFailed);

      final content = (data['content'] as List?) ?? const [];
      final toolUse = content.cast<Map<String, dynamic>>().firstWhere(
            (block) => block['type'] == 'tool_use' && block['name'] == 'return_results',
            orElse: () => const {},
          );
      if (toolUse.isNotEmpty) {
        final results = ((toolUse['input'] as Map<String, dynamic>)['results'] as List?) ?? const [];
        return results
            .cast<Map<String, dynamic>>()
            .map((r) => WebSearchResultEntity(
                  title: r['title'] as String,
                  url: r['url'] as String,
                  snippet: r['snippet'] as String,
                ))
            .toList();
      }

      if (data['stop_reason'] != 'pause_turn') break;
      final messages = [...request['messages'] as List];
      messages.add({'role': 'assistant', 'content': content});
      request = {...request, 'messages': messages};
    }

    debugPrint('Web recipe search returned no structured results');
    return [];
  }
}
