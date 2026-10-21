import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/my_recipes/presentation/pages/recipe_details_page.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/repositories/shared_recipes_repository.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Recipes extends Mock implements RecipesRepository {}

class _Ingestion extends Mock implements RecipeIngestionRepository {}

class _Shared extends Mock implements SharedRecipesRepository {}

class _FakeRecipe extends Fake implements RecipeEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRecipe());
    return LocaleSettings.setLocale(AppLocale.en);
  });
  setUp(
    () => FeaturesFlags.overrides = {
      for (final f in FeaturesFlags.values) f: FeatureFlagValue.hidden,
      FeaturesFlags.nutrition: FeatureFlagValue.enabled,
    },
  );
  tearDown(() => FeaturesFlags.overrides = null);

  final post = RecipeEntity(
    id: 'p1',
    title: 'Shakshuka',
    createdAt: DateTime(2026),
    ingredients: const [
      RecipeIngredientEntity(
        name: 'Eggs',
        amount: 4,
        unit: MeasurementUnit.unit,
      ),
    ],
    steps: const ['Cook.'],
  );

  testWidgets(
    'community post: a refused save says it failed, not "estimated"',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final recipes = _Recipes();
      final ingestion = _Ingestion();
      final shared = _Shared();
      when(() => ingestion.estimateNutrition(any())).thenAnswer(
        (_) async => post.copyWith(
          servings: 4,
          nutrition: const NutritionEntity(
            calories: 300,
            proteinGrams: 20,
            carbsGrams: 10,
            fatGrams: 15,
          ),
        ),
      );
      when(
        () => recipes.readyForSharing(any(), persist: any(named: 'persist')),
      ).thenAnswer(
        (inv) async => inv.positionalArguments.first as RecipeEntity,
      );
      when(
        () => shared.updateShared(any(), any()),
      ).thenThrow(Exception('permission-denied'));

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RecipesRepository>.value(value: recipes),
              RepositoryProvider<RecipeIngestionRepository>.value(
                value: ingestion,
              ),
              RepositoryProvider<SharedRecipesRepository>.value(value: shared),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              home: RecipeDetailsPage(recipe: post, sharedId: 'post-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.nutrition.estimate));
      await tester.pumpAndSettle();

      expect(find.text(t.nutrition.estimated), findsNothing);
      expect(find.text(t.nutrition.estimateFailed), findsOneWidget);
    },
  );
}
