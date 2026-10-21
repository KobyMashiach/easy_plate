import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/price_book/data/datasources/community_prices_remote_datasource.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_unit.dart';
import 'package:easy_plate/features/price_book/domain/price_estimator.dart';
import 'package:easy_plate/features/price_book/presentation/price_book_service.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Source = CommunityPricesRemoteDataSource;

void main() {
  group('unit on the wire', () {
    test('every app unit maps to the server spelling', () {
      expect(_Source.unitWire(PriceUnit.unit), 'unit');
      expect(_Source.unitWire(PriceUnit.kg), 'kg');
      expect(_Source.unitWire(PriceUnit.liter), 'liter');
      expect(_Source.unitWire(null), isNull);
    });

    test('a shared record carries its unit and currency', () {
      final record = PriceRecordEntity(
        id: '1',
        name: 'עגבניות',
        normalizedName: 'עגבניות',
        unitPrice: 7.9,
        quantity: 1.2,
        unit: PriceUnit.kg,
        currency: 'ils',
        store: 'shop',
        purchasedAt: DateTime(2026, 10, 1),
        receiptId: 'r',
      );
      expect(_Source.wireRecord(record), {
        'name': 'עגבניות',
        'price': 7.9,
        'unit': 'kg',
        'currency': 'ILS',
      });
    });

    test('grocery units map to the price unit they are counted in', () {
      expect(
        PriceBookService.communityUnitFor(MeasurementUnit.gram),
        PriceUnit.kg,
      );
      expect(
        PriceBookService.communityUnitFor(MeasurementUnit.milliliter),
        PriceUnit.liter,
      );
      expect(
        PriceBookService.communityUnitFor(MeasurementUnit.unit),
        PriceUnit.unit,
      );
      expect(PriceBookService.communityUnitFor(MeasurementUnit.cup), isNull);
    });
  });

  group('document ids match functions/priceStats.js keyFor', () {
    // Hashes computed with node's crypto over the same inputs.
    test('no unit, shekels: the legacy sha256(name)', () {
      expect(
        _Source.keyFor('חלב'),
        '4cb09b46c5a75672eac6294e5e762b826bf0489850e4add4932d54b0c1b715f4',
      );
    });

    test('with a unit: sha256("name|unit|CURRENCY")', () {
      expect(
        _Source.keyFor('חלב', unit: 'kg'),
        '4713dd78fd6af935809861e688994860d3306c354fb082132d7d466e61a2b1b5',
      );
      expect(
        _Source.keyFor('milk', unit: 'unit', currency: 'usd'),
        'e174cf3ab9ac49db6eada6660bec0554beb3e0d65c9d0104266b8cfd9e7095c5',
      );
    });

    test('another currency without a unit: sha256("name||CURRENCY")', () {
      expect(
        _Source.keyFor('חלב', currency: 'USD'),
        '5da908757f3106a75d82017e48a720a170fc218d2d78bb7d0c523410866b9bb5',
      );
    });
  });

  group('lookup', () {
    final keyed = _Source.keyFor('חלב', unit: 'kg');
    final legacy = _Source.keyFor('חלב');

    test('the keyed document wins and carries its unit', () async {
      final read = <String>[];
      final source = _Source.withReader((id) async {
        read.add(id);
        return id == keyed
            ? {'count': 4, 'median': 12.0, 'avg': 12.5}
            : {'count': 9, 'median': 6.0};
      });
      final hit = await source.lookup('חלב', unit: PriceUnit.kg);
      expect(hit!.median, 12.0);
      expect(hit.unit, PriceUnit.kg);
      expect(read, [keyed]);
    });

    test(
      'falls back to the legacy document when the keyed one is empty',
      () async {
        final read = <String>[];
        final source = _Source.withReader((id) async {
          read.add(id);
          return id == legacy ? {'count': 9, 'median': 6.0} : null;
        });
        final hit = await source.lookup('חלב', unit: PriceUnit.kg);
        expect(hit!.median, 6.0);
        expect(hit.unit, isNull);
        expect(read, [keyed, legacy]);
      },
    );

    test('without a unit only the legacy document is read', () async {
      final read = <String>[];
      final source = _Source.withReader((id) async {
        read.add(id);
        return null;
      });
      expect(await source.lookup('חלב'), isNull);
      expect(read, [legacy]);
    });

    test('a per-kg community figure prices the line per kg', () {
      final estimate = PriceEstimator.estimate(
        'חלב',
        const [],
        community: const CommunityPriceEntity(
          normalizedName: 'חלב',
          median: 12,
          average: 12,
          count: 4,
          unit: PriceUnit.kg,
        ),
      );
      expect(estimate.unit, PriceUnit.kg);
    });
  });
}
