import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/my_recipes/data/models/recipe_model.dart';
import '../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../utils/i18n/strings.g.dart';
import '../utils/step_duration.dart';
import 'auth_session_service.dart';
import 'cook_foreground_service.dart';
import 'shopping_reminder_service.dart';

/// One timer per step that names a duration. A running timer is defined by
/// the wall-clock moment it ends, not by counting ticks: a process that was
/// frozen in the background or relaunched still shows the right remainder.
class CookTimer {
  final int total;
  int _remaining;
  bool finished = false;

  /// Epoch milliseconds the countdown reaches zero; null while paused.
  int? endsAtMs;

  CookTimer({required this.total, int? remaining, this.endsAtMs})
    : _remaining = remaining ?? total;

  bool get running => endsAtMs != null;

  int get remaining {
    final ends = endsAtMs;
    if (ends == null) return _remaining;
    final left = (ends - clock.now().millisecondsSinceEpoch) / 1000;
    return max(0, left.ceil());
  }

  double get progress => total == 0 ? 0 : 1 - remaining / total;

  /// "12:30/30:00": what every view prints for this timer.
  String get display => '${formatClock(remaining)}/${formatClock(total)}';

  void start() {
    if (finished) reset();
    endsAtMs = clock.now().millisecondsSinceEpoch + _remaining * 1000;
  }

  void pause() {
    _remaining = remaining;
    endsAtMs = null;
  }

  /// Called on every tick and on every return to the foreground.
  void settle() {
    if (running && remaining <= 0) {
      _remaining = 0;
      endsAtMs = null;
      finished = true;
    }
  }

  void reset() {
    _remaining = total;
    endsAtMs = null;
    finished = false;
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'remaining': _remaining,
    'finished': finished,
    'endsAtMs': endsAtMs,
  };

  factory CookTimer.fromJson(Map<String, dynamic> json) => CookTimer(
    total: json['total'] as int,
    remaining: json['remaining'] as int?,
    endsAtMs: json['endsAtMs'] as int?,
  )..finished = json['finished'] as bool? ?? false;
}

/// One recipe being cooked: its step and its timers. Several can run at
/// once — a main and a side — each with its own screen and its own rings.
class CookSession {
  RecipeEntity recipe;

  /// 0–9: keeps this session's notification ids apart from the others'.
  final int slot;
  int stepIndex;
  final Map<int, CookTimer> timers;

  CookSession({
    required this.recipe,
    required this.slot,
    this.stepIndex = 0,
    Map<int, CookTimer>? timers,
  }) : timers = timers ?? {};

  String get id => recipe.id;

  /// Takes an edited copy of the recipe: timers survive on steps whose text
  /// did not change, the rest are re-read from the new text. Returns the
  /// timers that were dropped (the caller cancels their notifications), or
  /// null when nothing differed.
  List<CookTimer>? adopt(RecipeEntity edited) {
    final sameSteps = listEquals(edited.steps, recipe.steps);
    if (sameSteps &&
        edited.title == recipe.title &&
        _sameIngredients(edited.ingredients, recipe.ingredients)) {
      // Photo, servings, nutrition and the like: taken, nothing to re-time.
      recipe = edited;
      return null;
    }
    // The same number of steps means an edit in place, or a translation
    // (a language switch rewrites every step's text): timers stay with
    // their step. A different count is a real restructuring, and a timer
    // follows its step only where the text still matches.
    final sameCount = edited.steps.length == recipe.steps.length;
    final kept = <int, CookTimer>{};
    for (var i = 0; i < edited.steps.length; i++) {
      final seconds = parseStepDuration(edited.steps[i]);
      final old = i < recipe.steps.length ? timers[i] : null;
      // Unchanged text keeps its timer; so does a translation (same count,
      // same duration). A new duration rebuilds it.
      final unchanged =
          old != null &&
          (recipe.steps[i] == edited.steps[i] ||
              (sameCount && seconds == old.total));
      if (unchanged) {
        kept[i] = old;
      } else if (seconds != null) {
        kept[i] = CookTimer(total: seconds);
      }
    }
    final dropped = [
      for (final t in timers.values)
        if (!kept.values.contains(t)) t,
    ];
    timers
      ..clear()
      ..addAll(kept);
    recipe = edited;
    if (stepIndex >= edited.steps.length) {
      stepIndex = edited.steps.isEmpty ? 0 : edited.steps.length - 1;
    }
    return dropped;
  }

