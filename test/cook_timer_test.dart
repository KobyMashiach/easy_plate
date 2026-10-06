import 'package:clock/clock.dart';
import 'package:easy_plate/core/services/cook_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a running timer follows the wall clock, not the ticks', () {
    final start = DateTime(2026, 10, 6, 12);
    withClock(Clock(() => start), () {
      final timer = CookTimer(total: 240)..start();
      expect(timer.remaining, 240);
      withClock(Clock(() => start.add(const Duration(seconds: 90))), () {
        expect(timer.remaining, 150);
        timer.pause();
        expect(timer.running, isFalse);
      });
      // Paused: the clock may move, the remainder does not.
      withClock(Clock(() => start.add(const Duration(hours: 1))), () {
        expect(timer.remaining, 150);
      });
    });
  });

  test('a timer that ended while the app was away settles as rung', () {
    final start = DateTime(2026, 10, 6, 12);
    final json = withClock(Clock(() => start), () {
      return (CookTimer(total: 60)..start()).toJson();
    });
    withClock(Clock(() => start.add(const Duration(minutes: 5))), () {
      final restored = CookTimer.fromJson(json)..settle();
      expect(restored.finished, isTrue);
      expect(restored.running, isFalse);
      expect(restored.remaining, 0);
    });
  });

  test('a timer restored before its end keeps counting from the clock', () {
    final start = DateTime(2026, 10, 6, 12);
    final json = withClock(Clock(() => start), () {
      return (CookTimer(total: 600)..start()).toJson();
    });
    withClock(Clock(() => start.add(const Duration(minutes: 4))), () {
      final restored = CookTimer.fromJson(json)..settle();
      expect(restored.running, isTrue);
      expect(restored.remaining, 360);
    });
  });
}
