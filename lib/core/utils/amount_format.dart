/// How a quantity is written for a cook: `800`, not `800.0`; `1.5`, not
/// `1.50`; two decimals at most, because no kitchen measures finer than
/// that. A missing amount comes out blank, so callers can join the pieces
/// of a line without minding it.
String formatAmount(num? value) {
  if (value == null) return '';
  final number = value.toDouble();
  if (number == number.roundToDouble()) return number.round().toString();
  return number
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
