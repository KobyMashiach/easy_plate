import 'package:intl/intl.dart' as intl;

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../admin_billing/domain/entities/billing_entities.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Number and label formatting shared by the dashboard's widgets.
abstract class DashboardFormat {
  static String usd(double v) => v.abs() < 0.01 && v != 0
      ? '\$${v.toStringAsFixed(4)}'
      : intl.NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(v);

  /// A dollar amount shown the way the bill is read here: in shekels, at
  /// the table's weekly rate.
  static String cost(double usd, AiPricing pricing) =>
      ils(usd * pricing.usdToIls);

  static String ils(double v) =>
      intl.NumberFormat.currency(symbol: '₪', decimalDigits: 2).format(v);

  static String money(double v, String currency) => switch (currency) {
    'ILS' => ils(v),
    'USD' => usd(v),
    _ => '${intl.NumberFormat.decimalPattern().format(v)} $currency',
  };

  static String count(num v) => intl.NumberFormat.decimalPattern().format(v);

  static String compact(num v) => intl.NumberFormat.compact().format(v);

  static String date(DateTime at) =>
      intl.DateFormat('dd/MM/yyyy HH:mm').format(at.toLocal());

  static String day(DateTime at) =>
      intl.DateFormat('dd/MM').format(at.toLocal());

  static String dayFull(DateTime at) =>
      intl.DateFormat('dd/MM/yyyy').format(at);

  /// The feature a call was tagged with, in the user's language.
  static String kind(String kind) {
    final s = t.adminDashboard;
    return switch (kind) {
      'text' => s.kindText,
      'url' => s.kindUrl,
      'social' => s.kindSocial,
      'social_video' => s.kindSocialVideo,
      'video' => s.kindVideo,
      'search' => s.kindSearch,
      'image' => s.kindImage,
      'receipt' => s.kindReceipt,
      'nutrition' => s.kindNutrition,
      'refine' => s.kindRefine,
      'generate' => s.kindGenerate,
      _ => kind,
    };
  }

  /// What the user did with a call ([AiActions] id), in the user's language.
  static String action(String action) {
    final a = t.adminDashboard.actions;
    return switch (action) {
      'recipe_text' => a.recipe_text,
      'recipe_photo' => a.recipe_photo,
      'recipe_pdf' => a.recipe_pdf,
      'recipe_audio' => a.recipe_audio,
      'recipe_file' => a.recipe_file,
      'recipe_url' => a.recipe_url,
      'recipe_video' => a.recipe_video,
      'recipe_generate' => a.recipe_generate,
      'recipe_refine' => a.recipe_refine,
      'recipe_search' => a.recipe_search,
      'recipe_suggest' => a.recipe_suggest,
      'nutrition' => a.nutrition,
      'receipt_scan' => a.receipt_scan,
      'image_recipe' => a.image_recipe,
      'image_book_cover' => a.image_book_cover,
      'image_other' => a.image_other,
      'assistant_chat' => a.assistant_chat,
      'translate' => a.translate,
      'whatsapp' => a.whatsapp,
      'admin' => a.admin,
      _ => a.other,
    };
  }

  /// The area an action belongs to ("recipes", "books"…).
  static String category(String category) {
    final c = t.adminDashboard.categories;
    return switch (category) {
      'recipes' => c.recipes,
      'books' => c.books,
      'shopping' => c.shopping,
      'assistant' => c.assistant,
      'translate' => c.translate,
      'admin' => c.admin,
      _ => c.other,
    };
  }

  /// "Books · Cover for a book": the area, then exactly what was done.
  static String whatTheyDid(String action) =>
      '${category(AiActions.categoryOf(action))} · ${DashboardFormat.action(action)}';

  /// One subscription step as a line of the history.
  static String step(SubscriptionHistoryEntry e) {
    final s = t.adminDashboard.subHistory.steps;
    final until = e.until;
    return switch (e.step) {
      SubscriptionStep.joined => s.joined,
      SubscriptionStep.trial => s.trial,
      SubscriptionStep.renewed => s.renewed,
      SubscriptionStep.cancelled =>
        until == null ? s.cancelledNoDate : s.cancelled(date: dayFull(until)),
      SubscriptionStep.uncancelled => s.uncancelled,
      SubscriptionStep.ended => s.ended,
      SubscriptionStep.billingIssue => s.billingIssue,
      SubscriptionStep.changedPlan => s.changedPlan,
      SubscriptionStep.oneTime => s.oneTime,
      SubscriptionStep.paused => s.paused,
      SubscriptionStep.transferred => s.transferred,
      SubscriptionStep.refunded => s.refunded,
      SubscriptionStep.adminGrant =>
        until == null
            ? s.adminGrantForever
            : s.adminGrant(date: dayFull(until)),
      SubscriptionStep.adminRevoke => s.adminRevoke,
      SubscriptionStep.other => s.other(type: e.event.type),
    };
  }

  /// "12.5%", or a dash when there is nothing to divide by.
  static String percent(num part, num whole) => whole == 0
      ? '—'
      : '${intl.NumberFormat('0.0').format(part * 100 / whole)}%';

  static String platform(String platform) {
    final s = t.adminDashboard;
    return switch (platform) {
      'ios' => s.platformIos,
      'android' => s.platformAndroid,
      '' => s.platformUnknown,
      _ => platform,
    };
  }
}
