import '../repositories/auth_repository.dart';

class RefreshEmailVerifiedUseCase {
  final AuthRepository repository;
  RefreshEmailVerifiedUseCase(this.repository);

  Future<bool> call() => repository.refreshEmailVerified();
}
