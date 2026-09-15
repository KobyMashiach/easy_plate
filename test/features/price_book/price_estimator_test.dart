import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/price_estimator.dart';
import 'package:easy_plate/features/price_book/domain/product_name.dart';
import 'package:flutter_test/flutter_test.dart';

PriceRecordEntity _r(String name, double price, {int day = 1}) => PriceRecordEntity(
      id: '$name-$day',
      name: name,
      normalizedName: normalizeProductName(name),
      unitPrice: price,
      quantity: 1,
      currency: 'ILS',
      store: null,
      purchasedAt: DateTime(2026, 9, day),
      receiptId: 'r',
    );

void main() {
  final book = [
    _r('חלב 3% תנובה', 6.9, day: 1),
    _r('חלב 3% תנובה', 7.2, day: 5),
    _r('לחם אחיד', 8.0),
    _r('זית ירוק', 12.0),
  ];

  test('the most recent exact match wins', () {
    final e = PriceEstimator.estimate('חלב 3% תנובה', book);
    expect(e.basis, PriceBasis.personal);
    expect(e.unitPrice, 7.2);
  });

  test('a short grocery word finds the fuller receipt name', () {
    final e = PriceEstimator.estimate('חלב', book);
    expect(e.unitPrice, 7.2);
    expect(e.matchedName, 'חלב 3% תנובה');
  });

  test('a word in common is not a product in common', () {
    expect(PriceEstimator.estimate('שמן זית', book).basis, PriceBasis.none);
  });

  test('the community fills in only when the book is silent', () {
    const community = CommunityPriceEntity(normalizedName: 'שמן זית', median: 30, average: 31, count: 12);
    expect(PriceEstimator.estimate('שמן זית', book, community: community).basis, PriceBasis.community);
    expect(PriceEstimator.estimate('חלב', book, community: community).basis, PriceBasis.personal);
  });

  test('the summary adds only what it knows and counts the rest', () {
    final s = GroceryCostSummary.of([
      (estimate: PriceEstimator.estimate('חלב', book), multiplier: 2),
      (estimate: PriceEstimator.estimate('לחם', book), multiplier: 1),
      (estimate: PriceEstimator.estimate('קינוח', book), multiplier: 1),
    ]);
    expect(s.knownTotal, closeTo(7.2 * 2 + 8.0, 1e-9));
    expect(s.pricedItems, 2);
    expect(s.unpricedItems, 1);
  });
}
