import 'package:easy_plate/core/translation/content_translation.dart';
import 'package:easy_plate/core/translation/content_translation_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _DS = ContentTranslationRemoteDataSource;

TranslatableItem _recipe(String id, int steps) => TranslatableItem(
  type: 'recipe',
  id: id,
  fields: {
    'title': 'Recipe $id',
    'steps': [for (var i = 0; i < steps; i++) 'step $i'],
  },
);

void main() {
  test('lines are counted the way the server counts them', () {
    expect(_DS.linesIn(_recipe('a', 0)), 1);
    expect(_DS.linesIn(_recipe('a', 9)), 10);
  });

  test('a library of long recipes is cut under the per-call line cap', () {
    // 120 recipes of 100 lines each: one call of 120 would carry 12000 lines.
    final items = [for (var i = 0; i < 120; i++) _recipe('$i', 99)];
    final batches = _DS.batchesOf(items);
    expect(batches.expand((b) => b).length, 120);
    for (final batch in batches) {
      final lines = batch.fold<int>(0, (n, item) => n + _DS.linesIn(item));
      expect(lines, lessThanOrEqualTo(_DS.maxLinesPerCall));
      expect(batch.length, lessThanOrEqualTo(_DS.batchSize));
    }
  });

  test('short records still go 120 to a call', () {
    final items = [for (var i = 0; i < 250; i++) _recipe('$i', 2)];
    final batches = _DS.batchesOf(items);
    expect(batches.map((b) => b.length), [120, 120, 10]);
  });

  test('a record over the per-item cap is left out, not the whole call', () {
    final items = [_recipe('ok1', 5), _recipe('huge', 250), _recipe('ok2', 5)];
    final batches = _DS.batchesOf(items);
    expect(batches.expand((b) => b).map((i) => i.id), ['ok1', 'ok2']);
  });

  test('nothing to send is no calls', () {
    expect(_DS.batchesOf(const []), isEmpty);
  });

  test('budget units are counted the way the server counts them', () {
    // functions/translateContent.js unitsOf: max(1, ceil(trimmed / 300)).
    expect(_DS.unitsOf('short'), 1);
    expect(_DS.unitsOf(''), 1);
    expect(_DS.unitsOf('x' * 300), 1);
    expect(_DS.unitsOf('x' * 301), 2);
    expect(_DS.unitsOf('  ${'x' * 2000}  '), 7);
    final item = TranslatableItem(
      type: 'recipe',
      id: 'a',
      fields: {
        'title': 'Title',
        'steps': ['x' * 650, 'short'],
      },
    );
    expect(_DS.linesIn(item), 3, reason: 'the per-call caps stay in lines');
    expect(_DS.unitsIn(item), 1 + 3 + 1);
  });

  group('a call larger than what is left of the day', () {
    Map<String, Object?> refusal({
      required int used,
      required int limit,
      int? requested,
    }) => {
      'error': {
        'code': 'quota',
        'quota': {
          'used': used,
          'limit': limit,
          'kind': 'translate',
          'requested': ?requested,
        },
      },
    };

    test('is cut to the records that fit', () {
      final slice = [for (var i = 0; i < 5; i++) _recipe('$i', 99)]; // 100 each
      final fits = _DS.fitting(
        slice,
        refusal(used: 2750, limit: 3000, requested: 500),
      );
      expect(fits!.map((i) => i.id), ['0', '1']);
    });

    test('long lines are cut by their units, not their line count', () {
      // One 1500-character step each: 2 lines but 1 + 5 units a record.
      final slice = [
        for (var i = 0; i < 5; i++)
          TranslatableItem(
            type: 'recipe',
            id: '$i',
            fields: {
              'title': 'Recipe $i',
              'steps': ['x' * 1500],
            },
          ),
      ];
      // 13 units left: two records (12). Counted in lines all five (10)
      // would have been sent again, and refused again.
      final fits = _DS.fitting(
        slice,
        refusal(used: 2987, limit: 3000, requested: 30),
      );
      expect(fits!.map((i) => i.id), ['0', '1']);
    });

    test('nothing smaller is sent when the day is spent', () {
      final slice = [_recipe('a', 9), _recipe('b', 9)];
      expect(
        _DS.fitting(slice, refusal(used: 3000, limit: 3000)),
        isNull,
      );
      expect(
        _DS.fitting(slice, refusal(used: 2995, limit: 3000, requested: 20)),
        isNull,
        reason: 'not even the first record fits',
      );
    });

    test('a refusal the client counts as fitting is not sent again', () {
      final slice = [_recipe('a', 9), _recipe('b', 9)]; // 20 lines
      expect(
        _DS.fitting(slice, refusal(used: 0, limit: 3000, requested: 20)),
        isNull,
      );
    });

    test('a body without the quota object cuts nothing', () {
      expect(_DS.fitting([_recipe('a', 1)], {'error': {}}), isNull);
      expect(_DS.fitting([_recipe('a', 1)], null), isNull);
    });
  });
}
