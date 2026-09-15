import '../services/firebase_service.dart';
import 'daily_quota_policy.dart';
import 'entitlement_service.dart';

/// The live monetisation switches, resolved from Remote Config on every read.
///
/// Nothing here is cached: the values are cheap to read from the activated
/// config, and a listener on `FirebaseService().configRevision` is how a
/// screen finds out that they changed.
abstract class MonetizationConfig {
  static FirebaseService get _remote => FirebaseService();

  /// The kill switch. Off, the app behaves exactly as it did before ads: no
  /// cards in the feeds, no quotas, no gates.
  static bool get adsEnabled => _remote.remoteBool(FirebaseService.adsEnabledKey);

  /// Grant the unlock when no rewarded ad could be served.
  static bool get failOpen => _remote.remoteBool(FirebaseService.adsFailOpenKey);

  /// Feed items between two native cards. Zero or less disables the cards.
  static int get feedAdInterval => _remote.remoteInt(FirebaseService.feedAdIntervalKey);

  static QuotaLimits get limits => QuotaLimits(
        freeSharedViews: _remote.remoteInt(FirebaseService.quotaSharedFreeKey),
        rewardedSharedViews: _remote.remoteInt(FirebaseService.quotaSharedRewardedKey),
        rewardedAiExtractions: _remote.remoteInt(FirebaseService.quotaAiRewardedKey),
        premiumAiExtractions: _remote.remoteInt(FirebaseService.quotaAiPremiumKey),
      );

  static bool get isPremium => EntitlementService().isPremium;

  /// True when this account sees no ads and no *shared-recipe* quota: premium,
  /// or ads off. The AI quota is the exception — premium still has one, a
  /// larger one — so the AI gate asks [aiGated] instead.
  static bool get adFree => !adsEnabled || isPremium;

  /// Whether AI extractions are counted at all. The kill switch turns every
  /// quota off; premium only changes which allowance applies.
  static bool get aiGated => adsEnabled;
}
