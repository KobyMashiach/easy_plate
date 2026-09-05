import '../entities/app_user_entity.dart';
import '../repositories/auth_repository.dart';

class StartPhoneVerificationUseCase {
  final AuthRepository repository;
  StartPhoneVerificationUseCase(this.repository);

  Future<String> call(
    String phoneNumber, {
    void Function(AppUserEntity user)? autoResolved,
  }) =>
      repository.startPhoneVerification(phoneNumber, autoResolved: autoResolved);
}
