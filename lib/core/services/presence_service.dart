import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Tells the server, while the app is open, that the account is in use.
///
/// Every [interval] the signed-in account's document gets `online: true`
/// and a fresh `lastSeenAt`; going to the background, or signing out,
/// writes `online: false`. The web console reads the two together: an
/// account is "online" when the flag is set and the stamp is recent (see
/// [isOnline]) — the flag alone would keep showing a phone that died with
/// the app open, the stamp alone cannot tell a backgrounded app from one
/// still in hand.
///
/// The interval is the console's `presence_heartbeat_seconds`; zero switches
/// the report off entirely. Writes are never awaited by the callers and
/// never throw: presence is a convenience for the administrator, not
/// something the user should ever wait on.
class PresenceService {
  static final PresenceService _instance = PresenceService._();
  factory PresenceService() => _instance;
  PresenceService._();

  /// How far past its last beat a report still counts as "online". Twice
  /// the interval plus a little, so one missed write (a flaky network, the
  /// phone asleep for a moment) does not flicker the account offline.
  static Duration onlineWindow(int heartbeatSeconds) =>
      Duration(seconds: heartbeatSeconds * 2 + 30);

  /// Pure: whether a document's `online` flag and `lastSeenAt` stamp mean
  /// the account is in use right now. Mirrors what the web console computes.
  static bool isOnline({
    required bool? online,
    required DateTime? lastSeenAt,
    required DateTime now,
    required int heartbeatSeconds,
  }) {
    if (online != true || lastSeenAt == null || heartbeatSeconds <= 0) {
      return false;
    }
    return now.difference(lastSeenAt) <= onlineWindow(heartbeatSeconds);
  }

  FirebaseFirestore? _firestore;
  int? _intervalOverride;
  Timer? _timer;
  String? _uid;
  bool _foreground = true;

  /// Tests only: swap the database and pin the interval.
  @visibleForTesting
  void configure({FirebaseFirestore? firestore, int? intervalSeconds}) {
    _firestore = firestore;
    _intervalOverride = intervalSeconds;
  }

  /// The account currently reporting, or null.
  String? get uid => _uid;

  /// Seconds between beats; zero means presence is switched off.
  int get interval {
    if (_intervalOverride case final seconds?) return seconds;
    try {
      return FirebaseService().remoteInt(FirebaseService.presenceHeartbeatKey);
    } catch (_) {
      return 0;
    }
  }

  /// Starts reporting for [uid]. Called once the account is through the
  /// gate; a half-made account never reports.
  void start(String uid) {
    if (_uid == uid && _timer != null) return;
    _timer?.cancel();
    _uid = uid;
    if (_foreground) _beat();
  }

  /// Stops reporting and marks the account offline. Must run while the
  /// account is still signed in — the rules let only the owner write the
  /// document — which is why the sign-out path awaits it before Firebase
  /// drops the user.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    final uid = _uid;
    _uid = null;
    if (uid != null) await _write(uid, online: false);
  }

  /// The app moved to the foreground (true) or away from it (false).
  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    final uid = _uid;
    if (uid == null) return;
    if (foreground) {
      _beat();
    } else {
      _timer?.cancel();
      _timer = null;
      unawaited(_write(uid, online: false));
    }
  }

  void _beat() {
    _timer?.cancel();
    _timer = null;
    final uid = _uid;
    if (uid == null || !_foreground) return;
    final seconds = interval;
    if (seconds <= 0) return;
    unawaited(_write(uid, online: true));
    _timer = Timer(Duration(seconds: seconds), _beat);
  }

  Future<void> _write(String uid, {required bool online}) async {
    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      await db.collection('users').doc(uid).set({
        'online': online,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Presence write failed: $e');
    }
  }

  @visibleForTesting
  void resetForTest() {
    _timer?.cancel();
    _timer = null;
    _uid = null;
    _foreground = true;
    _firestore = null;
    _intervalOverride = null;
  }
}
