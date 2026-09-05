import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories_impl/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/forum/data/datasources/forum_remote_datasource.dart';
import '../../features/forum/data/repositories_impl/forum_repository_impl.dart';
import '../../features/forum/domain/repositories/forum_repository.dart';
import '../../features/grocery_list/data/datasources/grocery_lists_local_datasource.dart';
import '../../features/grocery_list/data/repositories_impl/grocery_lists_repository_impl.dart';
import '../../features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../features/meal_planner/data/datasources/meal_plans_local_datasource.dart';
import '../../features/meal_planner/data/repositories_impl/meal_plans_repository_impl.dart';
import '../../features/meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../features/my_recipes/data/datasources/recipes_local_datasource.dart';
import '../../features/my_recipes/data/repositories_impl/recipes_repository_impl.dart';
import '../../features/my_recipes/domain/repositories/recipes_repository.dart';
import '../../features/recipe_books/data/datasources/recipe_books_local_datasource.dart';
import '../../features/recipe_books/data/repositories_impl/recipe_books_repository_impl.dart';
import '../../features/recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import '../../features/recipe_ingestion/data/repositories_impl/recipe_ingestion_repository_impl.dart';
import '../../features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../features/shared_recipes/data/datasources/shared_recipes_remote_datasource.dart';
import '../../features/shared_recipes/data/repositories_impl/shared_recipes_repository_impl.dart';
import '../../features/shared_recipes/domain/repositories/shared_recipes_repository.dart';
import '../../features/user_profile/data/datasources/user_preferences_local_datasource.dart';
import '../../features/user_profile/data/datasources/user_profile_remote_datasource.dart';
import '../../features/user_profile/data/repositories_impl/user_profile_repository_impl.dart';
import '../../features/user_profile/domain/repositories/user_profile_repository.dart';
import '../../features/user_profile/data/repositories_impl/user_preferences_repository_impl.dart';
import '../../features/user_profile/domain/repositories/user_preferences_repository.dart';

/// Data sources first, then the repositories that read them — order matters,
/// `create:` resolves earlier entries with `context.read`.
List<SingleChildWidget> buildRepositoryProviders() {
  return [
    RepositoryProvider<UserPreferencesLocalDataSource>(
      create: (_) => UserPreferencesLocalDataSourceImpl(),
    ),
    RepositoryProvider<AuthDataSource>(create: (_) => FirebaseAuthDataSource()),
    RepositoryProvider<UserProfileRemoteDataSource>(
      create: (_) => UserProfileFirestoreDataSource(),
    ),
    RepositoryProvider<ForumRemoteDataSource>(create: (_) => ForumFirestoreDataSource()),
    RepositoryProvider<SharedRecipesRemoteDataSource>(
      create: (_) => SharedRecipesFirestoreDataSource(),
    ),
    RepositoryProvider<RecipesLocalDataSource>(create: (_) => RecipesLocalDataSourceImpl()),
    RepositoryProvider<RecipeBooksLocalDataSource>(create: (_) => RecipeBooksLocalDataSourceImpl()),
    RepositoryProvider<MealPlansLocalDataSource>(create: (_) => MealPlansLocalDataSourceImpl()),
    RepositoryProvider<GroceryListsLocalDataSource>(
      create: (_) => GroceryListsLocalDataSourceImpl(),
    ),
    RepositoryProvider<RecipeAiDataSource>(create: (_) => GeminiRecipeAiDataSource()),
    RepositoryProvider<AuthRepository>(
      create: (context) => AuthRepositoryImpl(dataSource: context.read()),
    ),
    RepositoryProvider<ForumRepository>(
      create: (context) => ForumRepositoryImpl(remoteDataSource: context.read()),
    ),
    RepositoryProvider<SharedRecipesRepository>(
      create: (context) => SharedRecipesRepositoryImpl(remoteDataSource: context.read()),
    ),
    RepositoryProvider<UserProfileRepository>(
      create: (context) => UserProfileRepositoryImpl(remoteDataSource: context.read()),
    ),
    RepositoryProvider<UserPreferencesRepository>(
      create: (context) => UserPreferencesRepositoryImpl(localDataSource: context.read()),
    ),
    RepositoryProvider<RecipesRepository>(
      create: (context) => RecipesRepositoryImpl(localDataSource: context.read()),
    ),
    RepositoryProvider<RecipeBooksRepository>(
      create: (context) => RecipeBooksRepositoryImpl(localDataSource: context.read()),
    ),
    RepositoryProvider<MealPlansRepository>(
      create: (context) => MealPlansRepositoryImpl(localDataSource: context.read()),
    ),
    RepositoryProvider<GroceryListsRepository>(
      create: (context) => GroceryListsRepositoryImpl(localDataSource: context.read()),
    ),
    RepositoryProvider<RecipeIngestionRepository>(
      create: (context) => RecipeIngestionRepositoryImpl(aiDataSource: context.read()),
    ),
  ];
}
