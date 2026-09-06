import 'dart:convert';

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
  Future<RecipeEntity> refineRecipe(RecipeEntity recipe, {required bool timesChanged});
}

/// Calls the Gemini Interactions API over raw HTTP (there is no official Google
/// GenAI Dart SDK). Extraction runs in structured-output mode so the model's
/// answer validates against the recipe shape, and the `url_context` /
/// `google_search` server tools handle fetching and searching.
class GeminiRecipeAiDataSource implements RecipeAiDataSource {
  final HttpCalls httpCalls;
  static const _uuid = Uuid();

  GeminiRecipeAiDataSource({HttpCalls? httpCalls})
      : httpCalls = httpCalls ??
            HttpCalls(
              baseUrl: ApiConfig.aiBaseUrl,
              // Must be x-goog-api-key. An `Authorization: Bearer` header takes
              // precedence at the edge and is read as an OAuth2 token, which
              // fails the key with ACCESS_TOKEN_TYPE_UNSUPPORTED.
              headers: {'x-goog-api-key': ApiConfig.geminiApiKey},
            );

  static const _systemPrompt = '''
אתה מנתח מתכונים. החזר אך ורק מידע שמופיע במקור.
מדיניות אפס הזיות: אסור להמציא מצרכים, כמויות, יחידות מידה או שלבים שאינם מופיעים במקור.
אם כמות, יחידה או זמן חסרים במקור — השמט את השדה לגמרי. אל תנחש.
המר כמויות ליחידות מטריות כאשר המקור מציין יחידה ברורה.
שמור על סדר השלבים כפי שהוא במקור.
החזר JSON בלבד, ללא טקסט נלווה וללא גדרות קוד.''';

