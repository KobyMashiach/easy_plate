import '../../features/user_profile/domain/entities/user_profile_entity.dart';
import 'auth_session_service.dart';

/// Whether the signed-in account is an administrator: its users document
/// says `permission: "admin"` (see [UserPermission]). The Firestore rules and
/// the functions read the same field, so this only decides what is shown.
abstract class AdminAccess {
  static bool get isAdmin =>
      AuthSessionService().profile?.permission == UserPermission.admin;
}
