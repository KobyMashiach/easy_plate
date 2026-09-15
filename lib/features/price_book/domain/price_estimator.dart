import 'entities/price_record_entity.dart';
import 'entities/price_unit.dart';
import 'entities/product_pricing_entity.dart';
import 'product_name.dart';

/// Where an estimate came from — the label says "your receipt" or "what
/// others paid", and "no data" is an answer too.
enum PriceBasis { personal, community, none }

class PriceEstimate {
  final double? unitPrice;

  /// What [unitPrice] is per. Community figures are per package.
  final PriceUnit unit;
  final PriceBasis basis;

  /// The record or aggregate behind it, for the label.
  final String? matchedName;
  final int sampleCount;

  const PriceEstimate({
    required this.unitPrice,
    required this.basis,
    this.unit = PriceUnit.unit,
    this.matchedName,
    this.sampleCount = 0,
  });

  static const none = PriceEstimate(unitPrice: null, basis: PriceBasis.none);

  bool get hasPrice => unitPrice != null;
}

/// Pure: the personal price book is a list, the community answer is passed
/// in (already fetched, or null) so this never touches the network.
abstract class PriceEstimator {
  /// The best personal match: highest name score, most recent among ties.
  /// Below [minScore] a match is a coincidence of words, not a product.
  static PriceRecordEntity? bestPersonalMatch(
    String itemName,
    List<PriceRecordEntity> records, {
    double minScore = 0.3,
  }) {
    PriceRecordEntity? best;
    var bestScore = 0.0;
    for (final record in records) {
      final score = productMatchScore(itemName, record.name);
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
    final personal = bestPersonalMatch(itemName, records);
    if (personal != null) {
      final group = productRecords(personal, records);
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
      );
    }
    if (community != null) {
      return PriceEstimate(
        unitPrice: community.median,
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

  const GroceryCostSummary({
    required this.knownTotal,
    required this.pricedItems,
    required this.unpricedItems,
  });

  bool get hasAny => pricedItems > 0;

  static GroceryCostSummary of(
    Iterable<({PriceEstimate estimate, double multiplier})> lines,
  ) {
    var total = 0.0;
    var priced = 0;
    var unpriced = 0;
    for (final line in lines) {
      final price = line.estimate.unitPrice;
      if (price == null) {
        unpriced++;
      } else {
        priced++;
        total += price * line.multiplier;
      }
    }
    return GroceryCostSummary(
      knownTotal: total,
      pricedItems: priced,
      unpricedItems: unpriced,
    );
  }
}
