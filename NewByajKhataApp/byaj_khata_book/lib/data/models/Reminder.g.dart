// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 2;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      contactId: fields[0] as String,
      reminderId: fields[7] as int,
      scheduledDate: fields[6] as DateTime,
      amount: fields[2] as double,
      dueDate: fields[3] as DateTime?,
      createAt: fields[9] as DateTime,
      name: fields[10] as String,
      message: fields[8] as String,
      title: fields[1] as String,
      daysLeft: fields[4] as int,
      isCompleted: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.contactId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.daysLeft)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.scheduledDate)
      ..writeByte(7)
      ..write(obj.reminderId)
      ..writeByte(8)
      ..write(obj.message)
      ..writeByte(9)
      ..write(obj.createAt)
      ..writeByte(10)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