  static bool _sameIngredients(
    List<RecipeIngredientEntity> a,
    List<RecipeIngredientEntity> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name ||
          a[i].amount != b[i].amount ||
          a[i].unit != b[i].unit) {
        return false;
      }
    }
    return true;
  }

  List<MapEntry<int, CookTimer>> get activeTimers {
    final list = timers.entries
        .where((e) => e.value.running || e.value.finished)
        .toList();
    list.sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  bool get hasRunningTimer => timers.values.any((t) => t.running);

  Map<String, dynamic> toJson() => {
    'recipe': recipe.toModel().toJson(),
    'slot': slot,
    'stepIndex': stepIndex,
    'timers': {for (final e in timers.entries) '${e.key}': e.value.toJson()},
  };

  factory CookSession.fromJson(Map<String, dynamic> json) => CookSession(
    recipe: RecipeModel.fromJson(
      (json['recipe'] as Map).cast<String, dynamic>(),
    ).toEntity(),
    slot: json['slot'] as int? ?? 0,
    stepIndex: json['stepIndex'] as int? ?? 0,
    timers: {
      for (final e in (json['timers'] as Map).cast<String, dynamic>().entries)
        int.parse(e.key): CookTimer.fromJson(
          (e.value as Map).cast<String, dynamic>(),
        ),
    },
  );
}

/// A timer with the session and step it belongs to, for views that show
/// every timer across every recipe being cooked.
class ActiveCookTimer {
  final CookSession session;
  final int step;
  final CookTimer timer;

  const ActiveCookTimer(this.session, this.step, this.timer);

  String get key => '${session.id}:$step';
}

/// The cooking in progress, which outlives the cook-mode screen and the
/// process: leaving a recipe keeps its step and timers, the inbox shows a
/// card per recipe, everything is written to disk on every change and read
/// back on launch, and only "done" ends a recipe. While the app is in the
/// background every running timer is an ongoing notification whose
/// countdown the system itself keeps moving (Android), and each one is
/// also scheduled to ring at its end on both platforms.
class CookSessionService extends ChangeNotifier with WidgetsBindingObserver {
  static final CookSessionService _instance = CookSessionService._internal();
  factory CookSessionService() => _instance;
  CookSessionService._internal();

  /// What a tap on a cook-mode notification carries: `cook_mode:<recipeId>`.
  static const payloadPrefix = 'cook_mode:';

  static const _boxName = 'cookSessionBox';
  static const _key = 'sessions';
  static const _ongoingBase = 9000;
  static const _endBase = 10000;
  static const _slots = 10;
  static const _channel = 'cook_timers';

  /// Set by the app shell: navigates into cook mode on the given recipe.
  void Function(RecipeEntity recipe)? openCookMode;

  /// The recipe whose cook-mode screen is on top, if any; the global banner
  /// leaves that recipe's timers to the screen's own strip.
  String? get visibleRecipeId => _visible.isEmpty ? null : _visible.last;
  final List<String> _visible = [];

  /// A cook screen came on top (push) or left (pop): screens stack, and the
  /// same recipe may be open twice (inbox → continue), so this is a plain
  /// push/pop, not a set.
  void screenShown(String recipeId) {
    _visible.add(recipeId);
    _notify();
  }

  void screenHidden(String recipeId) {
    final at = _visible.lastIndexOf(recipeId);
    if (at < 0) return;
    _visible.removeAt(at);
    _notify();
  }

  final Map<String, CookSession> _sessions = {};
  Timer? _ticker;
  bool _inBackground = false;
  bool _observing = false;

  List<CookSession> get sessions => List.unmodifiable(_sessions.values);
  bool get isActive => _sessions.isNotEmpty;
  CookSession? session(String recipeId) => _sessions[recipeId];

