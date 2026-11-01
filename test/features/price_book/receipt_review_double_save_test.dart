import 'dart:async';

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
  setUpAll(() {
    registerFallbackValue(<Never>[]);
    return LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('two taps on Save in one frame store the receipt once', (
    tester,
  ) async {
    final prices = _Prices();
    final prefs = _Prefs();
    final write = Completer<void>();
    when(() => prices.getRecords()).thenAnswer((_) async => []);
    when(() => prices.getPricing()).thenAnswer((_) async => {});
    when(() => prices.saveRecords(any())).thenAnswer((_) => write.future);
    when(
      () => prefs.getPreferences(),
    ).thenAnswer(
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
                ReceiptLineEntity(name: 'Milk', quantity: 1, unitPrice: 6.9),
              ],
              unreadable: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final save = find.text(t.receipt.save);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();

    verify(() => prices.saveRecords(any())).called(1);
    write.completeError(StateError('done'));
    await tester.pumpAndSettle();
  });
}
