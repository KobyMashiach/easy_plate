import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/whats_new_release.dart';

/// Reads `whats_new_releases`: one document per build, written by the web
/// console through the adminPanel function (the rules allow a signed-in
/// account to read, nobody to write).
abstract class WhatsNewRepository {
  /// Every release with `fromBuild < versionCode <= toBuild`, published or
  /// not (the rule filters; this keeps the query to one range so it needs
  /// no composite index). Null when the read failed — offline, rules — so
  /// the caller can try again next launch instead of stamping the pointer
  /// past releases it never saw.
  Future<List<WhatsNewRelease>?> getReleasesBetween(int fromBuild, int toBuild);

  /// The newest published release at or below [build], for showing the
  /// book again from the support screen.
  Future<WhatsNewRelease?> latestPublished(int build);
}

class FirestoreWhatsNewRepository implements WhatsNewRepository {
  static const collection = 'whats_new_releases';

  final FirebaseFirestore _firestore;

  FirestoreWhatsNewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<WhatsNewRelease>?> getReleasesBetween(
    int fromBuild,
    int toBuild,
  ) async {
    if (toBuild <= fromBuild) return const [];
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('versionCode', isGreaterThan: fromBuild)
          .where('versionCode', isLessThanOrEqualTo: toBuild)
          .orderBy('versionCode')
          .get();
      return [
        for (final doc in snapshot.docs)
          WhatsNewRelease.fromMap(doc.data(), id: doc.id),
      ];
    } catch (e) {
      debugPrint('What\'s new read failed: $e');
      return null;
    }
  }

  @override
  Future<WhatsNewRelease?> latestPublished(int build) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('versionCode', isLessThanOrEqualTo: build)
          .orderBy('versionCode', descending: true)
          .limit(10)
          .get();
      for (final doc in snapshot.docs) {
        final release = WhatsNewRelease.fromMap(doc.data(), id: doc.id);
        if (release.isPublished && release.features.isNotEmpty) return release;
      }
      return null;
    } catch (e) {
      debugPrint('What\'s new read failed: $e');
      return null;
    }
  }
}
