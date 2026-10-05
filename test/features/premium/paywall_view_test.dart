import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/premium/domain/paywall_offer.dart';
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

  testWidgets('a subscriber gets a cancel button that reaches onManage', (
    tester,
  ) async {
    var managed = 0;
    await tester.pumpWidget(
      _app(
        PaywallView(
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
        ),
      ),
    );

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
    await tester.pumpWidget(
      _app(
        PaywallView(
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
        ),
      ),
    );
    expect(find.text(t.premium.cancel), findsNothing);
  });

  testWidgets(
    'a new subscriber sees the opening price, what follows it, and a coupon link',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      var redeemed = 0;
      await tester.pumpWidget(
        _app(
          PaywallView(
            offers: const [
              PaywallOffer(
                id: 'monthly',
                priceString: '₪20.00',
                period: PaywallPeriod.monthly,
                intro: PaywallIntro(
                  priceString: '₪10.00',
                  isFree: false,
                  count: 1,
                  unit: PaywallIntroUnit.month,
                ),
              ),
            ],
            selectedId: 'monthly',
            aiPerDay: 10,
            isPremium: false,
            loading: false,
            busy: false,
            onSelect: (_) {},
            onPurchase: () {},
            onRestore: () {},
            onManage: () {},
            onRedeem: () => redeemed++,
            onBack: () {},
          ),
        ),
      );

      // The button sells the opening price, not the regular one.
      expect(find.text(t.premium.startFor(price: '₪10.00')), findsOneWidget);
      expect(find.text(t.premium.subscribeFor(price: '₪20.00')), findsNothing);
      // Both prices are on the card, and the sentence both stores require —
      // what is paid now, for how long, what comes after — is on the screen.
      expect(find.text('₪10.00'), findsOneWidget);
      expect(find.text('₪20.00'), findsOneWidget);
      expect(
        find.textContaining('₪20.00 ${t.premium.perMonthly}'),
        findsWidgets,
      );
      expect(find.textContaining(t.premium.introMonths(n: 1)), findsWidgets);

      await tester.tap(find.text(t.premium.redeem));
      expect(redeemed, 1);
    },
  );

  testWidgets('without an opening deal the regular price is the offer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaywallView(
          offers: const [
            PaywallOffer(
              id: 'monthly',
              priceString: '₪20.00',
              period: PaywallPeriod.monthly,
            ),
          ],
          selectedId: 'monthly',
          aiPerDay: 10,
          isPremium: false,
          loading: false,
          busy: false,
          onSelect: (_) {},
          onPurchase: () {},
          onRestore: () {},
          onManage: () {},
          onBack: () {},
        ),
      ),
    );
    expect(find.text(t.premium.subscribeFor(price: '₪20.00')), findsOneWidget);
    expect(find.text(t.premium.redeem), findsNothing);
  });
}
