import '../../../../core/hive/user_scope.dart';

import '../models/user_preferences_model.dart';

abstract class UserPreferencesLocalDataSource {
  Future<UserPreferencesModel?> getPreferences();
  Future<void> savePreferences(UserPreferencesModel preferences);
}

class UserPreferencesLocalDataSourceImpl implements UserPreferencesLocalDataSource {
  @override
  Future<UserPreferencesModel?> getPreferences() async {
    final box = await UserScope().open<UserPreferencesModel>(UserPreferencesModel.hiveKey);
    return box.get(UserPreferencesModel.storageKey);
  }

  @override
  Future<void> savePreferences(UserPreferencesModel preferences) async {
    final box = await UserScope().open<UserPreferencesModel>(UserPreferencesModel.hiveKey);
    await box.put(UserPreferencesModel.storageKey, preferences);
  }
}
