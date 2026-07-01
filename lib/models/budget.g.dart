// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 3;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      name: fields[1] as String,
      monthlyAmount: fields[2] as double,
      startYear: fields[3] as int,
      startMonth: fields[4] as int,
      endYear: fields[5] as int,
      endMonth: fields[6] as int,
      usedAmount: fields[7] as double,
      emoji: fields[8] as String?,
      memo: fields[9] as String?,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.monthlyAmount)
      ..writeByte(3)
      ..write(obj.startYear)
      ..writeByte(4)
      ..write(obj.startMonth)
      ..writeByte(5)
      ..write(obj.endYear)
      ..writeByte(6)
      ..write(obj.endMonth)
      ..writeByte(7)
      ..write(obj.usedAmount)
      ..writeByte(8)
      ..write(obj.emoji)
      ..writeByte(9)
      ..write(obj.memo)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
