import '../repositories/auth_repository.dart';

class LinkPhoneUseCase {
  final AuthRepository repository;
  LinkPhoneUseCase(this.repository);

  Future<String> start(String phoneNumber) => repository.startPhoneLink(phoneNumber);

  Future<void> confirm(String verificationId, String smsCode) =>
      repository.linkPhone(verificationId, smsCode);
}
