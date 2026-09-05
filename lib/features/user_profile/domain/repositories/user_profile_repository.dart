import 'dart:io';

import '../entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  /// Null when the account has no profile document yet — the signal that the
  /// registration screen still has to run.
  Future<UserProfileEntity?> getProfile(String uid);
  Future<void> saveProfile(UserProfileEntity profile);

  /// Uploads to Firebase Storage and returns the download URL.
  Future<String> uploadPhoto(String uid, File file);

  Future<void> savePushToken(String uid, String token);
}
