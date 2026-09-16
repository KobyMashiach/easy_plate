import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/billing_entities.dart';

abstract class AdminBillingRemoteDataSource {
  Future<AdminBillingSnapshot> load();
  Future<void> setPremium(String uid, bool premium);
  Future<void> releaseLock(String uid);
}

/// Reads the three collections the rules open to the administrator alone —
/// `users`, `entitlements`, `purchase_events` — and joins them by uid.
class AdminBillingFirestoreDataSource implements AdminBillingRemoteDataSource {
  static const usersCollection = 'users';
  static const entitlementsCollection = 'entitlements';
  static const eventsCollection = 'purchase_events';

  final FirebaseFirestore _firestore;

  AdminBillingFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AdminBillingSnapshot> load() async {
    final results = await Future.wait([
      _firestore.collection(usersCollection).limit(2000).get(),
      _firestore.collection(entitlementsCollection).limit(2000).get(),
      _firestore
          .collection(eventsCollection)
          .orderBy('eventAt', descending: true)
          .limit(1000)
          .get(),
    ]);
    final users = results[0].docs;
    final entitlements = {for (final d in results[1].docs) d.id: d.data()};
    final events = results[2].docs.map(_toEvent).toList();

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
        _toAccount(
          uid,
          profiles[uid],
          entitlements[uid],
          byUid[uid] ?? const [],
          now,
        ),
    ];
    accounts.sort(_byInterest);
    return AdminBillingSnapshot(accounts: accounts, orphanEvents: orphans);
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
  Future<void> setPremium(String uid, bool premium) {
    return _firestore.collection(entitlementsCollection).doc(uid).set({
      'premium': premium,
      'premiumUntil': null,
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

  BillingAccountEntity _toAccount(
    String uid,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? entitlement,
    List<PurchaseEventEntity> events,
    DateTime now,
  ) {
    final until = (entitlement?['premiumUntil'] as Timestamp?)?.toDate();
    final premium =
        entitlement?['premium'] == true &&
        (until == null || until.isAfter(now));
    final lastEventAt = entitlement?['lastEventAt'];
    return BillingAccountEntity(
      uid: uid,
      name: (profile?['fullName'] as String?)?.trim().isNotEmpty == true
          ? (profile!['fullName'] as String).trim()
          : uid,
      email: profile?['email'] as String?,
      phone: profile?['phoneNumber'] as String?,
      premium: premium,
      premiumUntil: until,
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
