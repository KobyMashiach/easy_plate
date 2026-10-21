import 'package:easy_plate/core/widgets/clay/clay_segmented_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a row narrower than an icon per segment still lays out', () {
    final widths = ClaySegmentedControl.widthsFor(
      available: 150,
      count: 5,
      selected: 1,
      labelWidth: 60,
    );
    expect(widths, hasLength(5));
    expect(widths.fold<double>(0, (a, b) => a + b), closeTo(150, 0.001));
    expect(widths.every((w) => w >= 0), isTrue);
  });

  test('a roomy row widens the chosen segment', () {
    final widths = ClaySegmentedControl.widthsFor(
      available: 400,
      count: 3,
      selected: 0,
      labelWidth: 80,
    );
    expect(widths.first, greaterThan(widths[1]));
    expect(widths.fold<double>(0, (a, b) => a + b), closeTo(400, 0.001));
  });
}
