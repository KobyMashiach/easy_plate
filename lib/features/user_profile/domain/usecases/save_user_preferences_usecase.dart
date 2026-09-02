import '../entities/user_preferences_entity.dart';
import '../repositories/user_preferences_repository.dart';

class SaveUserPreferencesUseCase {
  final UserPreferencesRepository repository;
  SaveUserPreferencesUseCase(this.repository);

  Future<void> call(UserPreferencesEntity preferences) => repository.savePreferences(preferences);
}
