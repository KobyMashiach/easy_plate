import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/price_book/domain/entities/price_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weight prices convert grams and kilograms', () {
    expect(PriceUnit.kg.multiplierFor(MeasurementUnit.gram, 850), closeTo(0.85, 1e-9));
    expect(PriceUnit.kg.multiplierFor(MeasurementUnit.kilogram, 2), 2);
    expect(PriceUnit.kg.multiplierFor(MeasurementUnit.unit, 2), isNull);
  });

  test('package prices multiply by count only', () {
    expect(PriceUnit.unit.multiplierFor(MeasurementUnit.unit, 3), 3);
    expect(PriceUnit.unit.multiplierFor(MeasurementUnit.gram, 500), isNull);
  });

  test('litre prices convert millilitres', () {
    expect(PriceUnit.liter.multiplierFor(MeasurementUnit.milliliter, 250), 0.25);
    expect(PriceUnit.liter.multiplierFor(MeasurementUnit.cup, 1), isNull);
  });

  test('unknown names read as per package', () {
    expect(PriceUnit.fromName('gallon'), PriceUnit.unit);
    expect(PriceUnit.fromName('kg'), PriceUnit.kg);
  });
}
