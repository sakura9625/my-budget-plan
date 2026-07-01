// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewAdapter extends TypeAdapter<Review> {
  @override
  final int typeId = 7;

  @override
  Review read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Review(
      id: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      reviewDate: fields[3] as DateTime,
      accountBalance: fields[4] as double,
      effectiveBalance: fields[5] as double,
      overallProgress: fields[6] as double,
      planProgress: fields[7] as double,
      overallStatus: fields[8] as String,
      comment: fields[9] as String?,
      homeHeadline: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Review obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.reviewDate)
      ..writeByte(4)
      ..write(obj.accountBalance)
      ..writeByte(5)
      ..write(obj.effectiveBalance)
      ..writeByte(6)
      ..write(obj.overallProgress)
      ..writeByte(7)
      ..write(obj.planProgress)
      ..writeByte(8)
      ..write(obj.overallStatus)
      ..writeByte(9)
      ..write(obj.comment)
      ..writeByte(10)
      ..write(obj.homeHeadline);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
