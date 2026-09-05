import 'dart:io';

import '../entities/user_profile_entity.dart';
import '../repositories/user_profile_repository.dart';

class SaveUserProfileUseCase {
  final UserProfileRepository repository;
  SaveUserProfileUseCase(this.repository);

  /// Uploads [photo] first when one was picked, so the saved document already
  /// carries the final URL and the screen never shows a profile without it.
  Future<UserProfileEntity> call(UserProfileEntity profile, {File? photo}) async {
    var result = profile;
    if (photo != null) {
      result = result.copyWith(photoUrl: await repository.uploadPhoto(profile.uid, photo));
    }
    await repository.saveProfile(result);
    return result;
  }
}
