import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// A clock the user cannot wind.
///
/// The daily quotas reset at local midnight, and "local" is what makes the
/// phone's own clock the obvious way around them: set the date forward, get a
/// fresh allowance, set it back. This class takes the *time* from a server and
/// the *timezone* from the device, so the reset still lands at the user's
/// midnight while the date itself is not theirs to choose.
///
/// The server moment is anchored to a [Stopwatch] rather than to the wall
/// clock: a stopwatch counts monotonic ticks and does not notice the date
/// being changed under it. Until the first sync lands — offline, or in the
/// first second of a launch — the device time is used as-is; every unlock
/// needs the network anyway, so there is no allowance to be had offline.
class TrustedClock {
  static final TrustedClock _instance = TrustedClock._internal();
  factory TrustedClock() => _instance;
  TrustedClock._internal();

  /// Any Google endpoint will do: the answer is the `Date` header, which is
  /// set by the server regardless of status.
  static const _timeSource = 'https://www.googleapis.com/';

  DateTime? _serverUtcAtSync;
  final Stopwatch _sinceSync = Stopwatch();

  bool get isSynced => _serverUtcAtSync != null;

  /// The current moment, in the device's timezone, on the server's clock when
  /// one has been read.
  DateTime now() {
    final anchor = _serverUtcAtSync;
    if (anchor == null) return DateTime.now();
    return anchor.add(_sinceSync.elapsed).toLocal();
  }

  /// Today's key, `yyyy-MM-dd`, in the device's timezone.
  String get today => dayKeyOf(now());

  static String dayKeyOf(DateTime local) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  /// Re-reads the server time. Called on launch and on every resume; a phone
  /// that sat in a drawer through midnight comes back with the right day.
  Future<void> sync({Future<DateTime?> Function()? fetch}) async {
    final serverUtc = await (fetch ?? _fetchServerTime)();
    if (serverUtc == null) return;
    adopt(serverUtc);
  }

  /// Anchors the clock to [serverUtc] as of right now.
  @visibleForTesting
  void adopt(DateTime serverUtc) {
    _serverUtcAtSync = serverUtc.toUtc();
    _sinceSync
      ..reset()
      ..start();
  }

  static Future<DateTime?> _fetchServerTime() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.headUrl(Uri.parse(_timeSource));
      final response = await request.close().timeout(const Duration(seconds: 5));
      final header = response.headers.value(HttpHeaders.dateHeader);
      // Drain, or the socket stays open until the client is garbage collected.
      unawaited(response.drain<void>().catchError((_) {}));
      if (header == null) return null;
      return HttpDate.parse(header);
    } catch (e) {
      debugPrint('Trusted clock sync failed: $e');
      return null;
    } finally {
      client.close();
    }
  }

  @visibleForTesting
  void resetForTest() {
    _serverUtcAtSync = null;
    _sinceSync
      ..stop()
      ..reset();
  }
}
