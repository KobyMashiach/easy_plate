import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app's Dart side alive while a cook-mode timer runs in the
/// background (Android only). Without it the system freezes the process a
/// few seconds after the app leaves the screen, and the timer notifications
/// stop moving. The service's own notification is a one-line summary; the
/// per-timer cards with their bars are the session service's and keep
/// updating because of this one.
class CookForegroundService {
  static final CookForegroundService _instance =
      CookForegroundService._internal();
  factory CookForegroundService() => _instance;
  CookForegroundService._internal();

  /// Outside the session service's 9000–10999 timer ids.
  static const _serviceId = 12000;
  bool _initialized = false;
  bool _running = false;
  bool _permissionAsked = false;

  /// After a failed start, the next attempt waits this long: a denied
  /// permission or a background start the OS refuses must not become a
  /// failed platform call every second.
  static const _retryAfter = Duration(seconds: 60);
  DateTime? _failedAt;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _init() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'cook_service',
        channelName: 'Cook mode',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // The main isolate does the work; the task isolate only exists so
        // the service has something to run.
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: false,
        autoRunOnBoot: false,
        allowAutoRestart: false,
      ),
    );
    _initialized = true;
  }

  /// Every start, update and stop runs after the one before it: a stop
  /// landing in the middle of a start, or a sync in the middle of a stop,
  /// would leave the Dart flag and the OS service disagreeing.
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final next = _queue.then((_) => op());
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  /// Starts the service, or refreshes its text when it is already up.
  Future<void> sync({required String title, required String text}) =>
      _serial(() => _sync(title, text));

  Future<void> stop() => _serial(_stop);

  Future<void> _sync(String title, String text) async {
    if (!_supported) return;
    try {
      _init();
      // Our own flag first: a platform probe every second is wasted work.
      if (_running) {
        final updated = await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        if (updated is ServiceRequestSuccess) return;
        _running = false;
      }
      final failedAt = _failedAt;
      if (failedAt != null &&
          DateTime.now().difference(failedAt) < _retryAfter) {
        return;
      }
      await _start(title, text);
    } catch (e) {
      debugPrint('Cook foreground service failed: $e');
    }
  }

  Future<void> _start(String title, String text) async {
    if (!_permissionAsked) {
      _permissionAsked = true;
      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: [ForegroundServiceTypes.specialUse],
      notificationTitle: title,
      notificationText: text,
      callback: cookTimerTaskCallback,
    );
    if (result is ServiceRequestFailure) {
      if (result.error is ServiceAlreadyStartedException) {
        // Up from a previous attempt: carry on updating it.
        _running = true;
        _failedAt = null;
        return;
      }
      _running = false;
      _failedAt = DateTime.now();
      debugPrint('Cook foreground service not started: ${result.error}');
    } else {
      _running = true;
      _failedAt = null;
    }
  }

  Future<void> _stop() async {
    if (!_supported) return;
    if (!_running) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        final result = await FlutterForegroundTask.stopService();
        if (result is ServiceRequestFailure) {
          debugPrint('Cook foreground service not stopped: ${result.error}');
          return; // still up; the next sync keeps updating it
        }
      }
      _running = false;
    } catch (e) {
      debugPrint('Cook foreground service not stopped: $e');
    }
  }
}

/// The service's entry point, in its own isolate. It does nothing but keep
/// the service alive; a tap on its notification opens the app.
@pragma('vm:entry-point')
void cookTimerTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_CookTimerTaskHandler());
}

class _CookTimerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}
