import 'package:purchases_flutter/purchases_flutter.dart';

/// How often a package bills, in the app's own terms so the paywall does not
/// depend on the store SDK's enum.
enum PaywallPeriod {
  weekly,
  monthly,
  twoMonth,
  threeMonth,
  sixMonth,
  annual,
  lifetime,
  other,
}

/// How long an opening price lasts, in the app's own terms.
enum PaywallIntroUnit { day, week, month, year }

/// The opening deal on a subscription — a lower price (or nothing) for the
/// first period(s), after which the store moves the subscriber to the
/// regular price on its own. Defined in the stores (a Play offer on the
/// base plan, an App Store introductory offer); the app only shows it.
class PaywallIntro {
  /// Formatted by the store in the user's currency; ignored when [isFree].
  final String priceString;
  final bool isFree;

  /// How many [unit]s the deal covers in total: a month at the intro price
  /// is 1 × month, a 7-day trial is 7 × day.
  final int count;
  final PaywallIntroUnit unit;

  const PaywallIntro({
    required this.priceString,
    required this.isFree,
    required this.count,
    required this.unit,
  });

  static PaywallIntro? fromStore(IntroductoryPrice? intro) {
    if (intro == null) return null;
    final unit = switch (intro.periodUnit) {
      PeriodUnit.day => PaywallIntroUnit.day,
      PeriodUnit.week => PaywallIntroUnit.week,
      PeriodUnit.month => PaywallIntroUnit.month,
      PeriodUnit.year => PaywallIntroUnit.year,
      PeriodUnit.unknown => null,
    };
    if (unit == null) return null;
    final cycles = intro.cycles < 1 ? 1 : intro.cycles;
    final units = intro.periodNumberOfUnits < 1 ? 1 : intro.periodNumberOfUnits;
    return PaywallIntro(
      priceString: intro.priceString,
      isFree: intro.price == 0,
      count: cycles * units,
      unit: unit,
    );
  }
}

/// One thing the paywall can sell, reduced to what the screen shows: a price
/// string already formatted by the store in the user's currency, and a
/// billing period. The store product itself stays behind [PaywallOffer.id],
/// which is the RevenueCat package identifier.
class PaywallOffer {
  final String id;
  final String priceString;
  final PaywallPeriod period;

  /// The store product behind the package, for the eligibility check.
  final String productId;

  /// The opening deal, when the store has one AND this account may still
  /// take it — a returning subscriber sees the regular price only.
  final PaywallIntro? intro;

  const PaywallOffer({
    required this.id,
    required this.priceString,
    required this.period,
    this.productId = '',
    this.intro,
  });

  PaywallOffer withoutIntro() => PaywallOffer(
    id: id,
    priceString: priceString,
    period: period,
    productId: productId,
  );

  bool get isLifetime => period == PaywallPeriod.lifetime;

  static PaywallOffer fromPackage(Package package) => PaywallOffer(
    id: package.identifier,
    priceString: package.storeProduct.priceString,
    period: periodFor(package.packageType),
    productId: package.storeProduct.identifier,
    intro: PaywallIntro.fromStore(package.storeProduct.introductoryPrice),
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
