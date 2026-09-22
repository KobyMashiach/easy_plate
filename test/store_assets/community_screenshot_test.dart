// Renders the community tab with sample posts, as a raw screenshot for the
// store listing. Off by default — it writes into the repo:
//
//   flutter test test/store_assets --dart-define=STORE_SCREENSHOTS=true
//
// The feed, the cards and the like counts are the app's own widgets; only
// the posts behind them are made up, the way the paywall shot uses sample
// offers. Nothing is written to Firestore: a store picture must never put
// invented people into the real community.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/monetization/entitlement_service.dart';
import 'package:easy_plate/core/styles/app_theme.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/community/presentation/pages/community_page.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/domain/repositories/shared_recipes_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');

RecipeIngredientEntity _i(String name, double amount, MeasurementUnit unit) =>
    RecipeIngredientEntity(name: name, amount: amount, unit: unit);

/// Posts by several cooks, none of them the viewer — so the cards carry no
/// edit or delete action, exactly as someone else's post looks.
List<SharedRecipeEntity> _feed(AppLocale locale) {
  final he = locale == AppLocale.he;
  final now = DateTime(2026, 9, 20, 12);
  final posts = <(String, String, int, List<RecipeIngredientEntity>, int)>[
    (
      he ? 'שקשוקה של סבתא רחל' : "Grandma Rachel's Shakshuka",
      he ? 'רחל אברהמי' : 'Rachel Avrahami',
      248,
      [
        _i(he ? 'עגבניות' : 'Tomatoes', 6, MeasurementUnit.unspecified),
        _i(he ? 'פלפל אדום' : 'Red pepper', 1, MeasurementUnit.unspecified),
        _i(he ? 'ביצים' : 'Eggs', 4, MeasurementUnit.unspecified),
      ],
      2,
    ),
    (
      he ? 'קובה סלק סגולה' : 'Purple Beetroot Kubbeh',
      he ? 'יוסי ממן' : 'Yossi Maman',
      173,
      [
        _i(he ? 'סלק' : 'Beetroot', 4, MeasurementUnit.unspecified),
        _i(he ? 'סולת' : 'Semolina', 2, MeasurementUnit.cup),
        _i(he ? 'בשר טחון' : 'Ground beef', 500, MeasurementUnit.gram),
      ],
      5,
    ),
    (
      he ? 'עוגת שוקולד ללא גלוטן' : 'Gluten-free Chocolate Cake',
      he ? 'מאיה לוי' : 'Maya Levy',
      412,
      [
        _i(he ? 'שוקולד מריר' : 'Dark chocolate', 200, MeasurementUnit.gram),
        _i(he ? 'קמח שקדים' : 'Almond flour', 1.5, MeasurementUnit.cup),
        _i(he ? 'ביצים' : 'Eggs', 3, MeasurementUnit.unspecified),
      ],
      9,
    ),
    (
      he ? 'פסטה ברוטב שמנת ופטריות' : 'Creamy Mushroom Pasta',
      he ? 'דניאל כהן' : 'Daniel Cohen',
      96,
      [
        _i(he ? 'פטריות' : 'Mushrooms', 300, MeasurementUnit.gram),
        _i(he ? 'שמנת מתוקה' : 'Cream', 250, MeasurementUnit.milliliter),
      ],
      14,
    ),
  ];

  return [
    for (final (index, post) in posts.indexed)
      SharedRecipeEntity(
        id: 'sample-$index',
        authorUid: 'cook-$index',
        authorName: post.$2,
        likeCount: post.$3,
        likedByMe: index == 1,
        createdAt: now.subtract(Duration(days: post.$5)),
        recipe: RecipeEntity(
          id: 'sample-recipe-$index',
          title: post.$1,
          ingredients: post.$4,
          steps: const [],
          createdAt: now,
        ),
      ),
  ];
}

class _FakeSharedRecipes implements SharedRecipesRepository {
  _FakeSharedRecipes(this.feed);

  final List<SharedRecipeEntity> feed;

  @override
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
  }) async => feed;

  @override
  Future<SharedRecipeEntity?> getById(String id, {required String viewerUid}) async => null;

  @override
  Future<String> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async => '';

  @override
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid}) async => false;

  @override
  Future<void> updateShared(String sharedRecipeId, RecipeEntity recipe) async {}

  @override
  Future<void> unshare(String sharedRecipeId) async {}
}

class _FakeRecipes implements RecipesRepository {
  @override
  Future<List<RecipeEntity>> getRecipes() async => const [];

  @override
  Stream<List<RecipeEntity>> watchRecipes() => const Stream.empty();

  @override
  Future<RecipeEntity?> getRecipeById(String id) async => null;

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {}

  @override
  Future<void> deleteRecipe(String id) async {}

  @override
  Future<RecipeEntity> readyForSharing(RecipeEntity recipe, {bool persist = true}) async => recipe;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeForum implements ForumRepository {
  @override
  Future<List<ForumPostEntity>> getPosts({required String viewerUid, int limit = 50}) async =>
      const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    testWidgets('community feed ${locale.languageCode}', (tester) async {
      // The phone's screen less its status bar, the same frame the captured
      // shots come out at.
      tester.view.physicalSize = const Size(1080, 2266);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      // Premium, so no rewarded-video badge sits on someone else's card.
      EntitlementService().setForTest(true);
      addTearDown(EntitlementService().clear);

      LocaleSettings.setLocaleSync(locale);
      final key = GlobalKey();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<SharedRecipesRepository>.value(
              value: _FakeSharedRecipes(_feed(locale)),
            ),
            RepositoryProvider<RecipesRepository>.value(value: _FakeRecipes()),
            RepositoryProvider<ForumRepository>.value(value: _FakeForum()),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.current,
              locale: locale.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: RepaintBoundary(key: key, child: const CommunityPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.6);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = File('store_assets/raw/${locale.languageCode}/09_community.png');
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }, skip: !_enabled);
  }
}
