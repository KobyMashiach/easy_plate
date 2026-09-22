import '../entities/dashboard_entities.dart';

abstract class AdminDashboardRepository {
  Future<DashboardOverview> load(DashboardPeriod period);

  Future<AiPricing> loadPricing();
  Future<void> savePricing(AiPricing pricing);

  /// Pulls the current list prices from Google's Cloud Billing catalog into
  /// the table, through the adminUsers function. Throws with the reason
  /// when the catalog cannot be read (API not enabled, no match).
  Future<PricingSyncResult> syncPricingFromGoogle();

  /// One account's all-time totals with the feature split, for the detail
  /// sheet; null when it never made a call.
  Future<UserAiUsage?> userUsage(String uid);

  /// Newest first, from the audit trail.
  Future<List<AiCallEntity>> recentCalls(String uid, {int limit = 40});
}
