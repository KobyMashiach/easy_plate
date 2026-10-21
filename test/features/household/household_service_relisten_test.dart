import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/sync/user_cloud_collection.dart';
import 'package:easy_plate/features/household/domain/household_entity.dart';
import 'package:easy_plate/features/household/domain/household_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => HouseholdService().clear());

  test(
    'resolving again after the listener died keeps the household root',
    () async {
      final service = HouseholdService();
      final household = HouseholdEntity.fromJson('h1', {
        'ownerUid': 'u1',
        'tier': 'family',
        'seats': 6,
        'title': 'Cohens',
        'memberUids': ['u1', 'u2'],
      })!;
      // Answered once, then the stream errored (no subscription left).
      service.setForTest(household, uid: 'u2');
      final watched = <String>[];
      final live = StreamController<QuerySnapshot<Map<String, dynamic>>>();
      service.watch = (uid) {
        watched.add(uid);
        return live.stream;
      };

      await service.resolve('u2').timeout(const Duration(milliseconds: 100));

      expect(watched, ['u2'], reason: 'listening again');
      expect(service.current?.id, 'h1');
      expect(CloudRoot.householdId, 'h1', reason: 'no gap on the own root');
      await live.close();
    },
  );
}
