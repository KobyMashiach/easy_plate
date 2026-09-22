import 'package:intl/intl.dart' as intl;

import '../../../../core/utils/i18n/strings.g.dart';
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
