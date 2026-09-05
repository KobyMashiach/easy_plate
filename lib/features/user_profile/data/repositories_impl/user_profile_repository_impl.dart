import 'dart:io';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;

  UserProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfileEntity?> getProfile(String uid) => remoteDataSource.getProfile(uid);

  @override
  Future<void> saveProfile(UserProfileEntity profile) => remoteDataSource.saveProfile(profile);

  @override
  Future<String> uploadPhoto(String uid, File file) => remoteDataSource.uploadPhoto(uid, file);

  @override
  Future<void> savePushToken(String uid, String token) =>
      remoteDataSource.savePushToken(uid, token);
}
