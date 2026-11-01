import 'dart:math';

import 'package:easy_plate/features/price_book/domain/entities/price_record_entity.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_unit.dart';
import 'package:easy_plate/features/price_book/domain/price_estimator.dart';
import 'package:easy_plate/features/price_book/domain/product_name.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The score as first written: both names split on every call. The
/// estimator now splits the query once and each stored name once; it must
/// still pick exactly what this would.
double _reference(String q, String c) {
  if (q.isEmpty || c.isEmpty) return 0;
  if (q == c) return 1;
  final qt = productTokens(q).toSet();
  final ct = productTokens(c).toSet();
  if (qt.isEmpty || ct.isEmpty) return 0;
  final (short, long) = qt.length <= ct.length ? (qt, ct) : (ct, qt);
  if (!long.containsAll(short)) return 0;
  return short.length / long.length;
}

PriceRecordEntity? _referenceBest(String item, List<PriceRecordEntity> rs) {
  PriceRecordEntity? best;
  var bestScore = 0.0;
  final query = normalizeProductName(item);
  for (final r in rs) {
    final score = _reference(query, r.normalizedName);
    if (score < 0.3) continue;
    if (best == null ||
        score > bestScore ||
        (score == bestScore && r.purchasedAt.isAfter(best.purchasedAt))) {
      best = r;
      bestScore = score;
    }
  }
  return best;
}

void main() {
  const words = [
    'חלב', 'לחם', 'גבינה', 'עגבניות', 'מלפפון', 'ביצים', 'שמן', 'זית', //
    'קמח', 'סוכר', 'אורז', 'פסטה', 'עוף', 'בשר', 'טחון', 'יוגורט', 'milk',
    'bread', 'olive', 'oil',
  ];
  final random = Random(7);
  String name() => [
    for (var i = 0, n = 1 + random.nextInt(3); i < n; i++)
      words[random.nextInt(words.length)],
    if (random.nextBool()) '${random.nextInt(5)}%',
  ].join(' ');

  // A heavy book: a few hundred products, bought again and again.
  final products = [for (var i = 0; i < 300; i++) name()];
  final records = [
    for (var i = 0; i < 2000; i++)
      () {
        final n = products[random.nextInt(products.length)];
        return PriceRecordEntity(
          id: '$i',
          name: n,
          normalizedName: normalizeProductName(n),
          unitPrice: 1 + random.nextInt(40).toDouble(),
          unit: PriceUnit.unit,
          quantity: 1,
          currency: 'ILS',
          store: null,
          purchasedAt: DateTime(2026, 1, 1).add(Duration(hours: i)),
          receiptId: 'r${i ~/ 30}',
        );
      }(),
  ];
  final lines = [for (var i = 0; i < 80; i++) name()];

  test('the faster match picks exactly the record the original did', () {
    for (final line in lines) {
      expect(
        PriceEstimator.bestPersonalMatch(line, records)?.id,
        _referenceBest(line, records)?.id,
        reason: line,
      );
    }
  });

  test('a list priced against a heavy book (timing printed, not asserted)', () {
    final watch = Stopwatch()..start();
    for (final line in lines) {
      PriceEstimator.estimate(line, records);
    }
    final optimized = watch.elapsedMicroseconds;
    watch.reset();
    for (final line in lines) {
      _referenceBest(line, records);
    }
    final reference = watch.elapsedMicroseconds;
    debugPrint(
      '${lines.length} lines × ${records.length} records: '
      '${optimized ~/ 1000} ms now, ${reference ~/ 1000} ms as first written',
    );
  });
}
