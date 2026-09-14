import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';

abstract class RecipeAiDataSource {
  Future<RecipeEntity> parseRawText(String text, List<DietaryPreference> preferences);
  Future<List<WebSearchResultEntity>> searchWeb(String query, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromUrl(String url, List<DietaryPreference> preferences);
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences);
  Future<RecipeEntity> generateRecipe(String request, List<DietaryPreference> preferences);
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
      : httpCalls = httpCalls ?? _defaultHttpCalls();

  /// Two transports behind one interface. Against our proxy the credential is
  /// the signed-in user, resolved per request because ID tokens expire. Against
  /// Google it is the development key.
  static HttpCalls _defaultHttpCalls() {
    if (ApiConfig.usesProxy) {
      return HttpCalls(
        baseUrl: ApiConfig.aiBaseUrl,
        headerProvider: aiProxyAuthHeader,
      );
    }
    return HttpCalls(
      baseUrl: ApiConfig.aiBaseUrl,
      // Must be x-goog-api-key. An `Authorization: Bearer` header takes
      // precedence at the edge and is read as an OAuth2 token, which
      // fails the key with ACCESS_TOKEN_TYPE_UNSUPPORTED.
      headers: {'x-goog-api-key': ApiConfig.geminiApiKey},
    );
  }

  /// How the dietary tags are decided, appended to every prompt that returns
  /// a recipe. Decided from the ingredient list, never from the title or a
  /// hunch — an unjustified "kosher" or "gluten free" is worse than none, so
  /// the rule for every tag is "only when the ingredients show it".
  static const _dietaryTagRules = '''
בנוסף, קבע את התגיות התזונתיות של המתכון בשדה dietary_tags — אך ורק לפי רשימת המצרכים, לא לפי הכותרת ולא לפי ניחוש:
meat — המתכון מכיל בשר, עוף או מוצריהם.
dairy — המתכון מכיל חלב, גבינה, חמאה, שמנת, יוגורט או מוצר חלב אחר.
vegetarian — אין במתכון בשר, עוף או דגים (ביצים ומוצרי חלב מותרים).
vegan — אין במתכון שום מוצר מן החי: לא בשר, לא דגים, לא ביצים, לא חלב ולא דבש. מתכון טבעוני הוא גם צמחוני — סמן את שתי התגיות.
kosher — רק אם אין במתכון מאכלים אסורים (חזיר, פירות ים, דגים ללא סנפיר וקשקשת) וגם אין ערבוב של בשר עם חלב באותו מתכון.
glutenFree — רק אם אין במתכון קמח חיטה, לחם, פסטה, קוסקוס, סולת, בורגול, שעורה, שיפון, שיבולת שועל רגילה, רוטב סויה או כל מצרך אחר שמכיל גלוטן.
allergy — אם ורק אם שדה allergens אינו ריק.
תגית נקבעת רק כשהמצרכים מצדיקים אותה בבירור. בספק — אל תסמן.

קבע גם את שדה allergens — האלרגנים שנמצאים בפועל במצרכים, מתוך הרשימה הזו בלבד:
gluten (חיטה, קמח, לחם, פסטה, קוסקוס, סולת, בורגול, שעורה, שיפון), milk (חלב, גבינה, חמאה, שמנת, יוגורט), eggs (ביצים), fish (דגים), shellfish (פירות ים), peanuts (בוטנים), treeNuts (שקדים, אגוזי מלך, אגוזי לוז, קשיו, פיסטוק, פקאן), sesame (שומשום, טחינה), soy (סויה, רוטב סויה, טופו).
שדה may_contain — רק אלרגנים שהמקור מציין במפורש שהמתכון עלול להכיל אותם (למשל "עלול להכיל עקבות אגוזים"). בלי ציון מפורש כזה — רשימה ריקה. אל תנחש.''';

