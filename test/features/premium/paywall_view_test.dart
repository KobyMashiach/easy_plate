import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/premium/presentation/pages/paywall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => TranslationProvider(
      child: MaterialApp(
        locale: const Locale('he'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
    );

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  testWidgets('a subscriber gets a cancel button that reaches onManage', (tester) async {
    var managed = 0;
    await tester.pumpWidget(_app(PaywallView(
      offers: const [],
      selectedId: null,
      aiPerDay: 10,
      isPremium: true,
      loading: false,
      busy: false,
      onSelect: (_) {},
      onPurchase: () {},
      onRestore: () {},
      onManage: () => managed++,
      onBack: () {},
    )));

    expect(find.text(t.premium.cancel), findsOneWidget);
    expect(find.text(t.premium.cancelNote), findsOneWidget);
    // Nothing to buy or restore once premium: no restore link, no plan.
    expect(find.text(t.premium.restore), findsNothing);

    // The card sits below the benefits, past the test surface's fold.
    await tester.ensureVisible(find.text(t.premium.cancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.premium.cancel));
    expect(managed, 1);
  });

  testWidgets('a free account sees no cancel button', (tester) async {
    await tester.pumpWidget(_app(PaywallView(
      offers: const [],
      selectedId: null,
      aiPerDay: 10,
      isPremium: false,
      loading: false,
      busy: false,
      onSelect: (_) {},
      onPurchase: () {},
      onRestore: () {},
      onManage: () {},
      onBack: () {},
    )));
    expect(find.text(t.premium.cancel), findsNothing);
  });
}
