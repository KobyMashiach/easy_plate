import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/purchases_config.dart';
import 'entitlement_service.dart';

/// The RevenueCat side of premium.
///
/// RevenueCat is configured on the first sign-in, with that Firebase account
/// as its `app_user_id`, so a subscription bought on one phone follows the
/// account to the next. The id is always the Firebase uid — that is what the
/// webhook writes `entitlements/{uid}` under, and an anonymous RevenueCat id
/// would land the purchase on a document nobody reads.
///
/// Premium has two sources and [EntitlementService] merges them: the webhook
/// writing Firestore (authoritative, survives reinstalls and the SDK being
/// unreachable) and the SDK's own `CustomerInfo` (instant, so a purchase
/// unlocks the app before the webhook has landed). Neither is trusted to
/// *revoke* the other: a lapsed subscription expires through `premiumUntil`
/// on the document, and the SDK stops reporting the entitlement on its own.
class PurchasesService {
  static final PurchasesService _instance = PurchasesService._internal();
  factory PurchasesService() => _instance;
  PurchasesService._internal();

  bool _configured = false;
  String? _uid;

  bool get isConfigured => _configured;

  /// Nothing to configure yet: the SDK starts with the first [logIn], so it
  /// is never up under an anonymous id. Configured early, it synced the
  /// device's Play receipt before the account was known and posted it under
  /// a `$RCAnonymousID`, where no `entitlements/{uid}` document could follow.
  Future<void> init() async {
    if (!PurchasesConfig.enabled) {
      debugPrint('Purchases disabled: no RevenueCat key for this platform');
    }
  }

  Future<void>? _configuring;

  /// Ties the SDK to the signed-in account, configuring it on the first
  /// call. Idempotent for the same uid, so the auth stream re-emitting the
  /// same user costs nothing.
  Future<void> logIn(String uid) async {
    if (_uid == uid) return;
    // Set before the SDK call so a second sign-in during it is seen below;
    // cleared again by [_configure] / [_identify] when the call fails, or
    // the same account's next sign-in would be skipped as already done.
    _uid = uid;
    if (!PurchasesConfig.enabled) return;
    if (!_configured) {
      await (_configuring ??= _configure(uid));
      // Another account may have signed in while the SDK came up.
      if (_configured && _uid != null && _uid != uid) await _identify(_uid!);
      return;
    }
    await _identify(uid);
  }

