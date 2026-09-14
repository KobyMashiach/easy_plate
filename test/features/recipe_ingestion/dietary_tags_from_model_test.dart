import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known names come back as tags, in the app\'s order', () {
    expect(
      dietaryTagsFromModel(['kosher', 'vegetarian', 'allergy']),
      [DietaryPreference.vegetarian, DietaryPreference.kosher, DietaryPreference.allergy],
    );
  });

  test('a repeated or unknown value is dropped rather than failing the recipe', () {
    expect(
      dietaryTagsFromModel(['vegan', 'vegan', 'paleo', 3]),
      [DietaryPreference.vegan],
    );
  });

  test('a missing or malformed field is no tags', () {
    expect(dietaryTagsFromModel(null), isEmpty);
    expect(dietaryTagsFromModel('vegan'), isEmpty);
    expect(dietaryTagsFromModel(const []), isEmpty);
  });

  group('allergens', () {
    test('names come back as allergens, in the app\'s order, unknown ones dropped', () {
      expect(
        Allergen.fromNames(['sesame', 'eggs', 'eggs', 'lupin']),
        [Allergen.eggs, Allergen.sesame],
      );
      expect(Allergen.fromNames(null), isEmpty);
    });

    test('an allergen list forces the allergy tag on', () {
      expect(
        dietaryTagsWithAllergens([DietaryPreference.vegetarian], [Allergen.eggs]),
        [DietaryPreference.vegetarian, DietaryPreference.allergy],
      );
    });

    test('no allergens leaves the tags as the model said', () {
      expect(dietaryTagsWithAllergens([DietaryPreference.vegan], const []), [DietaryPreference.vegan]);
      // Including an allergy tag the model set on its own — that is its call.
      expect(
        dietaryTagsWithAllergens([DietaryPreference.allergy], const []),
        [DietaryPreference.allergy],
      );
    });

    test('an allergy tag already present is not doubled', () {
      expect(
        dietaryTagsWithAllergens([DietaryPreference.allergy], [Allergen.milk]),
        [DietaryPreference.allergy],
      );
    });
  });
}
