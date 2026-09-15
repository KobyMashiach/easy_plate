import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_unit.dart';
import 'package:easy_plate/features/price_book/domain/entities/product_pricing_entity.dart';
import 'package:easy_plate/features/price_book/domain/price_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

PriceRecordEntity _r(double price, {String store = 'a', String receipt = 'r', int day = 1}) =>
    PriceRecordEntity(
      id: '$store$receipt$day',
      name: 'חלב',
      normalizedName: 'חלב',
      unitPrice: price,
      quantity: 1,
      currency: 'ILS',
      store: store,
      purchasedAt: DateTime(2026, 9, day),
      receiptId: receipt,
    );

void main() {
  final records = [
    _r(6.0, store: 'a', receipt: 'r1', day: 1),
    _r(8.0, store: 'b', receipt: 'r2', day: 2),
    _r(7.0, store: 'a', receipt: 'r3', day: 3),
  ];
  const key = 'חלב|unit';

  test('latest, average, store and receipts each pick their own figure', () {
    expect(const ProductPricingEntity(key: key, mode: PricingMode.latest).resolve(records), 7.0);
    expect(const ProductPricingEntity(key: key, mode: PricingMode.average).resolve(records), 7.0);
    expect(const ProductPricingEntity(key: key, mode: PricingMode.store, store: 'b').resolve(records), 8.0);
    expect(
      const ProductPricingEntity(key: key, mode: PricingMode.receipts, receiptIds: ['r1', 'r2']).resolve(records),
      7.0,
    );
  });

  test('a policy that matches nothing falls back to the latest price', () {
    const gone = ProductPricingEntity(key: key, mode: PricingMode.store, store: 'z');
    expect(gone.resolve(records), isNull);
    final e = PriceEstimator.estimate('חלב', records, pricing: const {key: gone});
    expect(e.unitPrice, 7.0);
    expect(e.sampleCount, 3);
  });

  test('the estimate honours the policy', () {
    const avg = ProductPricingEntity(key: key, mode: PricingMode.average);
    expect(PriceEstimator.estimate('חלב', records, pricing: const {key: avg}).unitPrice, 7.0);
    expect(PriceEstimator.estimate('חלב', records).unitPrice, 7.0, reason: 'no policy = latest');
    expect(ProductPricingEntity.keyFor('חלב', PriceUnit.kg), 'חלב|kg');
  });
}
