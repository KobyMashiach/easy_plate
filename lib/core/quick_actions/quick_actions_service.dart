import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

import '../features/features_flags.dart';
import '../home_widgets/home_widget_launch.dart';
import '../utils/i18n/strings.g.dart';

/// The app icon's long-press menu (Android app shortcuts, iOS Home Screen
/// quick actions): talk to Shefi, add to the grocery list, add a receipt,
/// contact support.
///
/// A tap becomes the same [PendingHomeWidgetLaunch] a widget tap is, with
/// `source=shortcut`, so the main screen acts on it once a session is up
/// and gates it like every other door. The menu is redrawn when the
/// language or the console flags change: a hidden feature has no shortcut,
/// a Premium-only one keeps it and the tap goes to the paywall.
class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  factory QuickActionsService() => _instance;
  QuickActionsService._internal();

  static const _plugin = QuickActions();

  /// The shortcut types, which the platform hands back on a tap.
  static const assistant = 'shefi';
  static const groceryAdd = 'grocery_add';
  static const receipt = 'receipt';
  static const support = 'support';

  bool _bound = false;
  String? _drawn;

  /// Call once at startup, before the first frame: on a cold start the
  /// platform delivers the tap that launched the app to this handler.
  void bind() {
    if (_bound || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    _bound = true;
    try {
      unawaited(_plugin.initialize(_onTap));
    } catch (e) {
      debugPrint('Quick actions unavailable: $e');
      return;
    }
    FeaturesFlags.listenable.addListener(_redraw);
    LocaleSettings.getLocaleStream().listen((_) => _redraw());
    _redraw();
  }

  void _onTap(String type) {
    final launch = launchFor(type);
    if (launch != null) PendingHomeWidgetLaunch.notifier.value = launch;
  }

  /// What a shortcut opens, as the launch the main screen understands.
  @visibleForTesting
  static HomeWidgetLaunch? launchFor(String type) {
    const shortcut = {'source': 'shortcut'};
    return switch (type) {
      assistant => const HomeWidgetLaunch(HomeWidgetAction.assistant, {
        ...shortcut,
        'voice': '1',
      }),
      groceryAdd => const HomeWidgetLaunch(HomeWidgetAction.grocery, {
        ...shortcut,
        'add': '1',
      }),
      receipt => const HomeWidgetLaunch(HomeWidgetAction.receipt, shortcut),
      support => const HomeWidgetLaunch(HomeWidgetAction.support, shortcut),
      _ => null,
    };
  }

  /// The shortcuts this account should see, in menu order.
  @visibleForTesting
  static List<ShortcutItem> items() {
    if (!FeaturesFlags.quickActions.isVisible) return const [];
    final s = t.quickActions;
    return [
      if (FeaturesFlags.assistant.isVisible)
        ShortcutItem(type: assistant, localizedTitle: s.shefi, icon: 'qa_shefi'),
      if (FeaturesFlags.groceryLists.isVisible)
        ShortcutItem(
          type: groceryAdd,
          localizedTitle: s.groceryAdd,
          icon: 'qa_grocery',
        ),
      if (FeaturesFlags.receiptScan.isVisible)
        ShortcutItem(
          type: receipt,
          localizedTitle: s.receipt,
          icon: 'qa_receipt',
        ),
      ShortcutItem(type: support, localizedTitle: s.support, icon: 'qa_support'),
    ];
  }

  void _redraw() {
    final items = QuickActionsService.items();
    // The flags listenable fires on every config fetch and entitlement
    // change; the platform call is only made when the menu itself changed.
    final signature = items
        .map((i) => '${i.type}:${i.localizedTitle}')
        .join('|');
    if (signature == _drawn) return;
    _drawn = signature;
    unawaited(
      _plugin.setShortcutItems(items).catchError((Object e) {
        debugPrint('Quick actions update failed: $e');
        _drawn = null;
      }),
    );
  }
}
