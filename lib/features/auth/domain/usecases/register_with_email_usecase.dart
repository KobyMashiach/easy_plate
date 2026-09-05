import '../entities/app_user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  final AuthRepository repository;
  RegisterWithEmailUseCase(this.repository);

  Future<AppUserEntity> call(String email, String password) =>
      repository.registerWithEmail(email, password);
}
