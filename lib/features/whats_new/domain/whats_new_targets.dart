import 'package:flutter/material.dart';

import '../../../core/navigation/main_tabs.dart';
import '../../../core/utils/routing/routing.dart';

/// Where a "Try it" button may go, and the icons a page may carry. Both
/// lists are mirrored in the web console (`landing/admin/js/views/
/// whatsnew.js`), which offers exactly these names; anything else in a
/// document is ignored rather than crashing a push on a missing `extra`.
abstract class WhatsNewTargets {
  /// `tab:<name>` switches the dock; a route name is pushed over home.
  static const tabPrefix = 'tab:';

  static const tabs = <String, int>{
    'recipes': MainTabs.recipes,
    'library': MainTabs.library,
    'mealPlan': MainTabs.mealPlan,
    'groceries': MainTabs.groceries,
    'community': MainTabs.community,
  };

  /// Named routes that open with no `extra`.
  static const routes = <String>{
    Routing.ingestion,
    Routing.assistant,
    Routing.priceBook,
    Routing.settings,
    Routing.preferences,
    Routing.notificationSettings,
    Routing.accountMenu,
    Routing.notifications,
    Routing.profileEdit,
    Routing.sharing,
    Routing.household,
    Routing.joinCode,
    Routing.scanCode,
    Routing.homeWidgets,
    Routing.wakeWord,
    Routing.support,
    Routing.help,
    Routing.premium,
    Routing.tutorial,
  };

  static bool isValid(String target) {
    if (target.startsWith(tabPrefix)) {
      return tabs.containsKey(target.substring(tabPrefix.length));
    }
    return routes.contains(target);
  }

  /// The dock index for a `tab:` target, else null.
  static int? tabOf(String target) => target.startsWith(tabPrefix)
      ? tabs[target.substring(tabPrefix.length)]
      : null;
}

/// The icons a page may name. Kept to a fixed list so the console can
/// offer them and a document can never reference an icon the app lacks.
const whatsNewIcons = <String, IconData>{
  'auto_awesome': Icons.auto_awesome_rounded,
  'new_releases': Icons.new_releases_rounded,
  'celebration': Icons.celebration_rounded,
  'star': Icons.star_rounded,
  'lightbulb': Icons.lightbulb_rounded,
  'bolt': Icons.bolt_rounded,
  'restaurant_menu': Icons.restaurant_menu_rounded,
  'menu_book': Icons.menu_book_rounded,
  'library_books': Icons.library_books_rounded,
  'calendar_today': Icons.calendar_today_rounded,
  'shopping_cart': Icons.shopping_cart_rounded,
  'groups': Icons.groups_rounded,
  'forum': Icons.forum_rounded,
  'favorite': Icons.favorite_rounded,
  'timer': Icons.timer_rounded,
  'local_fire_department': Icons.local_fire_department_rounded,
  'monitor_heart': Icons.monitor_heart_rounded,
  'image': Icons.image_rounded,
  'image_search': Icons.image_search_rounded,
  'share': Icons.share_rounded,
  'qr_code': Icons.qr_code_rounded,
  'family_restroom': Icons.family_restroom_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'price_check': Icons.price_check_rounded,
  'notifications': Icons.notifications_rounded,
  'workspace_premium': Icons.workspace_premium_rounded,
  'translate': Icons.translate_rounded,
  'palette': Icons.palette_rounded,
  'school': Icons.school_rounded,
  'feedback': Icons.feedback_rounded,
  'devices': Icons.devices_rounded,
  'widgets': Icons.widgets_rounded,
  'mic': Icons.mic_rounded,
  'record_voice_over': Icons.record_voice_over_rounded,
  'smart_toy': Icons.smart_toy_rounded,
  'link': Icons.link_rounded,
  'video_library': Icons.video_library_rounded,
  'text_fields': Icons.text_fields_rounded,
  'picture_as_pdf': Icons.picture_as_pdf_rounded,
  'security': Icons.security_rounded,
};

IconData whatsNewIcon(String name) =>
    whatsNewIcons[name] ?? Icons.auto_awesome_rounded;
