import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:easy_plate/features/notifications/data/repositories_impl/notifications_repository_impl.dart';
import 'package:easy_plate/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote implements NotificationsRemoteDataSource {
  final controller = StreamController<List<AppNotificationEntity>>();
  @override
  Stream<List<AppNotificationEntity>> watch(String uid) => controller.stream;
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _Profiles implements UserProfileRepository {
  bool fail = false;
  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids, {
    bool refresh = false,
  }) async {
    if (fail) throw StateError('unavailable');
    return {
      for (final uid in uids)
        uid: PublicProfileEntity(uid: uid, fullName: 'Name of $uid'),
    };
  }

  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

AppNotificationEntity item(String id) => AppNotificationEntity(
  id: id,
  type: AppNotificationType.adminMessage,
  fromUid: 'dana',
  read: false,
  createdAt: DateTime(2026),
);

void main() {
  test('a failed sender lookup still delivers the snapshot, unnamed', () async {
    final remote = _Remote();
    final profiles = _Profiles();
    final repository = NotificationsRepositoryImpl(
      remoteDataSource: remote,
      userProfileRepository: profiles,
    );
    final seen = <List<AppNotificationEntity>>[];
    final errors = <Object>[];
    final sub = repository.watch('me').listen(seen.add, onError: errors.add);

    remote.controller.add([item('a')]);
    await pumpEventQueue();
    profiles.fail = true;
    remote.controller.add([item('b'), item('a')]);
    await pumpEventQueue();
    profiles.fail = false;
    remote.controller.add([item('c')]);
    await pumpEventQueue();

    expect(errors, isEmpty);
    expect(seen.map((l) => l.map((n) => n.id).toList()), [
      ['a'],
      ['b', 'a'],
      ['c'],
    ]);
    expect(seen[0].single.fromName, 'Name of dana');
    expect(seen[1].first.fromName, isNot('Name of dana'));
    expect(seen[2].single.fromName, 'Name of dana');
    await sub.cancel();
  });
}
