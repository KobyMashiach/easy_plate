import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every language is named, and the extraction prompt ends with it', () {
    const names = {
      AppLanguage.hebrew: 'עברית',
      AppLanguage.english: 'אנגלית',
      AppLanguage.arabic: 'ערבית',
      AppLanguage.french: 'צרפתית',
      AppLanguage.russian: 'רוסית',
    };
    for (final language in AppLanguage.values) {
      final line = GeminiRecipeAiDataSource.languageInstruction(language);
      expect(line, startsWith('שפת התשובה: ${names[language]}'));
      expect(
        line,
        contains('תרגם'),
        reason: 'a source in another language is translated',
      );
      final prompt = GeminiRecipeAiDataSource.systemInstructionFor(language);
      expect(prompt, endsWith(line));
      expect(
        prompt,
        contains('JSON'),
        reason: 'the extraction rules stay in front',
      );
    }
  });
}
