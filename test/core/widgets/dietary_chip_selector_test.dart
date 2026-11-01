import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/dietary_chip_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The onboarding / preferences cards leave ~280 dp for the chips on a
  // 360 dp phone; "Produits laitiers" at 2x is wider than that.
  testWidgets('a chip wider than the line wraps instead of overflowing', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.he));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: DietaryChipSelector(selected: const [], onToggle: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
