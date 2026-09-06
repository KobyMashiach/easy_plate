import '../repositories/auth_repository.dart';

class LinkAppleUseCase {
  final AuthRepository repository;

  LinkAppleUseCase(this.repository);

  Future<void> call() => repository.linkApple();
}
