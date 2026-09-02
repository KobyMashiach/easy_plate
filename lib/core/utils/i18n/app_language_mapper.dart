import '../../constants/app_enums.dart';
import 'strings.g.dart';

/// Bridges the persisted [AppLanguage] with slang's generated [AppLocale].
/// Keeping the mapping here means the domain layer never depends on generated
/// localisation code.
extension AppLanguageLocale on AppLanguage {
  AppLocale get locale => switch (this) {
        AppLanguage.hebrew => AppLocale.he,
        AppLanguage.english => AppLocale.en,
        AppLanguage.arabic => AppLocale.ar,
        AppLanguage.french => AppLocale.fr,
        AppLanguage.russian => AppLocale.ru,
      };

  String get label => switch (this) {
        AppLanguage.hebrew => t.language.hebrew,
        AppLanguage.english => t.language.english,
        AppLanguage.arabic => t.language.arabic,
        AppLanguage.french => t.language.french,
        AppLanguage.russian => t.language.russian,
      };
}
