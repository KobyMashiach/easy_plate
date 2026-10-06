import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/meal_planner/presentation/pages/nutrition_dashboard_page.dart';
import '../../../features/price_book/presentation/pages/receipt_review_page.dart';
import '../../../features/price_book/presentation/pages/price_book_page.dart';
import '../../../features/price_book/presentation/pages/receipt_details_page.dart';
import '../../../features/price_book/domain/entities/receipt_entity.dart';
import '../../../features/price_book/presentation/pages/receipt_images_page.dart';
import '../../../features/auth/presentation/pages/phone_claimed_page.dart';
import '../../../features/auth/presentation/pages/phone_gate_page.dart';
import '../../../features/auth/presentation/pages/phone_verification_page.dart';
import '../../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../../features/auth/presentation/pages/email_verification_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/forum/domain/entities/forum_post_entity.dart';
import '../../../features/forum/presentation/pages/forum_thread_page.dart';
import '../../../features/more/presentation/pages/account_menu_page.dart';
import '../../../features/more/presentation/pages/sharing_management_page.dart';
import '../../../features/more/presentation/pages/support_page.dart';
import '../../../features/premium/presentation/pages/paywall_page.dart';
import '../../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../../features/my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../features/my_recipes/presentation/pages/cook_mode_page.dart';
import '../../../features/my_recipes/presentation/pages/recipe_editor_page.dart';
import '../../../features/navigation/presentation/pages/main_nav_bar.dart';
import '../../../features/notifications/presentation/pages/notifications_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/recipe_books/presentation/pages/book_viewer_page.dart';
import '../../../features/recipe_ingestion/domain/entities/ingestion_file.dart';
import '../../../features/recipe_ingestion/presentation/pages/ingestion_page.dart';
import '../../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../../features/settings/presentation/pages/preferences_page.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import '../../services/auth_session_service.dart';
import '../../services/firebase_service.dart';
import 'routing.dart';
import '../../monetization/entitlement_service.dart';
import '../../monetization/monetization_config.dart';
import '../../../features/more/presentation/pages/tutorial_book_page.dart';
import '../../../features/admin_dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../../features/auth/presentation/pages/blocked_page.dart';

/// The screen each unfinished stage owns. Everything else redirects to
/// whatever the current [AuthStage] demands.
const _stageEntryPoint = {
  AuthStage.unknown: Routing.splash,
  AuthStage.signedOut: Routing.login,
  AuthStage.needsPhone: Routing.phoneGate,
  AuthStage.needsEmailVerification: Routing.verifyEmail,
  AuthStage.needsProfile: Routing.register,
  AuthStage.phoneClaimed: Routing.phoneClaimed,
  AuthStage.needsOnboarding: Routing.onboarding,
  AuthStage.blocked: Routing.blocked,
};

/// The gate's whole decision, as a pure function so it can be exercised
/// without a Firebase-initialised router around it.
///
/// Returns the location to redirect to, or null to let [location] through.
String? gateRedirect({required AuthStage stage, required String location}) {
  if (stage == AuthStage.ready) {
    // Nothing left to gate; the gate's own screens must not stay reachable.
    // `phoneVerify` is listed separately because it is pushed with arguments
    // rather than being a stage's entry point, so it is not in the map.
    return _stageEntryPoint.values.contains(location) ||
            location == Routing.phoneVerify
        ? Routing.home
        : null;
  }

  // The SMS code screen belongs to the signed-out stage: the user is mid
  // sign-in and must not be bounced back to the login form.
  if (stage == AuthStage.signedOut && location == Routing.phoneVerify) {
    return null;
  }

  final destination = _stageEntryPoint[stage]!;
  return location == destination ? null : destination;
}

