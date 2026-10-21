import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../user_profile/domain/entities/user_permission.dart';

import '../../domain/entities/billing_entities.dart';

abstract class AdminBillingRemoteDataSource {
  Future<AdminBillingSnapshot> load();
  Future<void> setPremium(
    String uid,
    bool premium, {
    DateTime? from,
    DateTime? until,
  });
  Future<void> releaseLock(String uid);
}

/// Reads the three collections the rules open to the administrator alone —
/// `users`, `entitlements`, `purchase_events` — and joins them by uid.
class AdminBillingFirestoreDataSource implements AdminBillingRemoteDataSource {
  static const usersCollection = 'users';
  static const entitlementsCollection = 'entitlements';
  static const eventsCollection = 'purchase_events';
  static const statusCollection = 'account_status';

  /// The admin reads are capped, not paged: every account is held in memory
  /// and these sit far above what the app has. The dashboard bounds its
  /// reads by the same two numbers, so its totals and this tab's list cover
  /// the same documents; past them both go silently short, and the next
  /// step is paging, not a bigger number.
  static const maxAccountDocs = 5000;
  static const maxPurchaseEvents = 2000;

  final FirebaseFirestore _firestore;

  AdminBillingFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AdminBillingSnapshot> load() async {
    final results = await Future.wait([
      _firestore.collection(usersCollection).limit(maxAccountDocs).get(),
      _firestore.collection(entitlementsCollection).limit(maxAccountDocs).get(),
      _firestore
          .collection(eventsCollection)
          .orderBy('eventAt', descending: true)
          .limit(maxPurchaseEvents)
          .get(),
      _firestore.collection(statusCollection).limit(maxAccountDocs).get(),
    ]);
    final users = results[0].docs;
    final entitlements = {for (final d in results[1].docs) d.id: d.data()};
    final events = results[2].docs.map(_toEvent).toList();
    final statuses = {for (final d in results[3].docs) d.id: d.data()};

    final byUid = <String, List<PurchaseEventEntity>>{};
    final orphans = <PurchaseEventEntity>[];
    for (final e in events) {
      final uid = e.uid;
      if (uid == null) {
        orphans.add(e);
      } else {
        byUid.putIfAbsent(uid, () => []).add(e);
      }
    }

    // Every profile, plus any uid that has an entitlement or an event but no
    // profile document (deleted account, or one that never finished sign-up).
    final uids = <String>{
      for (final d in users) d.id,
      ...entitlements.keys,
      ...byUid.keys,
    };
    final profiles = {for (final d in users) d.id: d.data()};
    final now = DateTime.now();
    final accounts = [
      for (final uid in uids)
        toAccount(
          uid,
          profiles[uid],
          entitlements[uid],
          byUid[uid] ?? const [],
          statuses[uid],
          now,
        ),
    ];
    accounts.sort(_byInterest);
    return AdminBillingSnapshot(
      accounts: accounts,
      orphanEvents: orphans,
      accountsCap:
          [results[0], results[1], results[3]].any(
            (r) => r.docs.length >= maxAccountDocs,
          )
          ? maxAccountDocs
          : null,
      eventsCap: results[2].docs.length >= maxPurchaseEvents
          ? maxPurchaseEvents
          : null,
    );
  }

  /// Problems first, then paying accounts, then the rest — by most recent
  /// event, then name.
  static int _byInterest(BillingAccountEntity a, BillingAccountEntity b) {
    final now = DateTime.now();
    int rank(BillingAccountEntity x) {
      if (x.hasProblem(now)) return 0;
      if (x.premium) return 1;
      if (x.hasEvents) return 2;
      return 3;
    }

    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final at = (b.lastEventAt ?? DateTime(0)).compareTo(
      a.lastEventAt ?? DateTime(0),
    );
    if (at != 0) return at;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  @override
  Future<void> setPremium(
    String uid,
    bool premium, {
    DateTime? from,
    DateTime? until,
  }) {
    return _firestore.collection(entitlementsCollection).doc(uid).set({
      'premium': premium,
      'premiumFrom': premium && from != null ? Timestamp.fromDate(from) : null,
      'premiumUntil': premium && until != null
          ? Timestamp.fromDate(until)
          : null,
      'adminLock': true,
      'source': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> releaseLock(String uid) {
    return _firestore.collection(entitlementsCollection).doc(uid).set({
      'adminLock': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // users/{uid} is written by its owner: a field of the wrong type there
  // must cost that one value, not the whole list for the administrator.
  static String? _str(Object? v) => v is String ? v : null;
  static DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;

  @visibleForTesting
  static BillingAccountEntity toAccount(
    String uid,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? entitlement,
    List<PurchaseEventEntity> events,
    Map<String, dynamic>? status,
    DateTime now,
  ) {
    final until = (entitlement?['premiumUntil'] as Timestamp?)?.toDate();
    final from = (entitlement?['premiumFrom'] as Timestamp?)?.toDate();
    final premium =
        entitlement?['premium'] == true &&
        (from == null || !from.isAfter(now)) &&
        (until == null || until.isAfter(now));
    final lastEventAt = entitlement?['lastEventAt'];
    return BillingAccountEntity(
      uid: uid,
      name: _str(profile?['fullName'])?.trim().isNotEmpty == true
          ? _str(profile!['fullName'])!.trim()
          : uid,
      email: _str(profile?['email']),
      phone: _str(profile?['phoneNumber']),
      premium: premium,
      premiumUntil: until,
      premiumFrom: from,
      grantPending:
          entitlement?['premium'] == true && from != null && from.isAfter(now),
      source: (entitlement?['source'] as String?) ?? '',
      adminLock: entitlement?['adminLock'] == true,
      lastEventType: (entitlement?['lastEventType'] as String?) ?? '',
      lastEventAt: events.isNotEmpty
          ? events.first.eventAt
          : lastEventAt is num
          ? DateTime.fromMillisecondsSinceEpoch(lastEventAt.toInt())
          : null,
      productId: (entitlement?['productId'] as String?) ?? '',
      store: (entitlement?['store'] as String?) ?? '',
      events: events,
      disabled: status?['disabled'] == true,
      blockMessage: (status?['message'] as String?) ?? '',
      platform: _str(profile?['platform']) ?? '',
      appVersion: _str(profile?['appVersion']) ?? '',
      lastSeenAt: _time(profile?['lastSeenAt']),
      createdAt: _time(profile?['createdAt']),
      hasPushToken: _str(profile?['pushToken'])?.isNotEmpty == true,
      permission: UserPermission.fromName(profile?['permission']),
    );
  }

  PurchaseEventEntity _toEvent(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final uid = data['uid'];
    return PurchaseEventEntity(
      id: doc.id,
      uid: uid is String && uid.isNotEmpty ? uid : null,
      appUserId: (data['appUserId'] as String?) ?? '',
      type: (data['type'] as String?) ?? '',
      productId: (data['productId'] as String?) ?? '',
      store: (data['store'] as String?) ?? '',
      entitlementIds: [
        for (final id in (data['entitlementIds'] as List?) ?? const [])
          id.toString(),
      ],
      grantsPremium: data['grantsPremium'] == true,
      environment: (data['environment'] as String?) ?? '',
      eventAt: (data['eventAt'] as Timestamp?)?.toDate() ?? DateTime(0),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      price: (data['price'] as num?)?.toDouble(),
      currency: (data['currency'] as String?) ?? '',
    );
  }
}
