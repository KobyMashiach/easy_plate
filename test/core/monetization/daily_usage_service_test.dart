import 'dart:io';

import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/monetization/daily_usage_model.dart';
import 'package:easy_plate/core/monetization/daily_usage_service.dart';
import 'package:easy_plate/core/monetization/trusted_clock.dart';
import 'package:easy_plate/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('daily_usage_test');
    Hive.init(dir.path);
    UserScope().resetForTest();
    DailyUsageService().reset();
  });

  tearDown(() async {
    await Hive.close();
    UserScope().resetForTest();
    DailyUsageService().reset();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test(
    'a load outlived by an account switch never counts for the next one',
    () async {
      final today = TrustedClock().today;
      // The second account already spent some of today's allowance.
      await UserScope().switchTo('u2');
      final seeded = await UserScope().open<DailyUsageModel>(
        DailyUsageModel.hiveKey,
      );
      await seeded.put(
        DailyUsageModel.storageKey,
        DailyUsageModel(day: today, aiExtractions: 3),
      );
      await seeded.close();

      await UserScope().switchTo('u1');
      final service = DailyUsageService();
      // u1's read is in flight when the scope moves to u2, and u2's own
      // caller arrives while that read is still running. Before the fix the
      // second caller took the first load as its own and came back with an
      // empty record stamped u1 — and the next write would have overwritten
      // u2's count with it.
      final first = service.ensureLoaded();
      await UserScope().switchTo('u2');
      final second = service.ensureLoaded();
      await Future.wait([first, second]);

      expect(service.isLoaded, isTrue);
      expect(service.aiExtractionsToday, 3);
    },
  );

  test(
    'a cloud copy that lands behind the loaded one is taken in, not overwritten',
    () async {
      final today = TrustedClock().today;
      await UserScope().switchTo('u1');
      final service = DailyUsageService();
      // The quota indicator asks the moment the scope moves: an empty box.
      await service.ensureLoaded();
      expect(service.aiExtractionsToday, 0);

      // The hydrate writes the account's record straight into the box —
      // three extractions already spent on another device today.
      final box = await UserScope().open<DailyUsageModel>(
        DailyUsageModel.hiveKey,
      );
      await box.put(
        DailyUsageModel.storageKey,
        DailyUsageModel(day: today, aiExtractions: 3, viewedSharedIds: ['s1']),
      );

      // Before the fix the in-memory copy stayed at 0 and the next spend
      // would have written 1 over the 3, here and in the cloud.
      await service.ensureLoaded();
      expect(service.aiExtractionsToday, 3);
      expect(service.hasViewedShared('s1'), isTrue);
    },
  );
}
