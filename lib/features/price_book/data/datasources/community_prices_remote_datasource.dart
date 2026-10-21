import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/price_unit.dart';

/// Reads `price_stats/{hash}` (client-readable, server-written) and posts
/// shared prices to the `priceStats` function that writes it.
class CommunityPricesRemoteDataSource {
  static const collection = 'price_stats';

  /// The server's default: a record without a currency is shekels.
  static const defaultCurrency = 'ILS';

  final FirebaseFirestore? _firestore;

  /// Tests only: reads one `price_stats` document's data by id.
  final Future<Map<String, dynamic>?> Function(String docId)? _readDoc;

  late final HttpCalls _calls = HttpCalls(
    baseUrl: ApiConfig.priceStatsUrl,
    headerProvider: aiProxyAuthHeader,
  );

  CommunityPricesRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _readDoc = null;

  @visibleForTesting
  CommunityPricesRemoteDataSource.withReader(
    Future<Map<String, dynamic>?> Function(String docId) readDoc,
  ) : _firestore = null,
      _readDoc = readDoc;

  /// The unit as functions/priceStats.js spells it ("unit" | "kg" |
  /// "liter"), or null for anything it does not know.
  static String? unitWire(PriceUnit? unit) => switch (unit) {
    PriceUnit.unit => 'unit',
    PriceUnit.kg => 'kg',
    PriceUnit.liter => 'liter',
    null => null,
  };

  /// Same id as `keyFor` in functions/priceStats.js. Without a unit and in
  /// shekels: sha256 of the normalised name (the legacy document). With a
  /// unit, or in another currency: sha256 of "name|unit|CURRENCY".
  static String keyFor(
    String normalizedName, {
    String? unit,
    String currency = defaultCurrency,
  }) {
    final upper = currency.toUpperCase();
    final legacy = (unit == null || unit.isEmpty) && upper == defaultCurrency;
    final source = legacy
        ? normalizedName
        : '$normalizedName|${unit ?? ''}|$upper';
    return sha256.convert(utf8.encode(source)).toString();
  }

  Future<Map<String, dynamic>?> _read(String docId) async {
    if (_readDoc case final read?) return read(docId);
    final doc = await _firestore!.collection(collection).doc(docId).get();
    return doc.data();
  }

  /// The figure for a product priced per [unit] in shekels: the keyed
  /// document first, then the legacy per-name one (which mixes units, and
  /// is what clients older than the unit wrote to).
  Future<CommunityPriceEntity?> lookup(
    String normalizedName, {
    PriceUnit? unit,
  }) async {
    try {
      final wire = unitWire(unit);
      if (wire != null) {
        final keyed = _entity(
          normalizedName,
          await _read(keyFor(normalizedName, unit: wire)),
          unit: unit,
        );
        if (keyed != null) return keyed;
      }
      return _entity(normalizedName, await _read(keyFor(normalizedName)));
    } catch (e) {
      // Rethrown: "no data" is an answer, a failed read is not, and the
      // caller must not keep it as one.
      debugPrint('Community price lookup failed: $e');
      rethrow;
    }
  }

  static CommunityPriceEntity? _entity(
    String normalizedName,
    Map<String, dynamic>? data, {
    PriceUnit? unit,
  }) {
    if (data == null) return null;
    final count = (data['count'] as num?)?.toInt() ?? 0;
    final median = (data['median'] as num?)?.toDouble();
    if (count == 0 || median == null) return null;
    return CommunityPriceEntity(
      normalizedName: normalizedName,
      median: median,
      average: (data['avg'] as num?)?.toDouble() ?? median,
      count: count,
      unit: unit,
    );
  }

  /// One record as the function reads it: the unit when known, and the
  /// currency when it is a three-letter code (anything else would make the
  /// server refuse the record, so it is left to the shekel default).
  static Map<String, Object> wireRecord(PriceRecordEntity r) {
    final unit = unitWire(r.unit);
    final currency = r.currency.trim().toUpperCase();
    return {
      'name': r.name,
      'price': r.unitPrice,
      'unit': ?unit,
      if (RegExp(r'^[A-Z]{3}$').hasMatch(currency)) 'currency': currency,
    };
  }

  Future<void> share(List<PriceRecordEntity> records) async {
    if (records.isEmpty) return;
    await _calls.post(
      '',
      data: {
        'records': [for (final r in records) wireRecord(r)],
      },
    );
  }
}
