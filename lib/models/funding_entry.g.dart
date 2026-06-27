// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'funding_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FundingEntryAdapter extends TypeAdapter<FundingEntry> {
  @override
  final int typeId = 3;

  @override
  FundingEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FundingEntry(
      id: fields[0] as String,
      projectId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      memo: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FundingEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.memo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
