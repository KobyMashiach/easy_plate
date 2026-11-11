import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/presentation/widgets/recipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The recipe grid's card has a fixed height (the grid's row extent): at
/// the largest in-app text size its title and tag line must still fit.
void main() {
  for (final locale in [AppLocale.he, AppLocale.ru]) {
    testWidgets('the recipe card at 1.3 (${locale.name})', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.he));
      final recipe = RecipeEntity(
        id: 'r',
        title: 'Very long recipe title that wraps onto two lines and more',
        ingredients: const [],
        steps: const [],
        createdAt: DateTime(2026),
        prepTimeMinutes: 20,
        dietaryTags: const [
          DietaryPreference.vegetarian,
          DietaryPreference.glutenFree,
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 152,
                  child: RecipeCard(recipe: recipe, onTap: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }
}
