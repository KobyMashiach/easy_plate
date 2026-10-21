import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
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

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  Future<bool> shareSwitch(WidgetTester tester, bool preference) async {
    final prices = _Prices();
    final prefs = _Prefs();
    when(() => prices.getRecords()).thenAnswer((_) async => []);
    when(() => prices.getPricing()).thenAnswer((_) async => {});
    when(() => prefs.getPreferences()).thenAnswer(
      (_) async => UserPreferencesEntity(
        shoppingDay: ShoppingDay.friday,
        dietaryPreferences: const [],
        communityPricesEnabled: preference,
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
              items: [],
              unreadable: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<Switch>(find.byType(Switch).first).value;
  }

  testWidgets('sharing starts off when the preference is off', (
    tester,
  ) async {
    expect(await shareSwitch(tester, false), isFalse);
  });

  testWidgets('sharing starts on when the user opted in', (tester) async {
    expect(await shareSwitch(tester, true), isTrue);
  });
}
