import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';
import '../../../my_recipes/domain/entities/nutrition_entity.dart';
import '../../../price_book/domain/entities/price_unit.dart';
import '../../../price_book/domain/entities/receipt_scan_entity.dart';
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
  Future<RecipeEntity> estimateNutrition(RecipeEntity recipe);

  /// A picture for [prompt], as JPEG bytes.
  Future<Uint8List> generateImage(String prompt);

  /// The products and prices on a receipt, from one or more photos of it
  /// or a PDF. Several photos are parts of the same receipt.
  Future<ReceiptScanEntity> scanReceipt(List<ReceiptPage> pages);
}

/// One page handed to the receipt scanner: a photo or a PDF, as bytes.
class ReceiptPage {
  final Uint8List bytes;
  final String mimeType;

  const ReceiptPage({required this.bytes, required this.mimeType});

  bool get isPdf => mimeType == 'application/pdf';
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

  /// The video function shares the proxy's auth, so the same header provider
  /// signs it; built on first use so tests that never touch it pay nothing.
  late final HttpCalls _socialCalls = HttpCalls(
    baseUrl: ApiConfig.socialRecipeUrl,
    headerProvider: aiProxyAuthHeader,
  );

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
יוצא מן הכלל אחד: את מספר המנות ואת הערכים התזונתיים למנה (קלוריות, חלבון, פחמימות, שומן) עליך תמיד להעריך לפי המצרכים והכמויות, גם כשהמקור לא מציין אותם. אלה הערכות סבירות, לא המצאות.
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
      'servings': _servingsSchema,
      'nutrition': _nutritionSchema,
    },
    // The tags and allergens are required so the model always rules on them —
    // an empty list is an answer, a missing key would be silence. Servings
    // and nutrition are required for the same reason: estimated, never blank.
    'required': [
      'title',
      'ingredients',
      'steps',
      'dietary_tags',
      'allergens',
      'may_contain',
      'servings',
      'nutrition',
    ],
  };

  static const _servingsSchema = {
    'type': 'integer',
    'minimum': 1,
    'description':
        'How many servings the recipe yields. Use the stated yield; otherwise estimate from the ingredient amounts',
  };

  /// Per-serving nutrition, always estimated: a recipe with no numbers on it
  /// is one the planner cannot add up.
  static const _nutritionSchema = {
    'type': 'object',
    'description':
        'Estimated nutrition for ONE serving, derived from the ingredient amounts divided by servings. Estimate from typical values when amounts are missing',
    'properties': {
      'calories': {'type': 'integer', 'description': 'kcal per serving'},
      'protein_g': {'type': 'number', 'description': 'grams of protein per serving'},
      'carbs_g': {'type': 'number', 'description': 'grams of carbohydrate per serving'},
      'fat_g': {'type': 'number', 'description': 'grams of fat per serving'},
    },
    'required': ['calories', 'protein_g', 'carbs_g', 'fat_g'],
  };

  /// What [estimateNutrition] asks for: only the two fields it fills.
  static const _estimateSchema = {
    'type': 'object',
    'properties': {'servings': _servingsSchema, 'nutrition': _nutritionSchema},
    'required': ['servings', 'nutrition'],
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
ציין תמיד את מספר המנות שהמתכון מניב, ואת הערכים התזונתיים למנה אחת — קלוריות, חלבון, פחמימות ושומן בגרמים — מחושבים מהמצרכים והכמויות שכתבת חלקי מספר המנות. אם הבקשה מציינת כמות סועדים, זה מספר המנות.
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
    required Object input,
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
    return _decodeRecipe(await _callRaw(body, headers: headers));
  }

  Future<Map<String, dynamic>> _postSocial(Map<String, dynamic> body) async {
    _assertConfigured();
    try {
      final response = await _socialCalls.post('', data: body);
      final data = response?.data;
      if (data is! Map<String, dynamic>) throw const AppException(AppErrorType.parsingFailed);
      return data;
    } on AppException catch (e) {
      // The function's own refusals travel as 422 with a SOCIAL_* status.
      if (e.message.contains('SOCIAL_UNREADABLE') || e.message.contains('SOCIAL_EMPTY')) {
        throw AppException(AppErrorType.unreadableSource, message: e.message);
      }
      rethrow;
    }
  }

  /// The JSON object inside an interaction's text.
  Map<String, dynamic> _decodeRecipe(Map<String, dynamic> data) {
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

  /// The interaction as Google returned it, after the capacity retries.
  Future<Map<String, dynamic>> _callRaw(
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
    return data;
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
      servings: _servingsFrom(input['servings']),
      nutrition: nutritionFromModel(input['nutrition']),
      sourceChannel: channel,
      sourceUrl: sourceUrl,
      createdAt: DateTime.now(),
    );
  }

  static int? _servingsFrom(Object? raw) {
    final n = (raw as num?)?.toInt();
    return n == null || n < 1 ? null : n;
  }

  static const _receiptSchema = {
    'type': 'object',
    'properties': {
      'store': {'type': 'string', 'description': 'Store or chain name as printed. Omit if absent'},
      'date': {'type': 'string', 'description': 'Purchase date as YYYY-MM-DD. Omit if absent'},
      'currency': {'type': 'string', 'description': 'ISO 4217 code, e.g. ILS. Default ILS'},
      'total': {'type': 'number', 'description': 'The receipt total as printed. Omit if absent'},
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description':
                  'The GENERIC product, 1-3 words, as a shopper would write it on a list: "אנטריקוט", "חלב 3%", "עגבניות". Drop brand, cut, freshness, packaging, size and codes',
            },
            'printed_name': {
              'type': 'string',
              'description': 'The line exactly as printed on the receipt',
            },
            'unit': {
              'type': 'string',
              'enum': ['unit', 'kg', 'liter'],
              'description':
                  'What unit_price is per: "kg" for weighed lines (shown as ק"ג / קג / KG), "liter" for volume-priced lines, else "unit"',
            },
            'quantity': {
              'type': 'number',
              'description':
                  'How many of that unit: 0.85 for 0.850 ק"ג, 3 for three packages. 1 when not shown',
            },
            'unit_price': {
              'type': 'number',
              'description': 'Price per one unit, after any discount line that applies to this item',
            },
            'line_total': {
              'type': 'number',
              'description': 'The amount paid for the line as printed, after discounts',
            },
          },
          'required': ['name', 'printed_name', 'unit', 'quantity', 'unit_price', 'line_total'],
        },
      },
      'unreadable': {
        'type': 'array',
        'items': {'type': 'string'},
        'description':
            'Short notes, in Hebrew, about product lines that could NOT be read — where they are and why, e.g. "מתחת לבצל מיובש: שורה מטושטשת". Never list deposits, credits, totals or discounts here',
      },
    },
    'required': ['items', 'unreadable'],
  };

  static const _receiptSystemPrompt = '''
אתה קורא קבלות מסופרמרקטים בישראל בדיוק מלא. המשתמש מצלם קבלה — לפעמים בכמה תמונות חופפות — או שולח PDF.

איך קבלה ישראלית בנויה:
- כל שורת מוצר: שם המוצר, ולידו כמות × מחיר ליחידה = סכום השורה. לעיתים הכמות והמחיר ליחידה בשורה נפרדת מתחת לשם.
- מוצר שקול: "0.850 ק"ג × 119.00" — אז unit="kg", quantity=0.85, unit_price=119.00, line_total=101.15.
- מוצר ביחידות: "3 × 5.90" — unit="unit", quantity=3, unit_price=5.90, line_total=17.70. בלי כמות מודפסת: quantity=1 ו-unit_price שווה לסכום השורה.
- שורת הנחה ("הנחה", "מבצע", מספר שלילי) מתייחסת למוצר שמעליה: הפחת אותה מסכום השורה של אותו מוצר וחשב unit_price מחדש. אל תרשום את ההנחה כמוצר.
- שורות סה"כ, מע"מ, עודף, מזומן, אשראי, קופון, מועדון, ברקוד — אינן מוצרים. השמט אותן לגמרי.
- גם פיקדון בקבוק, זיכוי אריזה, החזר פיקדון, שקית/שקיות, דמי משלוח — אינם מוצרים. השמט אותם לגמרי, לא ב-items ולא ב-unreadable.

כללי דיוק:
- קרא מספרים בדיוק כפי שהם מודפסים, עם הנקודה העשרונית במקום הנכון. 119.00 ולא 11900 ולא 1190.
- בדוק את עצמך: סכום כל line_total צריך להתקרב ל-total המודפס. אם יש פער גדול, חזור וקרא שוב את השורות.
- name הוא שם המוצר הכללי כפי שאדם יכתוב ברשימת קניות: "אנטריקוט" ולא "אנטריקוט ח. טרי מיושן"; "חלב 3%" ולא "חלב תנובה 3% 1 ליטר"; "עגבניות" ולא "עגבניה שרי מגש". printed_name הוא השורה כפי שהודפסה.
- כשיש כמה תמונות של אותה קבלה: אחד אותן, מוצר שמופיע בשתי תמונות בגלל חפיפה נספר פעם אחת.
- שורת מוצר שלא ניתן לקרוא בביטחון: אל תנחש. רשום ב-unreadable הערה קצרה — איפה השורה ומה הבעיה ("מתחת לבצל מיובש: מטושטש"). זו הערה למשתמש, לא מוצר.
החזר JSON בלבד.''';

  /// Reads a receipt from photos or a PDF. Overlapping photos are merged by
  /// the model (the prompt says so); the caller only concatenates.
  @override
  Future<ReceiptScanEntity> scanReceipt(List<ReceiptPage> pages) async {
    if (pages.isEmpty) return ReceiptScanEntity.empty;
    final blocks = <Map<String, dynamic>>[
      for (final page in pages)
        {
          'type': page.isPdf ? 'document' : 'image',
          'mime_type': page.mimeType,
          'data': base64Encode(page.bytes),
        },
      {
        'type': 'text',
        'text': pages.length > 1
            ? 'אלה ${pages.length} תמונות של אותה קבלה, אולי חופפות. חלץ את המוצרים והמחירים.'
            : 'חלץ את המוצרים והמחירים מהקבלה.',
      },
    ];
    final data = await _callStructured(
      _body(
        input: blocks,
        schema: _receiptSchema,
        systemInstruction: _receiptSystemPrompt,
        // Unlike a recipe, a receipt is arithmetic: the model checks its
        // reading against the printed total, and that needs room to think.
        thinkingLevel: 'high',
      ),
    );
    return _receiptFrom(data);
  }

  static ReceiptScanEntity _receiptFrom(Map<String, dynamic> data) {
    final items = <ReceiptLineEntity>[];
    for (final raw in (data['items'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final name = (raw['name'] as String?)?.trim() ?? '';
      final printed = (raw['printed_name'] as String?)?.trim();
      var price = (raw['unit_price'] as num?)?.toDouble();
      var quantity = (raw['quantity'] as num?)?.toDouble() ?? 1;
      final lineTotal = (raw['line_total'] as num?)?.toDouble();
      // A missing unit price is recoverable from the line total.
      if ((price == null || price <= 0) && lineTotal != null && lineTotal > 0) {
        price = quantity > 0 ? lineTotal / quantity : lineTotal;
      }
      if (name.isEmpty || price == null || price <= 0) continue;
      if (quantity <= 0) quantity = 1;
      items.add(ReceiptLineEntity(
        name: name,
        printedName: printed == null || printed.isEmpty ? name : printed,
        quantity: quantity,
        unitPrice: price,
        unit: PriceUnit.fromName(raw['unit'] as String?),
      ));
    }
    final date = data['date'] is String ? DateTime.tryParse(data['date'] as String) : null;
    return ReceiptScanEntity(
      store: (data['store'] as String?)?.trim(),
      purchasedAt: date,
      currency: (data['currency'] as String?)?.trim().toUpperCase() ?? 'ILS',
      total: (data['total'] as num?)?.toDouble(),
      items: items,
      unreadable: ((data['unreadable'] as List?) ?? const []).whereType<String>().toList(),
    );
  }

  /// One picture from the image model. The Interactions API takes the image
  /// request as a `response_format` of type `image` and answers with an
  /// `image` content block carrying base64 — same envelope as text, so the
  /// same proxy, quota and auth apply. (No `delivery` field: the API rejects
  /// it, inline is what it does.)
  @override
  Future<Uint8List> generateImage(String prompt) async {
    final data = await _callRaw({
      'model': ApiConfig.imageModel,
      'input': prompt,
      'response_format': {
        'type': 'image',
        'aspect_ratio': '4:3',
        'image_size': '1K',
        'mime_type': 'image/jpeg',
      },
    });
    for (final step in (data['steps'] as List?) ?? const []) {
      if (step is! Map) continue;
      for (final block in (step['content'] as List?) ?? const []) {
        if (block is Map && block['type'] == 'image' && block['data'] is String) {
          return base64Decode(block['data'] as String);
        }
      }
    }
    debugPrint('Gemini returned no image block: ${jsonEncode(data).substring(0, 300)}');
    throw const AppException(AppErrorType.parsingFailed, message: 'No image returned');
  }

  /// Fills in servings and per-serving nutrition for a recipe that has none —
  /// everything written before nutrition existed, and anything typed by hand.
  /// The rest of the recipe is untouched.
  @override
  Future<RecipeEntity> estimateNutrition(RecipeEntity recipe) async {
    final payload = jsonEncode({
      'title': recipe.title,
      'servings': recipe.servings,
      'ingredients': [
        for (final i in recipe.ingredients)
          {'name': i.name, 'amount': i.amount, 'unit': i.unit.name},
      ],
      'steps': recipe.steps,
    });
    final data = await _callStructured(
      _body(
        input: 'הערך את מספר המנות ואת הערכים התזונתיים למנה אחת של המתכון הבא. '
            'אם מספר המנות נתון, השתמש בו.\n\n$payload',
        schema: _estimateSchema,
      ),
    );
    final nutrition = nutritionFromModel(data['nutrition']);
    if (nutrition == null) {
      throw const AppException(AppErrorType.parsingFailed, message: 'No nutrition returned');
    }
    return recipe.copyWith(
      servings: recipe.servings ?? _servingsFrom(data['servings']),
      nutrition: nutrition,
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

  /// The video itself, when there is a server to fetch it: the social
  /// function downloads it and hands Gemini the frames, the audio and the
  /// caption together. Against Google directly (no proxy) it degrades to
  /// reading the page, which the short-form platforms mostly refuse.
  ///
  /// The function answers in the Interactions envelope, so the same reader
  /// applies; its typed 422s become [AppErrorType.unreadableSource], which
  /// the ingestion screen turns into "we could not read this video".
  /// Tier 2 (audio transcription + on-screen OCR) needs a video-processing
  /// service that this client does not have access to.
  @override
  Future<RecipeEntity> parseFromSocialVideo(String url, List<DietaryPreference> preferences) async {
    if (ApiConfig.usesProxy) {
      final data = await _postSocial({
        'url': url,
        'model': ApiConfig.model,
        'system_instruction': _systemPrompt,
        'prompt': 'שלוף את המתכון מהסרטון הבא: מהטקסט שמופיע על המסך, ממה שנאמר, ממה שנעשה, ומהכיתוב. '
            'אם הכמויות לא נאמרות אך נראות, הערך אותן. אם אין מתכון בסרטון, החזר רשימות ריקות.'
            '${_dietaryHint(preferences)}',
        'schema': _recipeSchema,
      });
      return _toEntity(
        _decodeRecipe(data),
        channel: RecipeIngestionChannel.socialVideo,
        sourceUrl: url,
      );
    }
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

/// The model's `nutrition` object as an entity, or null when it is missing
/// or unusable. Negative numbers are the model misreading a unit, and are
/// clamped rather than failing the whole recipe over one figure.
NutritionEntity? nutritionFromModel(Object? raw) {
  if (raw is! Map) return null;
  final calories = (raw['calories'] as num?)?.toInt();
  if (calories == null) return null;
  double grams(String key) => ((raw[key] as num?)?.toDouble() ?? 0).clamp(0, double.infinity);
  return NutritionEntity(
    calories: calories < 0 ? 0 : calories,
    proteinGrams: grams('protein_g'),
    carbsGrams: grams('carbs_g'),
    fatGrams: grams('fat_g'),
  );
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
