import '../../features/user_profile/data/datasources/user_preferences_local_datasource.dart';
import '../../features/user_profile/data/repositories_impl/user_preferences_repository_impl.dart';
import '../../features/user_profile/domain/entities/user_preferences_entity.dart';

/// Resolved once during startup so the router knows whether onboarding is
/// still pending, and the reminder scheduler knows the configured day.
class AppDependencies {
  final UserPreferencesEntity preferences;

  const AppDependencies({required this.preferences});

  static Future<AppDependencies> create() async {
    final repository = UserPreferencesRepositoryImpl(
      localDataSource: UserPreferencesLocalDataSourceImpl(),
    );
    return AppDependencies(preferences: await repository.getPreferences());
  }
}
