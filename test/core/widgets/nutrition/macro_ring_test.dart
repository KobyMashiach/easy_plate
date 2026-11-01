import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/nutrition/nutrition_widgets.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  const day = NutritionEntity(
    calories: 12850,
    proteinGrams: 410,
    carbsGrams: 1200,
    fatGrams: 520,
  );

  for (final size in [88.0, 104.0, 132.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('a big day fits the $size ring at text scale $scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Center(
                  child: MacroRing(nutrition: day, size: size, thickness: 11),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(t.nutrition.kcal), findsOneWidget);
      });
    }
  }
}
