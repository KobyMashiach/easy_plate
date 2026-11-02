import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = UserPreferencesEntity(
    shoppingDay: ShoppingDay.thursday,
    dietaryPreferences: [],
  );

  test('several days are stored as the first one plus the rest', () {
    final p = base.withShoppingDays(const [
      ShoppingDay.friday,
      ShoppingDay.monday,
    ]);
    expect(p.shoppingDay, ShoppingDay.monday);
    expect(p.extraShoppingDays, [ShoppingDay.friday]);
    expect(p.shoppingDays, [ShoppingDay.monday, ShoppingDay.friday]);
  });

  test('an empty choice keeps the days there are', () {
    expect(base.withShoppingDays(const []).shoppingDays, [
      ShoppingDay.thursday,
    ]);
  });

  test('the extra days survive the cloud record and the model', () {
    final p = base.withShoppingDays(const [
      ShoppingDay.sunday,
      ShoppingDay.wednesday,
    ]);
    final json = p.toModel().toJson();
    expect(json['extraShoppingDays'], ['wednesday']);
    final back = UserPreferencesModel.fromJson(json).toEntity();
    expect(back.shoppingDays, [ShoppingDay.sunday, ShoppingDay.wednesday]);
  });

  test(
    'a record from before the field, or with a bad name, reads as one day',
    () {
      final old = UserPreferencesModel.fromJson({
        'shoppingDay': 'tuesday',
        'dietaryPreferences': <String>[],
      }).toEntity();
      expect(old.shoppingDays, [ShoppingDay.tuesday]);
      final odd = UserPreferencesModel.fromJson({
        'shoppingDay': 'tuesday',
        'dietaryPreferences': <String>[],
        'extraShoppingDays': ['someday', 'friday', 3],
      }).toEntity();
      expect(odd.shoppingDays, [ShoppingDay.tuesday, ShoppingDay.friday]);
    },
  );
}
