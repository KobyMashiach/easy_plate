import 'package:easy_plate/features/price_book/domain/product_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalisation matches the server rule', () {
    expect(normalizeProductName('  חָלָב 3%, תנובה '), 'חלב 3% תנובה');
    expect(normalizeProductName('Milk 3%'), 'milk 3%');
  });

  test('a grocery word finds the receipt line that contains it', () {
    expect(productMatchScore('חלב', 'חלב 3% תנובה'), closeTo(1 / 3, 1e-9));
    expect(productMatchScore('חלב 3%', 'חלב 3%'), 1);
    expect(productMatchScore('שמן זית', 'זית ירוק'), 0, reason: 'one shared word is not a match');
    expect(productMatchScore('', 'x'), 0);
  });
}