  static const _systemPrompt = '''
אתה מנתח מתכונים. החזר אך ורק מידע שמופיע במקור.
מדיניות אפס הזיות: אסור להמציא מצרכים, כמויות, יחידות מידה או שלבים שאינם מופיעים במקור.
אם כמות, יחידה או זמן חסרים במקור — השמט את השדה לגמרי. אל תנחש.
המר כמויות ליחידות מטריות כאשר המקור מציין יחידה ברורה.
שמור על סדר השלבים כפי שהוא במקור.
$_dietaryTagRules
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
      'dietary_tags': {
        'type': 'array',
        'items': {
          'type': 'string',
          // Mirrors DietaryPreference by name; a value the model returns
          // outside this list is dropped by dietaryTagsFromModel.
          'enum': ['meat', 'dairy', 'vegetarian', 'vegan', 'kosher', 'glutenFree', 'allergy'],
        },
        'description':
            'Dietary tags decided from the ingredient list alone. Empty when none clearly applies',
      },
      'allergens': {
        'type': 'array',
        'items': {'type': 'string', 'enum': _allergenNames},
        'description': 'Allergens actually present in the ingredient list',
      },
      'may_contain': {
        'type': 'array',
        'items': {'type': 'string', 'enum': _allergenNames},
        'description':
            'Allergens the source explicitly warns may be present as traces. Empty unless stated',
      },
    },
    // The tags and allergens are required so the model always rules on them —
    // an empty list is an answer, a missing key would be silence.
    'required': ['title', 'ingredients', 'steps', 'dietary_tags', 'allergens', 'may_contain'],
  };

  // Mirrors Allergen by name.
  static const _allergenNames = [
    'gluten',
    'milk',
    'eggs',
    'fish',
    'shellfish',
    'peanuts',
    'treeNuts',
    'sesame',
    'soy',
  ];

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

  /// The one prompt that *wants* the model to fill things in. Every other call
  /// is an extraction under a no-invention rule; here there is no source, and
  /// a recipe with amounts and times left out would be useless to cook from.
  static const _generateSystemPrompt = '''
אתה שף ומפתח מתכונים. המשתמש מתאר מנה שהוא רוצה להכין, ואתה כותב לו מתכון מלא ומעשי.
כתוב את המתכון בשפה שבה נכתבה הבקשה.
המתכון חייב להיות שלם: כותרת קצרה, זמן הכנה וזמן בישול בדקות, רשימת מצרכים עם כמות ויחידת מידה לכל מצרך, ושלבי הכנה ברורים לפי הסדר.
השתמש ביחידות מטריות (גרם, מ"ל, כפית, כף, כוס, יחידה).
התאם את המתכון לכל דרישה שבבקשה — גיל, אלרגיות, העדפות תזונתיות, כמות סועדים, זמן — ולהעדפות התזונתיות של המשתמש אם צוינו. אם הבקשה מזכירה תינוק או ילד קטן, הקפד על התאמה בטיחותית לגיל (ללא דבש מתחת לגיל שנה, ללא מלח או סוכר מוספים לתינוקות, מרקם מתאים).
$_dietaryTagRules
אל תוסיף הערות, הקדמות או הסברים מחוץ למבנה. החזר JSON בלבד, ללא טקסט נלווה וללא גדרות קוד.''';

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
    String thinkingLevel = ApiConfig.thinkingLevel,
  }) {
    return {
      'model': model,
      'system_instruction': systemInstruction,
      'input': input,
      if (tools.isNotEmpty) 'tools': tools,
      // Left out entirely when blank, so an empty define hands the decision
      // back to the model's own default rather than sending an invalid level.
      if (thinkingLevel.isNotEmpty)
        'generation_config': {'thinking_level': thinkingLevel},
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

  /// Headers that let the proxy cache a link extraction by its URL.
  ///
  /// The proxy answers a link it has already extracted from Firestore rather
  /// than from Gemini — a recipe page does not change between two people
  /// pasting it, and the model call is the one thing here that costs money.
  /// [kind] keeps the web and social prompts apart: they ask for different
  /// things from the same URL. Ignored by Google when talking to it directly.
  static Map<String, String> sourceUrlHeaders(String url, {required String kind}) => {
        'x-easyplate-source-url': url,
        'x-easyplate-source-kind': kind,
      };

  /// Capacity spikes on a hot model answer with a retryable status rather than
  /// a permanent failure, so the identical request is worth re-sending before
  /// surfacing the error to the user.
  Future<Map<String, dynamic>> _callStructured(
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    _assertConfigured();

    Map<String, dynamic>? data;
    for (var attempt = 0; ; attempt++) {
      try {
        final response =
            await httpCalls.post(ApiConfig.interactionsPath, data: body, headers: headers);
        data = response?.data as Map<String, dynamic>?;
        break;
      } on AppException catch (e) {
        // Only capacity errors come back here — a spent daily allowance is
        // typed `quotaExceeded` and falls straight through, since waiting for
        // it cannot help.
        if (e.type != AppErrorType.overloaded || attempt >= 2) rethrow;
        debugPrint('Gemini busy, retrying (attempt ${attempt + 1}): ${e.message}');
        // Sub-second, deliberately. The whole analysis runs under the bloc's
        // timeout, and the old 2s/4s pair spent a fifth of that budget waiting
        // rather than working — a retry that lands after the deadline is the
        // same as no retry at all.
        await Future.delayed(Duration(milliseconds: 600 << attempt));
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

    final allergens = Allergen.fromNames(input['allergens']);

    return RecipeEntity(
      id: _uuid.v4(),
      title: input['title'] as String,
      prepTimeMinutes: (input['prep_time_minutes'] as num?)?.toInt(),
      cookTimeMinutes: (input['cook_time_minutes'] as num?)?.toInt(),
      ingredients: ingredients,
      steps: ((input['steps'] as List?) ?? const []).cast<String>(),
      dietaryTags: dietaryTagsWithAllergens(
        dietaryTagsFromModel(input['dietary_tags']),
        allergens,
      ),
      allergens: allergens,
      mayContain: Allergen.fromNames(input['may_contain']),
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
      headers: sourceUrlHeaders(url, kind: 'url'),
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
      headers: sourceUrlHeaders(url, kind: 'social'),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.socialVideo, sourceUrl: url);
  }

  /// No cache headers: two people asking for "a lasagne" are two requests,
  /// and the proxy's URL cache keys on a link this call does not have.
  @override
  Future<RecipeEntity> generateRecipe(String request, List<DietaryPreference> preferences) async {
    final input = await _callStructured(
      _body(
        input: 'כתוב מתכון מלא לפי הבקשה הבאה:\n\n$request${_dietaryHint(preferences)}',
        schema: _recipeSchema,
        systemInstruction: _generateSystemPrompt,
      ),
    );
    return _toEntity(input, channel: RecipeIngestionChannel.aiRequest);
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
        thinkingLevel: ApiConfig.searchThinkingLevel,
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

/// The model's `dietary_tags` as enum values, in the app's own order and
/// without repeats. Anything outside the enum — a value the schema should
/// have refused, or a non-string — is dropped rather than failing the whole
/// recipe over a tag.
List<DietaryPreference> dietaryTagsFromModel(Object? raw) {
  if (raw is! List) return const [];
  final names = raw.whereType<String>().toSet();
  return [for (final tag in DietaryPreference.values) if (names.contains(tag.name)) tag];
}

/// The `allergy` tag follows the allergen list: a recipe the model found
/// eggs in is tagged as an allergy recipe even when it forgot the tag, so the
/// two never disagree on the review screen.
List<DietaryPreference> dietaryTagsWithAllergens(
  List<DietaryPreference> tags,
  List<Allergen> allergens,
) {
  if (allergens.isEmpty || tags.contains(DietaryPreference.allergy)) return tags;
  return [...tags, DietaryPreference.allergy];
}
