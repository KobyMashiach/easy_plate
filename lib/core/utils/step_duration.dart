/// "mm:ss", or "h:mm:ss" past the hour.
String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

final _number = RegExp(r'(\d+(?:[.,]\d+)?)');
final _minuteWord = RegExp(
  r'^(minutes?|mins?|min\.?|דקות|דקה|דק[׳\x27]?|دقائق|دقيقة|minutes?|мин(?:ут[аыу]?)?\.?)$',
  caseSensitive: false,
);
final _hourWord = RegExp(
  r'^(hours?|hrs?|hr\.?|h|שעות|שעה|ساعات|ساعة|heures?|час(?:а|ов)?)$',
  caseSensitive: false,
);

/// The first duration a step names, in seconds, across the app's languages:
/// "4 minutes", "4 דקות", "4 دقائق", "4 min", "4 мин", and hours likewise.
/// A range such as "4-5 minutes" takes its first number. Returns null when
/// the step names no duration.
int? parseStepDuration(String step) {
  // Durations written without a digit.
  const words = <String, int>{
    'חצי שעה': 30 * 60,
    'רבע שעה': 15 * 60,
    'half an hour': 30 * 60,
    'quarter of an hour': 15 * 60,
    'نصف ساعة': 30 * 60,
    'ربع ساعة': 15 * 60,
    'دقيقتين': 2 * 60,
    'ساعتين': 2 * 3600,
    'une demi-heure': 30 * 60,
    'полчаса': 30 * 60,
  };
  final lower = step.toLowerCase();
  int? best;
  int bestAt = lower.length;
  for (final entry in words.entries) {
    final at = lower.indexOf(entry.key);
    if (at >= 0 && at < bestAt) {
      best = entry.value;
      bestAt = at;
    }
  }

  // "4 minutes", "4-5 minutes", "4 to 5 minutes": the unit word follows the
  // number, possibly after a second number and a separator.
  final tokens = step.split(RegExp(r'\s+'));
  for (var i = 0; i < tokens.length; i++) {
    final numMatch = _number.firstMatch(tokens[i]);
    if (numMatch == null) continue;
    var j = i + 1;
    while (j < tokens.length &&
        j <= i + 3 &&
        (_number.hasMatch(tokens[j]) ||
            RegExp(r'^(-|–|to|עד|إلى|à|до)$').hasMatch(tokens[j]))) {
      j++;
    }
    if (j >= tokens.length) continue;
    final unit = tokens[j].replaceAll(RegExp(r'[,.;:!?)]+$'), '');
    final value = double.parse(numMatch.group(1)!.replaceAll(',', '.'));
    int? seconds;
    if (_minuteWord.hasMatch(unit)) seconds = (value * 60).round();
    if (_hourWord.hasMatch(unit)) seconds = (value * 3600).round();
    if (seconds == null) continue;
    final at = step.indexOf(tokens[i]);
    if (at < bestAt) {
      best = seconds;
      bestAt = at;
    }
    break;
  }
  return best == null || best <= 0 ? null : best;
}
