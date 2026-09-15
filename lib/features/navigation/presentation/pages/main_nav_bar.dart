import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../community/presentation/pages/community_page.dart';
import '../../../grocery_list/presentation/pages/grocery_list_page.dart';
import '../../../meal_planner/presentation/pages/meal_planner_page.dart';
import '../../../my_recipes/presentation/pages/my_recipes_page.dart';
import '../../../recipe_books/presentation/pages/library_page.dart';
import '../../../user_profile/domain/repositories/user_preferences_repository.dart';

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  /// The account the first-run tour was already offered to in this process,
  /// so a locale change — which rebuilds this widget — does not offer it
  /// twice. A different account signing in gets its own offer.
  static String? _tourOfferedTo;

  @override
  void initState() {
    super.initState();
    // The main screen is where a signed-in session lands: the token goes
    // to the log each time, so a test push always has a fresh one to use.
    FirebaseService().logPushToken();
    MainTabs.index.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerFirstRunTour());
  }

  @override
  void dispose() {
    MainTabs.index.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() => setState(() {});

  /// A new account is walked through the app once. Finished or closed, the
  /// flag is saved with the preferences so it never comes back on its own —
  /// the support screen is where it can be run again.
  Future<void> _offerFirstRunTour() async {
    final uid = AuthSessionService().user?.uid;
    if (uid == null || _tourOfferedTo == uid || !mounted) return;
    _tourOfferedTo = uid;

    final preferences = context.read<UserPreferencesRepository>();
    final current = await preferences.getPreferences();
    if (current.walkthroughSeen || !mounted) return;

    Walkthrough.start(
      context,
      firstRunWalkthrough(),
      onDone: (_) async {
        final latest = await preferences.getPreferences();
        await preferences.savePreferences(latest.copyWith(walkthroughSeen: true));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // `context.t` subscribes to the locale, so switching language rebuilds the
    // dock straight away. The global `t` would not: this widget is built as a
    // const instance, so Flutter skips it when only the locale changed and the
    // labels stayed stale until something else forced a rebuild.
    final t = context.t;
    final index = MainTabs.index.value;

    // Keying each tab by locale remounts them — and so re-reads the global `t`
    // they build with — the moment the language changes, while leaving them
    // untouched on every other rebuild. Const instances would be identical
    // across builds, which is what left the tabs in the old language.
    final locale = LocaleSettings.currentLocale;
    // Recipes lead: they are the home tab, with the books right after them.
    final pages = [
      MyRecipesPage(key: ValueKey('recipes-$locale')),
      LibraryPage(key: ValueKey('library-$locale')),
      MealPlannerPage(key: ValueKey('mealPlanner-$locale')),
      GroceryListPage(key: ValueKey('groceries-$locale')),
      CommunityPage(key: ValueKey('community-$locale')),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      // The dock floats above the content rather than displacing it, so pages
      // reserve ClayNavDock.bottomPadding at the bottom of their scroll views.
      body: Stack(
        children: [
          IndexedStack(index: index, children: pages),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              // Android needs the gesture-bar inset; on iOS the dock's own
              // bottom margin already clears the home indicator, so reserving
              // it again just floats the dock too high.
              bottom: defaultTargetPlatform == TargetPlatform.android,
              child: ClayNavDock(
                selectedIndex: index,
                onSelected: (selected) => MainTabs.index.value = selected,
                destinations: [
                  ClayNavDestination(
                    icon: Icons.receipt_long_rounded,
                    label: t.nav.recipes,
                  ),
                  ClayNavDestination(
                    icon: Icons.library_books_rounded,
                    label: t.nav.library,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
