import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../community/presentation/pages/community_page.dart';
import '../../../grocery_list/presentation/pages/grocery_list_page.dart';
import '../../../meal_planner/presentation/pages/meal_planner_page.dart';
import '../../../my_recipes/presentation/pages/my_recipes_page.dart';
import '../../../recipe_books/presentation/pages/library_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // `context.t` subscribes to the locale, so switching language rebuilds the
    // dock straight away. The global `t` would not: this widget is built as a
    // const instance, so Flutter skips it when only the locale changed and the
    // labels stayed stale until something else forced a rebuild.
    final t = context.t;

    // Keying each tab by locale remounts them — and so re-reads the global `t`
    // they build with — the moment the language changes, while leaving them
    // untouched on every other rebuild. Const instances would be identical
    // across builds, which is what left the tabs in the old language.
    final locale = LocaleSettings.currentLocale;
    final pages = [
      LibraryPage(key: ValueKey('library-$locale')),
      MyRecipesPage(key: ValueKey('recipes-$locale')),
      MealPlannerPage(key: ValueKey('mealPlanner-$locale')),
      GroceryListPage(key: ValueKey('groceries-$locale')),
      CommunityPage(key: ValueKey('community-$locale')),
      SettingsPage(key: ValueKey('settings-$locale')),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      // The dock floats above the content rather than displacing it, so pages
      // reserve ClayNavDock.reservedHeight at the bottom of their scroll views.
      body: Stack(
        children: [
          IndexedStack(index: _index, children: pages),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              // Android needs the gesture-bar inset; on iOS the dock's own
              // bottom margin already clears the home indicator, so reserving
              // it again just floats the dock too high.
              bottom: defaultTargetPlatform == TargetPlatform.android,
              child: ClayNavDock(
                selectedIndex: _index,
                onSelected: (index) => setState(() => _index = index),
                destinations: [
                  ClayNavDestination(
                    icon: Icons.library_books_rounded,
                    label: t.nav.library,
                  ),
                  ClayNavDestination(
                    icon: Icons.receipt_long_rounded,
                    label: t.nav.recipes,
                  ),
                  ClayNavDestination(
                    icon: Icons.calendar_today_rounded,
                    label: t.nav.mealPlan,
                  ),
                  ClayNavDestination(
                    icon: Icons.shopping_cart_rounded,
                    label: t.nav.groceries,
                  ),
                  ClayNavDestination(
                    icon: Icons.groups_rounded,
                    label: t.nav.community,
                  ),
                  ClayNavDestination(
                    icon: Icons.person_rounded,
                    label: t.nav.settings,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
