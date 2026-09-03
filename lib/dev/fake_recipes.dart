import 'package:uuid/uuid.dart';

import '../core/constants/app_enums.dart';
import '../features/my_recipes/domain/entities/recipe_entity.dart';
import '../features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../features/recipe_ingestion/domain/entities/web_search_result_entity.dart';

const _uuid = Uuid();

/// Debug-only stand-in used when no Gemini API key is configured, so the
/// ingestion flow can be exercised end to end without network access.
RecipeEntity fakeParsedRecipe(RecipeIngestionChannel channel, {String? sourceUrl}) {
  return RecipeEntity(
    id: _uuid.v4(),
    title: 'שקשוקה ירושלמית',
    prepTimeMinutes: 10,
    cookTimeMinutes: 20,
    ingredients: const [
      RecipeIngredientEntity(name: 'עגבניות מרוסקות', amount: 400, unit: MeasurementUnit.gram),
      RecipeIngredientEntity(name: 'ביצים', amount: 4, unit: MeasurementUnit.unit),
      RecipeIngredientEntity(name: 'בצל', amount: 1, unit: MeasurementUnit.unit),
      RecipeIngredientEntity(name: 'שמן זית', amount: 2, unit: MeasurementUnit.tablespoon),
      RecipeIngredientEntity(name: 'פפריקה מתוקה', amount: null, unit: MeasurementUnit.unspecified),
    ],
    steps: const [
      'מחממים שמן זית במחבת ומטגנים את הבצל עד להזהבה.',
      'מוסיפים את העגבניות המרוסקות ומבשלים 10 דקות.',
      'שוברים את הביצים לתוך הרוטב ומכסים עד שהחלבון מתקשה.',
    ],
    sourceChannel: channel,
    sourceUrl: sourceUrl,
    createdAt: DateTime.now(),
  );
}

const fakeWebSearchResults = [
  WebSearchResultEntity(
    title: 'שקשוקה קלאסית',
    url: 'https://example.com/shakshuka',
    snippet: 'מתכון מסורתי לשקשוקה עם עגבניות טריות.',
  ),
  WebSearchResultEntity(
    title: 'שקשוקה ירוקה',
    url: 'https://example.com/green-shakshuka',
    snippet: 'גרסה עם תרד וכרישה.',
  ),
];
