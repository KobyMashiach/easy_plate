/// What the model writes versus what is shown and what is said. The chat
/// renders plain text, so markdown marks (asterisks, hashes, backticks)
/// would appear as such; and a voice reads words, not symbols.
abstract class AssistantText {
  /// Markdown stripped for the bubble: bold and italic marks removed,
  /// headings flattened, list bullets turned into a plain dot, code marks
  /// dropped. Line structure is kept.
  static String display(String raw) {
    var s = raw.replaceAll('\r\n', '\n');
    // replaceAll takes its replacement literally (no group references):
    // the inner text is put back by hand.
    String inner(Match m) => m[1]!;
    s = s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), inner);
    s = s.replaceAllMapped(RegExp(r'__(.+?)__'), inner);
    s = s.replaceAllMapped(
      RegExp(r'(?<!\w)\*(?!\s)(.+?)(?<!\s)\*(?!\w)'),
      inner,
    );
    s = s.replaceAllMapped(RegExp(r'(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)'), inner);
    s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s*[*\-+]\s+', multiLine: true), '• ');
    s = s.replaceAll('`', '');
    // Whatever asterisk is left stood for nothing the reader needs.
    s = s.replaceAll('*', '');
    return s.trim();
  }

  /// The words only, for the voice: markdown gone, bullets and other
  /// symbols dropped, emoji removed, sentence punctuation kept so the
  /// pauses stay natural.
  static String speech(String raw) {
    var s = display(raw);
    s = s.replaceAll('•', ' ');
    s = s.replaceAll(
      RegExp(
        r'[*#_`~>|\[\]{}<>\\/^=+]|[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]',
        unicode: true,
      ),
      ' ',
    );
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    return s
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  /// Whether the reply asks the user something: the cue to open the
  /// microphone again in a spoken conversation.
  static bool asks(String raw) {
    final text = display(raw).trimRight();
    if (text.isEmpty) return false;
    final lastLine = text.split('\n').last.trim();
    return lastLine.endsWith('?') || lastLine.endsWith('؟');
  }
}
