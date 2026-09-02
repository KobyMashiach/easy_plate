import '../entities/user_preferences_entity.dart';

abstract class UserPreferencesRepository {
  Future<UserPreferencesEntity> getPreferences();
  Future<void> savePreferences(UserPreferencesEntity preferences);
}
