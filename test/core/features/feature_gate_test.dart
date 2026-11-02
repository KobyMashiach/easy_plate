import 'package:easy_plate/core/features/feature_gate.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));
  tearDown(() => FeaturesFlags.overrides = null);

  Future<void> pumpGate(WidgetTester tester, FeatureFlagValue value) {
    FeaturesFlags.overrides = {FeaturesFlags.books: value};
    return tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeatureGate(
            feature: FeaturesFlags.books,
            child: Text('books'),
          ),
        ),
      ),
    );
  }

  testWidgets('maintenance draws the entry dimmed under its own tag', (
    tester,
  ) async {
    await pumpGate(tester, FeatureFlagValue.maintenance);

    expect(find.text('books'), findsOneWidget);
    expect(find.text(t.feature.maintenance), findsOneWidget);
    expect(find.text(t.feature.comingSoon), findsNothing);
    expect(
      find.ancestor(
        of: find.text('books'),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });

  testWidgets('coming soon keeps its own tag', (tester) async {
    await pumpGate(tester, FeatureFlagValue.comingSoon);

    expect(find.text(t.feature.comingSoon), findsOneWidget);
    expect(find.text(t.feature.maintenance), findsNothing);
  });

  testWidgets('enabled draws the child as built', (tester) async {
    await pumpGate(tester, FeatureFlagValue.enabled);

    expect(find.text('books'), findsOneWidget);
    expect(find.text(t.feature.maintenance), findsNothing);
    expect(find.byType(GatedChild), findsNothing);
  });
}
