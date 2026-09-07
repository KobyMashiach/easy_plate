import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_item_model.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_item_source_model.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:easy_plate/features/meal_planner/data/models/meal_item_model.dart';
import 'package:easy_plate/features/meal_planner/data/models/meal_model.dart';
import 'package:easy_plate/features/meal_planner/data/models/meal_plan_model.dart';
import 'package:easy_plate/features/my_recipes/data/models/recipe_ingredient_model.dart';
import 'package:easy_plate/features/my_recipes/data/models/recipe_model.dart';
import 'package:easy_plate/features/recipe_books/data/models/book_recipe_ref_model.dart';
import 'package:easy_plate/features/recipe_books/data/models/recipe_book_model.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cloud mirror stores each model as the JSON its own generated codec
/// produces, so `fromJson(toJson(x)) == x` is the whole guarantee that an
/// account gets its data back rather than a damaged copy of it. A field added
/// to a model but left out of its Hive/JSON annotations would slip through
/// every other test and only show up as a recipe that came back wrong.
void main() {
  /// Firestore stores maps, lists, strings, numbers and bools. Anything else —
  /// an enum, a DateTime, a nested model — has to have been flattened by the
  /// codec before it is written, or the SDK rejects the document at runtime.
  void expectFirestoreSafe(Object? value, String path) {
    if (value == null || value is String || value is num || value is bool) return;
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        expectFirestoreSafe(value[i], '$path[$i]');
      }
      return;
    }
    if (value is Map) {
      value.forEach((key, child) {
        expect(key, isA<String>(), reason: 'non-string key at $path');
        expectFirestoreSafe(child, '$path.$key');
      });
      return;
    }
    fail('$path is a ${value.runtimeType}, which Firestore cannot store');
  }

  test('a fully populated recipe survives the round trip', () {
    final recipe = RecipeModel(
      id: 'r1',
      title: 'שקשוקה',
      prepTimeMinutes: 10,
      cookTimeMinutes: 25,
      ingredients: const [
        RecipeIngredientModel(name: 'עגבניות', amount: 500, unit: MeasurementUnit.gram),
        // An ingredient the source gave no amount for: the omitted field is how
        // the model says "not stated", and it has to stay omitted.
        RecipeIngredientModel(name: 'מלח', unit: MeasurementUnit.pinch),
      ],
      steps: const ['לחתוך', 'לטגן'],
      dietaryTags: const [DietaryPreference.vegetarian, DietaryPreference.kosher],
      sourceChannel: 'urlScrape',
      sourceUrl: 'https://example.com/shakshuka',
      createdAt: DateTime.utc(2026, 9, 7, 12, 30),
      imageFileName: 'abc.jpg',
      imageStoragePath: 'recipe_images/uid-1/abc.jpg',
      savedFromSharedId: 'shared-9',
      pendingAnalysis: true,
      collabId: 'collab-3',
      collabRole: 'editor',
    );

    final json = recipe.toJson();
    expectFirestoreSafe(json, 'recipe');
    expect(RecipeModel.fromJson(json), recipe);
  });

  test('a book keeps its ordering and its collaborator roles', () {
    final book = RecipeBookModel(
      id: 'b1',
      title: 'האוסף שלי',
      recipeRefs: const [
        BookRecipeRefModel(recipeId: 'r2', order: 1),
        BookRecipeRefModel(recipeId: 'r1', order: 0),
      ],
      collaborators: const {'uid-2': 'viewer'},
      createdAt: DateTime.utc(2026, 9, 1),
      coverImageFileName: 'cover.png',
      coverImageStoragePath: 'recipe_images/uid-1/cover.png',
    );

    final json = book.toJson();
    expectFirestoreSafe(json, 'book');

    final restored = RecipeBookModel.fromJson(json);
    expect(restored, book);
    expect(restored.recipeRefs.map((r) => r.recipeId), ['r2', 'r1']);
  });

  test('preferences survive, which is what stops a second sign-in re-asking', () {
    const preferences = UserPreferencesModel(
      shoppingDay: ShoppingDay.thursday,
      dietaryPreferences: [DietaryPreference.vegan, DietaryPreference.glutenFree],
      soundEffectsEnabled: false,
      onboardingComplete: true,
      language: AppLanguage.english,
      fastPageTurnEnabled: false,
    );

    final json = preferences.toJson();
    expectFirestoreSafe(json, 'preferences');

    final restored = UserPreferencesModel.fromJson(json);
    expect(restored, preferences);
    // The two the user actually notices missing.
    expect(restored.shoppingDay, ShoppingDay.thursday);
    expect(restored.onboardingComplete, isTrue);
  });

  test('a meal plan keeps its nested meals and their ingredients', () {
    final plan = MealPlanModel(
      id: 'p1',
      name: 'השבוע',
      meals: const [
        MealModel(
          id: 'm1',
          weekday: 4,
          name: 'ארוחת ערב',
          order: 2,
          items: [
            MealItemModel(
              id: 'i1',
              recipeId: 'r1',
              ingredients: [
                RecipeIngredientModel(name: 'אורז', amount: 1.5, unit: MeasurementUnit.cup),
              ],
            ),
            MealItemModel(id: 'i2', freeText: 'סלט'),
          ],
        ),
      ],
      createdAt: DateTime.utc(2026, 9, 5),
    );

    final json = plan.toJson();
    expectFirestoreSafe(json, 'mealPlan');
    expect(MealPlanModel.fromJson(json), plan);
  });

  test('a grocery list keeps its ticked items and its plan selection', () {
    final list = GroceryListModel(
      id: 'g1',
      name: 'קניות',
      items: const [
        GroceryItemModel(
          id: 'gi1',
          name: 'חלב',
          unit: MeasurementUnit.liter,
          sources: [GroceryItemSourceModel(recipeId: 'r1', label: 'שקשוקה', amount: 2)],
          category: 'מוצרי חלב',
        ),
        GroceryItemModel(
          id: 'gi2',
          name: 'לחם',
          unit: MeasurementUnit.unit,
          sources: [GroceryItemSourceModel(label: 'נוסף ידנית', amount: 1)],
          isChecked: true,
          isAdHoc: true,
        ),
      ],
      collaborators: const {'uid-2': 'editor'},
      createdAt: DateTime.utc(2026, 9, 6),
      selectedPlanIds: const ['p1'],
    );

    final json = list.toJson();
    expectFirestoreSafe(json, 'groceryList');

    final restored = GroceryListModel.fromJson(json);
    expect(restored, list);
    expect(restored.items.last.isChecked, isTrue);
  });
}
