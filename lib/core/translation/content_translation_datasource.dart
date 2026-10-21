import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../errors/app_exception.dart';
import '../hive/user_scope.dart';
import '../network/ai_auth_header.dart';
import '../network/http_calls.dart';
import '../services/account_deletion_guard.dart';
import 'content_translation.dart';

/// Where an account's translated content lives and how fresh text is asked
/// for. Two sources, cheapest first:
///
///   users/{uid}/i18n/{lang}/{type}/{id}  what this account already has
///   the translateContent function        the model, for what is missing
///
/// A record's own language is never stored here — the record itself is the
/// original — so going back to it costs nothing.
abstract class ContentTranslationDataSource {
  /// What the account already holds in [lang], keyed by `type/id`.
  Future<Map<String, TranslatedFields>> readVariants(
    String lang,
    Iterable<String> types,
  );

  /// Translates [items] into [lang]. The function writes them into the
  /// account's folder on the way back, so this is paid for once.
  Future<Map<String, TranslatedFields>> translate(
    String lang,
    List<TranslatableItem> items,
  );

  /// Files a record's own text under its own language, so switching back to
  /// it later is a download rather than a translation. The model is not
  /// involved: this text is the original.
  Future<void> writeSource(String lang, TranslatableItem item);

  /// Forgets every language's copy of one record — after an edit, the old
  /// translations describe text that no longer exists.
  Future<void> forget(String type, String id, Iterable<String> langs);
}

