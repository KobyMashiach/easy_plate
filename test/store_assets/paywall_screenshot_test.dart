// Renders the paywall with sample offers and writes it out as PNG, in the
// sizes App Store Connect accepts for the "Review Information" screenshot a
// subscription must carry before it can be saved. Off by default — it writes
// into the repo — and run on purpose with:
//
//   flutter test test/store_assets --dart-define=STORE_SCREENSHOTS=true
//
// (or `./run.sh storeScreenshots`). The prices are placeholders: the real
// ones come from the store at runtime and the screenshot is only seen by the
// reviewer, who needs to recognise the screen, not audit the price.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_plate/core/styles/app_theme.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/premium/domain/paywall_offer.dart';
import 'package:easy_plate/features/premium/presentation/pages/paywall_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');
const _outDir = 'store_assets/app_store';

const _offers = [
  PaywallOffer(id: 'monthly', priceString: '₪14.90', period: PaywallPeriod.monthly),
  PaywallOffer(id: 'annual', priceString: '₪99.90', period: PaywallPeriod.annual),
];

/// Sizes Apple lists for the in-app purchase review screenshot.
const _sizes = [(640, 920), (1080, 1920)];

Future<void> _loadFonts() async {
  // Tests otherwise render every glyph in the Ahem test font.
  final jakarta = FontLoader('Plus Jakarta Sans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await jakarta.load();
  // Plus Jakarta Sans has no Hebrew; on a device the platform fills that in
  // through AppTextStyles.fontFamilyFallback. The test has no platform fonts,
  // so a Mac system face that does carry Hebrew is registered under one of
  // those fallback names.
  for (final path in const [
    '/System/Library/Fonts/Supplemental/Arial Hebrew.ttc',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Tahoma.ttf',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final hebrew = FontLoader('Arial Hebrew')
      ..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
    await hebrew.load();
    break;
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(icons.readAsBytes().then((b) => ByteData.sublistView(b)));
      await loader.load();
    }
  }
}

const _locales = [AppLocale.he, AppLocale.en];

void main() {
  setUpAll(() async {
    if (!_enabled) return;
    await _loadFonts();
    // Non-base locales are deferred libraries. Loading one is real async
    // work that never completes inside a test's fake-async zone, so it is
    // done here, once, and the tests switch synchronously.
    for (final locale in _locales) {
      await LocaleSettings.setLocale(locale);
    }
  });

  for (final locale in _locales) {
    for (final (width, height) in _sizes) {
      testWidgets(
        'paywall ${locale.languageCode} ${width}x$height',
        (tester) async {
          // Logical size at 2x for the phone-sized output, 1x for the
          // small one, so text and spacing look like a phone in both.
          final ratio = width >= 1080 ? 2.0 : 1.0;
          tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
          tester.view.devicePixelRatio = ratio;
          addTearDown(tester.view.reset);

          LocaleSettings.setLocaleSync(locale);
          final key = GlobalKey();
          await tester.pumpWidget(
            TranslationProvider(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                locale: locale.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: RepaintBoundary(
                  key: key,
                  child: PaywallView(
                    offers: _offers,
                    selectedId: 'annual',
                    isPremium: false,
                    loading: false,
                    busy: false,
                    onSelect: (_) {},
                    onPurchase: () {},
                    onRestore: () {},
                    onBack: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: ratio);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            expect(image.width, width);
            expect(image.height, height);
            final file = File('$_outDir/premium_${locale.languageCode}_${width}x$height.png');
            await file.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        },
        skip: !_enabled,
      );
    }
  }
}
