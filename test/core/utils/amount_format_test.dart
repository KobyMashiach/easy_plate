import 'package:easy_plate/core/utils/amount_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('whole amounts lose the decimal point', () {
    expect(formatAmount(800), '800');
    expect(formatAmount(1.0), '1');
    expect(formatAmount(0), '0');
  });

  test('fractions keep what matters, two decimals at most', () {
    expect(formatAmount(1.5), '1.5');
    expect(formatAmount(0.25), '0.25');
    expect(formatAmount(0.333333), '0.33');
    expect(formatAmount(2.10), '2.1');
  });

  test('a missing amount is blank, so a joined line has no hole in it', () {
    expect(formatAmount(null), '');
  });
}
