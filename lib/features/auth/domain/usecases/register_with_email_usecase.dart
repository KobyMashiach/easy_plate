import '../entities/app_user_entity.dart';
import '../repositories/auth_repository.dart';

/// Not reachable from the UI. An account is opened by phone and nothing else,
/// so the login screen offers email as a way back in, never as a way to sign
/// up. Kept because the repository mirrors Firebase's own surface.
///
/// Wiring this to a button would not actually bypass the rule — the account it
/// creates carries no `phone` provider, so [AuthStage.needsPhone] holds it at
/// the gate — but it would produce an account the user cannot explain.
class RegisterWithEmailUseCase {
  final AuthRepository repository;
  RegisterWithEmailUseCase(this.repository);

  Future<AppUserEntity> call(String email, String password) =>
      repository.registerWithEmail(email, password);
}
