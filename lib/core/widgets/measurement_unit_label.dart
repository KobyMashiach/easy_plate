import '../constants/app_enums.dart';

String measurementUnitLabel(MeasurementUnit unit) => switch (unit) {
      MeasurementUnit.gram => 'גרם',
      MeasurementUnit.kilogram => 'ק"ג',
      MeasurementUnit.milliliter => 'מ"ל',
      MeasurementUnit.liter => 'ליטר',
      MeasurementUnit.teaspoon => 'כפית',
      MeasurementUnit.tablespoon => 'כף',
      MeasurementUnit.cup => 'כוס',
      MeasurementUnit.unit => 'יחידה',
      MeasurementUnit.pinch => 'קורט',
      MeasurementUnit.unspecified => '',
    };
