import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../utils/i18n/strings.g.dart';
import '../utils/step_duration.dart';
import 'shopping_reminder_service.dart';

/// One timer per step that names a duration.
class CookTimer {
  final int total;
  int remaining;
  bool running = false;
  bool finished = false;

  CookTimer({required this.total}) : remaining = total;

  double get progress => total == 0 ? 0 : 1 - remaining / total;

  void reset() {
    remaining = total;
    running = false;
    finished = false;
  }
}

/// The cooking in progress, which outlives the cook-mode screen: leaving the
/// recipe keeps the step and the timers, the inbox shows a card for it, and
/// only "done" ends it. While the app is in the background every running
/// timer is an ongoing notification with its progress (Android), and each
/// one is also scheduled to ring at its end on both platforms, so a timer
/// is never lost to a suspended process.
class CookSessionService extends ChangeNotifier with WidgetsBindingObserver {
  static final CookSessionService _instance = CookSessionService._internal();
  factory CookSessionService() => _instance;
  CookSessionService._internal();

  /// What a tap on a cook-mode notification carries.
  static const payload = 'cook_mode';

  static const _ongoingBase = 9000;
  static const _endBase = 9100;
  static const _channel = 'cook_timers';

  /// Set by the app shell: navigates into cook mode on the given recipe.
  void Function(RecipeEntity recipe)? openCookMode;

  RecipeEntity? _recipe;
  int _stepIndex = 0;
  final Map<int, CookTimer> _timers = {};
  Timer? _ticker;
  bool _inBackground = false;
  bool _observing = false;

  RecipeEntity? get recipe => _recipe;
  bool get isActive => _recipe != null;
  int get stepIndex => _stepIndex;
  Map<int, CookTimer> get timers => Map.unmodifiable(_timers);

  /// Step index → timer, for every timer counting down or just finished and
  /// not yet acknowledged, in step order.
  List<MapEntry<int, CookTimer>> get activeTimers {
    final list = _timers.entries
        .where((e) => e.value.running || e.value.finished)
        .toList();
    list.sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  bool get hasRunningTimer => _timers.values.any((t) => t.running);

  /// Opens a session on [recipe]; the same recipe resumes where it was.
  void start(RecipeEntity recipe) {
    if (_recipe?.id == recipe.id) {
      _recipe = recipe;
      return;
    }
    _clear();
    _recipe = recipe;
    for (var i = 0; i < recipe.steps.length; i++) {
      final seconds = parseStepDuration(recipe.steps[i]);
      if (seconds != null) _timers[i] = CookTimer(total: seconds);
    }
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    notifyListeners();
  }

  void setStep(int index) {
    if (index == _stepIndex) return;
    _stepIndex = index;
    notifyListeners();
  }

  void toggleTimer(int index) {
    final timer = _timers[index];
    if (timer == null) return;
    if (timer.finished) {
      timer.reset();
      timer.running = true;
    } else {
      timer.running = !timer.running;
    }
    HapticFeedback.selectionClick();
    if (timer.running) {
      unawaited(_scheduleEnd(index, timer));
    } else {
      unawaited(_cancelEnd(index));
      unawaited(_cancelOngoing(index));
    }
    _ensureTicking();
    notifyListeners();
  }

  void resetTimer(int index) {
    final timer = _timers[index];
    if (timer == null) return;
    timer.reset();
    unawaited(_cancelEnd(index));
    unawaited(_cancelOngoing(index));
    _ensureTicking();
    notifyListeners();
  }

  /// "Done": everything about this cooking is forgotten.
  void finish() {
    final hadRecipe = _recipe != null;
    _clear();
    if (hadRecipe) notifyListeners();
  }

  /// A tap on one of the session's notifications.
  void reopen() {
    final recipe = _recipe;
    if (recipe != null) openCookMode?.call(recipe);
  }

  void _clear() {
    for (final index in _timers.keys) {
      unawaited(_cancelEnd(index));
      unawaited(_cancelOngoing(index));
    }
    _timers.clear();
    _recipe = null;
    _stepIndex = 0;
    _ticker?.cancel();
    _ticker = null;
  }

  void _ensureTicking() {
    if (hasRunningTimer) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    var changed = false;
    for (final entry in _timers.entries) {
      final timer = entry.value;
      if (!timer.running) continue;
      timer.remaining -= 1;
      changed = true;
      if (timer.remaining <= 0) {
        timer.remaining = 0;
        timer.running = false;
        timer.finished = true;
        unawaited(_cancelOngoing(entry.key));
        if (_inBackground) {
          // The scheduled ring covers this moment; nothing else to do.
        } else {
          unawaited(_cancelEnd(entry.key));
          unawaited(_ring());
        }
      } else if (_inBackground) {
        unawaited(_showOngoing(entry.key, timer));
      }
    }
    if (changed) notifyListeners();
    _ensureTicking();
  }

  /// Three heavy taps and the system alert: enough to be noticed from the
  /// stove without a notification permission.
  Future<void> _ring() async {
    SystemSound.play(SystemSoundType.alert);
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
  }

  // ---- Lifecycle -----------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _inBackground) return;
    _inBackground = background;
    for (final entry in _timers.entries) {
      if (!entry.value.running) continue;
      if (background) {
        unawaited(_showOngoing(entry.key, entry.value));
      } else {
        unawaited(_cancelOngoing(entry.key));
      }
    }
  }

