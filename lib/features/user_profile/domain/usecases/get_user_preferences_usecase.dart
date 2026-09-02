import '../entities/user_preferences_entity.dart';
import '../repositories/user_preferences_repository.dart';

class GetUserPreferencesUseCase {
  final UserPreferencesRepository repository;
  GetUserPreferencesUseCase(this.repository);

  Future<UserPreferencesEntity> call() => repository.getPreferences();
}
