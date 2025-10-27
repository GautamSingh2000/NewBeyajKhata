// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      date: fields[0] as DateTime,
      amount: fields[1] as double,
      contactId: fields[6] as String,
      transactionType: fields[2] as String,
      note: fields[3] as String,
      imagePath: fields[4] as String?,
      isInterestPayment: fields[5] as bool,
      isPrincipal: fields[7] as bool,
      interestRate: fields[8] as double?,
      balanceAfterTx: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.transactionType)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.isInterestPayment)
      ..writeByte(6)
      ..write(obj.contactId)
      ..writeByte(7)
      ..write(obj.isPrincipal)
      ..writeByte(8)
      ..write(obj.interestRate)
      ..writeByte(9)
      ..write(obj.balanceAfterTx);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
