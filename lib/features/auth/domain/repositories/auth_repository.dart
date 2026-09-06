import '../entities/app_user_entity.dart';

abstract class AuthRepository {
  /// Emits on sign-in, sign-out and token refresh. Emits null when signed out.
  Stream<AppUserEntity?> authStateChanges();

  AppUserEntity? get currentUser;

  Future<AppUserEntity> signInWithEmail(String email, String password);
  Future<AppUserEntity> registerWithEmail(String email, String password);
  Future<AppUserEntity> signInWithGoogle();
  Future<AppUserEntity> signInWithApple();
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

  /// Language for the SMS and email messages Firebase sends on our behalf.
  Future<void> setLanguage(String languageCode);

  Future<void> sendEmailVerification();

  /// Re-reads the account from the server and reports whether the email has
  /// been confirmed since.
  Future<bool> refreshEmailVerified();

  /// Attaches a phone number to the account that is already signed in, so a
  /// later phone sign-in resolves to this same user rather than a new one.
  Future<String> startPhoneLink(String phoneNumber);
  Future<void> linkPhone(String verificationId, String smsCode);

  /// The mirror of [startPhoneLink] for an account created by phone.
  Future<void> linkEmailPassword(String email, String password);

  /// Attaches a Google account. Also gives a phone-only account a verified
  /// email, since Firebase adopts Google's address when the account has none.
  Future<void> linkGoogle();
  Future<void> linkApple();
}
