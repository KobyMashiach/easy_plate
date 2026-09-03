import 'package:go_router/go_router.dart';

import '../../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../../features/my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../features/my_recipes/presentation/pages/recipe_editor_page.dart';
import '../../../features/navigation/presentation/pages/main_nav_bar.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/recipe_books/presentation/pages/book_viewer_page.dart';
import '../../../features/recipe_ingestion/presentation/pages/ingestion_page.dart';
import 'routing.dart';

GoRouter buildRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: onboardingComplete ? Routing.home : Routing.onboarding,
    routes: [
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
            path: Routing.ingestion,
            name: Routing.ingestion,
            builder: (context, state) => const IngestionPage(),
          ),
        ],
      ),
    ],
  );
}
