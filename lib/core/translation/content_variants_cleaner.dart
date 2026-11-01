import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/app_enums.dart';
import 'content_translation.dart';
import 'content_translation_datasource.dart';
import 'content_variants_local_store.dart';

/// Removes the translations of records that no longer exist.
///
/// Without it every deleted recipe, book, plan and list kept its copies in
/// `users/{uid}/i18n/{lang}/…` and in [ContentVariantsLocalStore], and each
/// language switch read (and paid for) all of them again.
///
/// Never awaited by a delete: a delete must not fail, or wait, because a
/// translation could not be dropped. What is left behind is harmless — no
/// record carries the id — and the next switch prunes it.
class ContentVariantsCleaner {
  ContentVariantsCleaner({
    ContentTranslationDataSource? remote,
    ContentVariantsLocalStore? local,
  }) : _remote = remote,
       _local = local ?? ContentVariantsLocalStore();

  // Built on first use: a repository is constructed before Firebase is
  // touched in some paths (tests, the headless voice engine).
  ContentTranslationDataSource? _remote;
  ContentTranslationDataSource get remote =>
      _remote ??= ContentTranslationRemoteDataSource();
  final ContentVariantsLocalStore _local;

  /// Every language a copy can be filed under: the record's own language is
  /// filed too (see [ContentTranslationDataSource.writeSource]).
  static final langs = [for (final l in AppLanguage.values) l.code];

  /// Fire-and-forget: drops [type]/[id] in every language, here and in
  /// Firebase.
  void forget(String type, String id) => unawaited(forgetAll(['$type/$id']));

  /// Drops each `type/id` in [typeIds]. Completes when done; never throws.
  Future<void> forgetAll(Iterable<String> typeIds) async {
    final keys = typeIds.toSet();
    if (keys.isEmpty) return;
    try {
      await Future.wait([
        _local.forget(keys),
        for (final key in keys)
          if (key.indexOf('/') case final cut when cut > 0)
            remote.forget(key.substring(0, cut), key.substring(cut + 1), langs),
      ]);
    } catch (e) {
      debugPrint('Dropping translations of ${keys.length} records failed: $e');
    }
  }
}
