// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 2;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      id: fields[0] as String,
      type: fields[1] as GoalType,
      name: fields[2] as String,
      targetAmount: fields[3] as double,
      startYear: fields[4] as int,
      startMonth: fields[5] as int,
      endYear: fields[6] as int,
      endMonth: fields[7] as int,
      manualAmount: fields[8] as double,
      status: fields[9] as GoalStatus,
      emoji: fields[10] as String?,
      memo: fields[11] as String?,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.targetAmount)
      ..writeByte(4)
      ..write(obj.startYear)
      ..writeByte(5)
      ..write(obj.startMonth)
      ..writeByte(6)
      ..write(obj.endYear)
      ..writeByte(7)
      ..write(obj.endMonth)
      ..writeByte(8)
      ..write(obj.manualAmount)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.emoji)
      ..writeByte(11)
      ..write(obj.memo)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 0;

  @override
  GoalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalType.saving;
      case 1:
        return GoalType.project;
      default:
        return GoalType.saving;
    }
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    switch (obj) {
      case GoalType.saving:
        writer.writeByte(0);
        break;
      case GoalType.project:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalStatusAdapter extends TypeAdapter<GoalStatus> {
  @override
  final int typeId = 1;

  @override
  GoalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalStatus.active;
      case 1:
        return GoalStatus.completed;
      case 2:
        return GoalStatus.frozen;
      case 3:
        return GoalStatus.abandoned;
      default:
        return GoalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, GoalStatus obj) {
    switch (obj) {
      case GoalStatus.active:
        writer.writeByte(0);
        break;
      case GoalStatus.completed:
        writer.writeByte(1);
        break;
      case GoalStatus.frozen:
        writer.writeByte(2);
        break;
      case GoalStatus.abandoned:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
