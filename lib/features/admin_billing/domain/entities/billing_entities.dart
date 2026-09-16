/// One RevenueCat event, as the webhook recorded it in `purchase_events`.
class PurchaseEventEntity {
  final String id;

  /// The Firebase uid the event resolved to, or null for a receipt that
  /// arrived under an anonymous RevenueCat id — a purchase with no account.
  final String? uid;
  final String appUserId;
  final String type;
  final String productId;
  final String store;
  final List<String> entitlementIds;

  /// Whether the receipt carried the premium entitlement. False means the
  /// product was not attached to it in the dashboard at the time.
  final bool grantsPremium;
  final String environment;
  final DateTime eventAt;
  final DateTime? expiresAt;
  final double? price;
  final String currency;

  const PurchaseEventEntity({
    required this.id,
    required this.uid,
    required this.appUserId,
    required this.type,
    required this.productId,
    required this.store,
    required this.entitlementIds,
    required this.grantsPremium,
    required this.environment,
    required this.eventAt,
    required this.expiresAt,
    required this.price,
    required this.currency,
  });

  static const _paymentTypes = {
    'INITIAL_PURCHASE',
    'RENEWAL',
    'NON_RENEWING_PURCHASE',
    'UNCANCELLATION',
    'PRODUCT_CHANGE',
  };

  /// Money changed hands, or a paid period was reaffirmed.
  bool get isPayment => _paymentTypes.contains(type);

  bool get isSandbox => environment.toUpperCase() == 'SANDBOX';

  /// A payment whose period has not run out: the account should be premium.
  bool coversNow(DateTime now) =>
      isPayment && (expiresAt == null || expiresAt!.isAfter(now));
}

/// One account as the subscriptions screen shows it: who they are, what the
/// entitlement document says, and every event RevenueCat sent about them.
class BillingAccountEntity {
  final String uid;
  final String name;
  final String? email;
  final String? phone;

  /// The document's verdict, with a past `premiumUntil` read as free — the
  /// same rule the app applies.
  final bool premium;
  final DateTime? premiumUntil;

  /// `revenuecat`, `admin`, or blank when there is no document yet.
  final String source;

  /// Set by hand from this screen; the webhook leaves the document alone
  /// until it is released.
  final bool adminLock;
  final String lastEventType;
  final DateTime? lastEventAt;
  final String productId;
  final String store;
  final List<PurchaseEventEntity> events;

  const BillingAccountEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.premium,
    required this.premiumUntil,
    required this.source,
    required this.adminLock,
    required this.lastEventType,
    required this.lastEventAt,
    required this.productId,
    required this.store,
    required this.events,
  });

  bool get hasEvents => events.isNotEmpty;

  /// A payment that still covers today, whatever the document says.
  bool paidThrough(DateTime now) => events.any((e) => e.coversNow(now));

  /// A payment that came in without the entitlement on it: the product was
  /// not attached in the RevenueCat dashboard, so nothing unlocked.
  bool get paidWithoutEntitlement =>
      events.any((e) => e.isPayment && !e.grantsPremium);

  /// Something the administrator should look at.
  bool hasProblem(DateTime now) =>
      (paidThrough(now) && !premium) || (paidWithoutEntitlement && !premium);

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        (email?.toLowerCase().contains(q) ?? false) ||
        (phone?.contains(q) ?? false) ||
        uid.toLowerCase().contains(q);
  }
}

/// Everything the screen needs in one read.
class AdminBillingSnapshot {
  final List<BillingAccountEntity> accounts;

  /// Events that resolved to no uid: receipts with no account to unlock.
  final List<PurchaseEventEntity> orphanEvents;

  const AdminBillingSnapshot({
    required this.accounts,
    required this.orphanEvents,
  });
}
