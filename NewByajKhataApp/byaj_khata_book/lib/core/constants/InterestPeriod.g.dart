// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'InterestPeriod.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InterestPeriodAdapter extends TypeAdapter<InterestPeriod> {
  @override
  final int typeId = 5;

  @override
  InterestPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InterestPeriod.daily;
      case 1:
        return InterestPeriod.weekly;
      case 2:
        return InterestPeriod.monthly;
      case 3:
        return InterestPeriod.yearly;
      default:
        return InterestPeriod.daily;
    }
  }

  @override
  void write(BinaryWriter writer, InterestPeriod obj) {
    switch (obj) {
      case InterestPeriod.daily:
        writer.writeByte(0);
        break;
      case InterestPeriod.weekly:
        writer.writeByte(1);
        break;
      case InterestPeriod.monthly:
        writer.writeByte(2);
        break;
      case InterestPeriod.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
