import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/price_estimator.dart';
import 'package:easy_plate/features/price_book/domain/product_name.dart';
import 'package:flutter_test/flutter_test.dart';

PriceRecordEntity _r(String name, double price, {int day = 1}) =>
    PriceRecordEntity(
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
    const community = CommunityPriceEntity(
      normalizedName: 'שמן זית',
      median: 30,
      average: 31,
      count: 12,
    );
    expect(
      PriceEstimator.estimate('שמן זית', book, community: community).basis,
      PriceBasis.community,
    );
    expect(
      PriceEstimator.estimate('חלב', book, community: community).basis,
      PriceBasis.personal,
    );
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

  group('currencies', currencyTests);
}

PriceRecordEntity _foreign(String name, double price, String currency) =>
    PriceRecordEntity(
      id: '$name-$currency',
      name: name,
      normalizedName: normalizeProductName(name),
      unitPrice: price,
      quantity: 1,
      currency: currency,
      store: null,
      purchasedAt: DateTime(2026, 9, 20),
      receiptId: 'r-$currency',
    );

void currencyTests() {
  final mixed = [
    _r('חלב 3% תנובה', 6.9, day: 1),
    _r('לחם אחיד', 8.0),
    // A newer, pricier record of the same milk — in dollars.
    _foreign('חלב 3% תנובה', 4.5, 'USD'),
  ];

  test('a record in the minority currency never becomes the estimate', () {
    final e = PriceEstimator.estimate('חלב', mixed);
    expect(e.currency, 'ILS');
    expect(e.unitPrice, 6.9);
    expect(e.sampleCount, 1);
  });

  test('the majority currency wins, shekels on a tie or an empty book', () {
    expect(PriceEstimator.dominantCurrency(mixed), 'ILS');
    expect(PriceEstimator.dominantCurrency(const []), 'ILS');
    expect(
      PriceEstimator.dominantCurrency([
        _foreign('milk', 1, 'USD'),
        _r('חלב', 6.9),
      ]),
      'ILS',
    );
    expect(
      PriceEstimator.dominantCurrency([
        _foreign('milk', 1, 'USD'),
        _foreign('bread', 2, 'USD'),
        _r('חלב', 6.9),
      ]),
      'USD',
    );
  });

  test('the summary does not add dollars to shekels', () {
    const ils = PriceEstimate(unitPrice: 10, basis: PriceBasis.personal);
    const usd = PriceEstimate(
      unitPrice: 3,
      basis: PriceBasis.personal,
      currency: 'USD',
    );
    final s = GroceryCostSummary.of([
      (estimate: ils, multiplier: 1),
      (estimate: ils, multiplier: 2),
      (estimate: usd, multiplier: 1),
      (estimate: PriceEstimate.none, multiplier: 1),
    ]);
    expect(s.currency, 'ILS');
    expect(s.knownTotal, 30);
    expect(s.pricedItems, 2);
    // The foreign line and the unknown one are both "not in this total".
    expect(s.unpricedItems, 2);
  });
}
