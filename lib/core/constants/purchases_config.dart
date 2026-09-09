import 'dart:io';

import 'package:flutter/foundation.dart';

/// RevenueCat configuration.
///
/// The public SDK keys arrive through `--dart-define-from-file=dart_defines/dev.json`,
/// one per store, so the build picks the right one at compile time. They are
/// *public* keys by RevenueCat's own design (they can only read offerings and
/// post receipts), so unlike the Gemini key a blank here is a misconfiguration
/// rather than a leak — the SDK simply stays off and the account stays free.
///
/// The entitlement identifier is the one thing both sides must agree on: it is
/// the name of the entitlement in the RevenueCat dashboard, the key the
/// webhook looks for in `entitlement_ids`, and the key the app reads from
/// `CustomerInfo.entitlements.active`.
abstract class PurchasesConfig {
  static const _apiKeyAndroid = String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');
  static const _apiKeyIos = String.fromEnvironment('REVENUECAT_API_KEY_IOS');

  /// The single entitlement EasyPlate sells: no ads, no daily quotas.
  static const premiumEntitlementId = 'premium';

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// The key for the platform this build runs on, or blank when none was
  /// supplied — see [enabled].
  static String get apiKey => resolveKey(
        android: _apiKeyAndroid,
        ios: _apiKeyIos,
        isIos: _isIos,
      );

  @visibleForTesting
  static String resolveKey({
    required String android,
    required String ios,
    required bool isIos,
  }) =>
      (isIos ? ios : android).trim();

  /// Purchases only exist on the two mobile platforms with a key to talk to
  /// RevenueCat; everywhere else the layer is a no-op.
  static bool get enabled => supported && apiKey.isNotEmpty;

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
