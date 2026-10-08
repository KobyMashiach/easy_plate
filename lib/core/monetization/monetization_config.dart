import '../features/features_flags.dart';
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
  static bool get adsEnabled =>
      _remote.remoteBool(FirebaseService.adsEnabledKey);

  /// Grant the unlock when no rewarded ad could be served.
  static bool get failOpen =>
      _remote.remoteBool(FirebaseService.adsFailOpenKey);

  /// Feed items between two native cards. Zero or less disables the cards.
  static int get feedAdInterval =>
      _remote.remoteInt(FirebaseService.feedAdIntervalKey);

  static QuotaLimits get limits => QuotaLimits(
    freeSharedViews: _remote.remoteInt(FirebaseService.quotaSharedFreeKey),
    rewardedSharedViews: _remote.remoteInt(
      FirebaseService.quotaSharedRewardedKey,
    ),
    rewardedAiExtractions: _remote.remoteInt(
      FirebaseService.quotaAiRewardedKey,
    ),
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

  /// Cook mode, the assistant and the notifications are Premium while the
  /// console's feature flag says `3` (see `FeaturesFlags`). Kept here so the
  /// callers that ask "is it locked for this account" have one place to
  /// ask; the flag's other values (hidden, coming soon) are the gate's.
  static bool get cookModeLocked => FeaturesFlags.cookMode.isLocked;

  static bool get assistantLocked => FeaturesFlags.assistant.isLocked;

  /// Free-tier sharing allowances (Premium: unlimited).
  static int get freeRecipeSharesWeekly =>
      _remote.remoteInt(FirebaseService.shareFreeRecipesWeeklyKey);
  static int get freeSharedBooks =>
      _remote.remoteInt(FirebaseService.shareFreeBooksKey);
  static int get freeSharedPlans =>
      _remote.remoteInt(FirebaseService.shareFreePlansKey);
  static int get freeSharedLists =>
      _remote.remoteInt(FirebaseService.shareFreeListsKey);

  /// Pushes, reminders and popups are Premium while the console says so.
  /// The inbox itself stays: share invites must still be answerable.
  static bool get notificationsLocked => FeaturesFlags.notifications.isLocked;
}
