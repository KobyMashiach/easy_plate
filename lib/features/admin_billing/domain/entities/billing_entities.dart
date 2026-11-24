import '../../../user_profile/domain/entities/user_permission.dart';

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

  /// `TRIAL`, `NORMAL`, `INTRO`… as the store reported it; blank when unknown.
  final String periodType;

  /// For a grant or removal made by hand: the administrator's email.
  final String by;

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
    this.periodType = '',
    this.by = '',
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

  /// A grant dated ahead: [premium] is still false, [grantPending] true.
  final DateTime? premiumFrom;
  final bool grantPending;

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

  /// Switched off by the administrator, with the reason shown to them.
  final bool disabled;
  final String blockMessage;

  /// Where the account was last seen: `ios`, `android`, or blank for an
  /// account that has not signed in since this was recorded.
  final String platform;
  final String appVersion;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final bool hasPushToken;

  /// `users/{uid}.permission`: admin (console-set), superuser (granted
  /// from the admin screens) or user.
  final UserPermission permission;

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
    this.premiumFrom,
    this.grantPending = false,
    this.disabled = false,
    this.blockMessage = '',
    this.platform = '',
    this.appVersion = '',
    this.lastSeenAt,
    this.createdAt,
    this.hasPushToken = false,
    this.permission = UserPermission.user,
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

  /// The cap a read came back at, or null when it came back short of it:
  /// past the cap the list is partial, and the tab says so.
  final int? accountsCap;
  final int? eventsCap;

  const AdminBillingSnapshot({
    required this.accounts,
    required this.orphanEvents,
    this.accountsCap,
    this.eventsCap,
  });
}

/// What a broadcast reached, as the function reported it.
class BroadcastResult {
  final int items;
  final int sent;
  final int failed;

  const BroadcastResult({
    required this.items,
    required this.sent,
    required this.failed,
  });
}

/// What one subscription event meant for the account, in plain words.
enum SubscriptionStep {
  joined,
  trial,
  renewed,
  cancelled,
  uncancelled,
  ended,
  billingIssue,
  changedPlan,
  oneTime,
  paused,
  transferred,
  refunded,
  adminGrant,
  adminRevoke,
  other,
}

class SubscriptionHistoryEntry {
  final PurchaseEventEntity event;
  final SubscriptionStep step;
  const SubscriptionHistoryEntry(this.event, this.step);

  DateTime get at => event.eventAt;

  /// Until when the step leaves the account premium: the paid period after
  /// a cancellation, a gift's last day.
  DateTime? get until => event.expiresAt;
}

/// An account's subscription told as a story: when it joined Premium, when
/// it cancelled, when it ended — from the purchase_events rows, store and
/// web providers alike, plus the grants made by hand. The console's
/// `subscriptionHistory` (landing/admin/js) applies the same rules.
class SubscriptionHistory {
  /// Oldest first.
  final List<SubscriptionHistoryEntry> entries;
  const SubscriptionHistory(this.entries);

  static const _byType = {
    'RENEWAL': SubscriptionStep.renewed,
    'CANCELLATION': SubscriptionStep.cancelled,
    'UNCANCELLATION': SubscriptionStep.uncancelled,
    'EXPIRATION': SubscriptionStep.ended,
    'BILLING_ISSUE': SubscriptionStep.billingIssue,
    'PRODUCT_CHANGE': SubscriptionStep.changedPlan,
    'NON_RENEWING_PURCHASE': SubscriptionStep.oneTime,
    'SUBSCRIPTION_PAUSED': SubscriptionStep.paused,
    'TRANSFER': SubscriptionStep.transferred,
    'REFUND': SubscriptionStep.refunded,
    'ADMIN_GRANT': SubscriptionStep.adminGrant,
    'ADMIN_REVOKE': SubscriptionStep.adminRevoke,
  };

  factory SubscriptionHistory.of(Iterable<PurchaseEventEntity> events) {
    final sorted = [...events]..sort((a, b) => a.eventAt.compareTo(b.eventAt));
    final out = <SubscriptionHistoryEntry>[];
    var active = false;
    for (final e in sorted) {
      final step = _stepOf(e, active);
      out.add(SubscriptionHistoryEntry(e, step));
      switch (step) {
        case SubscriptionStep.joined ||
            SubscriptionStep.trial ||
            SubscriptionStep.renewed ||
            SubscriptionStep.uncancelled ||
            SubscriptionStep.changedPlan ||
            SubscriptionStep.oneTime ||
            SubscriptionStep.adminGrant:
          active = true;
        case SubscriptionStep.ended ||
            SubscriptionStep.refunded ||
            SubscriptionStep.adminRevoke:
          active = false;
        default:
      }
    }
    return SubscriptionHistory(out);
  }

  static SubscriptionStep _stepOf(PurchaseEventEntity e, bool active) {
    final type = e.type.toUpperCase();
    if (type == 'INITIAL_PURCHASE') {
      return e.periodType.toUpperCase() == 'TRIAL'
          ? SubscriptionStep.trial
          : SubscriptionStep.joined;
    }
    final known = _byType[type];
    if (known != null) return known;
    // The web providers name their events their own way (payplus.…,
    // subscription.…, Stripe's): read the words.
    final lower = e.type.toLowerCase();
    if (lower.contains('refund')) return SubscriptionStep.refunded;
    if (lower.contains('cancel')) return SubscriptionStep.cancelled;
    if (lower.contains('fail') || lower.contains('past_due')) {
      return SubscriptionStep.billingIssue;
    }
    if (lower.contains('expire') ||
        lower.contains('ended') ||
        lower.contains('deleted')) {
      return SubscriptionStep.ended;
    }
    if (e.grantsPremium) {
      return active ? SubscriptionStep.renewed : SubscriptionStep.joined;
    }
    return SubscriptionStep.other;
  }

  bool get isEmpty => entries.isEmpty;

  DateTime? _first(Set<SubscriptionStep> steps) =>
      entries.where((e) => steps.contains(e.step)).firstOrNull?.at;
  DateTime? _last(Set<SubscriptionStep> steps) =>
      entries.where((e) => steps.contains(e.step)).lastOrNull?.at;

  /// The first time the account became Premium, by payment, trial or gift.
  DateTime? get joinedAt => _first(const {
    SubscriptionStep.joined,
    SubscriptionStep.trial,
    SubscriptionStep.oneTime,
    SubscriptionStep.adminGrant,
  });

  DateTime? get lastCancelledAt => _last(const {SubscriptionStep.cancelled});

  DateTime? get lastEndedAt => _last(const {
    SubscriptionStep.ended,
    SubscriptionStep.refunded,
    SubscriptionStep.adminRevoke,
  });

  static const _paid = {
    SubscriptionStep.joined,
    SubscriptionStep.renewed,
    SubscriptionStep.oneTime,
    SubscriptionStep.changedPlan,
    SubscriptionStep.uncancelled,
  };

  /// Store payments, not gifts or trials; a missing price still counts
  /// (some providers leave it out), a price of zero does not.
  Iterable<SubscriptionHistoryEntry> get payments => entries.where(
    (e) => _paid.contains(e.step) && e.event.price != 0,
  );

  DateTime? get firstPaidAt => payments.firstOrNull?.at;

  SubscriptionHistoryEntry? get lastPayment => payments.lastOrNull;

  int get renewals =>
      entries.where((e) => e.step == SubscriptionStep.renewed).length;

  /// Newest first, for a list.
  List<SubscriptionHistoryEntry> get newestFirst => entries.reversed.toList();
}
