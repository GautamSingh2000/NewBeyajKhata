import 'package:hive/hive.dart';

part 'Reminder.g.dart';

@HiveType(typeId: 2)
class Reminder {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  int daysLeft;

  @HiveField(5)
  bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.daysLeft = 0,
    this.isCompleted = false,
  });
}
