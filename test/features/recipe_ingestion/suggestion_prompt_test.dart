import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a typed topic leads the request; the diet still binds', () {
    final prompt = GeminiRecipeAiDataSource.dishesPrompt(
      [DietaryPreference.vegan],
      topic: '  קינוחים ',
      language: AppLanguage.hebrew,
    );
    expect(prompt, contains('"קינוחים"'));
    expect(prompt, contains('vegan'));
    expect(prompt, isNot(contains('עיקריות, תוספות')));
  });

  test(
    'no topic: the varied list, and the popular fallback only when nothing is known',
    () {
      final bare = GeminiRecipeAiDataSource.dishesPrompt(
        const [],
        language: AppLanguage.hebrew,
      );
      expect(bare, contains('עיקריות, תוספות'));
      expect(bare, contains('פופולריות'));
      final topicOnly = GeminiRecipeAiDataSource.dishesPrompt(
        const [],
        topic: 'מרקים',
        language: AppLanguage.hebrew,
      );
      expect(topicOnly, isNot(contains('פופולריות')));
    },
  );
}
