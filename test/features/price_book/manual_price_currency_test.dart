import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/repositories/price_book_repository.dart';
import 'package:easy_plate/features/price_book/domain/usecases/price_book_usecases.dart';
import 'package:easy_plate/features/price_book/presentation/widgets/add_price_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements PriceBookRepository {}

PriceRecordEntity _record(String id, String currency) => PriceRecordEntity(
  id: id,
  name: 'milk',
  normalizedName: 'milk',
  unitPrice: 5,
  quantity: 1,
  currency: currency,
  store: null,
  purchasedAt: DateTime(2026, 9, 20),
  receiptId: 'r',
);

void main() {
  test('a manual price follows the book\'s majority currency', () async {
    final repo = _Repo();
    when(repo.getRecords).thenAnswer(
      (_) async => [
        _record('a', 'USD'),
        _record('b', 'USD'),
        _record('c', 'ILS'),
      ],
    );
    expect(await manualPriceCurrency(repo), 'USD');
  });

  test('an empty or unreadable book falls back to shekels', () async {
    final repo = _Repo();
    when(repo.getRecords).thenAnswer((_) async => []);
    expect(await manualPriceCurrency(repo), 'ILS');
    when(repo.getRecords).thenAnswer((_) async => throw StateError('hive'));
    expect(await manualPriceCurrency(repo), 'ILS');
  });

  test('only shekel prices go to the community median', () async {
    final repo = _Repo();
    List<PriceRecordEntity>? sent;
    when(() => repo.sharePrices(any())).thenAnswer((inv) async {
      sent = inv.positionalArguments.first as List<PriceRecordEntity>;
    });
    final count = await SharePricesUseCase(repo)([
      _record('a', 'USD'),
      _record('b', 'ILS'),
    ]);
    expect(sent!.map((r) => r.id), ['b']);
    expect(count, 1);
  });

  test('pass 9: a receipt with no shekel prices shares nothing', () async {
    final repo = _Repo();
    expect(await SharePricesUseCase(repo)([_record('a', 'USD')]), 0);
    verifyNever(() => repo.sharePrices(any()));
  });
}
