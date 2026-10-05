import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../errors/app_exception.dart';
import '../hive/user_scope.dart';
import '../network/ai_auth_header.dart';
import '../network/http_calls.dart';
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
    if (uid == null) return null;
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
    for (var i = 0; i < items.length; i += batchSize) {
      final slice = items.skip(i).take(batchSize).toList();
      final response = await _calls.post(
        '',
        data: {
          'targetLang': lang,
          'items': [for (final item in slice) item.toJson()],
        },
      );
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
