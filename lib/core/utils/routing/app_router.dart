import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/phone_verification_page.dart';
import '../../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/forum/domain/entities/forum_post_entity.dart';
import '../../../features/forum/presentation/pages/forum_thread_page.dart';
import '../../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../../features/my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../features/my_recipes/presentation/pages/recipe_editor_page.dart';
import '../../../features/navigation/presentation/pages/main_nav_bar.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/recipe_books/presentation/pages/book_viewer_page.dart';
import '../../../features/recipe_ingestion/presentation/pages/ingestion_page.dart';
import '../../services/auth_session_service.dart';
import '../../services/firebase_service.dart';
import 'routing.dart';

/// The screen each unfinished stage owns. Everything else redirects to
/// whatever the current [AuthStage] demands.
const _stageEntryPoint = {
  AuthStage.unknown: Routing.splash,
  AuthStage.signedOut: Routing.login,
  AuthStage.needsProfile: Routing.register,
  AuthStage.needsOnboarding: Routing.onboarding,
};

/// The gate's whole decision, as a pure function so it can be exercised
/// without a Firebase-initialised router around it.
///
/// Returns the location to redirect to, or null to let [location] through.
String? gateRedirect({required AuthStage stage, required String location}) {
  if (stage == AuthStage.ready) {
    // Nothing left to gate; the gate's own screens must not stay reachable.
    return _stageEntryPoint.values.contains(location) ? Routing.home : null;
  }

  // The SMS code screen belongs to the signed-out stage: the user is mid
  // sign-in and must not be bounced back to the login form.
  if (stage == AuthStage.signedOut && location == Routing.phoneVerify) return null;

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
        path: Routing.phoneVerify,
        name: Routing.phoneVerify,
        builder: (context, state) =>
            PhoneVerificationPage(args: state.extra as PhoneVerificationArgs),
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
            builder: (context, state) => BookViewerPage(bookId: state.extra as String),
          ),
          GoRoute(
            path: Routing.recipeDetails,
            name: Routing.recipeDetails,
            builder: (context, state) => RecipeDetailsPage(recipe: state.extra as RecipeEntity),
          ),
          GoRoute(
            path: Routing.recipeEditor,
            name: Routing.recipeEditor,
            builder: (context, state) => RecipeEditorPage(recipe: state.extra as RecipeEntity),
          ),
          GoRoute(
            path: Routing.forumThread,
            name: Routing.forumThread,
            builder: (context, state) =>
                ForumThreadPage(post: state.extra as ForumPostEntity),
          ),
          GoRoute(
            path: Routing.ingestion,
            name: Routing.ingestion,
            builder: (context, state) => const IngestionPage(),
          ),
        ],
      ),
    ],
  );
}
