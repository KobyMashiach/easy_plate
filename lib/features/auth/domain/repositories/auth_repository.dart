import '../entities/app_user_entity.dart';

abstract class AuthRepository {
  /// Emits on sign-in, sign-out and token refresh. Emits null when signed out.
  Stream<AppUserEntity?> authStateChanges();

  AppUserEntity? get currentUser;

  Future<AppUserEntity> signInWithEmail(String email, String password);
  Future<AppUserEntity> registerWithEmail(String email, String password);
  Future<AppUserEntity> signInWithGoogle();
  Future<void> sendPasswordReset(String email);

  /// Starts SMS verification and resolves with the verification id needed by
  /// [confirmPhoneCode]. Android may verify without any code being typed; that
  /// arrives on [autoResolved] instead.
  Future<String> startPhoneVerification(
    String phoneNumber, {
    void Function(AppUserEntity user)? autoResolved,
    void Function(Object error)? onFailed,
  });

  Future<AppUserEntity> confirmPhoneCode(String verificationId, String smsCode);

  Future<void> signOut();
}
