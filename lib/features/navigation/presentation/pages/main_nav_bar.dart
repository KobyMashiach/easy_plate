import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../assistant/presentation/widgets/assistant_fab.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../community/presentation/pages/community_page.dart';
import '../../../grocery_list/presentation/pages/grocery_list_page.dart';
import '../../../meal_planner/presentation/pages/meal_planner_page.dart';
import '../../../my_recipes/presentation/pages/my_recipes_page.dart';
import '../../../recipe_books/presentation/pages/library_page.dart';
import '../../../share_codes/domain/pending_share_code.dart';
import '../../../user_profile/domain/repositories/user_preferences_repository.dart';
import '../../../../core/features/feature_gate.dart';

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

  /// The five tabs, built once per locale. Rebuilding them on every tab
  /// switch — as a setState here once did — re-ran the build of all five,
  /// hidden ones included, with their filtering and price estimates.
  List<Widget>? _pages;
  AppLocale? _pagesLocale;

  @override
  void initState() {
    super.initState();
    // The main screen is where a signed-in session lands: the token goes
    // to the log each time, so a test push always has a fresh one to use.
    FirebaseService().logPushToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingShareCode();
      _offerFirstRunTour();
    });
  }

  /// A share link that arrived while the session was not ready for it.
  void _openPendingShareCode() {
    final code = PendingShareCode.take();
    if (code == null || !mounted) return;
    context.pushNamed(Routing.joinCode, queryParameters: {'code': code});
  }

  List<Widget> _pagesFor(AppLocale locale) {
    if (_pagesLocale == locale && _pages != null) return _pages!;
    _pagesLocale = locale;
    // Keying each tab by locale remounts them — and so re-reads the global
    // `t` they build with — the moment the language changes, while leaving
    // them untouched on every other rebuild.
    // Recipes lead: they are the home tab, with the books right after them.
    return _pages = [
      MyRecipesPage(key: ValueKey('recipes-$locale')),
      LibraryPage(key: ValueKey('library-$locale')),
      MealPlannerPage(key: ValueKey('mealPlanner-$locale')),
      GroceryListPage(key: ValueKey('groceries-$locale')),
      CommunityPage(key: ValueKey('community-$locale')),
    ];
  }

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
    // Switched off in the console: the tour waits, unmarked, for the day it
    // is switched back on.
    if (!FeaturesFlags.walkthrough.isEnabled) {
      _tourOfferedTo = null;
      return;
    }

    Walkthrough.start(
      context,
      firstRunWalkthrough(),
      onDone: (_) async {
        final latest = await preferences.getPreferences();
        await preferences.savePreferences(
          latest.copyWith(walkthroughSeen: true),
        );
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
    final pages = _pagesFor(LocaleSettings.currentLocale);
    final destinations = [
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
      ClayNavDestination(icon: Icons.groups_rounded, label: t.nav.community),
    ];

    // Which tabs the console lets through. Recipes are the home tab and
    // have no switch; a tab marked "coming soon" keeps its place in the
    // dock and opens on a notice instead of its page.
    const features = <FeaturesFlags?>[
      null,
      FeaturesFlags.books,
      FeaturesFlags.mealPlans,
      FeaturesFlags.groceryLists,
      FeaturesFlags.community,
    ];

    // Only the stack's index and the dock follow a tab switch; the pages
    // themselves are the same instances and are left alone.
    return ListenableBuilder(
      listenable: FeaturesFlags.listenable,
      builder: (context, _) {
        final states = [
          for (final feature in features)
            feature == null ? FeatureAccess.enabled : feature.access,
        ];
        final visible = [
          for (var i = 0; i < pages.length; i++)
            if (states[i].isVisible) i,
        ];
        final children = [
          for (var i = 0; i < pages.length; i++)
            // A gated tab (coming soon, or Premium on a free account) keeps
            // its place in the dock and opens on the notice instead.
            states[i].isEnabled
                ? pages[i]
                : GatedTab(
                    key: ValueKey('gated-$i-${states[i].name}'),
                    label: destinations[i].label,
                    feature: features[i]!,
                    access: states[i],
                  ),
        ];
        return ValueListenableBuilder<int>(
          valueListenable: MainTabs.index,
          builder: (context, index, _) {
            // A hidden tab can still be asked for (a reminder tap, the
            // assistant): the first visible one stands in.
            final current = visible.contains(index) ? index : visible.first;
            return Scaffold(
              backgroundColor: AppColors.background,
              // The dock floats above the content rather than displacing
              // it, so pages reserve ClayNavDock.bottomPadding at the
              // bottom of their scroll views.
              body: Stack(
                children: [
                  IndexedStack(index: current, children: children),
                  // The copilot, on every tab, in the end corner above the
                  // dock. A page's own floating button takes the start
                  // corner, on the same baseline, so neither hides the other.
                  PositionedDirectional(
                    end: AppSpacing.marginMobile,
                    bottom: ClayNavDock.fabBottom(context),
                    // Drawn only when the assistant is open to this account:
                    // a greyed pill with a tag sat on top of whatever the
                    // page had in that corner. The account menu's row keeps
                    // the locked / coming-soon state and the way to Premium.
                    child: FeatureGate.builder(
                      feature: FeaturesFlags.assistant,
                      builder: (context, access) => access.isEnabled
                          ? const AssistantFab()
                          : const SizedBox.shrink(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      // Android needs the gesture-bar inset; on iOS the
                      // dock's own bottom margin already clears the home
                      // indicator, so reserving it again just floats the
                      // dock too high.
                      bottom: defaultTargetPlatform == TargetPlatform.android,
                      child: ClayNavDock(
                        selectedIndex: visible.indexOf(current),
                        onSelected: (selected) =>
                            MainTabs.index.value = visible[selected],
                        destinations: [
                          for (final i in visible) destinations[i],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
