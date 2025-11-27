// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 0;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      contactId: fields[0] as String,
      name: fields[1] as String,
      displayPhone: fields[14] as String?,
      initials: fields[11] as String,
      interestRate: fields[2] as double,
      interestPeriod: fields[3] as InterestPeriod?,
      contactType: fields[4] as ContactType,
      colorValue: fields[5] as int?,
      dayAgo: fields[12] as int,
      lastEditedAt: fields[6] as DateTime?,
      interestType: fields[7] as InterestType,
      interestDue: fields[8] as double,
      isGet: fields[13] as bool,
      lastInterestCycleDate: fields[18] as DateTime?,
      isNewContact: fields[16] as bool,
      profileImage: fields[17] as String?,
      principal: fields[9] as double,
      displayAmount: fields[10] as double,
      category: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.contactId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.interestRate)
      ..writeByte(3)
      ..write(obj.interestPeriod)
      ..writeByte(4)
      ..write(obj.contactType)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.lastEditedAt)
      ..writeByte(7)
      ..write(obj.interestType)
      ..writeByte(8)
      ..write(obj.interestDue)
      ..writeByte(9)
      ..write(obj.principal)
      ..writeByte(10)
      ..write(obj.displayAmount)
      ..writeByte(11)
      ..write(obj.initials)
      ..writeByte(12)
      ..write(obj.dayAgo)
      ..writeByte(13)
      ..write(obj.isGet)
      ..writeByte(14)
      ..write(obj.displayPhone)
      ..writeByte(15)
      ..write(obj.category)
      ..writeByte(16)
      ..write(obj.isNewContact)
      ..writeByte(17)
      ..write(obj.profileImage)
      ..writeByte(18)
      ..write(obj.lastInterestCycleDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
