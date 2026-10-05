import 'dart:io';

import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  setUp(() => UserScope().resetForTest());

  test(
    'opening before a user resolves throws instead of falling back',
    () async {
      // A silent fallback to an unscoped box is precisely the bug this prevents:
      // it is how one account's recipes became visible to the next.
      expect(() => UserScope().open<String>('recipesBox'), throwsStateError);
    },
  );

  test('every scoped box is listed, so none keeps a device-wide name', () {
    expect(
      UserScope.scopedBoxes,
      containsAll([
        'userPreferencesBox',
        'recipesBox',
        'recipeBooksBox',
        'mealPlansBox',
        'groceryListsBox',
      ]),
    );
  });

  test('switching accounts moves the scope', () async {
    final scope = UserScope();
    await scope.switchTo('user-1');
    expect(scope.uid, 'user-1');

    await scope.switchTo('user-2');
    expect(scope.uid, 'user-2');
  });

  test('switching to the same account is a no-op', () async {
    final scope = UserScope();
    await scope.switchTo('user-1');
    await scope.switchTo('user-1');
    expect(scope.uid, 'user-1');
  });

  group('closing the previous account\'s boxes', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('user_scope_test');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      UserScope().resetForTest();
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test(
      'a typed box from the previous account closes without throwing',
      () async {
        final scope = UserScope();
        await scope.switchTo('user-1');

        // The type matters. Hive hands a box back only at the type it was opened
        // with, so closing it by asking for Box<dynamic> threw
        // "already open and of type Box<...>" and left the sign-in half done.
        final box = await scope.open<String>('recipesBox');
        await box.put('k', 'v');
        expect(box.isOpen, isTrue);

        await scope.switchTo('user-2');

        expect(scope.uid, 'user-2');
        expect(
          box.isOpen,
          isFalse,
          reason: 'the previous account\'s box must close',
        );
      },
    );

    test('the next account opens its own file, not the previous one', () async {
      final scope = UserScope();
      await scope.switchTo('user-1');
      await (await scope.open<String>('recipesBox')).put('k', 'from-user-1');

      await scope.switchTo('user-2');
      final second = await scope.open<String>('recipesBox');

      expect(second.get('k'), isNull);
    });

    group('clearing the account on sign-out', () {
      bool fileExists(String name) =>
          File('${dir.path}/${name.toLowerCase()}.hive').existsSync();

      test(
        'the account\'s boxes are deleted from disk, not just closed',
        () async {
          final scope = UserScope();
          await scope.switchTo('user-1');
          await (await scope.open<String>('recipesBox')).put('k', 'v');
          await (await scope.open<String>('groceryListsBox')).put('k', 'v');
          expect(fileExists('recipesBox_user-1'), isTrue);

          await scope.clearAccount();

          expect(scope.uid, isNull);
          expect(fileExists('recipesBox_user-1'), isFalse);
          expect(fileExists('groceryListsBox_user-1'), isFalse);
        },
      );

      test(
        'signing back in to the same account starts from empty boxes',
        () async {
          final scope = UserScope();
          await scope.switchTo('user-1');
          await (await scope.open<String>('recipesBox')).put('k', 'v');

          await scope.clearAccount();
          await scope.switchTo('user-1');

          expect((await scope.open<String>('recipesBox')).get('k'), isNull);
        },
      );

      test('boxes other accounts left on the device are swept too', () async {
        final scope = UserScope();
        await scope.switchTo('user-1');
        await (await scope.open<String>('recipesBox')).put('k', 'v');
        // Switching closes user-1's box but leaves its file behind.
        await scope.switchTo('user-2');
        await (await scope.open<String>('recipesBox')).put('k', 'v');
        expect(fileExists('recipesBox_user-1'), isTrue);

        await scope.clearAccount();

        expect(fileExists('recipesBox_user-1'), isFalse);
        expect(fileExists('recipesBox_user-2'), isFalse);
      });

      test('a device-level box is left alone', () async {
        final device = await Hive.openBox<String>('deviceSettingsBox');
        await device.put('theme', 'dark');
        final scope = UserScope();
        await scope.switchTo('user-1');
        await (await scope.open<String>('recipesBox')).put('k', 'v');

        await scope.clearAccount();

        expect(device.isOpen, isTrue);
        expect(device.get('theme'), 'dark');
      });

      test(
        'a read after the wipe throws instead of recreating a box',
        () async {
          final scope = UserScope();
          await scope.switchTo('user-1');
          await scope.open<String>('recipesBox');

          await scope.clearAccount();

          expect(() => scope.open<String>('recipesBox'), throwsStateError);
        },
      );
    });

    test('re-opening the same box for the same account is stable', () async {
      final scope = UserScope();
      await scope.switchTo('user-1');
      final a = await scope.open<String>('recipesBox');
      final b = await scope.open<String>('recipesBox');
      expect(identical(a, b), isTrue);
      expect(a.isOpen, isTrue);
    });
  });
}
