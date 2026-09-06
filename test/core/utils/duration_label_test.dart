import 'package:easy_plate/core/constants/app_constants.dart';
import 'package:easy_plate/core/utils/duration_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('under an hour stays in minutes', () {
    expect(durationLabel(50), '50 דק׳');
    expect(durationLabel(59), '59 דק׳');
  });

  test('past 59 minutes rolls into hours and minutes', () {
    // The case that prompted this: 160 minutes is not something anyone can
    // picture as a prep time.
    expect(durationLabel(160), '2 שע׳ ו40 דק׳');
    expect(durationLabel(90), '1 שע׳ ו30 דק׳');
  });

  test('a whole number of hours drops the minutes rather than showing zero', () {
    expect(durationLabel(60), '1 שע׳');
    expect(durationLabel(120), '2 שע׳');
  });

  test('zero is a real answer and stays in minutes', () {
    expect(durationLabel(0), '0 דק׳');
  });

  test('null is "not stated", which is not the same as zero', () {
    expect(optionalDurationLabel(null), kMissingInfoPlaceholder);
    expect(optionalDurationLabel(0), '0 דק׳');
    expect(optionalDurationLabel(160), '2 שע׳ ו40 דק׳');
  });
}