  /// Every timer counting down or just rung, across all recipes, in the
  /// order the recipes were started and then by step.
  List<ActiveCookTimer> get activeTimers => [
    for (final s in _sessions.values)
      for (final e in s.activeTimers) ActiveCookTimer(s, e.key, e.value),
  ];

  bool get hasRunningTimer => _sessions.values.any((s) => s.hasRunningTimer);

  /// Opens a session on [recipe]; a recipe already cooking resumes.
  CookSession start(RecipeEntity recipe) {
    final existing = _sessions[recipe.id];
    if (existing != null) {
      // Edited since it was started: new title and steps, timers kept where
      // the step text is unchanged, the step kept in range. A timer that
      // went with its step takes its ring and its card along.
      final before = Map<int, CookTimer>.of(existing.timers);
      final dropped = existing.adopt(recipe);
      if (dropped != null) {
        for (final entry in before.entries) {
          if (dropped.contains(entry.value)) {
            unawaited(_cancelEnd(existing, entry.key));
            unawaited(_cancelOngoing(existing, entry.key));
          }
        }
        _ensureTicking();
        _persist();
        _notify();
      }
      return existing;
    }
    // Ten at once is the ceiling; past it the oldest cooking makes room,
    // since two sessions on one slot would cancel each other's rings.
    if (_sessions.length >= _slots) finish(_sessions.keys.first);
    final used = _sessions.values.map((s) => s.slot).toSet();
    final slot = List.generate(_slots, (i) => i).firstWhere(
      (i) => !used.contains(i),
    );
    final session = CookSession(recipe: recipe, slot: slot);
    for (var i = 0; i < recipe.steps.length; i++) {
      final seconds = parseStepDuration(recipe.steps[i]);
      if (seconds != null) session.timers[i] = CookTimer(total: seconds);
    }
    _sessions[recipe.id] = session;
    _observe();
    _persist();
    _notify();
    return session;
  }

  void setStep(String recipeId, int index) {
    final session = _sessions[recipeId];
    if (session == null || session.stepIndex == index) return;
    session.stepIndex = index;
    _persist();
    _notify();
  }

  void toggleTimer(String recipeId, int index) {
    final session = _sessions[recipeId];
    final timer = session?.timers[index];
    if (session == null || timer == null) return;
    if (timer.running) {
      timer.pause();
      unawaited(_cancelEnd(session, index));
      unawaited(_cancelOngoing(session, index));
    } else {
      timer.start();
      unawaited(_scheduleEnd(session, index, timer));
    }
    HapticFeedback.selectionClick();
    _ensureTicking();
    _persist();
    _notify();
  }

  void resetTimer(String recipeId, int index) {
    final session = _sessions[recipeId];
    final timer = session?.timers[index];
    if (session == null || timer == null) return;
    timer.reset();
    unawaited(_cancelEnd(session, index));
    unawaited(_cancelOngoing(session, index));
    _ensureTicking();
    _persist();
    _notify();
  }

  /// "Done" for one recipe: everything about its cooking is forgotten.
  void finish(String recipeId) {
    final session = _sessions.remove(recipeId);
    if (session == null) return;
    _visible.removeWhere((id) => id == recipeId);
    for (final index in session.timers.keys) {
      unawaited(_cancelEnd(session, index));
      unawaited(_cancelOngoing(session, index));
    }
    _ensureTicking();
    _persist();
    _notify();
  }

  /// Every recipe at once (sign-out, tests).
  void finishAll() {
    for (final id in _sessions.keys.toList()) {
      finish(id);
    }
    // The next account reads its own sessions back; a read still in flight
    // for this one is disowned.
    _restoreGeneration++;
    _restored = false;
    _restoring = null;
    _pendingOpen = null;
  }

  /// A tap that arrived before the sessions were read back from disk (the
  /// app was launched by the notification); honoured once restore lands.
  String? _pendingOpen;

  /// A tap on one of the session's notifications, or on the banner.
  void reopen(String recipeId) {
    final session = _sessions[recipeId];
    if (session == null) {
      if (!_restored) _pendingOpen = recipeId;
      return;
    }
    // The route itself waits for the plan verdict before deciding.
    openCookMode?.call(session.recipe);
  }

