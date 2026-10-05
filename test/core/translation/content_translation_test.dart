import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/translation/content_translation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('language codes', () {
    test('every app language has a code, and every code a language', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguageCode.fromCode(language.code), language);
      }
      expect(AppLanguageCode.fromCode('xx'), isNull);
      expect(AppLanguageCode.fromCode(null), isNull);
    });
  });

  group('guessing a record language', () {
    test('reads the script', () {
      expect(
        guessLanguage('שקשוקה קלאסית', fallback: AppLanguage.english),
        AppLanguage.hebrew,
      );
      expect(
        guessLanguage('شكشوكة', fallback: AppLanguage.english),
        AppLanguage.arabic,
      );
      expect(
        guessLanguage('Борщ', fallback: AppLanguage.english),
        AppLanguage.russian,
      );
      expect(
        guessLanguage('Shakshuka', fallback: AppLanguage.hebrew),
        AppLanguage.english,
      );
    });

    test('numbers and units do not decide it', () {
      expect(
        guessLanguage('2 כוסות קמח', fallback: AppLanguage.english),
        AppLanguage.hebrew,
      );
      expect(
        guessLanguage('500', fallback: AppLanguage.hebrew),
        AppLanguage.hebrew,
      );
      expect(
        guessLanguage('', fallback: AppLanguage.french),
        AppLanguage.french,
      );
    });

    test('Latin text takes the fallback when it could be French', () {
      expect(
        guessLanguage('Ratatouille', fallback: AppLanguage.french),
        AppLanguage.french,
      );
      expect(
        guessLanguage('Ratatouille', fallback: AppLanguage.russian),
        AppLanguage.english,
      );
    });
  });

  group('reading a translated record', () {
    test('blank strings read as missing, so the original is kept', () {
      const fields = TranslatedFields({'title': '  ', 'name': 'Menu'});
      expect(fields.text('title'), isNull);
      expect(fields.text('name'), 'Menu');
      expect(fields.text('nothing'), isNull);
    });

    test('a list of the wrong length is refused', () {
      const fields = TranslatedFields({
        'steps': ['Fry', 'Serve'],
      });
      expect(fields.listOfLength('steps', 2), ['Fry', 'Serve']);
      expect(fields.listOfLength('steps', 3), isNull);
      expect(fields.listOfLength('missing', 2), isNull);
    });

    test('non-strings in a list are dropped', () {
      const fields = TranslatedFields({
        'items': ['Milk', 7, null, 'Eggs'],
      });
      expect(fields.list('items'), ['Milk', 'Eggs']);
    });
  });
}
