import 'dart:io';

import '../../domain/entities/public_profile_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;

  /// How long a fetched public profile is trusted. A rename by someone else
  /// shows up within this; the account's own rename shows up at once (see
  /// [_remember]).
  static const profileTtl = Duration(minutes: 5);

  /// Public profiles read this session, with when — including accounts that
  /// have none (null), so they are not asked for again. One instance serves
  /// the app, so the feed, the forum, notifications, the household and the
  /// sharing page all share it instead of each re-reading the same authors.
  final _profiles = <String, ({PublicProfileEntity? profile, DateTime at})>{};

  /// Lookups on the wire, per uid, so two screens asking at once share one
  /// read.
  final _inFlight = <String, Future<PublicProfileEntity?>>{};

  UserProfileRepositoryImpl({required this.remoteDataSource});

  void _remember(UserProfileEntity profile) {
    _profiles[profile.uid] = (
      profile: PublicProfileEntity(
        uid: profile.uid,
        fullName: profile.fullName,
        photoUrl: profile.photoUrl,
      ),
      at: DateTime.now(),
    );
  }

  @override
  Future<UserProfileEntity?> getProfile(String uid) =>
      remoteDataSource.getProfile(uid);

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    await remoteDataSource.saveProfile(profile);
    _remember(profile);
  }

  @override
  Future<String> uploadPhoto(String uid, File file) =>
      remoteDataSource.uploadPhoto(uid, file);

  @override
  Future<void> savePushToken(String uid, String token) =>
      remoteDataSource.savePushToken(uid, token);

  @override
  Future<void> touchDevice(
    String uid, {
    required String platform,
    String? appVersion,
  }) => remoteDataSource.touchDevice(
    uid,
    platform: platform,
    appVersion: appVersion,
  );

  @override
  Future<String?> blockMessage(String uid) =>
      remoteDataSource.blockMessage(uid);

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids, {
    bool refresh = false,
  }) async {
    final now = DateTime.now();
    final stale = {
      for (final uid in uids)
        if (!_inFlight.containsKey(uid) &&
            (refresh ||
                _profiles[uid] == null ||
                now.difference(_profiles[uid]!.at) > profileTtl))
          uid,
    };
    if (stale.isNotEmpty) {
      // Waiters hang off the settled read, not the raw one, so the cache and
      // the in-flight map are already up to date when any of them resumes.
      final settled = _settle(remoteDataSource.getPublicProfiles(stale), stale);
      for (final uid in stale) {
        final one = settled.then((found) => found[uid]);
        // A uid nobody ends up awaiting must not surface as an uncaught
        // error; an await below still throws.
        one.ignore();
        _inFlight[uid] = one;
      }
    }
    final result = <String, PublicProfileEntity>{};
    for (final uid in uids) {
      final pending = _inFlight[uid];
      final profile = pending != null ? await pending : _profiles[uid]?.profile;
      if (profile != null) result[uid] = profile;
    }
    return result;
  }

  /// Caches what [read] found, then lets [stale] be asked for again. A
  /// failed read is not cached — the next ask reads again — and reaches the
  /// waiters as is.
  Future<Map<String, PublicProfileEntity>> _settle(
    Future<Map<String, PublicProfileEntity>> read,
    Set<String> stale,
  ) async {
    try {
      final found = await read;
      final at = DateTime.now();
      for (final uid in stale) {
        _profiles[uid] = (profile: found[uid], at: at);
      }
      return found;
    } finally {
      for (final uid in stale) {
        _inFlight.remove(uid);
      }
    }
  }

  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) async {
    await remoteDataSource.publishPublicProfile(profile);
    _remember(profile);
  }

  @override
  Future<String?> findUidByContact(String contact) =>
      remoteDataSource.findUidByContact(contact);
}
