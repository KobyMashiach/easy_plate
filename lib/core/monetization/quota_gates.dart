import 'package:flutter/material.dart';

import '../ads/reward_gate_sheet.dart';
import '../constants/app_text_styles.dart';
import '../services/auth_session_service.dart';
import '../utils/i18n/strings.g.dart';
import 'daily_quota_policy.dart';
import 'daily_usage_service.dart';
import 'monetization_config.dart';

/// The two places the daily quotas are enforced, as one call each.
///
/// Both answer "may this go ahead?" and, when the answer is yes, have already
/// recorded the spend. The recording happens *before* the thing itself — the
/// recipe opening, the model call — so a crash or a slow network in between
/// never hands out a second free go.
abstract class QuotaGates {
  /// Opening a shared recipe from the community feed or a forum reply.
  ///
  /// The author's own recipes are always free: they are looking at what they
  /// published, not at the community's.
  static Future<bool> openSharedRecipe(
    BuildContext context, {
    required String sharedId,
    required String authorUid,
  }) async {
    if (MonetizationConfig.adFree) return true;
    if (AuthSessionService().user?.uid == authorUid) return true;

    final usage = DailyUsageService();
    await usage.ensureLoaded();
    if (!context.mounted) return false;

    final limits = MonetizationConfig.limits;
    final verdict = DailyQuotaPolicy.sharedRecipe(
      viewedToday: usage.sharedViewsToday,
      alreadyViewed: usage.hasViewedShared(sharedId),
      premium: false,
      limits: limits,
    );

    switch (verdict) {
      case GateVerdict.free:
        await usage.recordSharedView(sharedId);
        return true;
      case GateVerdict.blocked:
        _notify(context, t.ads.sharedQuotaReached);
        return false;
      case GateVerdict.rewarded:
        final remaining =
            DailyQuotaPolicy.remainingRewardedSharedViews(usage.sharedViewsToday, limits);
        final unlocked = await showRewardGateSheet(
          context,
          title: t.ads.unlockRecipeTitle,
          message: t.ads.unlockRecipeMessage(count: remaining),
        );
        if (unlocked) await usage.recordSharedView(sharedId);
        return unlocked;
    }
  }

  /// Extracting a recipe from a link with the model.
  static Future<bool> extractWithAi(BuildContext context) async {
    if (MonetizationConfig.adFree) return true;

    final usage = DailyUsageService();
    await usage.ensureLoaded();
    if (!context.mounted) return false;

    final limits = MonetizationConfig.limits;
    final verdict = DailyQuotaPolicy.aiExtraction(
      usedToday: usage.aiExtractionsToday,
      premium: false,
      limits: limits,
    );

    switch (verdict) {
      case GateVerdict.free:
        return true;
      case GateVerdict.blocked:
        _notify(context, t.ads.aiQuotaReached);
        return false;
      case GateVerdict.rewarded:
        final remaining =
            DailyQuotaPolicy.remainingAiExtractions(usage.aiExtractionsToday, limits);
        final unlocked = await showRewardGateSheet(
          context,
          title: t.ads.unlockAiTitle,
          message: t.ads.unlockAiMessage(count: remaining),
        );
        if (unlocked) await usage.recordAiExtraction();
        return unlocked;
    }
  }

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppTextStyles.bodyMd)),
    );
  }
}
