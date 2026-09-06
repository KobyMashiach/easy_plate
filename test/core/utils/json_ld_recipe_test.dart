import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/json_ld_recipe.dart';
import 'package:flutter_test/flutter_test.dart';

String page(String json) => '<html><head><script type="application/ld+json">$json</script></head></html>';

void main() {
  group('parseJsonLdRecipe', () {
    test('reads a plain Recipe object', () {
      final recipe = parseJsonLdRecipe(page('''{
        "@context": "https://schema.org", "@type": "Recipe",
        "name": "שקשוקה", "prepTime": "PT10M", "cookTime": "PT20M",
        "recipeIngredient": ["4 ביצים", "400 גרם עגבניות מרוסקות"],
        "recipeInstructions": [
          {"@type": "HowToStep", "text": "מטגנים בצל."},
          {"@type": "HowToStep", "text": "מוסיפים עגבניות."}
        ]
      }'''));

      expect(recipe, isNotNull);
      expect(recipe!.title, 'שקשוקה');
      expect(recipe.prepMinutes, 10);
      expect(recipe.cookMinutes, 20);
      expect(recipe.ingredientLines, ['4 ביצים', '400 גרם עגבניות מרוסקות']);
      expect(recipe.steps, ['מטגנים בצל.', 'מוסיפים עגבניות.']);
    });

    test('finds the recipe inside a @graph wrapper', () {
      final recipe = parseJsonLdRecipe(page('''{
        "@context": "https://schema.org",
        "@graph": [
          {"@type": "WebSite", "name": "אתר"},
          {"@type": "Recipe", "name": "קובה", "recipeIngredient": ["סולת"], "recipeInstructions": "לשים."}
        ]
      }'''));
      expect(recipe?.title, 'קובה');
    });

    test('accepts @type given as a list', () {
      final recipe = parseJsonLdRecipe(page('''{
        "@type": ["Recipe", "NewsArticle"], "name": "סלט",
        "recipeIngredient": ["מלפפון"], "recipeInstructions": "חותכים."
      }'''));
      expect(recipe?.title, 'סלט');
    });

    test('flattens HowToSection groups into one ordered list', () {
      final recipe = parseJsonLdRecipe(page('''{
        "@type": "Recipe", "name": "עוגה", "recipeIngredient": ["קמח"],
        "recipeInstructions": [
          {"@type": "HowToSection", "name": "בצק", "itemListElement": [
            {"@type": "HowToStep", "text": "מערבבים."},
            {"@type": "HowToStep", "text": "לשים."}
          ]},
          {"@type": "HowToSection", "name": "אפייה", "itemListElement": [
            {"@type": "HowToStep", "text": "אופים."}
          ]}
        ]
      }'''));
      expect(recipe?.steps, ['מערבבים.', 'לשים.', 'אופים.']);
    });

    test('splits a single instruction string on line breaks and strips tags', () {
      final recipe = parseJsonLdRecipe(page('''{
        "@type": "Recipe", "name": "מרק", "recipeIngredient": ["מים"],
        "recipeInstructions": "<p>מרתיחים מים.</p><p>מוסיפים &amp; מערבבים.</p>"
      }'''));
      expect(recipe?.steps, ['מרתיחים מים.', 'מוסיפים & מערבבים.']);
    });

    test('maps schema.org diets to the app\'s chips, once each', () {
      final recipe = parseJsonLdRecipe(page('''{
        "@type": "Recipe", "name": "טופו", "recipeIngredient": ["טופו"],
        "recipeInstructions": "מטגנים.",
        "suitableForDiet": ["https://schema.org/VeganDiet", "https://schema.org/GlutenFreeDiet",
                            "https://schema.org/VeganDiet", "https://schema.org/LowFatDiet"]
      }'''));
      expect(recipe?.diets, unorderedEquals([DietaryPreference.vegan, DietaryPreference.glutenFree]));
    });

    test('a broken block does not hide a good one after it', () {
      final html = '<script type="application/ld+json">{not json</script>'
          '${page('{"@type":"Recipe","name":"תקין","recipeIngredient":["x"],"recipeInstructions":"y"}')}';
      expect(parseJsonLdRecipe(html)?.title, 'תקין');
    });

    test('a stub with neither ingredients nor steps is not a recipe', () {
      // The model does better with the page than we would with an empty shell.
      expect(parseJsonLdRecipe(page('{"@type":"Recipe","name":"רק כותרת"}')), isNull);
    });

    test('a page with no JSON-LD is null, not an error', () {
      expect(parseJsonLdRecipe('<html><body><p>סתם עמוד</p></body></html>'), isNull);
    });
  });

  group('parseIso8601DurationMinutes', () {
    test('minutes, hours, and mixed', () {
      expect(parseIso8601DurationMinutes('PT30M'), 30);
      expect(parseIso8601DurationMinutes('PT2H'), 120);
      expect(parseIso8601DurationMinutes('PT1H15M'), 75);
      expect(parseIso8601DurationMinutes('P0DT0H45M'), 45);
      expect(parseIso8601DurationMinutes('P1D'), 1440);
    });

    test('free text is unstated, never a guess', () {
      expect(parseIso8601DurationMinutes('30 minutes'), isNull);
      expect(parseIso8601DurationMinutes(''), isNull);
      expect(parseIso8601DurationMinutes(null), isNull);
    });
  });

  group('parseIngredientLine', () {
    test('Hebrew amount, unit and name', () {
      final p = parseIngredientLine('2 כוסות קמח');
      expect(p.amount, 2);
      expect(p.unit, MeasurementUnit.cup);
      expect(p.name, 'קמח');
    });

    test('drops the connective after the unit', () {
      expect(parseIngredientLine('2 כוסות של קמח').name, 'קמח');
      expect(parseIngredientLine('2 cups of flour').name, 'flour');
    });

    test('a number with no unit word means pieces', () {
      final p = parseIngredientLine('4 ביצים');
      expect(p.amount, 4);
      expect(p.unit, MeasurementUnit.unit);
      expect(p.name, 'ביצים');
    });

    test('fractions, mixed numbers and Hebrew words for them', () {
      expect(parseIngredientLine('1/2 כפית מלח').amount, 0.5);
      expect(parseIngredientLine('1 1/2 כוסות סוכר').amount, 1.5);
      expect(parseIngredientLine('½ כוס שמן').amount, 0.5);
      expect(parseIngredientLine('חצי כוס מים').amount, 0.5);
      expect(parseIngredientLine('1,5 ק"ג בשר').amount, 1.5);
      expect(parseIngredientLine('1,5 ק"ג בשר').unit, MeasurementUnit.kilogram);
    });

    test('English units', () {
      expect(parseIngredientLine('200 g butter').unit, MeasurementUnit.gram);
      expect(parseIngredientLine('2 tbsp olive oil').unit, MeasurementUnit.tablespoon);
      expect(parseIngredientLine('1 tsp salt').unit, MeasurementUnit.teaspoon);
      expect(parseIngredientLine('250 ml milk').unit, MeasurementUnit.milliliter);
    });

    test('no leading number keeps the whole line as the name, unstated amount', () {
      // The same "the source did not say" the model reports — nothing is lost.
      final p = parseIngredientLine('מלח לפי הטעם');
      expect(p.amount, isNull);
      expect(p.unit, MeasurementUnit.unspecified);
      expect(p.name, 'מלח לפי הטעם');
    });

    test('a line that is only a number keeps the original text as the name', () {
      // Better a nonsense name than an empty one that saves as a blank row.
      expect(parseIngredientLine('2').name, '2');
    });
  });
}
