import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allergens survive the cloud record, in enum order', () {
    const p = UserPreferencesEntity(
      shoppingDay: ShoppingDay.sunday,
      dietaryPreferences: [DietaryPreference.allergy],
      allergens: [Allergen.sesame, Allergen.eggs],
    );
    final json = p.toModel().toJson();
    expect(json['allergens'], ['sesame', 'eggs']);
    final back = UserPreferencesModel.fromJson(json).toEntity();
    expect(back.allergens, [Allergen.eggs, Allergen.sesame]);
    expect(back.activeAllergens, [Allergen.eggs, Allergen.sesame]);
  });

  test('older records and unknown names read as no allergens', () {
    final old = UserPreferencesModel.fromJson({
      'shoppingDay': 'sunday',
      'dietaryPreferences': ['allergy'],
    }).toEntity();
    expect(old.allergens, isEmpty);
    final odd = UserPreferencesModel.fromJson({
      'shoppingDay': 'sunday',
      'dietaryPreferences': ['allergy'],
      'allergens': ['eggs', 'kryptonite', 3],
    }).toEntity();
    expect(odd.allergens, [Allergen.eggs]);
  });

  test('allergens count only while the allergy diet is on', () {
    const p = UserPreferencesEntity(
      shoppingDay: ShoppingDay.sunday,
      dietaryPreferences: [DietaryPreference.vegan],
      allergens: [Allergen.eggs],
    );
    expect(p.activeAllergens, isEmpty);
    expect(p.allergens, [Allergen.eggs]);
  });
}
