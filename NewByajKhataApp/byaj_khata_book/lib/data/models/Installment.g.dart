// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Installment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstallmentAdapter extends TypeAdapter<Installment> {
  @override
  final int typeId = 7;

  @override
  Installment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Installment(
      installmentNumber: fields[0] as int,
      dueDate: fields[1] as DateTime?,
      paidDate: fields[2] as DateTime?,
      totalAmount: fields[3] as double,
      principal: fields[4] as double,
      interest: fields[5] as double,
      remainingAmount: fields[6] as double,
      isPaid: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Installment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.installmentNumber)
      ..writeByte(1)
      ..write(obj.dueDate)
      ..writeByte(2)
      ..write(obj.paidDate)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.principal)
      ..writeByte(5)
      ..write(obj.interest)
      ..writeByte(6)
      ..write(obj.remainingAmount)
      ..writeByte(7)
      ..write(obj.isPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
