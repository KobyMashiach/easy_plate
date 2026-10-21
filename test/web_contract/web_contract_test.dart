// The website (webapp/) writes the same Firestore records the app mirrors.
// The app parses them with strict generated fromJson code, so a record the
// website shapes differently would break a phone on its next hydrate.
//
// Every sample the website's code produces lives in
//   webapp/contract-fixtures/<collection>/<name>.json
// and this test parses each one with the model the app uses for that
// collection, then checks the round trip writes the same keys back — a key
// the website forgets, renames or adds shows up here, not on a phone.
import 'dart:convert';
import 'dart:io';

import 'package:easy_plate/core/monetization/daily_usage_model.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:easy_plate/features/meal_planner/data/models/meal_plan_model.dart';
import 'package:easy_plate/features/my_recipes/data/models/recipe_model.dart';
import 'package:easy_plate/features/price_book/data/models/price_record_model.dart';
import 'package:easy_plate/features/price_book/data/models/product_pricing_model.dart';
import 'package:easy_plate/features/price_book/data/models/receipt_model.dart';
import 'package:easy_plate/features/recipe_books/data/models/recipe_book_model.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Codec = Map<String, dynamic> Function(Map<String, dynamic> json);

final Map<String, _Codec> _roundTrip = {
  'recipes': (j) => RecipeModel.fromJson(j).toJson(),
  'books': (j) => RecipeBookModel.fromJson(j).toJson(),
  'meal_plans': (j) => MealPlanModel.fromJson(j).toJson(),
  'grocery_lists': (j) => GroceryListModel.fromJson(j).toJson(),
  'price_records': (j) => PriceRecordModel.fromJson(j).toJson(),
  'receipts': (j) => ReceiptModel.fromJson(j).toJson(),
  'product_pricing': (j) => ProductPricingModel.fromJson(j).toJson(),
  'preferences': (j) => UserPreferencesModel.fromJson(j).toJson(),
  'usage': (j) => DailyUsageModel.fromJson(j).toJson(),
};

/// Every key path in a JSON value ("ingredients[].unit"), so nested shapes
/// are compared too, not only the top level.
Set<String> _paths(Object? value, [String prefix = '']) {
  final out = <String>{};
  if (value is Map) {
    for (final entry in value.entries) {
      final key = prefix.isEmpty ? '${entry.key}' : '$prefix.${entry.key}';
      out.add(key);
      out.addAll(_paths(entry.value, key));
    }
  } else if (value is List) {
    for (final item in value) {
      out.addAll(_paths(item, '$prefix[]'));
    }
  }
  return out;
}

void main() {
  final root = Directory('webapp/contract-fixtures');

  test('every fixture folder names a collection the app mirrors', () {
    if (!root.existsSync()) return;
    for (final dir in root.listSync().whereType<Directory>()) {
      final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      expect(
        _roundTrip.containsKey(name),
        isTrue,
        reason: 'unknown collection folder "$name"',
      );
    }
  });

  if (!root.existsSync()) return;
  for (final dir in root.listSync().whereType<Directory>()) {
    final collection = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final codec = _roundTrip[collection];
    if (codec == null) continue;
    for (final file in dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    )) {
      final label = '$collection/${file.uri.pathSegments.last}';
      test(
        '$label parses as the app parses it and writes the same keys back',
        () {
          final json =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final back =
              jsonDecode(jsonEncode(codec(json))) as Map<String, dynamic>;
          final written = _paths(json);
          final expected = _paths(back);
          expect(
            written.difference(expected),
            isEmpty,
            reason: '$label has keys the app does not know (renamed or extra)',
          );
          expect(
            expected.difference(written),
            isEmpty,
            reason:
                '$label is missing keys the app writes — write them (null when empty)',
          );
        },
      );
    }
  }
}
