// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingDayAdapter extends TypeAdapter<ShoppingDay> {
  @override
  final typeId = 20;

  @override
  ShoppingDay read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShoppingDay.sunday;
      case 1:
        return ShoppingDay.monday;
      case 2:
        return ShoppingDay.tuesday;
      case 3:
        return ShoppingDay.wednesday;
      case 4:
        return ShoppingDay.thursday;
      case 5:
        return ShoppingDay.friday;
      case 6:
        return ShoppingDay.saturday;
      default:
        return ShoppingDay.sunday;
    }
  }

  @override
  void write(BinaryWriter writer, ShoppingDay obj) {
    switch (obj) {
      case ShoppingDay.sunday:
        writer.writeByte(0);
      case ShoppingDay.monday:
        writer.writeByte(1);
      case ShoppingDay.tuesday:
        writer.writeByte(2);
      case ShoppingDay.wednesday:
        writer.writeByte(3);
      case ShoppingDay.thursday:
        writer.writeByte(4);
      case ShoppingDay.friday:
        writer.writeByte(5);
      case ShoppingDay.saturday:
        writer.writeByte(6);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DietaryPreferenceAdapter extends TypeAdapter<DietaryPreference> {
  @override
  final typeId = 21;

  @override
  DietaryPreference read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DietaryPreference.meat;
      case 1:
        return DietaryPreference.dairy;
      case 2:
        return DietaryPreference.vegetarian;
      case 3:
        return DietaryPreference.vegan;
      case 4:
        return DietaryPreference.kosher;
      case 5:
        return DietaryPreference.glutenFree;
      case 6:
        return DietaryPreference.allergy;
      default:
        return DietaryPreference.meat;
    }
  }

  @override
  void write(BinaryWriter writer, DietaryPreference obj) {
    switch (obj) {
      case DietaryPreference.meat:
        writer.writeByte(0);
      case DietaryPreference.dairy:
        writer.writeByte(1);
      case DietaryPreference.vegetarian:
        writer.writeByte(2);
      case DietaryPreference.vegan:
        writer.writeByte(3);
      case DietaryPreference.kosher:
        writer.writeByte(4);
      case DietaryPreference.glutenFree:
        writer.writeByte(5);
      case DietaryPreference.allergy:
        writer.writeByte(6);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccessRoleAdapter extends TypeAdapter<AccessRole> {
  @override
  final typeId = 22;

  @override
  AccessRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccessRole.viewer;
      case 1:
        return AccessRole.editor;
      default:
        return AccessRole.viewer;
    }
  }

  @override
  void write(BinaryWriter writer, AccessRole obj) {
    switch (obj) {
      case AccessRole.viewer:
        writer.writeByte(0);
      case AccessRole.editor:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppLanguageAdapter extends TypeAdapter<AppLanguage> {
  @override
  final typeId = 24;

  @override
  AppLanguage read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppLanguage.hebrew;
      case 1:
        return AppLanguage.english;
      case 2:
        return AppLanguage.arabic;
      case 3:
        return AppLanguage.french;
      case 4:
        return AppLanguage.russian;
      default:
        return AppLanguage.hebrew;
    }
  }

  @override
  void write(BinaryWriter writer, AppLanguage obj) {
    switch (obj) {
      case AppLanguage.hebrew:
        writer.writeByte(0);
      case AppLanguage.english:
        writer.writeByte(1);
      case AppLanguage.arabic:
        writer.writeByte(2);
      case AppLanguage.french:
        writer.writeByte(3);
      case AppLanguage.russian:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementUnitAdapter extends TypeAdapter<MeasurementUnit> {
  @override
  final typeId = 23;

  @override
  MeasurementUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeasurementUnit.gram;
      case 1:
        return MeasurementUnit.kilogram;
      case 2:
        return MeasurementUnit.milliliter;
      case 3:
        return MeasurementUnit.liter;
      case 4:
        return MeasurementUnit.teaspoon;
      case 5:
        return MeasurementUnit.tablespoon;
      case 6:
        return MeasurementUnit.cup;
      case 7:
        return MeasurementUnit.unit;
      case 8:
        return MeasurementUnit.pinch;
      case 9:
        return MeasurementUnit.unspecified;
      default:
        return MeasurementUnit.gram;
    }
  }

  @override
  void write(BinaryWriter writer, MeasurementUnit obj) {
    switch (obj) {
      case MeasurementUnit.gram:
        writer.writeByte(0);
      case MeasurementUnit.kilogram:
        writer.writeByte(1);
      case MeasurementUnit.milliliter:
        writer.writeByte(2);
      case MeasurementUnit.liter:
        writer.writeByte(3);
      case MeasurementUnit.teaspoon:
        writer.writeByte(4);
      case MeasurementUnit.tablespoon:
        writer.writeByte(5);
      case MeasurementUnit.cup:
        writer.writeByte(6);
      case MeasurementUnit.unit:
        writer.writeByte(7);
      case MeasurementUnit.pinch:
        writer.writeByte(8);
      case MeasurementUnit.unspecified:
        writer.writeByte(9);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
