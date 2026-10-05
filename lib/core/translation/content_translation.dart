import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/app_enums.dart';
import '../utils/i18n/strings.g.dart';

/// One record handed to the translator: what it is, and the text it carries.
/// Ids, numbers, units and image paths stay out — they mean the same thing in
/// every language and are not worth a token.
class TranslatableItem {
  /// The record's [contentVersion]: what the translation will be filed under,
  /// so it can be recognised as still current on the next switch.
  final int version;

  /// `recipe`, `book`, `mealPlan` or `groceryList`, as the function names them.
  final String type;
  final String id;
  final Map<String, Object?> fields;

  const TranslatableItem({
    required this.type,
    required this.id,
    required this.fields,
    this.version = 0,
  });

  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'version': version,
    'fields': fields,
  };
}

/// Which text fields each kind of record carries, in the order the server
/// reads them. Both sides walk this order to fingerprint a record, so the
/// two hashes agree.
const contentShapes = <String, Map<String, bool>>{
  // field name -> is it a list of strings
  'recipe': {'title': false, 'ingredients': true, 'steps': true},
  'book': {'title': false},
  'mealPlan': {'name': false, 'meals': true, 'items': true},
  'groceryList': {'name': false, 'items': true},
};

/// A record's source text boiled to one hash, matching `fingerprint` in
/// functions/translateContent.js. A stored translation carries the hash of
/// the text it was made from; when the record is edited the hash moves and
/// the old translation is ignored, so nothing has to be cleaned up on save.
String fingerprintOf(TranslatableItem item) {
  final shape = contentShapes[item.type] ?? const {};
  final parts = <String>[];
  for (final entry in shape.entries) {
    final value = item.fields[entry.key];
    if (entry.value) {
      for (final line in value is List ? value : const []) {
        parts.add(line is String ? line : '');
      }
    } else {
      parts.add(value is String ? value : '');
    }
  }
  return sha256.convert(utf8.encode(parts.join('\n'))).toString();
}

/// The text of one record in one language, as it comes back from the
/// function or out of the account's own language folder.
class TranslatedFields {
  final Map<String, Object?> fields;

  const TranslatedFields(this.fields);

  /// Which version of the record this was made from. A variant written
  /// before versions existed reads as -1, which matches nothing and is made
  /// again once.
  int get version {
    final value = fields['version'];
    return value is num ? value.toInt() : -1;
  }

  String? text(String field) {
    final value = fields[field];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// A list field, with anything that is not a string dropped. Returns null
  /// when the field is absent, so a caller can keep what it had.
  List<String>? list(String field) {
    final value = fields[field];
    if (value is! List) return null;
    return [
      for (final v in value)
        if (v is String) v,
    ];
  }

  /// A list is only usable in place of the original when it came back with
  /// the same number of entries — a recipe with three steps must not end up
  /// with two.
  List<String>? listOfLength(String field, int length) {
    final value = list(field);
    return value != null && value.length == length ? value : null;
  }
}

/// The language codes the app and the function agree on.
extension AppLanguageCode on AppLanguage {
  String get code => switch (this) {
    AppLanguage.hebrew => 'he',
    AppLanguage.english => 'en',
    AppLanguage.arabic => 'ar',
    AppLanguage.french => 'fr',
    AppLanguage.russian => 'ru',
  };

  static AppLanguage? fromCode(String? code) => switch (code) {
    'he' => AppLanguage.hebrew,
    'en' => AppLanguage.english,
    'ar' => AppLanguage.arabic,
    'fr' => AppLanguage.french,
    'ru' => AppLanguage.russian,
    _ => null,
  };
}

/// What a record's text is written in when nothing was recorded — every
/// record saved before this feature existed. The script is enough to tell
/// the app's languages apart except French from English, which share the
/// Latin alphabet; those fall back to [fallback].
AppLanguage guessLanguage(String text, {required AppLanguage fallback}) {
  var hebrew = 0;
  var arabic = 0;
  var cyrillic = 0;
  var latin = 0;
  for (final rune in text.runes) {
    if (rune >= 0x0590 && rune <= 0x05FF) {
      hebrew++;
    } else if (rune >= 0x0600 && rune <= 0x06FF) {
      arabic++;
    } else if (rune >= 0x0400 && rune <= 0x04FF) {
      cyrillic++;
    } else if ((rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A)) {
      latin++;
    }
  }
  final best = [
    hebrew,
    arabic,
    cyrillic,
    latin,
  ].reduce((a, b) => a > b ? a : b);
  if (best == 0) return fallback;
  if (best == hebrew) return AppLanguage.hebrew;
  if (best == arabic) return AppLanguage.arabic;
  if (best == cyrillic) return AppLanguage.russian;
  // Latin: English and French are indistinguishable by script.
  return fallback == AppLanguage.french
      ? AppLanguage.french
      : AppLanguage.english;
}

/// The language the app is being read in right now — what a record the user
/// just wrote is in, unless it says otherwise.
AppLanguage currentContentLanguage() => switch (LocaleSettings.currentLocale) {
  AppLocale.he => AppLanguage.hebrew,
  AppLocale.en => AppLanguage.english,
  AppLocale.ar => AppLanguage.arabic,
  AppLocale.fr => AppLanguage.french,
  AppLocale.ru => AppLanguage.russian,
};
