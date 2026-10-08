import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../constants/api_config.dart';
import '../network/ai_auth_header.dart';
import '../network/http_calls.dart';
import 'device_locale_store.dart';

/// Why this device may no longer hold the account's session.
enum SessionEnd {
  /// Another device signed in while this one was out, or the administrator
  /// released this one; the session document now names someone else.
  otherDevice,

  /// The month ran out, or the record was removed.
  expired,
}

/// The other device holding the account, as the server described it.
class SessionRefusal {
  final String platform;
  final DateTime? since;
  const SessionRefusal({required this.platform, this.since});
}

/// One device per account, a month at a time.
///
/// The device carries an id minted once per install (device-wide Hive box,
/// not the per-account one, so it survives sign-outs). On sign-in the
/// account's session is claimed through the `sessions` function; refused
/// when another device holds a live one. While signed in the session
/// document is watched, so a release or an expiry elsewhere signs this
/// device out at once rather than when its token happens to stop renewing.
class DeviceSessionService {
  static final DeviceSessionService _instance = DeviceSessionService._();
  factory DeviceSessionService() => _instance;
  DeviceSessionService._();

  static const _deviceIdKey = 'device_id';

  HttpCalls? _calls;
  FirebaseFirestore? _firestore;
  String? _deviceId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _watch;
  DateTime? _expiresAt;

  /// Tests only: swap the network and the database.
  @visibleForTesting
  void configure({
    HttpCalls? calls,
    FirebaseFirestore? firestore,
    String? deviceId,
  }) {
    _calls = calls;
    _firestore = firestore;
    _deviceId = deviceId;
  }

  HttpCalls get _http => _calls ??= HttpCalls(
    baseUrl: ApiConfig.sessionsUrl,
    headerProvider: aiProxyAuthHeader,
  );

  String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    _ => 'other',
  };

  /// When this device's session runs out, as the server said; null when
  /// unknown or when sessions never expire.
  DateTime? get expiresAt => _expiresAt;

  Future<String> deviceId() async {
    if (_deviceId case final id?) return id;
    try {
      final box = await Hive.openBox<String>(DeviceLocaleStore.boxName);
      final stored = box.get(_deviceIdKey);
      if (stored != null && stored.isNotEmpty) return _deviceId = stored;
      final minted = const Uuid().v4();
      await box.put(_deviceIdKey, minted);
      return _deviceId = minted;
    } catch (e) {
      // No box: a per-process id still makes the session work for this run.
      debugPrint('Device id store failed: $e');
      return _deviceId = const Uuid().v4();
    }
  }

  /// Asks the server for the account's session. Null when this device holds
  /// it; the refusal when another device does. A network failure counts as
  /// held: an offline phone must still open the account it already has.
  Future<SessionRefusal?> claim() async {
    if (!ApiConfig.usesProxy) return null;
    try {
      final response = await _http.post(
        '',
        data: {
          'action': 'claim',
          'deviceId': await deviceId(),
          'platform': platform,
        },
      );
      final data = response?.data;
      if (data is! Map) return null;
      if (data['ok'] == true) {
        final expires = data['expiresAt'];
        _expiresAt = expires is num
            ? DateTime.fromMillisecondsSinceEpoch(expires.toInt())
            : null;
        return null;
      }
      final refusal = data['refusal'];
      if (refusal is! Map) return null;
      final since = refusal['since'];
      return SessionRefusal(
        platform: (refusal['platform'] as String?) ?? 'other',
        since: since is num
            ? DateTime.fromMillisecondsSinceEpoch(since.toInt())
            : null,
      );
    } catch (e) {
      debugPrint('Session claim failed: $e');
      return null;
    }
  }

  /// Frees the account's session if this device holds it. Best effort,
  /// run before the Firebase sign-out so the token is still valid.
  Future<void> release() async {
    if (!ApiConfig.usesProxy) return;
    try {
      await _http.post(
        '',
        data: {
          'action': 'release',
          'deviceId': await deviceId(),
        },
      );
    } catch (e) {
      debugPrint('Session release failed: $e');
    }
    _expiresAt = null;
  }

  /// Follows the account's session document and reports the moment this
  /// device stops being its holder. A document that is missing right after
  /// a successful claim is the write still landing, so only a document that
  /// names another device, or one that disappears later, counts.
  void watch(String uid, void Function(SessionEnd end) onEnd) {
    unwatch();
    // No proxy, no session service (and in tests, no Firestore to open).
    if (!ApiConfig.usesProxy && _firestore == null) return;
    final db = _firestore ?? FirebaseFirestore.instance;
    var seen = false;
    _watch = db.doc('sessions/$uid').snapshots().listen(
      (snapshot) async {
        final mine = await deviceId();
        final end = evaluate(
          exists: snapshot.exists,
          deviceId: snapshot.data()?['deviceId'] as String?,
          expiresAt: (snapshot.data()?['expiresAt'] as Timestamp?)?.toDate(),
          mine: mine,
          now: DateTime.now(),
          seenBefore: seen,
        );
        seen = seen || snapshot.exists;
        if (end != null) onEnd(end);
      },
      onError: (Object e) => debugPrint('Session watch failed: $e'),
    );
  }

  /// Pure: whether the document means this device is out, and why.
  static SessionEnd? evaluate({
    required bool exists,
    required String? deviceId,
    required DateTime? expiresAt,
    required String mine,
    required DateTime now,
    required bool seenBefore,
  }) {
    if (!exists) return seenBefore ? SessionEnd.expired : null;
    if (deviceId != null && deviceId != mine) return SessionEnd.otherDevice;
    if (expiresAt != null && !expiresAt.isAfter(now)) return SessionEnd.expired;
    return null;
  }

  /// Whether the month has run out by this device's own clock — checked on
  /// resume, so an app left open past the day the server revoked it does
  /// not wait for the next token refresh to find out.
  bool get isExpired =>
      _expiresAt != null && !_expiresAt!.isAfter(DateTime.now());

  void unwatch() {
    _watch?.cancel();
    _watch = null;
  }

  @visibleForTesting
  void resetForTest() {
    unwatch();
    _calls = null;
    _firestore = null;
    _deviceId = null;
    _expiresAt = null;
  }
}
