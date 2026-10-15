import '../../features/user_profile/domain/entities/user_profile_entity.dart';
import 'auth_session_service.dart';
import 'firebase_service.dart';

/// What the signed-in account's `permission` grants in the UI (see
/// [UserPermission]). The Firestore rules and the functions read the same
/// field, so this only decides what is shown.
abstract class AdminAccess {
  static bool get isAdmin =>
      AuthSessionService().profile?.permission == UserPermission.admin;

  static bool get isSuperuser =>
      AuthSessionService().profile?.permission == UserPermission.superuser;

  /// Whether every feature flag reads as on for this account: always for a
  /// superuser, and for the administrator while the console's
  /// `admin_all_features` is true. Off, the administrator is treated like
  /// any account — the way to see what free and Premium users see.
  static bool get hasAllFeatures =>
      isSuperuser ||
      (isAdmin &&
          FirebaseService().remoteBool(FirebaseService.adminAllFeaturesKey));
}
