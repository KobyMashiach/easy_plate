import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/grocery_product_name.dart';
import 'package:easy_plate/features/grocery_list/domain/usecases/build_aggregate_grocery_list_usecase.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the recipe\'s words for a product are dropped', () {
    expect(
      groceryProductName('שמן שומשום מבושל קלוי כמו שאני אוהבת'),
      'שמן שומשום',
    );
    expect(groceryProductName('בצל גדול קצוץ דק'), 'בצל');
    expect(groceryProductName('שיני שום כתושות'), 'שיני שום');
    expect(groceryProductName('חמאה רכה, בטמפרטורת החדר'), 'חמאה');
    expect(groceryProductName('שמיר (לא חובה)'), 'שמיר');
    expect(groceryProductName('צנוברים קלויים לקישוט'), 'צנוברים');
    expect(groceryProductName('מלח לפי הטעם'), 'מלח');
    expect(groceryProductName('שמן זית או שמן קנולה'), 'שמן זית');
    expect(groceryProductName('2 large onions, finely chopped'), '2 onions');
    expect(groceryProductName('toasted sesame oil, optional'), 'sesame oil');
  });

  test('words that change what is bought stay', () {
    expect(groceryProductName('פטרוזיליה טרייה'), 'פטרוזיליה טרייה');
    expect(groceryProductName('מלפפון חמוץ'), 'מלפפון חמוץ');
    expect(groceryProductName('בשר טחון'), 'בשר טחון');
    expect(groceryProductName('fresh basil'), 'fresh basil');
  });

  test('plain water is never bought, other waters are', () {
    expect(groceryProductName('מים'), isNull);
    expect(groceryProductName('מים קרים'), isNull);
    expect(groceryProductName('מים רותחים'), isNull);
    expect(groceryProductName('Warm water'), isNull);
    expect(groceryProductName('מי ורדים'), 'מי ורדים');
    expect(groceryProductName('מים מוגזים'), 'מים מוגזים');
  });

  test('a line that is nothing but a description keeps its words', () {
    expect(groceryProductName('קצוץ'), 'קצוץ');
  });

  test('the grocery lines use the product name and skip water', () {
    final lines = <String, GroceryItemEntity>{};
    addIngredientLines(
      lines,
      ingredients: const [
        RecipeIngredientEntity(
          name: 'שמן שומשום קלוי',
          amount: 1,
          unit: MeasurementUnit.tablespoon,
        ),
        RecipeIngredientEntity(
          name: 'שמן שומשום',
          amount: 2,
          unit: MeasurementUnit.tablespoon,
        ),
        RecipeIngredientEntity(
          name: 'מים',
          amount: 1,
          unit: MeasurementUnit.cup,
        ),
      ],
      sourceLabel: 'מתכון',
      recipeId: 'r1',
    );
    expect(lines.length, 1);
    expect(lines.values.single.name, 'שמן שומשום');
    expect(lines.values.single.sources.length, 2);
  });
}
