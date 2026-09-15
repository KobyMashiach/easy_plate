import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';
import '../../domain/entities/price_record_entity.dart';

/// Reads `price_stats/{hash}` (client-readable, server-written) and posts
/// shared prices to the `priceStats` function that writes it.
class CommunityPricesRemoteDataSource {
  static const collection = 'price_stats';

  final FirebaseFirestore _firestore;
  late final HttpCalls _calls = HttpCalls(
    baseUrl: ApiConfig.priceStatsUrl,
    headerProvider: aiProxyAuthHeader,
  );

  CommunityPricesRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Same key as functions/priceStats.js: sha256 of the normalised name.
  static String keyFor(String normalizedName) =>
      sha256.convert(utf8.encode(normalizedName)).toString();

  Future<CommunityPriceEntity?> lookup(String normalizedName) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(keyFor(normalizedName))
          .get();
      final data = doc.data();
      if (data == null) return null;
      final count = (data['count'] as num?)?.toInt() ?? 0;
      final median = (data['median'] as num?)?.toDouble();
      if (count == 0 || median == null) return null;
      return CommunityPriceEntity(
        normalizedName: normalizedName,
        median: median,
        average: (data['avg'] as num?)?.toDouble() ?? median,
        count: count,
      );
    } catch (e) {
      debugPrint('Community price lookup failed: $e');
      return null;
    }
  }

  Future<void> share(List<PriceRecordEntity> records) async {
    if (records.isEmpty) return;
    await _calls.post(
      '',
      data: {
        'records': [
          for (final r in records) {'name': r.name, 'price': r.unitPrice},
        ],
      },
    );
  }
}