  // ---- Notifications -------------------------------------------------------

  FlutterLocalNotificationsPlugin get _plugin =>
      ShoppingReminderService().plugin;

  Future<bool> _ready() async {
    try {
      await ShoppingReminderService().initialize();
      return true;
    } catch (e) {
      debugPrint('Cook timer notifications unavailable: $e');
      return false;
    }
  }

  String _stepTitle(int index) =>
      '${_recipe?.title ?? t.cookMode.title} · ${t.cookMode.stepLabel(n: '${index + 1}')}';

  /// Android: a silent, non-dismissible card with the countdown and a bar,
  /// refreshed every second while the app is away. iOS has no live
  /// notification without a Live Activity, so it relies on the scheduled
  /// ring alone.
  Future<void> _showOngoing(int index, CookTimer timer) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!await _ready()) return;
    try {
      await _plugin.show(
        id: _ongoingBase + index,
        title: _stepTitle(index),
        body: t.cookMode.ongoingBody(
          remaining: formatClock(timer.remaining),
          total: formatClock(timer.total),
          n: '${index + 1}',
        ),
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            t.cookMode.title,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            silent: true,
            showProgress: true,
            maxProgress: timer.total,
            progress: timer.total - timer.remaining,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Cook timer notification failed: $e');
    }
  }

  Future<void> _cancelOngoing(int index) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!await _ready()) return;
    try {
      await _plugin.cancel(id: _ongoingBase + index);
    } catch (_) {}
  }

  /// Rings at the second the timer ends even if the process is suspended.
  /// Exact where the user allows it (Android 14+ asks), inexact otherwise.
  Future<void> _scheduleEnd(int index, CookTimer timer) async {
    if (!await _ready()) return;
    final when = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: timer.remaining));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel,
        t.cookMode.title,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      var mode = AndroidScheduleMode.exactAllowWhileIdle;
      if (android != null &&
          !(await android.canScheduleExactNotifications() ?? false)) {
        final granted = await android.requestExactAlarmsPermission() ?? false;
        if (!granted) mode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
      await _plugin.zonedSchedule(
        id: _endBase + index,
        title: _recipe?.title ?? t.cookMode.title,
        body: t.cookMode.timeUpBody(n: '${index + 1}'),
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Cook timer ring could not be scheduled: $e');
    }
  }

  Future<void> _cancelEnd(int index) async {
    if (!await _ready()) return;
    try {
      await _plugin.cancel(id: _endBase + index);
    } catch (_) {}
  }
}
