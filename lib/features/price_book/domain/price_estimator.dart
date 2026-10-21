import 'entities/price_record_entity.dart';
import 'entities/price_unit.dart';
import 'entities/product_pricing_entity.dart';
import 'product_name.dart';

/// Where an estimate came from — the label says "your receipt" or "what
/// others paid", and "no data" is an answer too.
enum PriceBasis { personal, community, none }

class PriceEstimate {
  final double? unitPrice;

  /// What [unitPrice] is per. Community figures from the legacy per-name
  /// document are per package.
  final PriceUnit unit;
  final PriceBasis basis;

  /// The record or aggregate behind it, for the label.
  final String? matchedName;
  final int sampleCount;

  /// What [unitPrice] is in. Community figures are shekels.
  final String currency;

  const PriceEstimate({
    required this.unitPrice,
    required this.basis,
    this.unit = PriceUnit.unit,
    this.matchedName,
    this.sampleCount = 0,
    this.currency = 'ILS',
  });

  static const none = PriceEstimate(unitPrice: null, basis: PriceBasis.none);

  bool get hasPrice => unitPrice != null;
}

/// Pure: the personal price book is a list, the community answer is passed
/// in (already fetched, or null) so this never touches the network.
abstract class PriceEstimator {
  /// The currency most of [records] are in; shekels on a tie or an empty
  /// book. One estimate, one currency: a record in another currency is left
  /// out rather than added up as if it were shekels.
  ///
  /// Open decision (Koby): a book that genuinely spans currencies — convert
  /// at a rate, or show one total per currency. Until then the minority is
  /// ignored, not converted.
  static String dominantCurrency(Iterable<PriceRecordEntity> records) {
    final counts = <String, int>{};
    for (final r in records) {
      counts[r.currency] = (counts[r.currency] ?? 0) + 1;
    }
    var best = 'ILS';
    var bestCount = counts['ILS'] ?? 0;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        best = e.key;
        bestCount = e.value;
      }
    }
    return best;
  }

  /// The best personal match: highest name score, most recent among ties.
  /// Below [minScore] a match is a coincidence of words, not a product.
  static PriceRecordEntity? bestPersonalMatch(
    String itemName,
    List<PriceRecordEntity> records, {
    double minScore = 0.3,
  }) {
    PriceRecordEntity? best;
    var bestScore = 0.0;
    final query = normalizeProductName(itemName);
    for (final record in records) {
      final score = productMatchScoreNormalized(query, record.normalizedName);
      if (score < minScore) continue;
      if (best == null ||
          score > bestScore ||
          (score == bestScore &&
              record.purchasedAt.isAfter(best.purchasedAt))) {
        best = record;
        bestScore = score;
      }
    }
    return best;
  }

  /// Every record of the matched product — same name, same unit.
  static List<PriceRecordEntity> productRecords(
    PriceRecordEntity match,
    List<PriceRecordEntity> records,
  ) => records
      .where(
        (r) => r.normalizedName == match.normalizedName && r.unit == match.unit,
      )
      .toList();

  static PriceEstimate estimate(
    String itemName,
    List<PriceRecordEntity> records, {
    CommunityPriceEntity? community,
    Map<String, ProductPricingEntity> pricing = const {},
  }) {
    final currency = dominantCurrency(records);
    final sameCurrency = records.where((r) => r.currency == currency).toList();
    final personal = bestPersonalMatch(itemName, sameCurrency);
    if (personal != null) {
      final group = productRecords(personal, sameCurrency);
      final policy =
          pricing[ProductPricingEntity.keyFor(
            personal.normalizedName,
            personal.unit,
          )];
      // A policy that matches nothing (its store gone, its receipts
      // deleted) falls back to the latest price rather than to nothing.
      final chosen = policy?.resolve(group) ?? personal.unitPrice;
      return PriceEstimate(
        unitPrice: chosen,
        unit: personal.unit,
        basis: PriceBasis.personal,
        matchedName: personal.name,
        sampleCount: group.length,
        currency: personal.currency,
      );
    }
    if (community != null) {
      return PriceEstimate(
        unitPrice: community.median,
        unit: community.unit ?? PriceUnit.unit,
        basis: PriceBasis.community,
        matchedName: community.normalizedName,
        sampleCount: community.count,
      );
    }
    return PriceEstimate.none;
  }
}

/// A whole grocery list priced: what is known, what is not, and the sum of
/// what is. Always an estimate — the screen says so.
class GroceryCostSummary {
  final double knownTotal;
  final int pricedItems;
  final int unpricedItems;

  /// What [knownTotal] is in: the currency most priced lines share.
  final String currency;

  const GroceryCostSummary({
    required this.knownTotal,
    required this.pricedItems,
    required this.unpricedItems,
    this.currency = 'ILS',
  });

  bool get hasAny => pricedItems > 0;

  /// Sums the lines priced in the majority currency (shekels on a tie); a
  /// line priced in another currency counts as unpriced rather than being
  /// added to a total in the wrong money. See
  /// [PriceEstimator.dominantCurrency] for the open decision.
  static GroceryCostSummary of(
    Iterable<({PriceEstimate estimate, double multiplier})> lines,
  ) {
    final known = [
      for (final line in lines)
        if (line.estimate.unitPrice != null) line,
    ];
    final counts = <String, int>{};
    for (final line in known) {
      final c = line.estimate.currency;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    var currency = 'ILS';
    var bestCount = counts['ILS'] ?? 0;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        currency = e.key;
        bestCount = e.value;
      }
    }
    var total = 0.0;
    var priced = 0;
    for (final line in known) {
      if (line.estimate.currency != currency) continue;
      priced++;
      total += line.estimate.unitPrice! * line.multiplier;
    }
    return GroceryCostSummary(
      knownTotal: total,
      pricedItems: priced,
      unpricedItems: lines.length - priced,
      currency: currency,
    );
  }
}
