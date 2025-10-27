// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ContactType.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactTypeAdapter extends TypeAdapter<ContactType> {
  @override
  final int typeId = 4;

  @override
  ContactType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContactType.borrower;
      case 1:
        return ContactType.lender;
      default:
        return ContactType.borrower;
    }
  }

  @override
  void write(BinaryWriter writer, ContactType obj) {
    switch (obj) {
      case ContactType.borrower:
        writer.writeByte(0);
        break;
      case ContactType.lender:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
