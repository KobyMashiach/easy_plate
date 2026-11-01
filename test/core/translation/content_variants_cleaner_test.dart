import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/translation/content_translation.dart';
import 'package:easy_plate/core/translation/content_translation_datasource.dart';
import 'package:easy_plate/core/translation/content_variants_cleaner.dart';
import 'package:easy_plate/core/translation/content_variants_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote implements ContentTranslationDataSource {
  bool throws = false;
  final forgotten = <String>[];
  @override
  Future<void> forget(String type, String id, Iterable<String> langs) async {
    if (throws) throw StateError('offline');
    forgotten.add('$type/$id:${langs.join(',')}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Local extends ContentVariantsLocalStore {
  final forgotten = <String>[];
  @override
  Future<void> forget(Iterable<String> typeIds) async =>
      forgotten.addAll(typeIds);
}

void main() {
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'a deleted record is dropped in every language, here and there',
    () async {
      final remote = _Remote();
      final local = _Local();
      ContentVariantsCleaner(
        remote: remote,
        local: local,
      ).forget('recipe', 'r1');
      await settle();
      expect(local.forgotten, ['recipe/r1']);
      expect(remote.forgotten, ['recipe/r1:he,en,ar,fr,ru']);
    },
  );

  test('a failure never reaches the delete that asked', () async {
    final remote = _Remote()..throws = true;
    final cleaner = ContentVariantsCleaner(remote: remote, local: _Local());
    await expectLater(cleaner.forgetAll(['book/b1']), completes);
  });

  test('the languages are every app language', () {
    expect(ContentVariantsCleaner.langs, [
      for (final l in AppLanguage.values) l.code,
    ]);
  });
}
