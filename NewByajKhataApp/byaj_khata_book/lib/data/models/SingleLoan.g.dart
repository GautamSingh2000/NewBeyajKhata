// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SingleLoan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SingleLoanAdapter extends TypeAdapter<SingleLoan> {
  @override
  final int typeId = 6;

  @override
  SingleLoan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SingleLoan(
      id: fields[0] as String,
      loanType: fields[1] as String,
      category: fields[2] as String,
      loanAmount: fields[3] as double,
      interestRate: fields[4] as double,
      loanTerm: fields[5] as int,
      status: fields[6] as String,
      progress: fields[7] as double,
      startAt: fields[8] as DateTime,
      firstPaymentDate: fields[9] as DateTime,
      createdDate: fields[10] as DateTime,
      completionDate: fields[11] as DateTime?,
      installments: (fields[12] as List?)?.cast<Installment>(),
      loanName: fields[13] as String,
      loanProvider: fields[14] as String?,
      loanNumber: fields[15] as String?,
      helplineNumber: fields[16] as String?,
      managerNumber: fields[17] as String?,
      paymentMethod: fields[18] as String,
      interestType: fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SingleLoan obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.loanType)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.loanAmount)
      ..writeByte(4)
      ..write(obj.interestRate)
      ..writeByte(5)
      ..write(obj.loanTerm)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.startAt)
      ..writeByte(9)
      ..write(obj.firstPaymentDate)
      ..writeByte(10)
      ..write(obj.createdDate)
      ..writeByte(11)
      ..write(obj.completionDate)
      ..writeByte(12)
      ..write(obj.installments)
      ..writeByte(13)
      ..write(obj.loanName)
      ..writeByte(14)
      ..write(obj.loanProvider)
      ..writeByte(15)
      ..write(obj.loanNumber)
      ..writeByte(16)
      ..write(obj.helplineNumber)
      ..writeByte(17)
      ..write(obj.managerNumber)
      ..writeByte(18)
      ..write(obj.paymentMethod)
      ..writeByte(19)
      ..write(obj.interestType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SingleLoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
