import 'package:easy_plate/core/utils/step_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Each step names a duration the way recipes in that language do.
  const cases = <String, int?>{
    'Sear the salmon skin-side down for 4 minutes until golden.': 240,
    'Simmer 4-5 minutes, then stir.': 240,
    'Bake for 1.5 hours at 180°C.': 5400,
    'צורבים את הסלמון עם העור כלפי מטה 4 דקות עד להזהבה.': 240,
    'מבשלים חצי שעה על אש נמוכה': 1800,
    'מכניסים לתנור ל-25 דק׳.': 1500,
    'اتركه على النار 10 دقائق.': 600,
    'اتركه يغلي دقيقتين.': 120,
    'Laisser mijoter 20 minutes.': 1200,
    'Варить 15 мин.': 900,
    'Варить полчаса.': 1800,
    'Add 2 cups of flour and 3 eggs.': null,
    'Serve at 180 degrees.': null,
  };

  cases.forEach((text, expected) {
    test('duration of "$text"', () {
      expect(parseStepDuration(text), expected);
    });
  });

  test('clock format', () {
    expect(formatClock(240), '04:00');
    expect(formatClock(5400), '1:30:00');
    expect(formatClock(7), '00:07');
  });
}
