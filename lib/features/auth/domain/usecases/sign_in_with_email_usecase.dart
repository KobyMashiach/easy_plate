import '../entities/app_user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository repository;
  SignInWithEmailUseCase(this.repository);

  Future<AppUserEntity> call(String email, String password) =>
      repository.signInWithEmail(email, password);
}
