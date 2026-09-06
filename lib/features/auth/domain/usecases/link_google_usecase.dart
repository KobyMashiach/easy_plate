import '../repositories/auth_repository.dart';

class LinkGoogleUseCase {
  final AuthRepository repository;
  LinkGoogleUseCase(this.repository);

  Future<void> call() => repository.linkGoogle();
}
