/// A typed quantity, as a shopper types it: "1.5" and "1,5" alike (the
/// comma is the decimal mark on fr/ru/ar keyboards), surrounding spaces
/// ignored. Null for anything that is not a positive number — a zero or
/// negative amount is not a quantity of anything.
double? parseAmount(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}
