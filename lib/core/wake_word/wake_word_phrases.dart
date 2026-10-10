/// What counts as "Hey Shefi", in the five app languages, and how a
/// transcript is matched against it.
///
/// The matching itself runs natively (Kotlin, Swift), because on Android the
/// listener keeps going after the Flutter engine is gone. The vocabulary
/// lives here and is handed to the native side on every start, so the three
/// implementations share one source of words; [WakeWordPhrases.match] is the
/// reference algorithm the native copies follow, and what the tests pin.
///
/// The rule: a greeting word immediately followed by a form of the name
/// ("היי שפי", "hey shefi", "эй шефи"), or the two run together as one
/// word ("הישפי"). The name alone is not enough: "של שפי" in a sentence
/// about the assistant must not open it.
class WakeWordPhrases {
  final List<String> greetings;
  final List<String> names;
  final List<String> joined;

  const WakeWordPhrases({
    required this.greetings,
    required this.names,
    required this.joined,
  });

  /// Every language's words at once: the recognizer transcribes in the app's
  /// language, but a Hebrew speaker saying "hey shefi" to an English
  /// recognizer, or the reverse, still lands in one of these lists.
  static const all = WakeWordPhrases(
    greetings: [
      // Hebrew
      'היי', 'הי', 'הייי', 'אהלן', 'יא',
      // English
      'hey', 'hi', 'hay', 'hei',
      // Arabic
      'هاي', 'هي', 'يا', 'اهلا',
      // French
      'hé', 'he', 'eh',
      // Russian
      'эй', 'хей', 'хэй', 'привет',
    ],
    names: [
      // Hebrew, with the spellings recognizers produce for it
      'שפי', 'שפיי', 'שעפי', 'שאפי', 'שף',
      // English / French
      'shefi', 'shefy', 'shefee', 'sheffi', 'sheffy', 'chefi', 'chefy',
      'cheffy', 'chefie', 'chéfi', 'shafi', 'shefie', 'chef',
      // Arabic
      'شيفي', 'شفي', 'شيف',
      // Russian
      'шефи', 'шеффи', 'шэфи', 'шеф',
    ],
    joined: ['הישפי', 'היישפי', 'heyshefi', 'heychefi', 'хейшефи'],
  );

  /// Lowercase, marks (Hebrew vowel points, accents left detached) and
  /// punctuation removed, whitespace collapsed.
  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll(_marks, '')
      .replaceAll(_notWord, ' ')
      .replaceAll(_spaces, ' ')
      .trim();

  static final _marks = RegExp(r'[֑-ׇ]');
  static final _notWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final _spaces = RegExp(r'\s+');

  /// The match in [transcript], or null. What follows the wake words is the
  /// command ("היי שפי מה לבשל היום" → "מה לבשל היום"), empty when the user
  /// only called.
  WakeWordMatch? match(String transcript) {
    final words = normalize(transcript).split(' ');
    for (var i = 0; i < words.length; i++) {
      var end = -1;
      if (joined.contains(words[i])) {
        end = i + 1;
      } else if (i + 1 < words.length &&
          greetings.contains(words[i]) &&
          names.contains(words[i + 1])) {
        end = i + 2;
      }
      if (end != -1) return WakeWordMatch(words.skip(end).join(' ').trim());
    }
    return null;
  }

  Map<String, Object> toChannel() => {
    'greetings': greetings,
    'names': names,
    'joined': joined,
  };
}

class WakeWordMatch {
  /// What was said after the wake words; empty when nothing was.
  final String command;
  const WakeWordMatch(this.command);
}
