import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/price_book/presentation/widgets/price_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Deferred locale loading needs real async, outside the test's fake clock.
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.fr);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.he);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.he));

  testWidgets('a receipt date is written the way the app language writes it', (
    tester,
  ) async {
    // The date symbols come with the app's localizations, as on a phone.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('he'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    final first = DateTime(2026, 11, 1);

    LocaleSettings.setLocaleSync(AppLocale.he);
    expect(purchaseDateLabel(first), '1.11.2026', reason: 'not 11/1/2026');
    LocaleSettings.setLocaleSync(AppLocale.fr);
    expect(purchaseDateLabel(first), '01/11/2026');
    LocaleSettings.setLocaleSync(AppLocale.en);
    expect(purchaseDateLabel(first), '11/1/2026');
  });
}
