// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'InterestType.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InterestTypeAdapter extends TypeAdapter<InterestType> {
  @override
  final int typeId = 3;

  @override
  InterestType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InterestType.withInterest;
      case 1:
        return InterestType.withoutInterest;
      default:
        return InterestType.withInterest;
    }
  }

  @override
  void write(BinaryWriter writer, InterestType obj) {
    switch (obj) {
      case InterestType.withInterest:
        writer.writeByte(0);
        break;
      case InterestType.withoutInterest:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
