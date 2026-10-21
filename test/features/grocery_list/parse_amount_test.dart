import 'package:easy_plate/features/grocery_list/domain/parse_amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a comma is a decimal mark too', () {
    expect(parseAmount('1,5'), 1.5);
    expect(parseAmount(' 2.25 '), 2.25);
    expect(parseAmount('3'), 3);
  });

  test('nothing, zero, negatives and junk are not amounts', () {
    for (final bad in ['', 'abc', '0', '-1', '0,0', 'NaN', 'Infinity']) {
      expect(parseAmount(bad), isNull, reason: bad);
    }
  });
}
