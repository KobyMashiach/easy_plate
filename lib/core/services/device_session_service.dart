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

/// Another device asked this one, the holder, to sign out.
class ReleaseRequest {
  final String platform;
  final DateTime at;
  const ReleaseRequest({required this.platform, required this.at});
}

/// What became of a request to the holder.
enum ReleaseOutcome {
  /// The holder got a push and is being asked.
  notified,

  /// No push could reach it; it is asked the next time it opens the app.
  queued,

  /// Nobody holds the account any more: claim again.
  free,

  /// The request could not be sent.
  failed,
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
  bool _exempt = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _waitWatch;
  DateTime? _handledRequest;

  /// The server exempted this account from the one-device rule (the store
  /// review account): there is no record to follow.
  bool get exempt => _exempt;

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
  Future<SessionRefusal?> claim({String? pushToken}) async {
    if (!ApiConfig.usesProxy) return null;
    try {
      final response = await _http.post(
        '',
        data: {
          'action': 'claim',
          'deviceId': await deviceId(),
          'platform': platform,
          // Kept with the session, so a refused device can ask exactly this
          // one to sign out.
          'pushToken': ?pushToken,
        },
      );
      final data = response?.data;
      if (data is! Map) return null;
      if (data['ok'] == true) {
        _exempt = data['exempt'] == true;
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

  /// From a refused device: asks the holder to sign out, with the push's
  /// [title] and [body] already in the user's language.
  Future<ReleaseOutcome> requestRelease({
    required String title,
    required String body,
    String? pushToken,
  }) async {
    if (!ApiConfig.usesProxy) return ReleaseOutcome.failed;
    try {
      final response = await _http.post(
        '',
        data: {
          'action': 'requestRelease',
          'deviceId': await deviceId(),
          'platform': platform,
          'title': title,
          'body': body,
          'pushToken': ?pushToken,
        },
      );
      final data = response?.data;
      if (data is! Map || data['ok'] != true) return ReleaseOutcome.failed;
      if (data['free'] == true) return ReleaseOutcome.free;
      return data['notified'] == true
          ? ReleaseOutcome.notified
          : ReleaseOutcome.queued;
    } catch (e) {
      debugPrint('Release request failed: $e');
      return ReleaseOutcome.failed;
    }
  }

  /// From the holder: stays signed in, and the asker is told.
  Future<void> declineRelease() async {
    if (!ApiConfig.usesProxy) return;
    try {
      await _http.post(
        '',
        data: {'action': 'declineRelease', 'deviceId': await deviceId()},
      );
    } catch (e) {
      debugPrint('Release decline failed: $e');
    }
  }

  /// From a refused device: follows the record so the gate can move on by
  /// itself the moment the holder signs out ([onFree]), or say the holder
  /// declined ([onDeclined]).
  void waitForRelease(
    String uid, {
    required VoidCallback onFree,
    required VoidCallback onDeclined,
  }) {
    stopWaiting();
    if (!ApiConfig.usesProxy && _firestore == null) return;
    final db = _firestore ?? FirebaseFirestore.instance;
    _waitWatch = db.doc('sessions/$uid').snapshots().listen((snapshot) async {
      final data = snapshot.data();
      final expires = (data?['expiresAt'] as Timestamp?)?.toDate();
      if (!snapshot.exists ||
          (expires != null && !expires.isAfter(DateTime.now()))) {
        onFree();
        return;
      }
      final request = data?['releaseRequest'];
      if (request is Map &&
          request['deviceId'] == await deviceId() &&
          request['declinedAt'] != null) {
        onDeclined();
      }
    }, onError: (Object e) => debugPrint('Release wait failed: $e'));
  }

  void stopWaiting() {
    _waitWatch?.cancel();
    _waitWatch = null;
  }

  /// Pure: the request on a record this device holds that it has not shown
  /// yet, or null.
  @visibleForTesting
  static ReleaseRequest? pendingRequest(
    Map<String, dynamic>? data, {
    required String mine,
    required DateTime? handled,
  }) {
    if (data == null || data['deviceId'] != mine) return null;
    final request = data['releaseRequest'];
    if (request is! Map || request['declinedAt'] != null) return null;
    if (request['deviceId'] == mine) return null;
    final at = (request['at'] as Timestamp?)?.toDate();
    if (at == null || (handled != null && !at.isAfter(handled))) return null;
    // An old request is not worth a dialog.
    if (DateTime.now().difference(at) > const Duration(minutes: 30)) {
      return null;
    }
    return ReleaseRequest(
      platform: (request['platform'] as String?) ?? 'other',
      at: at,
    );
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
  void watch(
    String uid,
    void Function(SessionEnd end) onEnd, {
    void Function(ReleaseRequest request)? onReleaseRequest,
  }) {
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
        if (end != null) {
          onEnd(end);
          return;
        }
        final request = pendingRequest(
          snapshot.data(),
          mine: mine,
          handled: _handledRequest,
        );
        if (request != null && onReleaseRequest != null) {
          _handledRequest = request.at;
          onReleaseRequest(request);
        }
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
    _exempt = false;
    stopWaiting();
    _handledRequest = null;
  }
}
