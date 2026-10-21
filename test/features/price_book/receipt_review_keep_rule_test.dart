import 'package:easy_plate/core/constants/app_colors.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/product_pricing_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/receipt_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/receipt_scan_entity.dart';
import 'package:easy_plate/features/price_book/domain/repositories/price_book_repository.dart';
import 'package:easy_plate/features/price_book/presentation/pages/receipt_review_page.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Prices extends Mock implements PriceBookRepository {}

class _Prefs extends Mock implements UserPreferencesRepository {}

class _FakePricing extends Fake implements ProductPricingEntity {}

class _FakeReceipt extends Fake implements ReceiptEntity {}

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.en);
    registerFallbackValue(_FakePricing());
    registerFallbackValue(_FakeReceipt());
  });

  final milk = PriceRecordEntity(
    id: 'r1',
    name: 'milk',
    normalizedName: 'milk',
    unitPrice: 6,
    quantity: 1,
    currency: 'ILS',
    store: null,
    purchasedAt: DateTime(2026, 9, 1),
    receiptId: 'old-receipt',
  );
  const key = 'milk|unit';

  Future<_Prices> open(WidgetTester tester, ProductPricingEntity rule) async {
    final prices = _Prices();
    final prefs = _Prefs();
    when(() => prices.getRecords()).thenAnswer((_) async => [milk]);
    when(() => prices.getPricing()).thenAnswer((_) async => {key: rule});
    when(() => prices.saveRecords(any())).thenAnswer((_) async {});
    when(() => prices.saveReceipt(any())).thenAnswer((_) async {});
    when(() => prices.savePricing(any())).thenAnswer((_) async {});
    when(() => prices.deletePricing(any())).thenAnswer((_) async {});
    when(() => prefs.getPreferences()).thenAnswer(
      (_) async => const UserPreferencesEntity(
        shoppingDay: ShoppingDay.friday,
        dietaryPreferences: [],
      ),
    );
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<PriceBookRepository>.value(value: prices),
          RepositoryProvider<UserPreferencesRepository>.value(value: prefs),
        ],
        child: const MaterialApp(
          home: ReceiptReviewPage(
            scan: ReceiptScanEntity(
              store: null,
              purchasedAt: null,
              currency: 'ILS',
              total: null,
              items: [
                ReceiptLineEntity(name: 'milk', quantity: 1, unitPrice: 7),
              ],
              unreadable: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prices;
  }

  bool selected(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color == AppColors.onPrimary;

  testWidgets('the chip starts on the existing rule, and saving keeps it', (
    tester,
  ) async {
    final prices = await open(
      tester,
      const ProductPricingEntity(key: key, mode: PricingMode.average),
    );
    expect(selected(tester, t.receipt.keepAverage), isTrue);
    expect(selected(tester, t.receipt.keepNew), isFalse);

    await tester.tap(find.text(t.receipt.save));
    await tester.pumpAndSettle();
    verifyNever(() => prices.savePricing(any()));
    verifyNever(() => prices.deletePricing(any()));
  });

  testWidgets('a receipts rule starts on "Old price"', (tester) async {
    await open(
      tester,
      const ProductPricingEntity(
        key: key,
        mode: PricingMode.receipts,
        receiptIds: ['old-receipt'],
      ),
    );
    expect(selected(tester, t.receipt.keepOld), isTrue);
  });

  testWidgets('picking "New price" over a rule drops the rule', (
    tester,
  ) async {
    final prices = await open(
      tester,
      const ProductPricingEntity(key: key, mode: PricingMode.average),
    );
    await tester.tap(find.text(t.receipt.keepNew));
    await tester.pump();
    expect(selected(tester, t.receipt.keepNew), isTrue);

    await tester.tap(find.text(t.receipt.save));
    await tester.pumpAndSettle();
    verify(() => prices.deletePricing(key)).called(1);
    verifyNever(() => prices.savePricing(any()));
  });
}
