import 'package:easy_plate/features/price_book/presentation/widgets/price_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a price carries its own currency, never a borrowed ₪', () {
    expect(priceLabel(12.5), '₪12.50');
    expect(priceLabel(12.5, currency: 'ILS'), '₪12.50');
    expect(priceLabel(3, currency: 'usd'), r'$3.00');
    expect(priceLabel(3, currency: 'EUR'), '€3.00');
    expect(priceLabel(3, currency: 'GBP'), '£3.00');
    expect(priceLabel(99, currency: 'RUB'), '₽99.00');
    expect(priceLabel(7, currency: 'CHF'), 'CHF 7.00');
    expect(priceLabel(7, currency: ''), '₪7.00');
  });
}