  Future<void> _configure(String uid) async {
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(
        PurchasesConfiguration(PurchasesConfig.apiKey)..appUserID = uid,
      );
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _configured = true;
      final info = await Purchases.getCustomerInfo();
      // Only while this is still the signed-in account: a sign-out (or a
      // switch) during the read must not hand its premium to the next one.
      if (_uid == uid) _onCustomerInfo(info);
    } catch (e) {
      debugPrint('Purchases init failed: $e');
      // Nothing is configured, so nobody is logged in: forget the uid and
      // the next auth event tries again instead of returning early.
      if (!_configured) _uid = null;
    } finally {
      _configuring = null;
    }
  }

  /// Detaches the account on sign-out. RevenueCat then mints a fresh anonymous
  /// id, which is what we want: the next sign-in must not inherit this one's
  /// receipts.
  Future<void> logOut() async {
    _uid = null;
    // A sign-out while the SDK is still coming up: let it finish, or it
    // would stay identified as the account that just left.
    if (_configuring case final configuring?) await configuring;
    if (!_configured || _uid != null) return;
    try {
      // Already anonymous (a sign-out right after a failed sign-in) throws.
      if (await Purchases.isAnonymous) return;
      // A sign-in landed during that check: the SDK now belongs to it.
      if (_uid != null) return;
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Purchases logOut skipped: $e');
    }
  }

  Future<void> _identify(String uid) async {
    try {
      final result = await Purchases.logIn(uid);
      if (_uid == uid) _onCustomerInfo(result.customerInfo);
    } catch (e) {
      debugPrint('Purchases logIn failed: $e');
      // The SDK is still on the previous id; the next auth event retries.
      if (_uid == uid) _uid = null;
    }
  }

  /// The packages currently on sale, or null when there is nothing to show
  /// (no key, no offering configured in the dashboard yet, offline).
  Future<Offering?> currentOffering() async {
    if (!_configured) return null;
    try {
      return (await Purchases.getOfferings()).current;
    } catch (e) {
      debugPrint('Purchases offerings failed: $e');
      return null;
    }
  }

  /// The products whose opening deal this account may NOT take. Apple
  /// answers per product; Google Play answers "unknown" because it already
  /// leaves an offer the account is not eligible for out of the product, so
  /// only a clear "ineligible" hides the deal.
  Future<Set<String>> introIneligible(Iterable<String> productIds) async {
    final ids = productIds.where((id) => id.isNotEmpty).toList();
    if (!_configured || ids.isEmpty) return const {};
    try {
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility(
        ids,
      );
      return {
        for (final entry in result.entries)
          if (entry.value.status ==
                  IntroEligibilityStatus.introEligibilityStatusIneligible ||
              entry.value.status ==
                  IntroEligibilityStatus
                      .introEligibilityStatusNoIntroOfferExists)
            entry.key,
      };
    } catch (e) {
      debugPrint('Intro eligibility check failed: $e');
      return const {};
    }
  }

  /// Opens the store's own screen for a promo / offer code. On iOS that is
  /// Apple's redemption sheet; on Android the Play Store's redeem page with
  /// [code] filled in. The purchase it produces reaches this account through
  /// [restore], which the paywall runs when the app comes back.
  Future<bool> redeemCode({String? code}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (!_configured) return false;
        await Purchases.presentCodeRedemptionSheet();
        return true;
      }
      final uri = Uri.https('play.google.com', '/redeem', {
        if (code != null && code.isNotEmpty) 'code': code,
      });
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Code redemption failed: $e');
      return false;
    }
  }

  /// The store product behind the account's active premium (and, on Google
  /// Play, its base plan), or null when premium does not come from a store
  /// purchase on this account (granted by hand, inherited from a household,
  /// or none at all).
  Future<ActivePlan?> activePlan() async {
    if (!_configured) return null;
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement =
          info.entitlements.active[PurchasesConfig.premiumEntitlementId];
      if (entitlement == null) return null;
      return ActivePlan(
        productId: entitlement.productIdentifier,
        basePlan: entitlement.productPlanIdentifier,
      );
    } catch (e) {
      debugPrint('Active plan lookup failed: $e');
      return null;
    }
  }

  /// Buys [package]. Returns true when the account holds premium afterwards.
  /// A cancelled purchase sheet is not an error and reads as false; anything
  /// else is rethrown so the paywall can say what went wrong.
  ///
  /// [replacing] switches an active subscription to this package. Google
  /// Play needs to be told which subscription is replaced (or it would sell
  /// a second one alongside); the remaining time is credited at once.
  /// The App Store switches within the subscription group by itself.
  Future<bool> purchase(Package package, {ActivePlan? replacing}) async {
    if (!_configured) return false;
    try {
      final change =
          replacing != null && defaultTargetPlatform == TargetPlatform.android
          ? StoreProductChangeInfo(
              replacing.subscriptionId,
              replacementMode: StoreReplacementMode.withTimeProration,
            )
          : null;
      final result = await Purchases.purchase(
        PurchaseParams.package(package, productChangeInfo: change),
      );
      _onCustomerInfo(result.customerInfo);
      return hasPremium(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// Re-reads the store's receipts for this account — the "restore purchases"
  /// button Apple requires. Returns whether premium came back.
  Future<bool> restore() async {
    if (!_configured) return false;
    final info = await Purchases.restorePurchases();
    _onCustomerInfo(info);
    return hasPremium(info);
  }

  /// The "cancel subscription" button. Opens the store's own subscription
  /// page for this account, where cancelling means auto-renew off: the
  /// subscription runs to the end of the period already paid for, and the
  /// webhook's CANCELLATION event keeps `premium` until EXPIRATION. No
  /// refund is offered from here, by design — a refund is the store's call.
  /// Falls back to the Customer Center when the store gave no URL (Test
  /// Store, or a purchase made on the other platform). Returns false when
  /// neither could be shown.
  Future<bool> openSubscriptionManagement() async {
    if (!_configured) return false;
    try {
      final url = (await Purchases.getCustomerInfo()).managementURL;
      if (url != null && url.isNotEmpty) {
        return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Subscription management URL failed: $e');
    }
    return openCustomerCenter();
  }

  /// Opens RevenueCat's Customer Center: cancel, change plan, ask for a
  /// refund, restore — the "manage subscription" screen both stores expect
  /// an app to offer somewhere. Returns false when there is no SDK to open
  /// it with, so the caller can say so instead of showing nothing.
  Future<bool> openCustomerCenter() async {
    if (!_configured) return false;
    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: _onCustomerInfo,
      );
      // Anything decided inside (a cancellation, a plan change) reaches the
      // account through the listener; re-reading here just closes the gap.
      _onCustomerInfo(await Purchases.getCustomerInfo());
      return true;
    } catch (e) {
      debugPrint('Customer Center failed: $e');
      return false;
    }
  }

  void _onCustomerInfo(CustomerInfo info) =>
      EntitlementService().setFromStore(hasPremium(info));

  /// Tests share the singleton; the app configures it once for its lifetime.
  @visibleForTesting
  void resetForTest() {
    _configured = false;
    _configuring = null;
    _uid = null;
  }

  static bool hasPremium(CustomerInfo info) => info.entitlements.active
      .containsKey(PurchasesConfig.premiumEntitlementId);
}

/// The store product an active subscription was bought as.
class ActivePlan {
  /// As RevenueCat reports it: a Play subscription id (sometimes with
  /// `:basePlan` attached) or an App Store product id.
  final String productId;

  /// Google Play's base plan, when there is one.
  final String? basePlan;

  const ActivePlan({required this.productId, this.basePlan});

  /// The Play subscription id alone, as a product change wants it.
  String get subscriptionId => productId.split(':').first;

  /// Whether the paywall offer for [offerProductId] (Play: `sub:basePlan`)
  /// is this plan.
  bool matches(String offerProductId) {
    if (offerProductId == productId) return true;
    final parts = offerProductId.split(':');
    if (parts.first != subscriptionId) return false;
    // One subscription can carry several base plans (monthly, yearly):
    // only the same one is the same plan.
    final plan =
        basePlan ?? (productId.contains(':') ? productId.split(':')[1] : null);
    return parts.length < 2 || plan == null || parts[1] == plan;
  }
}
