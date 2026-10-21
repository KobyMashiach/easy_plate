import 'package:easy_plate/core/services/store_review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 18);
  setUp(() => StoreReviewService.now = () => t0);
  tearDown(() => StoreReviewService.now = DateTime.now);

  test('waits for the second success', () {
    expect(
      StoreReviewService.shouldAsk(successes: 1, asks: 0, lastAskMillis: null),
      isFalse,
    );
    expect(
      StoreReviewService.shouldAsk(successes: 2, asks: 0, lastAskMillis: null),
      isTrue,
    );
  });

  test('keeps the cooldown between asks', () {
    final recent = t0.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final old = t0.subtract(const Duration(days: 121)).millisecondsSinceEpoch;
    expect(
      StoreReviewService.shouldAsk(
        successes: 9,
        asks: 1,
        lastAskMillis: recent,
      ),
      isFalse,
    );
    expect(
      StoreReviewService.shouldAsk(successes: 9, asks: 1, lastAskMillis: old),
      isTrue,
    );
  });

  test('never asks more than maxAsks times', () {
    final old = t0.subtract(const Duration(days: 400)).millisecondsSinceEpoch;
    expect(
      StoreReviewService.shouldAsk(
        successes: 50,
        asks: StoreReviewService.maxAsks,
        lastAskMillis: old,
      ),
      isFalse,
    );
  });
}
