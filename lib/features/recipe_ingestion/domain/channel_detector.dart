import '../../../core/constants/app_enums.dart';
import 'entities/ingestion_file.dart';

/// Guesses which way in a piece of typed or pasted text belongs to, so the
/// add-recipe screen can pick the category itself:
///
/// * a link to a video platform (Instagram, TikTok, YouTube, Facebook) — a
///   video, any other link — a page, also when it comes wrapped in a short
///   caption ("look at this https://…"), as a share from WhatsApp does;
/// * a recipe — several lines, a heading like "Ingredients", or simply long
///   — pasted text;
/// * a short line asking for something to be made up ("invent…", "I have
///   chicken and rice…") — a recipe request;
/// * any other short line ("kubbeh recipe") — a web search, the default.
///
/// Pure and cheap: it runs on every keystroke.
abstract final class ChannelDetector {
  /// Past this many characters outside a link, the text is a recipe that
  /// happens to quote its source, not a link with a caption.
  static const _captionMax = 200;

  /// A single line longer than this is not a search query.
  static const _queryMax = 160;

  static RecipeIngestionChannel detect(String text) {
    final value = text.trim();
    if (value.isEmpty) return RecipeIngestionChannel.webSearch;
    final lines = value
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;

    final url = IngestionLaunch.findWebUrl(value);
    if (url != null) {
      final rest = value.replaceFirst(_urlPattern, '').trim();
      if (rest.length <= _captionMax && lines <= 3) {
        return IngestionLaunch.channelForText(url);
      }
    }

    final lower = value.toLowerCase();
    final hasMarker = _recipeMarkers.any(lower.contains);
    if (lines >= 4 || value.length > 300 || (hasMarker && lines >= 2)) {
      return RecipeIngestionChannel.rawText;
    }
    if (_requestCues.any(lower.contains)) {
      return RecipeIngestionChannel.aiRequest;
    }
    if (lines >= 2 || value.length > _queryMax) {
      return RecipeIngestionChannel.rawText;
    }
    return RecipeIngestionChannel.webSearch;
  }

  static final _urlPattern = RegExp(
    r'(https?://|www\.)\S+',
    caseSensitive: false,
  );

  /// Headings only a written-out recipe carries.
  static const _recipeMarkers = [
    'מצרכים',
    'רכיבים',
    'אופן ההכנה',
    'אופן הכנה',
    'הוראות הכנה',
    'ingredients',
    'directions',
    'instructions',
    'method:',
    'ingrédients',
    'préparation',
    'ингредиенты',
    'приготовление',
    'المكونات',
    'طريقة التحضير',
  ];

  /// Phrases that ask for a recipe to be written rather than found, in the
  /// five app languages — whichever the UI is in, people type in their own.
  static const _requestCues = [
    // Hebrew
    'תמציא', 'המצא', 'תכתוב לי', 'כתוב לי', 'צור לי', 'תיצור',
    'בא לי משהו', 'יש לי', 'מה אפשר להכין', 'מה להכין עם', 'משהו עם',
    'עם מה שיש', 'מהמקרר', 'מה שנשאר',
    // English
    'invent', 'make up a', 'create a recipe', 'write me', 'generate',
    'i have ', "i've got", 'something with', 'what can i make',
    'what can i cook', 'using only', 'leftover',
    // French
    'invente', 'crée', 'écris-moi', "j'ai ", 'quelque chose avec',
    'que faire avec', 'que cuisiner avec', 'restes',
    // Russian
    'придумай', 'создай', 'напиши', 'у меня есть', 'что приготовить из',
    'что-нибудь с', 'остатки',
    // Arabic
    'اخترع', 'اكتب لي', 'أنشئ', 'لدي', 'عندي', 'شيء مع', 'ماذا أطبخ',
    'بقايا',
  ];
}
