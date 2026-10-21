import 'package:easy_plate/core/monetization/daily_usage_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const spent = DailyUsageModel(
    day: '2026-09-09',
    viewedSharedIds: ['a', 'b', 'c'],
    aiExtractions: 2,
  );

  test('the same day keeps its counts', () {
    expect(spent.forDay('2026-09-09'), same(spent));
  });

  test('a later day starts over', () {
    final next = spent.forDay('2026-09-10');
    expect(next.day, '2026-09-10');
    expect(next.viewedSharedIds, isEmpty);
    expect(next.aiExtractions, 0);
  });

  test(
    'an earlier day — the clock wound back — does not hand out a fresh allowance',
    () {
      expect(spent.forDay('2026-09-08'), same(spent));
      expect(spent.forDay('2025-12-31'), same(spent));
    },
  );

  test('round-trips through json for the cloud mirror', () {
    final json = spent.toJson();
    expect(DailyUsageModel.fromJson(json), spent);
  });

  group('two copies of the day meeting', () {
    test('the same day keeps the higher count and every id', () {
      const other = DailyUsageModel(
        day: '2026-09-09',
        viewedSharedIds: ['c', 'd'],
        aiExtractions: 5,
      );
      final merged = spent.mergedWith(other);
      expect(merged.aiExtractions, 5);
      expect(merged.viewedSharedIds, ['a', 'b', 'c', 'd']);
      // A copy that knows nothing new changes nothing.
      expect(spent.mergedWith(spent), spent);
    });

    test('across days the later day stands, whichever side holds it', () {
      const later = DailyUsageModel(day: '2026-09-10', aiExtractions: 1);
      expect(spent.mergedWith(later), later);
      expect(later.mergedWith(spent), later);
    });
  });
}
