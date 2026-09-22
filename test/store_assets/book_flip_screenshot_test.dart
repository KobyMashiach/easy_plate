// Renders the recipe book caught halfway through a page turn, as a raw
// landscape screenshot for the store listing (tools/store_screenshots
// frames it with a caption). Off by default — it writes into the repo:
//
//   flutter test test/store_assets --dart-define=STORE_SCREENSHOTS=true
//
// The recipes are samples and carry no photo; the same shot taken from a
// phone with real recipes (tools/store_screenshots/capture.sh) looks
// better and simply overwrites this file.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/styles/app_theme.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/book_spread_flip.dart';
import 'package:easy_plate/features/recipe_books/presentation/widgets/recipe_book_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');

RecipeIngredientEntity _i(String name, double amount, MeasurementUnit unit) =>
    RecipeIngredientEntity(name: name, amount: amount, unit: unit);

List<RecipeEntity> _recipes(AppLocale locale) {
  final he = locale == AppLocale.he;
  final at = DateTime(2026, 9, 1);
  return [
    RecipeEntity(
      id: 'r1',
      title: he ? 'שקשוקה ירושלמית' : 'Jerusalem Shakshuka',
      prepTimeMinutes: 10,
      cookTimeMinutes: 25,
      servings: 4,
      dietaryTags: const [DietaryPreference.vegetarian],
      ingredients: [
        _i(he ? 'עגבניות מרוסקות' : 'Crushed tomatoes', 800, MeasurementUnit.gram),
        _i(he ? 'שמן זית' : 'Olive oil', 3, MeasurementUnit.tablespoon),
        _i(he ? 'פפריקה מתוקה' : 'Sweet paprika', 1, MeasurementUnit.tablespoon),
        _i(he ? 'כמון' : 'Cumin', 1, MeasurementUnit.teaspoon),
      ],
      steps: he
          ? ['מטגנים בצל ופלפל עד ריכוך.', 'מוסיפים עגבניות ותבלינים ומבשלים 15 דקות.', 'שוברים ביצים פנימה ומכסים.']
          : ['Soften the onion and pepper.', 'Add tomatoes and spices, simmer 15 minutes.', 'Crack in the eggs and cover.'],
      createdAt: at,
    ),
    RecipeEntity(
      id: 'r2',
      title: he ? 'עוגת שוקולד של סבתא' : "Grandma's Chocolate Cake",
      prepTimeMinutes: 20,
      cookTimeMinutes: 40,
      servings: 10,
      dietaryTags: const [DietaryPreference.dairy],
      ingredients: [
        _i(he ? 'קמח' : 'Flour', 2, MeasurementUnit.cup),
        _i(he ? 'סוכר' : 'Sugar', 1.5, MeasurementUnit.cup),
        _i(he ? 'קקאו' : 'Cocoa', 0.5, MeasurementUnit.cup),
        _i(he ? 'חלב' : 'Milk', 250, MeasurementUnit.milliliter),
      ],
      steps: he
          ? ['מערבבים את היבשים.', 'מוסיפים את הרטובים וטורפים.', 'אופים 40 דקות ב-170 מעלות.']
          : ['Mix the dry ingredients.', 'Add the wet ones and whisk.', 'Bake 40 minutes at 170°C.'],
      createdAt: at,
    ),
    RecipeEntity(
      id: 'r3',
      title: he ? 'פסטה ברוטב שמנת פטריות' : 'Creamy Mushroom Pasta',
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      servings: 3,
      dietaryTags: const [DietaryPreference.dairy],
      ingredients: [
        _i(he ? 'פסטה' : 'Pasta', 500, MeasurementUnit.gram),
        _i(he ? 'פטריות' : 'Mushrooms', 300, MeasurementUnit.gram),
        _i(he ? 'שמנת לבישול' : 'Cooking cream', 250, MeasurementUnit.milliliter),
      ],
      steps: he
          ? ['מבשלים את הפסטה.', 'מקפיצים פטריות ושום.', 'מוסיפים שמנת ומערבבים עם הפסטה.']
          : ['Cook the pasta.', 'Sauté mushrooms and garlic.', 'Add cream and toss with the pasta.'],
      createdAt: at,
    ),
    RecipeEntity(
      id: 'r4',
      title: he ? 'סלט קינואה ירוק' : 'Green Quinoa Salad',
      prepTimeMinutes: 15,
      cookTimeMinutes: 15,
      servings: 2,
      dietaryTags: const [DietaryPreference.vegan],
      ingredients: [
        _i(he ? 'קינואה' : 'Quinoa', 1, MeasurementUnit.cup),
        _i(he ? 'מלפפון' : 'Cucumber', 2, MeasurementUnit.unspecified),
        _i(he ? 'מיץ לימון' : 'Lemon juice', 2, MeasurementUnit.tablespoon),
      ],
      steps: he
          ? ['מבשלים קינואה ומצננים.', 'קוצצים ירקות.', 'מתבלים ומגישים.']
          : ['Cook and cool the quinoa.', 'Chop the vegetables.', 'Dress and serve.'],
      createdAt: at,
    ),
  ];
}

Future<void> _loadFonts() async {
  final jakarta = FontLoader('Plus Jakarta Sans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await jakarta.load();
  for (final path in const [
    '/System/Library/Fonts/Supplemental/Arial Hebrew.ttc',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final hebrew = FontLoader('Arial Hebrew')
      ..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
    await hebrew.load();
    break;
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(icons.readAsBytes().then((b) => ByteData.sublistView(b)));
      await loader.load();
    }
  }
}

const _locales = [AppLocale.he, AppLocale.en];

void main() {
  setUpAll(() async {
    if (!_enabled) return;
    await _loadFonts();
    for (final locale in _locales) {
      await LocaleSettings.setLocale(locale);
    }
  });

  for (final locale in _locales) {
    testWidgets('book mid-flip ${locale.languageCode}', (tester) async {
      // A phone on its side: the book is landscape-only in the app.
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);

      LocaleSettings.setLocaleSync(locale);
      final controller = BookSpreadController();
      final key = GlobalKey();
      final recipes = _recipes(locale);
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.current,
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: SafeArea(
                  child: BookSpreadFlip(
                    controller: controller,
                    duration: const Duration(milliseconds: 1000),
                    pages: [
                      for (var i = 0; i < recipes.length; i++)
                        RecipeBookPage(recipe: recipes[i], pageNumber: i + 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start the turn and stop the clock partway: the leaf is in the air.
      final turn = controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.6);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = File('store_assets/raw/${locale.languageCode}/05_book_flip.png');
        // A shot taken from a real phone, with real recipes and photos, is
        // the better source and is never overwritten by this stand-in.
        if (out.existsSync()) {
          debugPrint('kept the existing ${out.path}');
          return;
        }
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(bytes!.buffer.asUint8List());
      });

      await tester.pumpAndSettle();
      await turn;
    }, skip: !_enabled);
  }
}
