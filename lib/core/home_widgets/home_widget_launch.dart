import 'package:flutter/foundation.dart';

/// A tap on a home-screen widget, as the URI the widget opened the app
/// with: `easyplate://open/widget/<action>?…`.
///
/// Both platforms hand the URI to the router like any deep link; the
/// `/widget/:action` route captures it here and sends the router home,
/// and the main screen acts on it once there is a signed-in session —
/// the same arrangement as a share link.
class HomeWidgetLaunch {
  final HomeWidgetAction action;
  final Map<String, String> params;

  const HomeWidgetLaunch(this.action, [this.params = const {}]);

  static HomeWidgetLaunch? parse(Uri uri) {
    // `easyplate://open/widget/<action>` as the widgets send it, where the
    // host is swallowed and the path is `/widget/<action>`; the bare
    // `easyplate://widget/<action>` form is taken too.
    final segments = uri.host == 'widget'
        ? ['widget', ...uri.pathSegments]
        : uri.pathSegments;
    if (segments.length != 2 || segments.first != 'widget') return null;
    final action = HomeWidgetAction.values
        .where((a) => a.name == segments.last)
        .firstOrNull;
    if (action == null) return null;
    return HomeWidgetLaunch(action, uri.queryParameters);
  }

  /// `assistant`: what to say first, and whether to open listening.
  String? get prompt => _text('prompt');
  bool get voice => params['voice'] == '1' || params['voice'] == 'true';

  /// `grocery`: which list, and whether the add sheet opens.
  String? get listId => _text('list');
  bool get add => params['add'] == '1' || params['add'] == 'true';

  /// `plan`: which plan.
  String? get planId => _text('plan');

  String? _text(String key) {
    final value = params[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

enum HomeWidgetAction { assistant, grocery, plan, settings }

/// Holds the latest widget launch until the main screen takes it.
abstract class PendingHomeWidgetLaunch {
  /// Set on capture, cleared by [take]; the main screen listens so a tap
  /// while the app is already open is acted on too.
  static final notifier = ValueNotifier<HomeWidgetLaunch?>(null);

  static void capture(Uri uri) {
    final launch = HomeWidgetLaunch.parse(uri);
    if (launch != null) notifier.value = launch;
  }

  static HomeWidgetLaunch? take() {
    final launch = notifier.value;
    notifier.value = null;
    return launch;
  }
}

/// What the main screen asks the tab pages to do for a launch. The pages
/// live in the IndexedStack with their own blocs, which the main screen
/// cannot reach, so each listens for its own request.
abstract class HomeWidgetRequests {
  /// The groceries tab: open this list (null keeps the open one) and
  /// then the add sheet.
  static final groceryAdd = ValueNotifier<GroceryAddRequest?>(null);

  /// The planner: show this plan (null keeps the open one) on this day.
  static final planner = ValueNotifier<PlannerRequest?>(null);
}

class GroceryAddRequest {
  final String? listId;
  const GroceryAddRequest({this.listId});
}

class PlannerRequest {
  final String? planId;
  final int weekday;
  const PlannerRequest({this.planId, required this.weekday});
}
