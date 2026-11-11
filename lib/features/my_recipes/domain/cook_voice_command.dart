/// What a cook can say to cook mode with their hands in the dough.
enum CookVoiceCommand { next, previous, repeat, timer }

/// Turns what the recognizer heard into a [CookVoiceCommand], or null.
///
/// Cook mode keeps the microphone open in a kitchen, where a radio, the
/// family and the cook's own muttering are all heard. So only a short
/// utterance counts (a command, perhaps with "okay" or "please" around it),
/// and only whole words from the five languages' lists below: "next" said
/// in a long sentence is conversation, not an instruction.
///
/// When one utterance holds two commands ("back… no, next") the last one
/// wins: it is the one the cook settled on.
class CookVoiceCommands {
  const CookVoiceCommands._();

  /// More words than this and the utterance is taken for talk.
  static const maxWords = 4;

  /// Each command's words, every language together: the recognizer runs in
  /// the app's language, but a Hebrew speaker saying "next" is understood
  /// too. Several-word phrases are matched before single words.
  static const Map<CookVoiceCommand, List<String>> vocabulary = {
    CookVoiceCommand.next: [
      // Hebrew
      'הבא', 'הבאה', 'לשלב הבא', 'קדימה', 'הלאה', 'המשך', 'תמשיך', 'תמשיכי',
      // English
      'next', 'next step', 'forward', 'continue', 'go on', 'go ahead',
      // French
      'suivant', 'suivante', 'étape suivante', 'continue', 'continuer',
      'après',
      // Russian
      'дальше', 'далее', 'следующий', 'следующая', 'следующий шаг', 'вперёд',
      // Arabic
      'التالي', 'التالية', 'التالى', 'الخطوة التالية', 'بعده', 'استمر',
    ],
    CookVoiceCommand.previous: [
      'הקודם',
      'הקודמת',
      'אחורה',
      'חזור',
      'תחזור אחורה',
      'חזרה',
      'שלב קודם',
      'back',
      'go back',
      'previous',
      'previous step',
      'last step',
      'précédent',
      'précédente',
      'étape précédente',
      'retour',
      'arrière',
      'назад',
      'обратно',
      'предыдущий',
      'предыдущая',
      'предыдущий шаг',
      'السابق',
      'السابقة',
      'الخطوة السابقة',
      'ارجع',
      'رجوع',
      'للخلف',
    ],
    CookVoiceCommand.repeat: [
      'שוב',
      'עוד פעם',
      'עוד הפעם',
      'תקריא',
      'תקריאי',
      'להקריא',
      'תחזור על זה',
      'again',
      'repeat',
      'say again',
      'say that again',
      'read',
      'read it',
      'one more time',
      'encore',
      'répète',
      'répéter',
      'relis',
      'relire',
      'encore une fois',
      'повтори',
      'повторить',
      'ещё раз',
      'еще раз',
      'снова',
      'прочитай',
      'مرة أخرى',
      'مره اخرى',
      'كرر',
      'أعد',
      'اعد',
      'اقرأ',
      'اقرا',
    ],
    CookVoiceCommand.timer: [
      'טיימר',
      'הטיימר',
      'תפעיל טיימר',
      'הפעל טיימר',
      'שעון עצר',
      'timer',
      'start timer',
      'start the timer',
      'set timer',
      'minuteur',
      'le minuteur',
      'minuterie',
      'chrono',
      'lance le minuteur',
      'таймер',
      'запусти таймер',
      'включи таймер',
      'مؤقت',
      'المؤقت',
      'ابدأ المؤقت',
      'شغل المؤقت',
    ],
  };

  /// Lower case, no punctuation, no Hebrew points or Arabic marks, one
  /// space between words — so "Next!" and "next" are the same word.
  static String normalize(String text) {
    var s = text.toLowerCase();
    // Hebrew niqqud and cantillation, Arabic harakat and tatweel.
    s = s.replaceAll(RegExp('[֑-ׇً-ٰٟـ]'), '');
    s = s.replaceAll('ё', 'е');
    s = s.replaceAll(RegExp(r'''[.,!?;:"“”«»()\[\]…'’\-–—]'''), ' ');
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Every phrase with its command, longest first, normalized the same way
  /// as what is heard. Built once.
  static final List<(String, CookVoiceCommand)> _phrases = () {
    final list = <(String, CookVoiceCommand)>[
      for (final entry in vocabulary.entries)
        for (final phrase in entry.value) (normalize(phrase), entry.key),
    ];
    list.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return list;
  }();

  static CookVoiceCommand? match(String heard) {
    final text = normalize(heard);
    if (text.isEmpty) return null;
    final words = text.split(' ');
    if (words.length > maxWords) return null;

    // Where in the word list each command was found; a longer phrase
    // claims its words first so "next step" is not also read as "next".
    final claimed = List<bool>.filled(words.length, false);
    CookVoiceCommand? best;
    var bestAt = -1;
    for (final (phrase, command) in _phrases) {
      final parts = phrase.split(' ');
      for (var i = 0; i + parts.length <= words.length; i++) {
        var fits = true;
        for (var j = 0; j < parts.length; j++) {
          if (claimed[i + j] || words[i + j] != parts[j]) {
            fits = false;
            break;
          }
        }
        if (!fits) continue;
        for (var j = 0; j < parts.length; j++) {
          claimed[i + j] = true;
        }
        if (i > bestAt) {
          bestAt = i;
          best = command;
        }
      }
    }
    return best;
  }
}
