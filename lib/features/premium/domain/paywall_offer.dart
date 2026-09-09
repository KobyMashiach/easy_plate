import 'package:purchases_flutter/purchases_flutter.dart';

/// How often a package bills, in the app's own terms so the paywall does not
/// depend on the store SDK's enum.
enum PaywallPeriod { weekly, monthly, twoMonth, threeMonth, sixMonth, annual, lifetime, other }

/// One thing the paywall can sell, reduced to what the screen shows: a price
/// string already formatted by the store in the user's currency, and a
/// billing period. The store product itself stays behind [PaywallOffer.id],
/// which is the RevenueCat package identifier.
class PaywallOffer {
  final String id;
  final String priceString;
  final PaywallPeriod period;

  const PaywallOffer({required this.id, required this.priceString, required this.period});

  bool get isLifetime => period == PaywallPeriod.lifetime;

  static PaywallOffer fromPackage(Package package) => PaywallOffer(
        id: package.identifier,
        priceString: package.storeProduct.priceString,
        period: periodFor(package.packageType),
      );

  static PaywallPeriod periodFor(PackageType type) => switch (type) {
        PackageType.weekly => PaywallPeriod.weekly,
        PackageType.monthly => PaywallPeriod.monthly,
        PackageType.twoMonth => PaywallPeriod.twoMonth,
        PackageType.threeMonth => PaywallPeriod.threeMonth,
        PackageType.sixMonth => PaywallPeriod.sixMonth,
        PackageType.annual => PaywallPeriod.annual,
        PackageType.lifetime => PaywallPeriod.lifetime,
        PackageType.custom || PackageType.unknown => PaywallPeriod.other,
      };

  /// The offer to preselect: the longest subscription on sale, since that is
  /// the one with the lowest monthly price, and a lifetime purchase sits
  /// above them all.
  static String? defaultSelection(List<PaywallOffer> offers) {
    if (offers.isEmpty) return null;
    const rank = {
      PaywallPeriod.lifetime: 7,
      PaywallPeriod.annual: 6,
      PaywallPeriod.sixMonth: 5,
      PaywallPeriod.threeMonth: 4,
      PaywallPeriod.twoMonth: 3,
      PaywallPeriod.monthly: 2,
      PaywallPeriod.weekly: 1,
      PaywallPeriod.other: 0,
    };
    var best = offers.first;
    for (final offer in offers.skip(1)) {
      if (rank[offer.period]! > rank[best.period]!) best = offer;
    }
    return best.id;
  }
}
