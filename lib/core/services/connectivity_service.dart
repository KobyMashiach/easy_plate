import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks live network reachability so repositories can decide
/// local-only vs. network-backed reads without hitting the platform
/// channel on every call.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _hasConnection = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get hasConnection => _hasConnection;

  Future<void> initialize() async {
    // Awaited by `main` before the first frame: a platform channel that
    // fails must not take the launch down with it. Without an answer the
    // app assumes it is online, which is what every caller did before.
    try {
      final results = await Connectivity().checkConnectivity();
      _hasConnection = _isConnected(results);
      _subscription = Connectivity().onConnectivityChanged.listen(
        (results) => _hasConnection = _isConnected(results),
        onError: (Object e) => debugPrint('Connectivity stream failed: $e'),
      );
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