GoRouter buildRouter() {
  final session = AuthSessionService();

  return GoRouter(
    initialLocation: Routing.splash,
    refreshListenable: session,
    observers: [
      // Absent when Firebase failed to start; screen-view tracking is not worth
      // taking the whole router down for.
      if (FirebaseService().analytics case final analytics?)
        FirebaseAnalyticsObserver(analytics: analytics),
    ],
    redirect: (context, state) =>
        gateRedirect(stage: session.stage, location: state.matchedLocation),
    routes: [
      GoRoute(
        path: Routing.splash,
        name: Routing.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routing.login,
        name: Routing.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routing.blocked,
        name: Routing.blocked,
        builder: (context, state) => const BlockedPage(),
      ),
      GoRoute(
        path: Routing.phoneVerify,
        name: Routing.phoneVerify,
        builder: (context, state) =>
            PhoneVerificationPage(args: state.extra as PhoneVerificationArgs),
      ),
      GoRoute(
        path: Routing.phoneGate,
        name: Routing.phoneGate,
        builder: (context, state) => const PhoneGatePage(),
      ),
      GoRoute(
        path: Routing.verifyEmail,
        name: Routing.verifyEmail,
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: Routing.phoneClaimed,
        name: Routing.phoneClaimed,
        builder: (context, state) => const PhoneClaimedPage(),
      ),
      GoRoute(
        path: Routing.register,
        name: Routing.register,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: Routing.onboarding,
        name: Routing.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routing.home,
        name: Routing.home,
        builder: (context, state) => const MainNavBar(),
        routes: [
          GoRoute(
            path: Routing.bookDetails,
            name: Routing.bookDetails,
            builder: (context, state) =>
                BookViewerPage(bookId: state.extra as String),
          ),
          GoRoute(
            path: Routing.recipeDetails,
            name: Routing.recipeDetails,
            builder: (context, state) {
              final args = state.extra as RecipeDetailsArgs;
              return RecipeDetailsPage(
                recipe: args.recipe,
                readOnly: args.readOnly,
              );
            },
          ),
          GoRoute(
            path: Routing.cookMode,
            name: Routing.cookMode,
            // The plan gate lives here, so every door into cook mode (the
            // recipe, the inbox card, a notification tap) is gated at once.
            redirect: (context, state) async {
              // The verdict first: a paying account on a fresh install must
              // not be bounced on the default while its document loads.
              await EntitlementService().whenResolved();
              return MonetizationConfig.cookModeLocked
                  ? state.namedLocation(Routing.premium)
                  : null;
            },
            builder: (context, state) =>
                CookModePage(recipe: state.extra as RecipeEntity),
          ),
          GoRoute(
            path: Routing.priceBook,
            name: Routing.priceBook,
            builder: (context, state) => const PriceBookPage(),
          ),
          GoRoute(
            path: Routing.receiptImages,
            name: Routing.receiptImages,
            builder: (context, state) =>
                ReceiptImagesPage(receipt: state.extra as ReceiptEntity),
          ),
          GoRoute(
            path: Routing.receiptDetails,
            name: Routing.receiptDetails,
            builder: (context, state) =>
                ReceiptDetailsPage(receipt: state.extra as ReceiptEntity),
          ),
          GoRoute(
            path: Routing.receiptReview,
            name: Routing.receiptReview,
            builder: (context, state) {
              final args = state.extra as ReceiptReviewArgs;
              return ReceiptReviewPage(scan: args.scan, pages: args.pages);
            },
          ),
          GoRoute(
            path: Routing.nutritionDashboard,
            name: Routing.nutritionDashboard,
            builder: (context, state) => NutritionDashboardPage(
              args: state.extra as NutritionDashboardArgs,
            ),
          ),
          GoRoute(
            path: Routing.recipeEditor,
            name: Routing.recipeEditor,
            builder: (context, state) =>
                RecipeEditorPage(recipe: state.extra as RecipeEntity),
          ),
          GoRoute(
            path: Routing.accountMenu,
            name: Routing.accountMenu,
            builder: (context, state) => const AccountMenuPage(),
          ),
          GoRoute(
            path: Routing.settings,
            name: Routing.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: Routing.preferences,
            name: Routing.preferences,
            builder: (context, state) => const PreferencesPage(),
          ),
          GoRoute(
            path: Routing.notificationSettings,
            name: Routing.notificationSettings,
            builder: (context, state) => const NotificationSettingsPage(),
          ),
          GoRoute(
            path: Routing.profileEdit,
            name: Routing.profileEdit,
            builder: (context, state) =>
                const ProfileSetupPage(isEditing: true),
          ),
          GoRoute(
            path: Routing.notifications,
            name: Routing.notifications,
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: Routing.sharing,
            name: Routing.sharing,
            builder: (context, state) => const SharingManagementPage(),
          ),
          GoRoute(
            path: Routing.support,
            name: Routing.support,
            builder: (context, state) => const SupportPage(),
          ),
          GoRoute(
            path: Routing.premium,
            name: Routing.premium,
            builder: (context, state) => const PaywallPage(),
          ),
          GoRoute(
            path: Routing.forumThread,
            name: Routing.forumThread,
            // `?reply=` names the reply to scroll to — set by a tap on a
            // reply notification, absent when opened from the list.
            builder: (context, state) => ForumThreadPage(
              post: state.extra as ForumPostEntity,
              highlightReplyId: state.uri.queryParameters['reply'],
            ),
          ),
          GoRoute(
            path: Routing.ingestion,
            name: Routing.ingestion,
            builder: (context, state) =>
                IngestionPage(launch: state.extra as IngestionLaunch?),
          ),
          GoRoute(
            path: Routing.tutorial,
            name: Routing.tutorial,
            builder: (context, state) => const TutorialBookPage(),
          ),
          GoRoute(
            path: Routing.adminDashboard,
            name: Routing.adminDashboard,
            // `extra` picks the opening tab, by AdminDashboardTab index.
            builder: (context, state) => AdminDashboardPage(
              initialTab: state.extra is int ? state.extra as int : 0,
            ),
          ),
        ],
      ),
    ],
  );
}
