import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_local_datasource.dart';
import '../models/user_preferences_model.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final UserPreferencesLocalDataSource localDataSource;

  UserPreferencesRepositoryImpl({required this.localDataSource});

  static const _defaultPreferences = UserPreferencesEntity(
    shoppingDay: ShoppingDay.sunday,
    dietaryPreferences: [],
  );

  @override
  Future<UserPreferencesEntity> getPreferences() async {
    final model = await localDataSource.getPreferences();
    return model?.toEntity() ?? _defaultPreferences;
  }

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) {
    return localDataSource.savePreferences(preferences.toModel());
  }
}
