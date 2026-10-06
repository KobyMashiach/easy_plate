import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Whether the signed-in account is premium — no ads, no daily quotas.
///
/// Read from `entitlements/{uid}`, a document the client may read but never
/// write (see `firestore.rules`): it will be written by the RevenueCat webhook
/// once subscriptions exist, and until then by hand from the console. Keeping
/// it outside `users/{uid}` is deliberate — that document is owner-writable,
/// and an entitlement the owner can grant themselves is not one.
///
/// The document shape is `{premium: bool, premiumFrom?: Timestamp,
/// premiumUntil?: Timestamp}`. A past `premiumUntil` reads as not premium, so
/// a lapsed subscription needs no second write to take effect; a future
/// `premiumFrom` (a grant the administrator dated ahead) reads as not yet.
/// Either boundary passing while the app is open is caught by a timer, so a
/// week's gift ends on the hour it was given for, not at the next launch.
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
  Timer? _boundary;
  Map<String, dynamic>? _lastData;

  /// The verdict every gate reads. Live once the account's document has
  /// been read; until then the one remembered from the last run for this
  /// account (or the store's word), so a paying account is not treated as
  /// free for the first second after launch, and a fresh install with
  /// nothing remembered is.
  bool get isPremium => _premium || (!_resolved && (_remembered ?? false));

  /// True once the account's entitlement document has been read at least
  /// once this session. Until then nothing should be locked on the strength
  /// of the default `false`: a paying account would see the paywall for the
  /// first second after launch.
  bool get resolved => _resolved;
  bool _resolved = false;

  bool? _remembered;
  String? _uid;

  /// Completes once the account's document has been read (at once if it
  /// already was), or after [timeout] offline, so a caller can wait for the
  /// real verdict instead of acting on a default.
  Future<void> whenResolved({Duration timeout = const Duration(seconds: 4)}) {
    if (_resolved) return Future.value();
    final completer = Completer<void>();
    late final VoidCallback listener;
    listener = () {
      if (_resolved && !completer.isCompleted) {
        removeListener(listener);
        completer.complete();
      }
    };
    addListener(listener);
    Future<void>.delayed(timeout, () {
      if (!completer.isCompleted) {
        removeListener(listener);
        completer.complete();
      }
    });
    return completer.future;
  }

  static const _cacheBox = 'entitlementCacheBox';

  Future<void> _loadRemembered(String uid) async {
    try {
      final box = await Hive.openBox<bool>(_cacheBox);
      final value = box.get(uid);
      if (_uid == uid && !_resolved && value != _remembered) {
        _remembered = value;
        notifyListeners();
      }
    } catch (_) {
      // No Hive (tests): nothing remembered.
    }
  }

  Future<void> _remember(bool premium) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final box = await Hive.openBox<bool>(_cacheBox);
      await box.put(uid, premium);
    } catch (_) {}
  }

  /// Follows [uid]'s entitlement for as long as they are signed in. Safe to
  /// call without Firebase up (tests): the failure is logged and the account
  /// stays free.
  void watch(String uid) {
    clear();
    _uid = uid;
    unawaited(_loadRemembered(uid));
    try {
      _subscription = FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .snapshots()
          .listen(
            (snapshot) => _onData(snapshot.data()),
            onError: (Object e) => debugPrint('Entitlement watch failed: $e'),
          );
    } catch (e) {
      debugPrint('Entitlement watch unavailable: $e');
    }
  }

  /// Stops following and drops back to free. Called on sign-out; a premium
  /// flag must never outlive the account it belonged to.
  void _onData(Map<String, dynamic>? data) {
    _lastData = data;
    // The verdict is applied before anyone is told the document is in.
    final first = !_resolved;
    _resolved = true;
    _force = first;
    final now = DateTime.now();
    _setServer(resolvePremium(data, now));
    _boundary?.cancel();
    final next = nextChange(data, now);
    if (next != null) {
      // A Timer cannot hold more than a few weeks reliably; a far boundary
      // is simply re-armed on the way.
      final wait = next.difference(now);
      const cap = Duration(days: 7);
      _boundary = Timer(
        (wait > cap ? cap : wait) + const Duration(seconds: 1),
        () => _onData(_lastData),
      );
    }
  }

  void clear() {
    _boundary?.cancel();
    _boundary = null;
    _lastData = null;
    _subscription?.cancel();
    _subscription = null;
    _server = false;
    _store = false;
    _resolved = false;
    _remembered = null;
    _uid = null;
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
    final from = data['premiumFrom'];
    if (from is Timestamp && from.toDate().isAfter(now)) return false;
    final until = data['premiumUntil'];
    if (until is Timestamp) return until.toDate().isAfter(now);
    return true;
  }

  /// The next instant the verdict can flip on its own: the start of a grant
  /// dated ahead, or the end of a running one. Null when nothing is pending.
  @visibleForTesting
  static DateTime? nextChange(Map<String, dynamic>? data, DateTime now) {
    if (data == null || data['premium'] != true) return null;
    final from = data['premiumFrom'];
    if (from is Timestamp && from.toDate().isAfter(now)) return from.toDate();
    final until = data['premiumUntil'];
    if (until is Timestamp && until.toDate().isAfter(now)) {
      return until.toDate();
    }
    return null;
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

  /// Set when the next recompute must notify even for an unchanged verdict:
  /// the first snapshot flips `resolved`, which listeners act on.
  bool _force = false;

  void _recompute() {
    final premium = _server || _store;
    if (_resolved && premium != _remembered) {
      _remembered = premium;
      unawaited(_remember(premium));
    }
    final force = _force;
    _force = false;
    if (_premium == premium && !force) return;
    _premium = premium;
    notifyListeners();
  }
}
