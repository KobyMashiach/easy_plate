import '../repositories/auth_repository.dart';

class LinkEmailPasswordUseCase {
  final AuthRepository repository;
  LinkEmailPasswordUseCase(this.repository);

  Future<void> call(String email, String password) =>
      repository.linkEmailPassword(email, password);
}
