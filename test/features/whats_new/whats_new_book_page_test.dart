import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/open_book_shell.dart';
import 'package:easy_plate/features/whats_new/domain/entities/whats_new_release.dart';
import 'package:easy_plate/features/whats_new/presentation/pages/whats_new_book_page.dart';
import 'package:easy_plate/features/whats_new/presentation/whats_new_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WhatsNewArgs args({int count = 3, String target = ''}) {
  final release = const WhatsNewRelease(
    version: '1.2.0',
    versionCode: 12,
    isPublished: true,
  );
  return WhatsNewArgs(
    build: 12,
    pages: [
      for (var i = 0; i < count; i++)
        WhatsNewPage(
          release: release,
          feature: WhatsNewFeature(
            featureKey: i == 0 ? 'ff_cook_mode' : 'ff_feature_$i',
            title: {
              'he': 'כותרת ארוכה למדי לפיצ׳ר מספר $i',
              'en': 'Feature $i',
            },
            description: {
              'he':
                  'תיאור ארוך של מה שהפיצ׳ר עושה ולמה הוא שימושי, שורה אחרי שורה.',
            },
            iconName: 'timer',
            targetRoute: i == 0 ? target : '',
            sortOrder: i,
          ),
        ),
    ],
  );
}

Widget host(Widget child, {Size? size}) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: size == null
        ? child
        : Center(
            child: SizedBox.fromSize(size: size, child: child),
          ),
  ),
);

/// Vertical overflows only: the test font draws every glyph a full em
/// wide, so Hebrew runs far wider than on a phone.
Future<List<String>> verticalOverflows(Future<void> Function() body) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(details.toString());
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return [
    for (final error in errors)
      if (!error.contains('overflowed by') ||
          error.contains('on the bottom') ||
          error.contains('on the top'))
        error.split('\n').take(12).join(' | '),
  ];
}

void main() {
  tearDown(() => FeaturesFlags.overrides = null);

  testWidgets('the book opens on the first page with next and dots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final errors = await verticalOverflows(() async {
      await tester.pumpWidget(
        host(WhatsNewBookPage(args: args(), onAcknowledged: (_) {})),
      );
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty);
    expect(find.byType(OpenBookShell), findsOneWidget);
    expect(find.byKey(const ValueKey('whatsNew.next')), findsWidgets);
    expect(find.textContaining('1'), findsWidgets);
  });

  testWidgets('every leaf fits a phone on its side', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final errors = await verticalOverflows(() async {
      await tester.pumpWidget(
        host(
          WhatsNewBookPage(
            args: args(target: 'tab:groceries'),
            onAcknowledged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty);
  });

  testWidgets('"Got it" on the last page acknowledges the build', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? acknowledged;
    await tester.pumpWidget(
      host(
        WhatsNewBookPage(
          args: args(count: 1),
          onAcknowledged: (build) => acknowledged = build,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('whatsNew.gotIt')));
    await tester.pumpAndSettle();
    expect(acknowledged, 12);
  });

  testWidgets('the capsule Close acknowledges too', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? acknowledged;
    await tester.pumpWidget(
      host(
        WhatsNewBookPage(
          args: args(),
          onAcknowledged: (build) => acknowledged = build,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(acknowledged, 12);
  });

  testWidgets('pass 8: the system back acknowledges too', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? acknowledged;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: WhatsNewBookPage(
            args: args(),
            onAcknowledged: (build) => acknowledged = build,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewBookPage), findsNothing);
    expect(acknowledged, 12);
  });

  testWidgets('"Try it" is drawn only for a target the app can open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        WhatsNewBookPage(
          args: args(count: 1, target: 'book_details'),
          onAcknowledged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('whatsNew.tryIt')), findsNothing);

    // A fresh book: the flip widget snapshots its pages when it mounts.
    await tester.pumpWidget(
      host(
        WhatsNewBookPage(
          key: UniqueKey(),
          args: args(count: 1, target: 'settings'),
          onAcknowledged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('whatsNew.tryIt')), findsOneWidget);
  });

  test(
    'a page is shown for an open or Premium-only flag, not a hidden one',
    () {
      FeaturesFlags.overrides = {
        FeaturesFlags.cookMode: FeatureFlagValue.hidden,
        FeaturesFlags.nutrition: FeatureFlagValue.comingSoon,
        FeaturesFlags.assistant: FeatureFlagValue.premiumOnly,
      };
      expect(WhatsNewService.isFeatureShown('ff_cook_mode'), isFalse);
      expect(WhatsNewService.isFeatureShown('ff_nutrition'), isFalse);
      expect(WhatsNewService.isFeatureShown('ff_assistant'), isTrue);
      expect(WhatsNewService.isFeatureShown('ff_books'), isTrue);
      expect(WhatsNewService.isFeatureShown('not_a_flag'), isTrue);
    },
  );
}
