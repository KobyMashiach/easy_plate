import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:easy_plate/features/my_recipes/data/models/recipe_model.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/price_book/data/models/price_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Pass 7: the website writes the same records. A record that fails to parse
// is skipped by the cloud merge and the older local copy is pushed back over
// it, so a slightly different shape must cost a field, not the record.
void main() {
  Map<String, dynamic> recipe(Map<String, dynamic> over) => {
    'id': 'r',
    'title': 'Soup',
    'ingredients': [
      {'name': 'Salt', 'amount': 1, 'unit': 'gram'},
    ],
    'steps': ['Boil'],
    'createdAt': '2026-10-18T10:15:00.000Z',
    ...over,
  };

  test('a date as a timestamp or as epoch millis parses', () {
    final at = DateTime.utc(2026, 10, 18, 10, 15);
    expect(
      RecipeModel.fromJson(
        recipe({'createdAt': Timestamp.fromDate(at)}),
      ).createdAt.toUtc(),
      at,
    );
    expect(
      RecipeModel.fromJson(
        recipe({'createdAt': at.millisecondsSinceEpoch}),
      ).createdAt.toUtc(),
      at,
    );
  });

  test('an unknown dietary tag or unit costs that value only', () {
    final model = RecipeModel.fromJson(
      recipe({
        'dietaryTags': ['vegan', 'pescatarian'],
        'ingredients': [
          {'name': 'Salt', 'amount': 2, 'unit': 'handful'},
        ],
      }),
    );
    expect(model.dietaryTags, [DietaryPreference.vegan]);
    expect(model.ingredients.single.unit, MeasurementUnit.unspecified);
    // An int where a double is kept.
    expect(model.ingredients.single.amount, 2.0);
  });

  test('a grocery list and a price record take the same shapes', () {
    final list = GroceryListModel.fromJson({
      'id': 'l',
      'name': 'List',
      'items': [
        {
          'id': 'i',
          'name': 'Milk',
          'unit': 'gallon',
          'sources': [
            {'label': 'Milk', 'amount': 1},
          ],
        },
      ],
      'createdAt': 1760782500000,
    });
    expect(list.items.single.unit, MeasurementUnit.unspecified);
    expect(list.createdAt.millisecondsSinceEpoch, 1760782500000);

    final record = PriceRecordModel.fromJson({
      'id': 'p',
      'name': 'Milk',
      'normalizedName': 'milk',
      'unitPrice': 7,
      'unit': 'liter',
      'quantity': 1,
      'currency': 'ILS',
      'purchasedAt': Timestamp.fromMillisecondsSinceEpoch(1760782500000),
      'receiptId': 'manual',
    });
    expect(record.unitPrice, 7.0);
    expect(record.purchasedAt.millisecondsSinceEpoch, 1760782500000);
  });

  test(
    'nutrition written as text or with a bad field costs only that field',
    () {
      final parsed = NutritionEntity.fromJson({
        'calories': '420',
        'proteinGrams': '12,5',
        'carbsGrams': 'lots',
        'fatGrams': double.nan,
      });
      expect(
        parsed,
        const NutritionEntity(
          calories: 420,
          proteinGrams: 12.5,
          carbsGrams: 0,
          fatGrams: 0,
        ),
      );
      expect(NutritionEntity.fromJson({'calories': 'n/a'}), isNull);
      expect(NutritionEntity.fromJson({'calories': 310.6})?.calories, 311);
    },
  );
}
