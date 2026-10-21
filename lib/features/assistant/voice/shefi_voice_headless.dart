import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../core/hive/adapters_controller.dart';
import '../../../core/hive/user_scope.dart';
import '../../../core/monetization/entitlement_service.dart';
import '../../../core/services/device_locale_store.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/sync/cloud_sync_service.dart';
import '../../../core/sync/recipe_image_store.dart';
import '../../../core/utils/i18n/app_language_mapper.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../grocery_list/data/datasources/grocery_lists_local_datasource.dart';
import '../../grocery_list/data/repositories_impl/grocery_lists_repository_impl.dart';
import '../../meal_planner/data/datasources/meal_plans_local_datasource.dart';
import '../../meal_planner/data/repositories_impl/meal_plans_repository_impl.dart';
import '../../my_recipes/data/datasources/recipes_local_datasource.dart';
import '../../my_recipes/data/repositories_impl/recipes_repository_impl.dart';
import '../../recipe_books/data/datasources/recipe_books_local_datasource.dart';
import '../../recipe_books/data/repositories_impl/recipe_books_repository_impl.dart';
import '../../recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import '../../recipe_ingestion/data/datasources/web_page_datasource.dart';
import '../../recipe_ingestion/data/repositories_impl/recipe_ingestion_repository_impl.dart';
import '../../feedback/data/datasources/feedback_remote_datasource.dart';
import '../../feedback/data/repositories_impl/feedback_repository_impl.dart';
import '../../user_profile/data/datasources/user_preferences_local_datasource.dart';
import '../../user_profile/data/repositories_impl/user_preferences_repository_impl.dart';
import '../../collab_containers/data/datasources/collab_containers_remote_datasource.dart';
import '../../collab_containers/data/repositories_impl/collab_containers_repository_impl.dart';
import '../../collab_containers/domain/container_sharing_service.dart';
import '../../recipe_sharing/data/datasources/recipe_sharing_remote_datasource.dart';
import '../../recipe_sharing/data/repositories_impl/recipe_sharing_repository_impl.dart';
import '../../user_profile/data/datasources/user_profile_remote_datasource.dart';
import '../../user_profile/data/repositories_impl/user_profile_repository_impl.dart';
import 'shefi_voice_channel.dart';
import 'shefi_voice_runner.dart';

/// The body of the `shefiVoiceMain` entry point: a Dart isolate with no UI,
/// started by the native side when a system assistant asks Shefi something
/// and the app itself is not running.
///
/// It brings up only what the agent needs (Firebase, Hive, the signed-in
/// account's scope, the plan, the language) and the same repositories the
/// app builds, then says `ready`. The native side destroys the engine once
/// the answer is back, so it never lives alongside the app's own engine
/// for long; the boxes are written through Hive the same way the app
/// writes them.
Future<void> runShefiVoiceHeadless() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService().init();
    await Hive.initFlutter();
    await AdaptersController.registerAdapters();

    final preferencesRepository = UserPreferencesRepositoryImpl(
      localDataSource: UserPreferencesLocalDataSourceImpl(),
      cloud: CloudSyncService().preferences,
    );
    final recipes = RecipesRepositoryImpl(
      localDataSource: RecipesLocalDataSourceImpl(),
      cloud: CloudSyncService().recipes,
      images: RecipeImageStore(),
    );
    final books = RecipeBooksRepositoryImpl(
      localDataSource: RecipeBooksLocalDataSourceImpl(),
      cloud: CloudSyncService().books,
      images: RecipeImageStore(),
    );
    final plans = MealPlansRepositoryImpl(
      localDataSource: MealPlansLocalDataSourceImpl(),
      cloud: CloudSyncService().mealPlans,
    );
    final groceries = GroceryListsRepositoryImpl(
      localDataSource: GroceryListsLocalDataSourceImpl(),
      cloud: CloudSyncService().groceryLists,
    );
    // The same sharing services the app builds, so an edit Siri makes to a
    // shared recipe, book, plan or list reaches the other members.
    final recipeSharing = RecipeSharingRepositoryImpl(
      remoteDataSource: RecipeSharingFirestoreDataSource(),
    );
    final sharing = ContainerSharingService(
      containers: CollabContainersRepositoryImpl(
        remote: CollabContainersFirestoreDataSource(),
      ),
      sharing: recipeSharing,
      recipes: recipes,
      profiles: UserProfileRepositoryImpl(
        remoteDataSource: UserProfileFirestoreDataSource(),
      ),
      booksRepository: books,
      plansRepository: plans,
      listsRepository: groceries,
    );
    final runner = ShefiVoiceRunner(
      recipes: recipes,
      books: books,
      plans: plans,
      groceries: groceries,
      sharing: sharing,
      recipeSharing: recipeSharing,
      activeList: HiveActiveGroceryListStore.instance,
      ingestion: RecipeIngestionRepositoryImpl(
        aiDataSource: GeminiRecipeAiDataSource(),
        webPageDataSource: WebPageDataSourceImpl(),
      ),
      preferences: preferencesRepository,
      feedback: FeedbackRepositoryImpl(
        remoteDataSource: FeedbackFirestoreDataSource(),
      ),
    );

    final user =
        FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
    if (user != null) {
      await UserScope().switchTo(user.uid);
      EntitlementService().watch(user.uid);
      try {
        final preferences = await preferencesRepository.getPreferences();
        await LocaleSettings.setLocale(preferences.language.locale);
      } catch (_) {
        final device = await DeviceLocaleStore().read();
        if (device != null) await LocaleSettings.setLocale(device.locale);
      }
    }
    ShefiVoiceChannel.bind(runner);
  } catch (e) {
    debugPrint('Shefi voice headless start failed: $e');
  }
  await ShefiVoiceChannel.ready();
}
