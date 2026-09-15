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
/// RevenueCat is configured once at startup and told which Firebase account
/// is signed in, so a subscription bought on one phone follows the account to
/// the next. Its `app_user_id` is always the Firebase uid — that is what the
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

  /// Configures the SDK. Safe to call without a key or off-platform (tests,
  /// desktop): it logs and does nothing, and every later call is a no-op.
  ///
  /// If a uid arrived before this finished (auth usually resolves faster than
  /// the native SDK starts), it is applied at the end rather than lost.
  Future<void> init() async {
    if (_configured || !PurchasesConfig.enabled) {
      if (!PurchasesConfig.enabled) debugPrint('Purchases disabled: no RevenueCat key for this platform');
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(
        PurchasesConfiguration(PurchasesConfig.apiKey)..appUserID = _uid,
      );
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _configured = true;
      if (_uid != null) await _identify(_uid!);
    } catch (e) {
      debugPrint('Purchases init failed: $e');
    }
  }

  /// Ties the SDK to the signed-in account. Idempotent for the same uid, so
  /// the auth stream re-emitting the same user costs nothing.
  Future<void> logIn(String uid) async {
    if (_uid == uid) return;
    _uid = uid;
    if (!_configured) return;
    await _identify(uid);
  }

  /// Detaches the account on sign-out. RevenueCat then mints a fresh anonymous
  /// id, which is what we want: the next sign-in must not inherit this one's
  /// receipts.
  Future<void> logOut() async {
    _uid = null;
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      // Already anonymous, or offline — nothing to detach either way.
      debugPrint('Purchases logOut skipped: $e');
    }
  }

  Future<void> _identify(String uid) async {
    try {
      final result = await Purchases.logIn(uid);
      _onCustomerInfo(result.customerInfo);
    } catch (e) {
      debugPrint('Purchases logIn failed: $e');
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

  /// Buys [package]. Returns true when the account holds premium afterwards.
  /// A cancelled purchase sheet is not an error and reads as false; anything
  /// else is rethrown so the paywall can say what went wrong.
  Future<bool> purchase(Package package) async {
    if (!_configured) return false;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _onCustomerInfo(result.customerInfo);
      return hasPremium(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
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

  void _onCustomerInfo(CustomerInfo info) => EntitlementService().setFromStore(hasPremium(info));

  static bool hasPremium(CustomerInfo info) =>
      info.entitlements.active.containsKey(PurchasesConfig.premiumEntitlementId);
}
