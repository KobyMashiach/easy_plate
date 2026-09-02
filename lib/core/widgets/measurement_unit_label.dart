import '../constants/app_enums.dart';
import '../utils/i18n/strings.g.dart';

/// Units are shown to the shopper, so they follow the app language rather than
/// staying pinned to Hebrew.
String measurementUnitLabel(MeasurementUnit unit) => switch (unit) {
      MeasurementUnit.gram => t.unit.gram,
      MeasurementUnit.kilogram => t.unit.kilogram,
      MeasurementUnit.milliliter => t.unit.milliliter,
      MeasurementUnit.liter => t.unit.liter,
      MeasurementUnit.teaspoon => t.unit.teaspoon,
      MeasurementUnit.tablespoon => t.unit.tablespoon,
      MeasurementUnit.cup => t.unit.cup,
      MeasurementUnit.unit => t.unit.unit,
      MeasurementUnit.pinch => t.unit.pinch,
      MeasurementUnit.unspecified => '',
    };

/// Label for the unit picker, where the "unspecified" option still needs
/// something visible to tap.
String measurementUnitPickerLabel(MeasurementUnit unit) =>
    unit == MeasurementUnit.unspecified ? t.unit.unspecified : measurementUnitLabel(unit);
