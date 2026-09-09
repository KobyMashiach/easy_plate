import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Whether the signed-in account is premium — no ads, no daily quotas.
///
/// Read from `entitlements/{uid}`, a document the client may read but never
/// write (see `firestore.rules`): it will be written by the RevenueCat webhook
/// once subscriptions exist, and until then by hand from the console. Keeping
/// it outside `users/{uid}` is deliberate — that document is owner-writable,
/// and an entitlement the owner can grant themselves is not one.
///
/// The document shape is `{premium: bool, premiumUntil?: Timestamp}`. A past
/// `premiumUntil` reads as not premium, so a lapsed subscription needs no
/// second write to take effect.
///
/// A second source is the RevenueCat SDK on this device (see
/// `PurchasesService`), which knows about a purchase the instant it completes,
/// seconds before the webhook has written the document. Premium is the OR of
/// the two: either alone unlocks, and each expires on its own terms.
class EntitlementService extends ChangeNotifier {
  static final EntitlementService _instance = EntitlementService._internal();
  factory EntitlementService() => _instance;
  EntitlementService._internal();

  static const collection = 'entitlements';

  bool _premium = false;
  bool _server = false;
  bool _store = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  bool get isPremium => _premium;

  /// Follows [uid]'s entitlement for as long as they are signed in. Safe to
  /// call without Firebase up (tests): the failure is logged and the account
  /// stays free.
  void watch(String uid) {
    clear();
    try {
      _subscription = FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .snapshots()
          .listen(
            (snapshot) => _setServer(resolvePremium(snapshot.data(), DateTime.now())),
            onError: (Object e) => debugPrint('Entitlement watch failed: $e'),
          );
    } catch (e) {
      debugPrint('Entitlement watch unavailable: $e');
    }
  }

  /// Stops following and drops back to free. Called on sign-out; a premium
  /// flag must never outlive the account it belonged to.
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _server = false;
    _store = false;
    _recompute();
  }

  /// What the store SDK reports for the signed-in account. Called on every
  /// `CustomerInfo` update, so it goes both ways: a purchase turns it on, an
  /// expiry the SDK notices turns it off — and the server flag still holds
  /// premium for as long as the document says so.
  void setFromStore(bool premium) {
    _store = premium;
    _recompute();
  }

  @visibleForTesting
  static bool resolvePremium(Map<String, dynamic>? data, DateTime now) {
    if (data == null || data['premium'] != true) return false;
    final until = data['premiumUntil'];
    if (until is Timestamp) return until.toDate().isAfter(now);
    return true;
  }

  @visibleForTesting
  void setForTest(bool premium) {
    _server = premium;
    _store = false;
    _recompute();
  }

  void _setServer(bool premium) {
    _server = premium;
    _recompute();
  }

  void _recompute() {
    final premium = _server || _store;
    if (_premium == premium) return;
    _premium = premium;
    notifyListeners();
  }
}
