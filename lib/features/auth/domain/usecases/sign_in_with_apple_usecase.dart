import '../entities/app_user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithAppleUseCase {
  final AuthRepository repository;

  SignInWithAppleUseCase(this.repository);

  Future<AppUserEntity> call() => repository.signInWithApple();
}
