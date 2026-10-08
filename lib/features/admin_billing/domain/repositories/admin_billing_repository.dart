import '../entities/billing_entities.dart';

abstract class AdminBillingRepository {
  Future<AdminBillingSnapshot> load();

  /// Sets the account by hand and locks it, so the webhook's next event does
  /// not undo the decision.
  ///
  /// [from] and [until] bound a grant: both null is "until I say otherwise",
  /// [until] alone is a gift that ends on its own, [from] dates it ahead.
  Future<void> setPremium(
    String uid,
    bool premium, {
    DateTime? from,
    DateTime? until,
  });

  /// Hands the account back to RevenueCat: the next event writes as usual.
  Future<void> releaseLock(String uid);

  /// Holds the account on the blocked screen with [message] from its next
  /// gate check; [enableAccount] lets it back in.
  Future<void> disableAccount(String uid, String message);

  /// Frees the account's device session and signs that device out.
  Future<void> releaseSession(String uid);
  Future<void> enableAccount(String uid);

  /// Removes the Auth user and every trace of the account. Irreversible.
  Future<void> deleteAccount(String uid);

  /// A message into one account's inbox, pushed to its phone.
  Future<void> notifyAccount(
    String uid, {
    required String title,
    required String body,
  });

  /// The same to every account, in one multicast.
  Future<BroadcastResult> notifyAll({
    required String title,
    required String body,
  });
}
