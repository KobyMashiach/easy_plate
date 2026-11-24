import '../features/features_flags.dart';

/// Swear words and slurs kept out of the community: threads, replies and
/// recipes shared to the community feed. The composer refuses to send them
/// (the text stays for the author to fix); the server masks any that still
/// arrive (functions/profanity.js, the canonical copy of these lists —
/// functions/profanity.test.js fails when this file drifts from it).
///
/// Whole words only, never substrings: a recipe is full of "כוס" (a cup)
/// and "מזין" (nourishing), so only unmistakable forms and phrases are
/// listed. Switched off with the `ff_profanity_filter` flag.
/// A community text refused by [ProfanityFilter]; nothing was written.
class OffensiveContentException implements Exception {
  const OffensiveContentException();
  @override
  String toString() => 'OffensiveContentException';
}

abstract class ProfanityFilter {
  static const words = [
    "זונה",
    "זונות",
    "שרמוטה",
    "שרמוטות",
    "שרמוט",
    "אחושרמוטה",
    "אחושלוקי",
    "מניאק",
    "מניאקית",
    "מניאקים",
    "מזדיין",
    "מזדיינת",
    "מזדיינים",
    "תזדיין",
    "תזדייני",
    "להזדיין",
    "זיון",
    "זיונים",
    "זין",
    "זיין",
    "כוסאמק",
    "כוסעמק",
    "כוסאמא",
    "כוסאמאשך",
    "כוסומו",
    "חרא",
    "חארה",
    "שמוק",
    "קוקסינל",
    "פאק",
    "פאקינג",
    "בנזונה",
    "יבנזונה",
    "fuck",
    "fucking",
    "fucker",
    "fuckers",
    "fucked",
    "fucks",
    "motherfucker",
    "motherfucking",
    "fck",
    "fuk",
    "shit",
    "shitty",
    "bullshit",
    "bitch",
    "bitches",
    "cunt",
    "cunts",
    "dickhead",
    "asshole",
    "assholes",
    "bastard",
    "slut",
    "sluts",
    "whore",
    "whores",
    "fag",
    "faggot",
    "nigger",
    "nigga",
    "retard",
    "twat",
    "wanker",
    "كس",
    "كسمك",
    "كسامك",
    "شرموطة",
    "شرموط",
    "منيوك",
    "منيك",
    "عرص",
    "زب",
    "نيك",
    "قحبة",
    "خول",
    "блять",
    "блядь",
    "бля",
    "сука",
    "суки",
    "хуй",
    "хуя",
    "хуйня",
    "пизда",
    "пиздец",
    "ебать",
    "ебал",
    "ебаный",
    "мудак",
    "долбоеб",
    "нахуй",
    "putain",
    "merde",
    "connard",
    "connasse",
    "salope",
    "encule",
    "pute",
    "niquer",
    "nique",
    "batard",
    "pede",
    "couilles",
  ];

  static const phrases = [
    "בן זונה",
    "בת זונה",
    "יא זונה",
    "כוס אמק",
    "כוס עמק",
    "כוס אמא",
    "כוס אמא שלך",
    "כוס אחותך",
    "כוס אוחתק",
    "לך תזדיין",
    "son of a bitch",
    "piece of shit",
    "كس امك",
    "ابن الشرموطة",
    "fils de pute",
    "ta gueule",
  ];

  /// Whether the filter runs: on unless the flag hides it.
  static bool get isOn => FeaturesFlags.profanityFilter.isVisible;

  /// The first listed word or phrase in [text], or null. Always checks,
  /// whatever the flag says — callers ask [blocks].
  static String? findIn(String text) {
    final list = tokens(text);
    for (final w in list) {
      if (_wordSet.contains(w)) return w;
    }
    for (final phrase in _phraseTokens) {
      for (var i = 0; i + phrase.length <= list.length; i++) {
        var all = true;
        for (var j = 0; j < phrase.length; j++) {
          if (list[i + j] != phrase[j]) {
            all = false;
            break;
          }
        }
        if (all) return phrase.join(' ');
      }
    }
    return null;
  }

  /// Whether any of [texts] may not be posted, with the flag applied.
  static bool blocks(Iterable<String?> texts) =>
      isOn && texts.any((t) => t != null && findIn(t) != null);

  /// Throws [OffensiveContentException] when [texts] may not be posted.
  static void check(Iterable<String?> texts) {
    if (blocks(texts)) throw const OffensiveContentException();
  }

  static final _wordSet = {for (final w in words) normalize(w)};
  static final _phraseTokens = [for (final p in phrases) tokens(p)];

  static const _lookalike = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '@': 'a',
    r'$': 's',
  };

  // Dart has no Unicode normalisation; the accented Latin letters the
  // French and English lists can meet, mapped by hand.
  static const _accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };

  static final _marks = RegExp(
    r'[\u0591-\u05C7\u064B-\u065F\u0670\u0300-\u036f]',
  );
  static final _repeats = RegExp(r'(\p{L})\1{2,}', unicode: true);
  static final _gaps = RegExp(r'[^\p{L}*]+', unicode: true);

  /// One word or text, the way it is compared.
  static String normalize(String text) {
    var s = text.toLowerCase().replaceAll(_marks, '');
    final b = StringBuffer();
    for (final c in s.split('')) {
      b.write(switch (c) {
        'ё' => 'е',
        'ך' => 'כ',
        'ם' => 'מ',
        'ן' => 'נ',
        'ף' => 'פ',
        'ץ' => 'צ',
        _ => _accents[c] ?? _lookalike[c] ?? c,
      });
    }
    s = b.toString();
    return s.replaceAllMapped(_repeats, (m) => m[1]!);
  }

  /// The text as normalised words; letters spelled out one at a time
  /// ("f u c k", "f.u.c.k") are joined into one word.
  static List<String> tokens(String text) {
    final out = <String>[];
    var run = '';
    for (final raw in normalize(text).split(_gaps)) {
      final word = raw.replaceAll('*', '');
      if (raw.isEmpty) continue;
      if (word.runes.length == 1) {
        run += word;
        continue;
      }
      if (run.isNotEmpty) {
        out.add(run);
        run = '';
      }
      if (word.isNotEmpty) out.add(word);
    }
    if (run.isNotEmpty) out.add(run);
    return out;
  }
}
