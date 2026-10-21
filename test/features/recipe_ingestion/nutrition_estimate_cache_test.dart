import 'dart:async';
import 'dart:convert';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Answer = ({int? servings, NutritionEntity nutrition});

const _nutrition = NutritionEntity(
  calories: 420,
  proteinGrams: 20,
  carbsGrams: 40,
  fatGrams: 12,
);

RecipeEntity _recipe({int? servings, double? eggs = 4, String title = 'x'}) =>
    RecipeEntity(
      id: 'r1',
      title: title,
      servings: servings,
      ingredients: [
        RecipeIngredientEntity(
          name: 'ביצים',
          amount: eggs,
          unit: MeasurementUnit.unit,
        ),
      ],
      steps: List.filled(100, 'לערבב היטב ולבשל על אש קטנה'),
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late int calls;
  late Future<_Answer> Function(String) ask;

  setUp(() {
    GeminiRecipeAiDataSource.clearNutritionCache();
    calls = 0;
    ask = (_) async {
      calls++;
      return (servings: 2, nutrition: _nutrition);
    };
  });

  Future<RecipeEntity> estimate(RecipeEntity r) =>
      GeminiRecipeAiDataSource.estimateNutritionCached(r, ask);

  test('the payload leaves the steps out when every amount is known', () {
    final payload =
        jsonDecode(GeminiRecipeAiDataSource.nutritionPayload(_recipe()))
            as Map<String, dynamic>;
    expect(payload.containsKey('steps'), isFalse);
    expect(payload['ingredients'], hasLength(1));

    final missing =
        jsonDecode(
              GeminiRecipeAiDataSource.nutritionPayload(_recipe(eggs: null)),
            )
            as Map<String, dynamic>;
    expect(missing['steps'], hasLength(100));
  });

  test('the same recipe asked twice costs one model call', () async {
    final first = await estimate(_recipe());
    final second = await estimate(_recipe());
    expect(calls, 1);
    expect(first.nutrition?.calories, 420);
    expect(second.servings, 2);
  });

  test('a double trigger while in flight shares the call', () async {
    final gate = Completer<void>();
    ask = (_) async {
      calls++;
      await gate.future;
      return (servings: 2, nutrition: _nutrition);
    };
    final a = estimate(_recipe());
    final b = estimate(_recipe());
    gate.complete();
    await Future.wait([a, b]);
    expect(calls, 1);
  });

  test(
    're-estimating the saved result (servings now filled) is free',
    () async {
      final saved = await estimate(_recipe());
      await estimate(saved);
      expect(calls, 1);
    },
  );

  test('a changed ingredient asks again', () async {
    await estimate(_recipe());
    await estimate(_recipe(eggs: 6));
    expect(calls, 2);
  });

  test('a failed call is not cached', () async {
    ask = (_) async {
      calls++;
      if (calls == 1) throw StateError('busy');
      return (servings: 2, nutrition: _nutrition);
    };
    await expectLater(estimate(_recipe()), throwsStateError);
    final retried = await estimate(_recipe());
    expect(calls, 2);
    expect(retried.nutrition?.calories, 420);
  });
}
