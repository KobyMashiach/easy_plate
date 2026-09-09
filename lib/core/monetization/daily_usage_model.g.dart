// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_usage_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyUsageModelAdapter extends TypeAdapter<DailyUsageModel> {
  @override
  final typeId = 12;

  @override
  DailyUsageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyUsageModel(
      day: fields[0] as String,
      viewedSharedIds: fields[1] == null
          ? []
          : (fields[1] as List).cast<String>(),
      aiExtractions: fields[2] == null ? 0 : (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsageModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.viewedSharedIds)
      ..writeByte(2)
      ..write(obj.aiExtractions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyUsageModel _$DailyUsageModelFromJson(Map<String, dynamic> json) =>
    _DailyUsageModel(
      day: json['day'] as String,
      viewedSharedIds:
          (json['viewedSharedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      aiExtractions: (json['aiExtractions'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DailyUsageModelToJson(_DailyUsageModel instance) =>
    <String, dynamic>{
      'day': instance.day,
      'viewedSharedIds': instance.viewedSharedIds,
      'aiExtractions': instance.aiExtractions,
    };
