// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      annualIncome: fields[0] as double,
      annualFixedCost: fields[1] as double,
      reviewDay: fields[2] as int,
      notificationEnabled: fields[3] as bool,
      notificationHour: fields[4] as int,
      notificationMinute: fields[5] as int,
      initialSetupCompleted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.annualIncome)
      ..writeByte(1)
      ..write(obj.annualFixedCost)
      ..writeByte(2)
      ..write(obj.reviewDay)
      ..writeByte(3)
      ..write(obj.notificationEnabled)
      ..writeByte(4)
      ..write(obj.notificationHour)
      ..writeByte(5)
      ..write(obj.notificationMinute)
      ..writeByte(6)
      ..write(obj.initialSetupCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
