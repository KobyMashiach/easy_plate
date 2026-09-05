import '../../domain/entities/app_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Stream<AppUserEntity?> authStateChanges() => dataSource.authStateChanges();

  @override
  AppUserEntity? get currentUser => dataSource.currentUser;

  @override
  Future<AppUserEntity> signInWithEmail(String email, String password) =>
      dataSource.signInWithEmail(email, password);

  @override
  Future<AppUserEntity> registerWithEmail(String email, String password) =>
      dataSource.registerWithEmail(email, password);

  @override
  Future<AppUserEntity> signInWithGoogle() => dataSource.signInWithGoogle();

  @override
  Future<void> sendPasswordReset(String email) => dataSource.sendPasswordReset(email);

  @override
  Future<String> startPhoneVerification(
    String phoneNumber, {
    void Function(AppUserEntity user)? autoResolved,
    void Function(Object error)? onFailed,
  }) =>
      dataSource.startPhoneVerification(
        phoneNumber,
        autoResolved: autoResolved,
        onFailed: onFailed,
      );

  @override
  Future<AppUserEntity> confirmPhoneCode(String verificationId, String smsCode) =>
      dataSource.confirmPhoneCode(verificationId, smsCode);

  @override
  Future<void> signOut() => dataSource.signOut();
}
