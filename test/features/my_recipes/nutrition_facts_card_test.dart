import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/presentation/widgets/nutrition_facts_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  Widget app(Widget child) => TranslationProvider(
        child: MaterialApp(
          locale: const Locale('he'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  const perServing = NutritionEntity(calories: 300, proteinGrams: 10, carbsGrams: 40, fatGrams: 8);

  testWidgets('the whole-recipe view multiplies the stored per-serving figures', (tester) async {
    await tester.pumpWidget(app(const NutritionFactsCard(
      nutrition: perServing,
      servings: 4,
      estimating: false,
      onEstimate: null,
    )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('300'), findsOneWidget);

    await tester.tap(find.text(t.nutrition.perRecipe));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1,200'), findsOneWidget, reason: '300 kcal × 4 servings');
    expect(find.text('40 ${t.nutrition.gramsShort}'), findsOneWidget, reason: 'protein 10 g × 4');
    expect(find.text(t.nutrition.perRecipeServings(count: 4)), findsOneWidget);
  });

  testWidgets('without a servings count there is nothing to scale by', (tester) async {
    await tester.pumpWidget(app(const NutritionFactsCard(
      nutrition: perServing,
      servings: null,
      estimating: false,
      onEstimate: null,
    )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(t.nutrition.perRecipe), findsNothing);
    expect(find.text(t.nutrition.perServing), findsOneWidget);
  });
}