class ContentTranslationRemoteDataSource
    implements ContentTranslationDataSource {
  static const usersCollection = 'users';
  static const folder = 'i18n';

  /// Records per call. The function caps at 2000; this leaves room and keeps
  /// one failure from costing a whole library.
  static const batchSize = 120;

  /// The function refuses a call with more than 3000 distinct lines, or one
  /// record with more than 200 (functions/translateContent.js). Batches are
  /// cut by line count under those caps, with room to spare, so a library of
  /// long recipes never has a whole call refused.
  static const maxLinesPerCall = 2500;
  static const maxLinesPerItem = 200;

  /// The lines one record carries, counted the way the server counts them:
  /// one per text field, one per list entry.
  @visibleForTesting
  static int linesIn(TranslatableItem item) {
    var n = 0;
    for (final value in item.fields.values) {
      if (value is String) {
        n += 1;
      } else if (value is List) {
        n += value.length;
      }
    }
    return n;
  }

  /// What the day's budget counts (functions/translateContent.js
  /// `unitsOf`): one unit per started [unitChars] characters of a trimmed
  /// line, so an ingredient is one and a 2000-character step is seven. The
  /// `quota` object of a refusal — `used`, `limit`, `requested` — is in
  /// these, so a call cut to "what is left" has to count the same way:
  /// counted in lines, a batch of long steps was sent again and refused
  /// again until nothing fitted.
  static const unitChars = 300;

  @visibleForTesting
  static int unitsOf(String text) {
    final length = text.trim().length;
    return length <= unitChars ? 1 : (length / unitChars).ceil();
  }

  /// The budget units one record costs, over the lines [linesIn] counts.
  /// An upper bound: the server skips lines its cache already holds, and
  /// counts a line repeated across records once; sending less than what
  /// is left is the safe side.
  @visibleForTesting
  static int unitsIn(TranslatableItem item) {
    var n = 0;
    for (final value in item.fields.values) {
      if (value is String) {
        n += unitsOf(value);
      } else if (value is List) {
        for (final line in value) {
          n += line is String ? unitsOf(line) : 1;
        }
      }
    }
    return n;
  }

  /// The calls a list of records is sent in: at most [batchSize] records and
  /// [maxLinesPerCall] lines each. A record over [maxLinesPerItem] is left
  /// out — the server would refuse the whole call for it — and stays in its
  /// source language.
  @visibleForTesting
  static List<List<TranslatableItem>> batchesOf(List<TranslatableItem> items) {
    final out = <List<TranslatableItem>>[];
    var current = <TranslatableItem>[];
    var lines = 0;
    for (final item in items) {
      final n = linesIn(item);
      if (n > maxLinesPerItem) {
        debugPrint('Not translating ${item.type}/${item.id}: $n lines');
        continue;
      }
      if (current.isNotEmpty &&
          (current.length >= batchSize || lines + n > maxLinesPerCall)) {
        out.add(current);
        current = <TranslatableItem>[];
        lines = 0;
      }
      current.add(item);
      lines += n;
    }
    if (current.isNotEmpty) out.add(current);
    return out;
  }

  /// The leading part of [slice] that fits in what a `quota` refusal
  /// ([body]) says is left of the day, or null when nothing smaller can be
  /// sent: the refusal was not about this call's size, nothing is left, or
  /// even the first record does not fit.
  @visibleForTesting
  static List<TranslatableItem>? fitting(
    List<TranslatableItem> slice,
    Object? body,
  ) {
    final quota = HttpCalls.quotaOf(body);
    if (quota == null || quota.requested == null) return null;
    final left = quota.limit - quota.used;
    final fits = <TranslatableItem>[];
    var units = 0;
    for (final item in slice) {
      final n = unitsIn(item);
      if (units + n > left) break;
      fits.add(item);
      units += n;
    }
    // Strictly smaller, or a refusal the client counts differently would
    // send the same call forever.
    if (fits.isEmpty || fits.length >= slice.length) return null;
    return fits;
  }

  final FirebaseFirestore _firestore;
  late final HttpCalls _calls = HttpCalls(
    baseUrl: ApiConfig.translateContentUrl,
    headerProvider: aiProxyAuthHeader,
  );

  ContentTranslationRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _typeRef(
    String lang,
    String type,
  ) {
    final uid = UserScope().uid;
    if (uid == null || AccountDeletionGuard.blocks(uid)) return null;
    return _firestore
        .collection(usersCollection)
        .doc(uid)
        .collection(folder)
        .doc(lang)
        .collection(type);
  }

  @override
  Future<Map<String, TranslatedFields>> readVariants(
    String lang,
    Iterable<String> types,
  ) async {
    final out = <String, TranslatedFields>{};
    for (final type in types) {
      final ref = _typeRef(lang, type);
      if (ref == null) continue;
      try {
        final snapshot = await ref.get();
        for (final doc in snapshot.docs) {
          out['$type/${doc.id}'] = TranslatedFields(doc.data());
        }
      } catch (e) {
        // A missing folder is the normal first-switch case; anything else
        // only means the model is asked for more than it had to be.
        debugPrint('Reading $type variants in $lang failed: $e');
      }
    }
    return out;
  }

  @override
  Future<Map<String, TranslatedFields>> translate(
    String lang,
    List<TranslatableItem> items,
  ) async {
    if (!ApiConfig.usesProxy) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'Translation needs the Cloud Functions deploy (AI_BASE_URL)',
      );
    }
    final out = <String, TranslatedFields>{};
    final queue = batchesOf(items);
    for (var i = 0; i < queue.length; i++) {
      final slice = queue[i];
      final Response? response;
      try {
        response = await _calls.post(
          '',
          data: {
            'targetLang': lang,
            'items': [for (final item in slice) item.toJson()],
          },
        );
      } on AppException catch (e) {
        if (e.type != AppErrorType.quotaExceeded) rethrow;
        // The day's allowance: a call larger than what is left is refused
        // whole (the refusal says `requested`), though a smaller one still
        // fits. Send what fits, then stop — nothing is left after it.
        final fits = fitting(slice, e.data);
        if (fits != null) {
          queue
            ..removeRange(i + 1, queue.length)
            ..add(fits);
          continue;
        }
        // Spent: what earlier calls brought back is kept (the server filed
        // it too), the rest stays in its own language until tomorrow.
        if (out.isNotEmpty) return out;
        rethrow;
      }
      final data = response?.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException(AppErrorType.parsingFailed);
      }
      final translations = data['translations'];
      if (translations is! Map) continue;
      for (final item in slice) {
        final record = translations[item.id];
        if (record is Map && record['fields'] is Map) {
          out['${item.type}/${item.id}'] = TranslatedFields(
            Map<String, Object?>.from(record['fields'] as Map),
          );
        }
      }
    }
    return out;
  }

  @override
  Future<void> writeSource(String lang, TranslatableItem item) async {
    final ref = _typeRef(lang, item.type);
    if (ref == null) return;
    try {
      await ref.doc(item.id).set({
        ...item.fields,
        'version': item.version,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Only means this record is translated again if it ever comes back.
      debugPrint(
        'Filing the $lang original of ${item.type}/${item.id} failed: $e',
      );
    }
  }

  @override
  Future<void> forget(String type, String id, Iterable<String> langs) async {
    for (final lang in langs) {
      final ref = _typeRef(lang, type);
      if (ref == null) continue;
      try {
        await ref.doc(id).delete();
      } catch (e) {
        debugPrint('Dropping the $lang copy of $type/$id failed: $e');
      }
    }
  }
}
