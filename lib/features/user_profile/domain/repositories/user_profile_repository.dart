import 'dart:io';

import '../entities/public_profile_entity.dart';
import '../entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  /// Null when the account has no profile document yet — the signal that the
  /// registration screen still has to run.
  Future<UserProfileEntity?> getProfile(String uid);
  Future<void> saveProfile(UserProfileEntity profile);

  /// Uploads to Firebase Storage and returns the download URL.
  Future<String> uploadPhoto(String uid, File file);

  Future<void> savePushToken(String uid, String token);

  /// Display names and photos for [uids], read live rather than from a copy
  /// stored at post time — so renaming shows up everywhere on the next read.
  /// Uids with no public profile are simply absent from the result.
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(Set<String> uids);

  /// Writes only the public half. Backfills accounts created before the
  /// public document existed, so their old posts stop showing a stale name.
  Future<void> publishPublicProfile(UserProfileEntity profile);

  /// Resolves an email or phone to a uid through the hashed directory, or
  /// null when nobody has registered that contact.
  Future<String?> findUidByContact(String contact);
}
