import '../entities/billing_entities.dart';

abstract class AdminBillingRepository {
  Future<AdminBillingSnapshot> load();

  /// Sets the account by hand and locks it, so the webhook's next event does
  /// not undo the decision.
  Future<void> setPremium(String uid, bool premium);

  /// Hands the account back to RevenueCat: the next event writes as usual.
  Future<void> releaseLock(String uid);
}
