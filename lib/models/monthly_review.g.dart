// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_review.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyReviewAdapter extends TypeAdapter<MonthlyReview> {
  @override
  final int typeId = 4;

  @override
  MonthlyReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyReview(
      id: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      totalAssets: fields[3] as double,
      cashAmount: fields[4] as double,
      prevTotalAssets: fields[5] as double?,
      prevCashAmount: fields[6] as double?,
      comment: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyReview obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.totalAssets)
      ..writeByte(4)
      ..write(obj.cashAmount)
      ..writeByte(5)
      ..write(obj.prevTotalAssets)
      ..writeByte(6)
      ..write(obj.prevCashAmount)
      ..writeByte(7)
      ..write(obj.comment)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
