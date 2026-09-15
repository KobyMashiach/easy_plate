import 'package:flutter/foundation.dart';

import '../../grocery_list/domain/entities/grocery_item_entity.dart';
import '../domain/entities/price_record_entity.dart';
import '../domain/entities/product_pricing_entity.dart';
import '../domain/price_estimator.dart';
import '../domain/product_name.dart';
import '../domain/repositories/price_book_repository.dart';

/// The grocery list's view of the price book: the records, loaded once, and
/// the community answers as they arrive. Estimates are synchronous so a
/// card can ask on every build; a community lookup that is still in flight
/// reads as "no data" and the card is rebuilt when it lands.
class PriceBookService extends ChangeNotifier {
  final PriceBookRepository repository;

  /// Whether to fall back to the community median — the user's preference,
  /// passed in by whoever knows it.
  bool communityEnabled;

  List<PriceRecordEntity> _records = const [];
  Map<String, ProductPricingEntity> _pricing = const {};
  final _community = <String, CommunityPriceEntity?>{};
  final _pending = <String>{};
  bool _loaded = false;

  PriceBookService({required this.repository, this.communityEnabled = false});

  bool get isLoaded => _loaded;
  List<PriceRecordEntity> get records => _records;

  Future<void> load() async {
    try {
      _records = await repository.getRecords();
      _pricing = await repository.getPricing();
    } catch (e) {
      debugPrint('Price book load failed: $e');
      _records = const [];
    }
    _loaded = true;
    notifyListeners();
  }

  /// How many of the estimate's price unit the line amounts to: 850 g of
  /// steak at a per-kg price is 0.85; three units at a per-package price is
  /// 3; grams against a per-package price do not convert and count once.
  static double multiplierFor(GroceryItemEntity item, PriceEstimate estimate) =>
      estimate.unit.multiplierFor(item.unit, item.totalAmount) ?? 1;

  PriceEstimate estimateFor(GroceryItemEntity item) {
    final personal = PriceEstimator.estimate(
      item.name,
      _records,
      pricing: _pricing,
    );
    if (personal.hasPrice || !communityEnabled) return personal;
    final key = normalizeProductName(item.name);
    if (_community.containsKey(key)) {
      return PriceEstimator.estimate(
        item.name,
        _records,
        community: _community[key],
        pricing: _pricing,
      );
    }
    _fetchCommunity(key);
    return PriceEstimate.none;
  }

  GroceryCostSummary summarize(Iterable<GroceryItemEntity> items) =>
      GroceryCostSummary.of([
        for (final item in items)
          if (estimateFor(item) case final estimate)
            (estimate: estimate, multiplier: multiplierFor(item, estimate)),
      ]);

  void _fetchCommunity(String key) {
    if (!_pending.add(key)) return;
    repository
        .communityPrice(key)
        .then((result) {
          _community[key] = result;
          _pending.remove(key);
          notifyListeners();
        })
        .catchError((Object e) {
          debugPrint('Community price failed: $e');
          _community[key] = null;
          _pending.remove(key);
        });
  }
}
