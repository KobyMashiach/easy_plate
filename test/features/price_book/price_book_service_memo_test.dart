import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_unit.dart';
import 'package:easy_plate/features/price_book/domain/price_estimator.dart';
import 'package:easy_plate/features/price_book/domain/repositories/price_book_repository.dart';
import 'package:easy_plate/features/price_book/presentation/price_book_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Prices extends Mock implements PriceBookRepository {}

PriceRecordEntity _record(String name, double price) => PriceRecordEntity(
  id: name,
  name: name,
  normalizedName: name,
  unitPrice: price,
  quantity: 1,
  currency: 'ILS',
  store: null,
  purchasedAt: DateTime(2026, 9, 1),
  receiptId: 'r',
);

GroceryItemEntity _item(String name) => GroceryItemEntity(
  id: name,
  name: name,
  unit: MeasurementUnit.unit,
  sources: const [],
  category: 'other',
);

/// Pass 10: the grocery tab asks for an estimate on every build of every
/// line, and each estimate scanned the whole book — so the answer is kept
/// per product and unit, and dropped only when an input changes.
void main() {
  late _Prices repo;
  late PriceBookService service;

  setUp(() {
    repo = _Prices();
    when(() => repo.getRecords()).thenAnswer((_) async => [_record('milk', 6)]);
    when(() => repo.getPricing()).thenAnswer((_) async => {});
    service = PriceBookService(repository: repo);
  });

  tearDown(() => service.dispose());

  test(
    'the same line gets the same estimate object until the book reloads',
    () async {
      await service.load();
      final first = service.estimateFor(_item('milk'));
      expect(first.unitPrice, 6);
      expect(service.estimateFor(_item('milk')), same(first));
      // A different spelling of the same product shares the answer.
      expect(service.estimateFor(_item('Milk ')), same(first));

      // A new receipt: the book reloads, and the estimate follows it.
      when(
        () => repo.getRecords(),
      ).thenAnswer((_) async => [_record('milk', 6), _record('milk', 7)]);
      await service.load();
      final after = service.estimateFor(_item('milk'));
      expect(after, isNot(same(first)));
      expect(after.sampleCount, 2);
    },
  );

  test('a community answer is cached once it lands, and dropped with the '
      'switch', () async {
    const answer = CommunityPriceEntity(
      normalizedName: 'bread',
      median: 9,
      average: 9,
      count: 4,
      unit: PriceUnit.unit,
    );
    when(
      () => repo.communityPrice('bread', unit: PriceUnit.unit),
    ).thenAnswer((_) async => answer);
    service.communityEnabled = true;
    await service.load();

    // Still being looked up: "no data", not cached as such.
    expect(service.estimateFor(_item('bread')).basis, PriceBasis.none);
    await Future<void>.delayed(Duration.zero);
    final community = service.estimateFor(_item('bread'));
    expect(community.basis, PriceBasis.community);
    expect(community.unitPrice, 9);
    expect(service.estimateFor(_item('bread')), same(community));
    verify(
      () => repo.communityPrice('bread', unit: PriceUnit.unit),
    ).called(1);

    // Community prices switched off: the cached community figure must not
    // keep showing.
    service.communityEnabled = false;
    expect(service.estimateFor(_item('bread')).basis, PriceBasis.none);
  });
}
