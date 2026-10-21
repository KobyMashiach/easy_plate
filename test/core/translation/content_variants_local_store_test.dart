import 'dart:io';

import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/translation/content_variants_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('variants_store_test');
    Hive.init(dir.path);
    UserScope().resetForTest();
    await UserScope().switchTo('u1');
  });

  tearDown(() async {
    await Hive.close();
    UserScope().resetForTest();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('one damaged entry costs that record, not the language', () async {
    final box = await UserScope().open<String>(
      ContentVariantsLocalStore.boxName,
    );
    await box.putAll({
      'en/recipe/good': '{"title":"Shakshuka","version":0}',
      'en/recipe/bad': '{"title":',
    });

    final read = await ContentVariantsLocalStore().read('en');

    expect(read.keys, ['recipe/good']);
    expect(read['recipe/good']!.text('title'), 'Shakshuka');
  });
}
