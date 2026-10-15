import 'user_permission.dart';

export 'user_permission.dart';

/// The account profile stored in Firestore, separate from the local
/// [UserPreferencesEntity] which stays device-side.
class UserProfileEntity {
  final String uid;
  final String fullName;
  final String? email;
  final String? phoneNumber;

  /// Download URL of the photo in Firebase Storage. Remote, unlike recipe
  /// photos, because a profile picture has to survive a reinstall.
  final String? photoUrl;
  final String? pushToken;
  final DateTime createdAt;

  /// What the account may do, from `users/{uid}.permission`. Set only in
  /// the Firebase console (the rules refuse it from the app).
  final UserPermission permission;

  const UserProfileEntity({
    required this.uid,
    required this.fullName,
    required this.createdAt,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.pushToken,
    this.permission = UserPermission.user,
  });

  /// A profile the user has actually filled in. Google gives us a name for
  /// free; email and phone sign-ups arrive without one.
  bool get isComplete => fullName.trim().isNotEmpty;

  UserProfileEntity copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? pushToken,
  }) {
    return UserProfileEntity(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      pushToken: pushToken ?? this.pushToken,
      createdAt: createdAt,
      permission: permission,
    );
  }
}
