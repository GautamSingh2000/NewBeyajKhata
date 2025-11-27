import 'package:hive/hive.dart';

part 'Reminder.g.dart';

@HiveType(typeId: 2)
class Reminder {
  @HiveField(0)
  String contactId;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  int daysLeft;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime scheduledDate;

  @HiveField(7)
  int reminderId;

  @HiveField(8)
  String message;

  @HiveField(9)
  DateTime createAt;

  @HiveField(10)
  String name;

  Reminder({
    required this.contactId,
    required this.reminderId,
    required this.scheduledDate,
    this.amount = 0,
    this.dueDate,
    required this.createAt,
    required this.name,
    this.message = "",
    this.title = "",
    this.daysLeft = 0,
    this.isCompleted = false,
  });
}
