/// The daily allowances, as numbers. Defaults mirror the Remote Config
/// defaults in `FirebaseService`; the live values come through
/// `MonetizationConfig.limits`.
class QuotaLimits {
  /// Shared recipes a free account opens per day with no ad at all.
  final int freeSharedViews;

  /// Shared recipes per day that open after a rewarded video, once the free
  /// ones are spent.
  final int rewardedSharedViews;

  /// AI link extractions per day, every one of them behind a rewarded video.
  final int rewardedAiExtractions;

  /// AI link extractions per day for a premium account: no video, but not
  /// unlimited either — every one of them is a paid model call.
  final int premiumAiExtractions;

  const QuotaLimits({
    required this.freeSharedViews,
    required this.rewardedSharedViews,
    required this.rewardedAiExtractions,
    required this.premiumAiExtractions,
  });

  static const defaults = QuotaLimits(
    freeSharedViews: 3,
    rewardedSharedViews: 3,
    rewardedAiExtractions: 2,
    premiumAiExtractions: 10,
  );

  /// The day's AI extraction allowance for this kind of account.
  int aiExtractionsFor({required bool premium}) =>
      premium ? premiumAiExtractions : rewardedAiExtractions;

  int get totalSharedViews => freeSharedViews + rewardedSharedViews;
}

/// What happens when the user asks for something the quota covers.
enum GateVerdict {
  /// Open it, no ad.
  free,

  /// Open it after a rewarded video.
  rewarded,

  /// Not today.
  blocked,
}

/// The quota rules with no state in them. The services hold the counts; this
/// is the one place that says what a count means.
abstract class DailyQuotaPolicy {
  /// Opening a shared (community) recipe.
  ///
  /// Recipes 1–3 of the day are free, 4–6 cost a video, the 7th is refused.
  /// A recipe already opened today is free again: it was paid for once.
  static GateVerdict sharedRecipe({
    required int viewedToday,
    required bool alreadyViewed,
    required bool premium,
    QuotaLimits limits = QuotaLimits.defaults,
  }) {
    if (premium || alreadyViewed) return GateVerdict.free;
    if (viewedToday < limits.freeSharedViews) return GateVerdict.free;
    if (viewedToday < limits.totalSharedViews) return GateVerdict.rewarded;
    return GateVerdict.blocked;
  }

  /// Extracting a recipe from a link with the model. For a free account
  /// every extraction, the first included, costs a video; premium extracts
  /// without one. Past the day's count either is refused: premium buys a
  /// bigger allowance, not a bottomless one.
  static GateVerdict aiExtraction({
    required int usedToday,
    required bool premium,
    QuotaLimits limits = QuotaLimits.defaults,
  }) {
    if (usedToday >= limits.aiExtractionsFor(premium: premium)) return GateVerdict.blocked;
    return premium ? GateVerdict.free : GateVerdict.rewarded;
  }

  static int remainingFreeSharedViews(int viewedToday, QuotaLimits limits) =>
      _clamp(limits.freeSharedViews - viewedToday);

  /// Rewarded openings left, counting only once the free ones are gone.
  static int remainingRewardedSharedViews(int viewedToday, QuotaLimits limits) =>
      _clamp(limits.totalSharedViews - _max(viewedToday, limits.freeSharedViews));

  static int remainingAiExtractions(
    int usedToday,
    QuotaLimits limits, {
    bool premium = false,
  }) =>
      _clamp(limits.aiExtractionsFor(premium: premium) - usedToday);

  static int _clamp(int n) => n < 0 ? 0 : n;
  static int _max(int a, int b) => a > b ? a : b;
}
