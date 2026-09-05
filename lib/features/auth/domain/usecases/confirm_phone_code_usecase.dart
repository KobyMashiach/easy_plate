import '../entities/app_user_entity.dart';
import '../repositories/auth_repository.dart';

class ConfirmPhoneCodeUseCase {
  final AuthRepository repository;
  ConfirmPhoneCodeUseCase(this.repository);

  Future<AppUserEntity> call(String verificationId, String smsCode) =>
      repository.confirmPhoneCode(verificationId, smsCode);
}
