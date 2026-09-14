import '../constants/app_enums.dart';
import '../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../features/recipe_books/domain/entities/book_recipe_ref_entity.dart';
import '../../features/recipe_books/domain/entities/recipe_book_entity.dart';
import '../utils/i18n/strings.g.dart';

/// Sample recipes and books for the guide: enough of each field filled in
/// that every part of a recipe page and a book — times, tags, allergens,
/// ingredients, steps, a contents page — has something to show. Built on
/// each call, in Hebrew or English by locale; never written anywhere.
abstract class DemoContent {
  static bool get _hebrew => LocaleSettings.currentLocale == AppLocale.he;

  static DateTime get _when => DateTime(2026, 1, 1);

  static RecipeIngredientEntity _i(String he, String en, double? amount, MeasurementUnit unit) =>
      RecipeIngredientEntity(name: _hebrew ? he : en, amount: amount, unit: unit);

  static List<RecipeEntity> recipes() => [
        RecipeEntity(
          id: 'demo-shakshuka',
          title: _hebrew ? 'שקשוקה ירושלמית' : 'Jerusalem shakshuka',
          prepTimeMinutes: 10,
          cookTimeMinutes: 20,
          ingredients: [
            _i('עגבניות מרוסקות', 'Crushed tomatoes', 400, MeasurementUnit.gram),
            _i('ביצים', 'Eggs', 4, MeasurementUnit.unit),
            _i('בצל', 'Onion', 1, MeasurementUnit.unit),
            _i('שמן זית', 'Olive oil', 2, MeasurementUnit.tablespoon),
            _i('פפריקה מתוקה', 'Sweet paprika', 1, MeasurementUnit.teaspoon),
            _i('מלח', 'Salt', 1, MeasurementUnit.pinch),
          ],
          steps: _hebrew
              ? [
                  'מחממים שמן זית במחבת ומטגנים את הבצל עד להזהבה.',
                  'מוסיפים את העגבניות והפפריקה ומבשלים 10 דקות על אש נמוכה.',
                  'שוברים את הביצים לתוך הרוטב, מכסים ומבשלים עד שהחלבון מתקשה.',
                  'מגישים עם לחם טרי.',
                ]
              : [
                  'Heat the olive oil in a pan and fry the onion until golden.',
                  'Add the tomatoes and paprika and simmer for 10 minutes.',
                  'Crack the eggs into the sauce, cover, and cook until the whites set.',
                  'Serve with fresh bread.',
                ],
          dietaryTags: const [
            DietaryPreference.vegetarian,
            DietaryPreference.kosher,
            DietaryPreference.glutenFree,
            DietaryPreference.allergy,
          ],
          allergens: const [Allergen.eggs],
          sourceChannel: RecipeIngestionChannel.rawText,
          createdAt: _when,
        ),
        RecipeEntity(
          id: 'demo-lentil-soup',
          title: _hebrew ? 'מרק עדשים כתומות' : 'Red lentil soup',
          prepTimeMinutes: 15,
          cookTimeMinutes: 35,
          ingredients: [
            _i('עדשים כתומות', 'Red lentils', 300, MeasurementUnit.gram),
            _i('גזר', 'Carrots', 2, MeasurementUnit.unit),
            _i('בצל', 'Onion', 1, MeasurementUnit.unit),
            _i('כמון', 'Cumin', 1, MeasurementUnit.teaspoon),
            _i('מים', 'Water', 1.5, MeasurementUnit.liter),
            _i('לימון', 'Lemon', 0.5, MeasurementUnit.unit),
          ],
          steps: _hebrew
              ? [
                  'קוצצים בצל וגזר ומאדים בסיר עם מעט שמן.',
                  'מוסיפים עדשים, כמון ומים ומביאים לרתיחה.',
                  'מבשלים 30 דקות עד שהעדשים מתרככות, וטוחנים חלקית.',
                  'מתבלים במלח ולימון ומגישים חם.',
                ]
              : [
                  'Chop the onion and carrots and sweat them in a pot with a little oil.',
                  'Add the lentils, cumin and water and bring to the boil.',
                  'Simmer for 30 minutes until the lentils soften, then blend partly.',
                  'Season with salt and lemon and serve hot.',
                ],
          dietaryTags: const [
            DietaryPreference.vegan,
            DietaryPreference.vegetarian,
            DietaryPreference.kosher,
            DietaryPreference.glutenFree,
          ],
          sourceChannel: RecipeIngestionChannel.aiRequest,
          createdAt: _when,
        ),
        RecipeEntity(
          id: 'demo-chicken',
          title: _hebrew ? 'עוף בתנור עם תפוחי אדמה' : 'Roast chicken with potatoes',
          prepTimeMinutes: 20,
          cookTimeMinutes: 75,
          ingredients: [
            _i('כרעיים עוף', 'Chicken thighs', 4, MeasurementUnit.unit),
            _i('תפוחי אדמה', 'Potatoes', 800, MeasurementUnit.gram),
            _i('שום', 'Garlic', 4, MeasurementUnit.unit),
            _i('רוזמרין', 'Rosemary', 2, MeasurementUnit.unit),
            _i('שמן זית', 'Olive oil', 3, MeasurementUnit.tablespoon),
            _i('פפריקה', 'Paprika', 1, MeasurementUnit.tablespoon),
          ],
          steps: _hebrew
              ? [
                  'מחממים תנור ל-200 מעלות.',
                  'מערבבים תפוחי אדמה חתוכים עם שמן, שום ורוזמרין בתבנית.',
                  'מתבלים את העוף בפפריקה ומלח ומניחים מעל.',
                  'אופים 75 דקות עד שהעוף זהוב ותפוחי האדמה רכים.',
                ]
              : [
                  'Preheat the oven to 200°C.',
                  'Toss the cut potatoes with oil, garlic and rosemary in a tray.',
                  'Season the chicken with paprika and salt and lay it on top.',
                  'Roast for 75 minutes until the chicken is golden and the potatoes soft.',
                ],
          dietaryTags: const [DietaryPreference.meat, DietaryPreference.kosher, DietaryPreference.glutenFree],
          sourceChannel: RecipeIngestionChannel.urlScrape,
          sourceUrl: 'https://example.com/roast-chicken',
          createdAt: _when,
        ),
        RecipeEntity(
          id: 'demo-cake',
          title: _hebrew ? 'עוגת שוקולד ביתית' : 'Homemade chocolate cake',
          prepTimeMinutes: 15,
          cookTimeMinutes: 40,
          ingredients: [
            _i('קמח', 'Flour', 2, MeasurementUnit.cup),
            _i('סוכר', 'Sugar', 1.5, MeasurementUnit.cup),
            _i('קקאו', 'Cocoa', 0.5, MeasurementUnit.cup),
            _i('ביצים', 'Eggs', 3, MeasurementUnit.unit),
            _i('חלב', 'Milk', 1, MeasurementUnit.cup),
            _i('חמאה', 'Butter', 100, MeasurementUnit.gram),
            _i('אגוזי מלך', 'Walnuts', 50, MeasurementUnit.gram),
          ],
          steps: _hebrew
              ? [
                  'מחממים תנור ל-180 מעלות ומשמנים תבנית.',
                  'מערבבים את החומרים היבשים, ובקערה נפרדת את הביצים, החלב והחמאה המומסת.',
                  'מאחדים לבלילה חלקה, מוסיפים אגוזים ויוצקים לתבנית.',
                  'אופים 40 דקות ובודקים עם קיסם.',
                ]
              : [
                  'Preheat the oven to 180°C and grease a tin.',
                  'Mix the dry ingredients; in another bowl whisk the eggs, milk and melted butter.',
                  'Combine into a smooth batter, fold in the walnuts and pour into the tin.',
                  'Bake for 40 minutes and test with a skewer.',
                ],
          dietaryTags: const [DietaryPreference.dairy, DietaryPreference.vegetarian, DietaryPreference.allergy],
          allergens: const [Allergen.gluten, Allergen.milk, Allergen.eggs, Allergen.treeNuts],
          mayContain: const [Allergen.peanuts],
          sourceChannel: RecipeIngestionChannel.manual,
          createdAt: _when,
        ),
        RecipeEntity(
          id: 'demo-salad',
          title: _hebrew ? 'סלט ישראלי קצוץ' : 'Chopped Israeli salad',
          prepTimeMinutes: 10,
          ingredients: [
            _i('עגבניות', 'Tomatoes', 3, MeasurementUnit.unit),
            _i('מלפפונים', 'Cucumbers', 3, MeasurementUnit.unit),
            _i('פטרוזיליה', 'Parsley', null, MeasurementUnit.unspecified),
            _i('לימון', 'Lemon', 1, MeasurementUnit.unit),
            _i('שמן זית', 'Olive oil', 2, MeasurementUnit.tablespoon),
          ],
          steps: _hebrew
              ? ['קוצצים את הירקות לקוביות קטנות.', 'מתבלים בלימון, שמן זית ומלח ומערבבים.']
              : ['Chop the vegetables into small dice.', 'Dress with lemon, olive oil and salt and toss.'],
          dietaryTags: const [
            DietaryPreference.vegan,
            DietaryPreference.vegetarian,
            DietaryPreference.kosher,
            DietaryPreference.glutenFree,
          ],
          sourceChannel: RecipeIngestionChannel.socialVideo,
          sourceUrl: 'https://www.tiktok.com/@example/video/1',
          createdAt: _when,
        ),
      ];

  static List<RecipeBookEntity> books() {
    final all = recipes();
    List<BookRecipeRefEntity> refs(List<int> indexes) => [
          for (var i = 0; i < indexes.length; i++)
            BookRecipeRefEntity(recipeId: all[indexes[i]].id, order: i),
        ];
    return [
      RecipeBookEntity(
        id: 'demo-book-weekday',
        title: _hebrew ? 'ארוחות של יום חול' : 'Weeknight dinners',
        recipeRefs: refs([0, 1, 2]),
        createdAt: _when,
      ),
      RecipeBookEntity(
        id: 'demo-book-family',
        title: _hebrew ? 'המתכונים של סבתא' : "Grandma's recipes",
        recipeRefs: refs([3, 4, 0]),
        createdAt: _when,
      ),
    ];
  }

  /// The recipes a demo book holds, in the book's order.
  static List<RecipeEntity> recipesOf(RecipeBookEntity book) {
    final byId = {for (final r in recipes()) r.id: r};
    return [for (final ref in book.orderedRefs) ?byId[ref.recipeId]];
  }
}
