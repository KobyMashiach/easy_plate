import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../hive/user_scope.dart';
import 'content_translation.dart';

/// The account's translations, kept on the device as well as in Firebase.
///
/// Switching to a language the account has already been in is then a Hive
/// read — no network, no loading card. Firebase stays the authority: a new
/// device, or this one after a reinstall, fills this box from there the first
/// time and never asks the model for what Firebase already had.
///
/// Scoped to the account like every other box (see [UserScope.scopedBoxes]),
/// so one account never reads another's translations. Stored as JSON strings
/// to need no adapter; the values are small maps of strings.
class ContentVariantsLocalStore {
  static const boxName = 'contentVariantsBox';

  static String keyOf(String lang, String type, String id) => '$lang/$type/$id';

  /// Everything held for [lang], keyed `type/id` like the remote side.
  Future<Map<String, TranslatedFields>> read(String lang) async {
    try {
      final box = await UserScope().open<String>(boxName);
      final prefix = '$lang/';
      final out = <String, TranslatedFields>{};
      for (final key in box.keys) {
        if (key is! String || !key.startsWith(prefix)) continue;
        final raw = box.get(key);
        if (raw == null) continue;
        final Object? decoded;
        try {
          decoded = jsonDecode(raw);
        } on FormatException catch (e) {
          // One damaged entry costs that record, not the whole language.
          debugPrint('Local translation $key unreadable: $e');
          continue;
        }
        if (decoded is Map) {
          out[key.substring(prefix.length)] = TranslatedFields(
            Map<String, Object?>.from(decoded),
          );
        }
      }
      return out;
    } catch (e) {
      // An unreadable box only means the network is asked; never fatal.
      debugPrint('Reading local $lang translations failed: $e');
      return {};
    }
  }

  /// Keeps [variants] (keyed `type/id`) for [lang].
  Future<void> write(
    String lang,
    Map<String, TranslatedFields> variants,
  ) async {
    if (variants.isEmpty) return;
    try {
      final box = await UserScope().open<String>(boxName);
      await box.putAll({
        for (final entry in variants.entries)
          '$lang/${entry.key}': jsonEncode(_plain(entry.value.fields)),
      });
    } catch (e) {
      debugPrint('Saving local $lang translations failed: $e');
    }
  }

  /// Every record held in any language, as `type/id` — what the switch
  /// compares against the account's records to find translations of ones
  /// that were deleted.
  Future<Set<String>> held() async {
    try {
      final box = await UserScope().open<String>(boxName);
      return {
        for (final key in box.keys) ?_recordOf(key),
      };
    } catch (e) {
      debugPrint('Listing local translations failed: $e');
      return {};
    }
  }

  /// Drops every language's copy of the records in [typeIds] (`type/id`).
  Future<void> forget(Iterable<String> typeIds) async {
    final doomed = typeIds.toSet();
    if (doomed.isEmpty) return;
    try {
      final box = await UserScope().open<String>(boxName);
      await box.deleteAll([
        for (final key in box.keys)
          if (_recordOf(key) case final record? when doomed.contains(record))
            key,
      ]);
    } catch (e) {
      // Left behind, it is only read and never applied: no record has the id.
      debugPrint('Dropping local translations failed: $e');
    }
  }

  /// The `type/id` part of a `lang/type/id` key.
  static String? _recordOf(Object? key) {
    if (key is! String) return null;
    final cut = key.indexOf('/');
    return cut > 0 ? key.substring(cut + 1) : null;
  }

  /// Firestore hands back timestamps and other types jsonEncode refuses;
  /// only the strings, lists of strings and the version are worth keeping.
  static Map<String, Object?> _plain(Map<String, Object?> fields) => {
    for (final entry in fields.entries)
      if (entry.value is String || entry.value is num)
        entry.key: entry.value
      else if (entry.value is List)
        entry.key: [
          for (final v in entry.value! as List)
            if (v is String) v,
        ],
  };
}
