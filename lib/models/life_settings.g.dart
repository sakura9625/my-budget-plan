// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'life_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LifeSettingsAdapter extends TypeAdapter<LifeSettings> {
  @override
  final int typeId = 0;

  @override
  LifeSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LifeSettings(
      annualIncome: fields[0] as double,
      fixedCost: fields[1] as double,
      savingsGoal: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LifeSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.annualIncome)
      ..writeByte(1)
      ..write(obj.fixedCost)
      ..writeByte(2)
      ..write(obj.savingsGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifeSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
