import '../constants/app_constants.dart';
import 'auth_session_service.dart';

/// Whether the signed-in account is the app's administrator: the one email
/// in [kAdminEmail], compared case-insensitively. The server enforces the
/// same address in the Firestore rules, so this only decides what is shown.
abstract class AdminAccess {
  static bool get isAdmin =>
      AuthSessionService().user?.email?.trim().toLowerCase() == kAdminEmail;
}