  /// Reopens a session on the step a timer belongs to.
  void reopenAt(ActiveCookTimer active) {
    setStep(active.session.id, active.step);
    reopen(active.session.id);
  }

  /// Routes a notification payload; false when it is not ours.
  bool handlePayload(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return false;
    reopen(payload.substring(payloadPrefix.length));
    return true;
  }

  /// Listeners live on every screen (the banner in each scaffold, the bell),
  /// so a notification raised while a frame is being built or torn down
  /// (cook mode's initState/dispose) would trip the framework. Those are
  /// deferred to the end of the frame; the rest go out at once.
  /// How many recipes have a timer counting down or rung (one per inbox
  /// card), for badges: changes when a timer starts, stops or rings, not
  /// every second.
  final ValueNotifier<int> activeCount = ValueNotifier(0);

  /// Bumped when the set of active timers, their rung state or the screen on
  /// top changes: what the banner's structure depends on. The ticking clock
  /// inside a card listens to the service itself.
  final ValueNotifier<int> structure = ValueNotifier(0);
  String _structureKey = '';

  /// The timer the user flipped to the front of the banner stack; one
  /// choice for every screen, so a flip on one tab holds on the next.
  String? selectedTimerKey;

  void _notify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      _publish();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => _publish());
    }
  }

  void _publish() {
    final active = activeTimers;
    final key = [
      for (final a in active) '${a.key}${a.timer.finished ? '!' : ''}',
      '|',
      visibleRecipeId ?? '',
    ].join(',');
    if (key != _structureKey) {
      _structureKey = key;
      // One per recipe being cooked with something counting down: what the
      // inbox shows a card for.
      activeCount.value = active.map((a) => a.session.id).toSet().length;
      structure.value++;
    }
    notifyListeners();
  }

  void _observe() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  void _ensureTicking({bool refreshService = true}) {
    if (hasRunningTimer) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _ticker?.cancel();
      _ticker = null;
      _ticks = 0;
    }
    if (refreshService) _syncForegroundService();
  }

  /// While anything counts down, a foreground service keeps this isolate
  /// awake in the background; its one-line notification names the timer
  /// ending soonest. Gone the moment the last timer pauses or rings.
  void _syncForegroundService() {
    final running = activeTimers.where((a) => a.timer.running).toList();
    if (running.isEmpty) {
      unawaited(CookForegroundService().stop());
      return;
    }
    running.sort((a, b) => a.timer.remaining.compareTo(b.timer.remaining));
    final lead = running.first;
    final others = running.length - 1;
    unawaited(
      CookForegroundService().sync(
        title: lead.session.recipe.title,
        text:
            '${t.cookMode.stepLabel(n: '${lead.step + 1}')} · ${lead.timer.display}'
            '${others > 0 ? '  +$others' : ''}',
      ),
    );
  }

  /// Ticks since the ticker started; the per-second work that only moves a
  /// progress bar is done every [_refreshEvery] ticks.
  int _ticks = 0;
  static const _refreshEvery = 5;

  void _tick() {
    _ticks++;
    final refresh = _ticks % _refreshEvery == 0;
    var changed = false;
    var finishedAny = false;
    for (final session in _sessions.values) {
      for (final entry in session.timers.entries) {
        final timer = entry.value;
        if (!timer.running) continue;
        changed = true;
        timer.settle();
        if (timer.finished) {
          finishedAny = true;
          unawaited(_cancelOngoing(session, entry.key));
          if (!_inBackground) unawaited(_ring());
        } else if (!_inBackground && timer.remaining <= 1) {
          // In the foreground the app rings itself; the system alarm set
          // for the same instant is withdrawn before it can double it.
          unawaited(_cancelEnd(session, entry.key));
        } else if (_inBackground && refresh) {
          // The countdown next to the title is the system's; this only
          // moves the bar, so a few seconds between posts is plenty.
          unawaited(_showOngoing(session, entry.key, timer));
        }
      }
    }
    if (finishedAny) _persist();
    if (changed) _notify();
    _ensureTicking(refreshService: refresh || finishedAny);
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

  // ---- Persistence ---------------------------------------------------------

  Box<String>? _box;

  Future<Box<String>?> _openBox() async {
    if (_box != null) return _box;
    try {
      return _box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      // No Hive (tests, or a storage failure): the sessions live in memory.
      debugPrint('Cook session box unavailable: $e');
      return null;
    }
  }

  void _persist() => unawaited(_write());

  Future<void> _write() async {
    final box = await _openBox();
    if (box == null) return;
    try {
      if (_sessions.isEmpty) {
        await box.delete(_key);
        return;
      }
      await box.put(
        _key,
        jsonEncode({
          'uid': AuthSessionService().user?.uid,
          'sessions': [for (final s in _sessions.values) s.toJson()],
        }),
      );
    } catch (e) {
      debugPrint('Cook sessions not saved: $e');
    }
  }

  /// Brings back what a previous run left behind. Running timers pick up
  /// from their wall-clock end; one that ended while the app was away is
  /// shown as rung (its scheduled notification already did ring).
  bool _restored = false;
  Future<void>? _restoring;
  int _restoreGeneration = 0;

  Future<void> restore() {
    // One read per process: the auth listener and initState both ask, and
    // a second pass would overwrite sessions started in between.
    if (_restored) return Future.value();
    final generation = ++_restoreGeneration;
    return _restoring ??= _restore().whenComplete(() {
      // A sign-out during the read belongs to the account that left.
      if (generation != _restoreGeneration) return;
      _restored = true;
      _openPending();
    });
  }

  /// The held tap, once the plan is known (the cook route redirects a free
  /// account, and must not do so on the default verdict). Gives up after a
  /// few seconds offline rather than never opening.
  void _openPending() {
    final pending = _pendingOpen;
    _pendingOpen = null;
    if (pending != null) reopen(pending);
  }

  Future<void> _restore() async {
    final box = await _openBox();
    final raw = box?.get(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['uid'] != AuthSessionService().user?.uid) return;
      // Sessions started while the box was being read win; stored ones
      // join beside them, moved off any slot that is now taken.
      final used = _sessions.values.map((s) => s.slot).toSet();
      for (final item in json['sessions'] as List) {
        CookSession stored;
        try {
          stored = CookSession.fromJson((item as Map).cast<String, dynamic>());
        } catch (e) {
          debugPrint('A stored cook session was unreadable: $e');
          continue;
        }
        if (_sessions.containsKey(stored.id)) continue;
        if (_sessions.length >= _slots) break;
        var session = stored;
        if (used.contains(session.slot)) {
          // The old slot's notification ids now belong to the live session
          // on it (which re-sets its own rings under them); the stored
          // session's rings are re-set under its new slot below.
          final free = List.generate(
            _slots,
            (i) => i,
          ).firstWhere((i) => !used.contains(i));
          session = CookSession(
            recipe: stored.recipe,
            slot: free,
            stepIndex: stored.stepIndex,
            timers: stored.timers,
          );
        }
        used.add(session.slot);
        for (final timer in session.timers.values) {
          timer.settle();
        }
        _sessions[session.id] = session;
      }
      _observe();
      // The previous run's ongoing cards are stale (a rung timer would
      // leave one that cannot be swiped away), and its rings may have been
      // dropped by the OS: cards go, rings for running timers are re-set.
      for (final session in _sessions.values) {
        for (final entry in session.timers.entries) {
          unawaited(_cancelOngoing(session, entry.key));
          if (entry.value.running) {
            unawaited(_scheduleEnd(session, entry.key, entry.value));
          }
        }
      }
      _ensureTicking();
      _notify();
    } catch (e) {
      debugPrint('Cook sessions not restored: $e');
      await box?.delete(_key);
    }
  }

  // ---- Lifecycle -----------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _inBackground) return;
    _inBackground = background;
    for (final session in _sessions.values) {
      for (final entry in session.timers.entries) {
        if (!entry.value.running) continue;
        if (background) {
          unawaited(_showOngoing(session, entry.key, entry.value));
          // Re-set in case the last foreground tick had withdrawn it.
          unawaited(_scheduleEnd(session, entry.key, entry.value));
        } else {
          unawaited(_cancelOngoing(session, entry.key));
        }
      }
    }
    if (!background) {
      // Time passed while frozen: settle every timer against the clock.
      for (final session in _sessions.values) {
        for (final timer in session.timers.values) {
          timer.settle();
        }
      }
      _ensureTicking();
      _notify();
    }
  }

  // ---- Notifications -------------------------------------------------------

  FlutterLocalNotificationsPlugin get _plugin =>
      ShoppingReminderService().plugin;

  int _ongoingId(CookSession s, int step) =>
      _ongoingBase + s.slot * 100 + (step % 100);
  int _endId(CookSession s, int step) => _endBase + s.slot * 100 + (step % 100);
  String _payload(CookSession s) => '$payloadPrefix${s.id}';

  Future<bool> _ready() async {
    try {
      await ShoppingReminderService().initialize();
      return true;
    } catch (e) {
      debugPrint('Cook timer notifications unavailable: $e');
      return false;
    }
  }

  String _stepTitle(CookSession s, int index) =>
      '${s.recipe.title} · ${t.cookMode.stepLabel(n: '${index + 1}')}';

  /// Android: a silent, non-dismissible card whose countdown the system
  /// runs on its own (a chronometer to the end moment), with a bar we move
  /// whenever the app is awake. iOS has no live notification without a
  /// Live Activity, so it relies on the scheduled ring alone.
  Future<void> _showOngoing(CookSession s, int index, CookTimer timer) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final ends = timer.endsAtMs;
    if (ends == null) return;
    if (!await _ready()) return;
    try {
      await _plugin.show(
        id: _ongoingId(s, index),
        title: _stepTitle(s, index),
        // The system runs the countdown next to the title (a chronometer);
        // this body is written once, so it carries only what stays true.
        body: t.cookMode.ongoingBody(
          time: DateFormat.Hm().format(
            DateTime.fromMillisecondsSinceEpoch(ends),
          ),
          total: formatClock(timer.total),
          n: '${index + 1}',
        ),
        payload: _payload(s),
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
            showWhen: true,
            when: ends,
            usesChronometer: true,
            chronometerCountDown: true,
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

  Future<void> _cancelOngoing(CookSession s, int index) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!await _ready()) return;
    try {
      await _plugin.cancel(id: _ongoingId(s, index));
    } catch (_) {}
  }

  /// Rings at the second the timer ends even if the process is suspended.
  /// Exact where the user allows it (Android 14+ asks), inexact otherwise.
  Future<void> _scheduleEnd(CookSession s, int index, CookTimer timer) async {
    final ends = timer.endsAtMs;
    if (ends == null) return;
    if (!await _ready()) return;
    final when = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, ends);
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
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        id: _endId(s, index),
        title: s.recipe.title,
        body: t.cookMode.timeUpBody(n: '${index + 1}'),
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: _payload(s),
      );
    } catch (e) {
      debugPrint('Cook timer ring could not be scheduled: $e');
    }
  }

  /// Whether a ring can be exact. The dialogs are shown once per process
  /// and one at a time (several timers restored together must not stack
  /// them); the exact-alarm state itself is probed every time, since the
  /// user may grant it in Settings later, and a failure is never cached.
  bool _notificationsAsked = false;
  bool _exactAsked = false;
  Future<void> _permissionQueue = Future.value();

  Future<AndroidScheduleMode> _scheduleMode() {
    final next = _permissionQueue.then((_) => _probeScheduleMode());
    _permissionQueue = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<AndroidScheduleMode> _probeScheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      if (!_notificationsAsked) {
        _notificationsAsked = true;
        await android.requestNotificationsPermission();
      }
      if (await android.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
      if (!_exactAsked) {
        _exactAsked = true;
        if (await android.requestExactAlarmsPermission() ?? false) {
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      }
    } catch (e) {
      debugPrint('Alarm permission check failed: $e');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _cancelEnd(CookSession s, int index) async {
    if (!await _ready()) return;
    try {
      await _plugin.cancel(id: _endId(s, index));
    } catch (_) {}
  }
}