  /// Optional fields are deliberately left out of `required` rather than typed
  /// as nullable — an omitted key is how the model says "the source does not
  /// say", and it keeps the schema inside the subset Gemini accepts.
  static const _recipeSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Dish title as written in the source'},
      'prep_time_minutes': {
        'type': 'integer',
        'description': 'Preparation time in minutes. Omit if the source does not state it',
      },
      'cook_time_minutes': {
        'type': 'integer',
        'description': 'Cook time in minutes. Omit if the source does not state it',
      },
      'ingredients': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'amount': {
              'type': 'number',
              'description': 'Numeric amount. Omit if the source omits it',
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
          'required': ['name', 'unit'],
        },
      },
      'steps': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Ordered preparation steps, without numbering prefixes',
      },
    },
    'required': ['title', 'ingredients', 'steps'],
  };

  static const _searchResultsSchema = {
    'type': 'object',
    'properties': {
      'results': {
        'type': 'array',
        'items': {
          'type': 'object',
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
  };

  static const _refineSystemPrompt = '''
אתה מגיה עברית של מתכונים. הטקסט הוקלד בנייד ולכן הוא מלא בשגיאות הקלדה.
המשימה העיקרית שלך: לתקן כל שגיאת כתיב והקלדה בכותרת, בשמות המצרכים ובשלבי ההכנה.

רוב השגיאות הן אותיות שכנות במקלדת העברית או אות סופית במקום רגילה. תקן אותן תמיד:
"ןאז" → "ואז"
"עפ מלח" → "עם מלח"
"לאיזב דקה" → "לאיזה דקה"
"מערביפ" → "מערבים"
"בסיר" נשאר "בסיר" — מילה תקינה לא משתנה.
כל מילה שאינה מילה תקינה בעברית היא שגיאת הקלדה שצריך לתקן למילה הקרובה ביותר שמתאימה להקשר של המתכון.

בנוסף: עדכן זמנים שמוזכרים בתוך טקסט השלבים כך שיתאימו לזמן ההכנה ולזמן הבישול שהמשתמש קבע.

מגבלות:
אסור להוסיף, למחוק, לפצל או לאחד מצרכים או שלבים — החזר בדיוק את אותו מספר פריטים ובאותו סדר.
אסור לשנות כמויות, יחידות מידה, או את הזמנים המספריים עצמם.
אל תשנה סגנון או ניסוח של טקסט תקין — רק שגיאות.
החזר JSON בלבד, ללא טקסט נלווה וללא גדרות קוד.''';

  /// Only the free-text fields come back. Amounts, units and the times the user
  /// set are merged in locally, so a refine can never restructure the recipe.
  static const _refineSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string'},
      'ingredient_names': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Same names in the same order, spelling corrected',
      },
      'steps': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Same steps in the same order, spelling and stated times corrected',
      },
    },
    'required': ['title', 'ingredient_names', 'steps'],
  };

  Map<String, dynamic> _body({
    required String input,
    required Map<String, dynamic> schema,
    String systemInstruction = _systemPrompt,
    List<Map<String, dynamic>> tools = const [],
    String model = ApiConfig.model,
  }) {
    return {
      'model': model,
      'system_instruction': systemInstruction,
      'input': input,
      if (tools.isNotEmpty) 'tools': tools,
      'response_format': {
        'type': 'text',
        'mime_type': 'application/json',
        'schema': schema,
      },
    };
  }

  void _assertConfigured() {
    if (!ApiConfig.isConfigured) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'GEMINI_API_KEY is not configured',
      );
    }
  }

  /// The model's answer sits in the `model_output` step, but tool-using turns
  /// interleave thought and tool steps around it, so every text block is
  /// collected and the JSON object is taken from the tail of the result.
  String _extractText(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    for (final step in (data['steps'] as List?) ?? const []) {
      if (step is! Map) continue;
      for (final block in (step['content'] as List?) ?? const []) {
        if (block is Map && block['text'] is String) buffer.write(block['text']);
      }
    }

    return buffer.toString();
  }

  /// Capacity spikes on a hot model answer with a retryable status rather than
  /// a permanent failure, so the identical request is worth re-sending before
  /// surfacing the error to the user.
  Future<Map<String, dynamic>> _callStructured(Map<String, dynamic> body) async {
    _assertConfigured();

    Map<String, dynamic>? data;
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await httpCalls.post(ApiConfig.interactionsPath, data: body);
        data = response?.data as Map<String, dynamic>?;
        break;
      } on AppException catch (e) {
        if (e.type != AppErrorType.overloaded || attempt >= 2) rethrow;
        debugPrint('Gemini busy, retrying (attempt ${attempt + 1}): ${e.message}');
        await Future.delayed(Duration(seconds: 2 << attempt));
      }
    }
    if (data == null) throw const AppException(AppErrorType.parsingFailed);

    final text = _extractText(data);
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) {
      debugPrint('Gemini returned no JSON object: $text');
      throw const AppException(
        AppErrorType.parsingFailed,
        message: 'No recipe returned by the model',
      );
    }

    try {
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } on FormatException catch (e) {
      debugPrint('Gemini JSON decode failed: $e');
      throw AppException(AppErrorType.parsingFailed, message: e.message);
    }
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
    final input = await _callStructured(
      _body(
        input: 'נתח את המתכון הבא לפורמט מובנה:\n\n$text',
        schema: _recipeSchema,
      ),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.rawText);
  }

  @override
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences) async {
    final input = await _callStructured(
      _body(
        input:
            'שלוף את המתכון מהכתובת הבאה והחזר אותו בפורמט מובנה. התעלם מפרסומות ותוכן שאינו חלק מהמתכון.\n$url',
        schema: _recipeSchema,
        tools: const [
          {'type': 'url_context'},
        ],
      ),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.urlScrape, sourceUrl: url);
  }

  /// Tier 1 of the social pipeline: title, caption and visible page text.
  /// Tier 2 (audio transcription + on-screen OCR) needs a video-processing
  /// service that this client does not have access to.
  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences) async {
    final input = await _callStructured(
      _body(
        input:
            'שלוף את המתכון מהכותרת, מהתיאור ומהתגובות בעמוד הסרטון הבא. אם אין מספיק מידע למתכון מלא, החזר את מה שקיים בלבד.\n$url',
        schema: _recipeSchema,
        tools: const [
          {'type': 'url_context'},
        ],
      ),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.socialVideo, sourceUrl: url);
  }

  @override
  Future<List<WebSearchResultEntity>> searchWeb(
    String query,
    List<DietaryPreference> preferences,
  ) async {
    final data = await _callStructured(
      _body(
        input: 'חפש 3 עד 5 מתכונים באינטרנט עבור: $query.${_dietaryHint(preferences)}',
        schema: _searchResultsSchema,
        tools: const [
          {'type': 'google_search'},
        ],
        model: ApiConfig.searchModel,
      ),
    );

    return ((data['results'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((r) => WebSearchResultEntity(
              title: r['title'] as String,
              url: r['url'] as String,
              snippet: r['snippet'] as String,
            ))
        .toList();
  }

  @override
  Future<RecipeEntity> refineRecipe(RecipeEntity recipe, {required bool timesChanged}) async {
    final payload = jsonEncode({
      'title': recipe.title,
      'prep_time_minutes': recipe.prepTimeMinutes,
      'cook_time_minutes': recipe.cookTimeMinutes,
      'ingredient_names': recipe.ingredients.map((i) => i.name).toList(),
      'steps': recipe.steps,
    });

    final instruction = timesChanged
        ? 'המשתמש שינה את זמן ההכנה או את זמן הבישול. תקן שגיאות כתיב, וגם ודא שכל זמן שמוזכר בתוך שלבי ההכנה תואם לזמנים החדשים.'
        : 'תקן שגיאות כתיב ודקדוק בלבד.';

    final data = await _callStructured(
      _body(
        input: '$instruction\n\n$payload',
        schema: _refineSchema,
        systemInstruction: _refineSystemPrompt,
      ),
    );

    final title = data['title'];
    final names = ((data['ingredient_names'] as List?) ?? const []).whereType<String>().toList();
    final steps = ((data['steps'] as List?) ?? const []).whereType<String>().toList();

    // A changed length means the model restructured the recipe instead of only
    // rewording it, so that part falls back to exactly what the user typed.
    return recipe.copyWith(
      title: title is String && title.trim().isNotEmpty ? title.trim() : recipe.title,
      ingredients: names.length == recipe.ingredients.length
          ? [
              for (var i = 0; i < names.length; i++)
                RecipeIngredientEntity(
                  name: names[i],
                  amount: recipe.ingredients[i].amount,
                  unit: recipe.ingredients[i].unit,
                ),
            ]
          : recipe.ingredients,
      steps: steps.length == recipe.steps.length ? steps : recipe.steps,
    );
  }
}
