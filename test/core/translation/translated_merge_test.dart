import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/translation/translated_merge.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeEntity recipe({
  required String title,
  required List<String> ingredients,
  required List<String> steps,
  String? contentLang,
  int version = 0,
  double amount = 4,
  int? servings,
}) => RecipeEntity(
  id: 'r1',
  title: title,
  ingredients: [
    for (final name in ingredients)
      RecipeIngredientEntity(
        name: name,
        amount: amount,
        unit: MeasurementUnit.unspecified,
      ),
  ],
  steps: steps,
  createdAt: DateTime(2026),
  contentLang: contentLang,
  contentVersion: version,
  servings: servings,
  collabId: 'c1',
);

void main() {
  final translated = recipe(
    title: 'Shakshuka',
    ingredients: ['Eggs', 'Tomatoes'],
    steps: ['Fry', 'Serve'],
    contentLang: 'en',
  );

  test('the shared Hebrew does not pour back over this account\'s English', () {
    final fromShare = recipe(
      title: 'שקשוקה',
      ingredients: ['ביצים', 'עגבניות'],
      steps: ['מטגנים', 'מגישים'],
      contentLang: 'he',
      servings: 6,
      amount: 5,
    );
    final result = keepTranslation(translated, fromShare);

    expect(result.keptTranslation, isTrue);
    expect(result.recipe.title, 'Shakshuka');
    expect(result.recipe.steps, ['Fry', 'Serve']);
    expect(
      [for (final i in result.recipe.ingredients) i.name],
      ['Eggs', 'Tomatoes'],
    );
    // Everything but the words still comes from the share.
    expect(result.recipe.servings, 6);
    expect([for (final i in result.recipe.ingredients) i.amount], [5, 5]);
    expect(result.recipe.contentLang, 'en');
  });

  test('a rewrite that changed the structure is taken as it is', () {
    final fromShare = recipe(
      title: 'שקשוקה',
      ingredients: ['ביצים', 'עגבניות', 'פלפל'],
      steps: ['מטגנים', 'מגישים'],
    );
    final result = keepTranslation(translated, fromShare);

    expect(result.keptTranslation, isFalse);
    expect(result.recipe.title, 'שקשוקה');
  });

  test('when both sides are in the same language the share wins', () {
    final hebrewLocal = recipe(
      title: 'שקשוקה',
      ingredients: ['ביצים', 'עגבניות'],
      steps: ['מטגנים', 'מגישים'],
      contentLang: 'he',
    );
    final fromShare = recipe(
      title: 'שקשוקה חריפה',
      ingredients: ['ביצים', 'עגבניות'],
      steps: ['מטגנים', 'מגישים'],
    );
    final result = keepTranslation(hebrewLocal, fromShare);

    expect(result.keptTranslation, isFalse);
    expect(result.recipe.title, 'שקשוקה חריפה');
  });

  test('a record that never recorded its language is left to the share', () {
    final legacy = recipe(
      title: 'Shakshuka',
      ingredients: ['Eggs'],
      steps: ['Fry'],
    );
    final fromShare = recipe(
      title: 'שקשוקה',
      ingredients: ['ביצים'],
      steps: ['מטגנים'],
    );
    expect(keepTranslation(legacy, fromShare).keptTranslation, isFalse);
  });
}
