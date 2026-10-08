import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/i18n/strings.g.dart';
import '../utils/routing/routing.dart';
import '../widgets/app_dialog.dart';
import 'monetization_config.dart';
import 'share_usage_service.dart';

/// The free tier's sharing allowances, applied before a share goes out:
/// recipes per week, books and plans held shared at once. Over the line a
/// dialog explains and offers Premium; Premium never sees it.
abstract class ShareGates {
  /// Pure verdicts, for tests and callers that already have the numbers.
  static bool allows({
    required bool premium,
    required int used,
    required int limit,
  }) => premium || limit <= 0 || used < limit;

  static Future<bool> recipe(BuildContext context) async {
    if (MonetizationConfig.isPremium) return true;
    final limit = MonetizationConfig.freeRecipeSharesWeekly;
    final used = await ShareUsageService().recipeSharesThisWeek();
    if (allows(premium: false, used: used, limit: limit)) return true;
    if (!context.mounted) return false;
    await _explain(context, t.shareCode.limitRecipes(count: limit));
    return false;
  }

  /// [sharedNow] is how many books this account already shares.
  static Future<bool> book(BuildContext context, {required int sharedNow}) =>
      _held(
        context,
        sharedNow,
        MonetizationConfig.freeSharedBooks,
        t.shareCode.limitBooks,
      );

  static Future<bool> plan(BuildContext context, {required int sharedNow}) =>
      _held(
        context,
        sharedNow,
        MonetizationConfig.freeSharedPlans,
        t.shareCode.limitPlans,
      );

  static Future<bool> _held(
    BuildContext context,
    int sharedNow,
    int limit,
    String Function({required Object count}) message,
  ) async {
    if (allows(
      premium: MonetizationConfig.isPremium,
      used: sharedNow,
      limit: limit,
    )) {
      return true;
    }
    await _explain(context, message(count: limit));
    return false;
  }

  static Future<void> _explain(BuildContext context, String message) async {
    final upgrade = await AppDialog.warning(
      title: t.premium.title,
      message: message,
      icon: Icons.workspace_premium_rounded,
      confirmLabel: t.shareCode.upgrade,
      cancelLabel: t.common.cancel,
    ).show(context);
    if (upgrade == true && context.mounted) context.pushNamed(Routing.premium);
  }
}
