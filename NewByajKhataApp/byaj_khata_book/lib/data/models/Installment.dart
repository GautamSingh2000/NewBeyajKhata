import 'package:hive/hive.dart';

part 'Installment.g.dart';

@HiveType(typeId: 7)
class Installment {
  @HiveField(0)
  int installmentNumber;

  @HiveField(1)
  DateTime? dueDate;

  @HiveField(2)
  DateTime? paidDate;

  @HiveField(3)
  double totalAmount;

  @HiveField(4)
  double principal;

  @HiveField(5)
  double interest;

  @HiveField(6)
  double remainingAmount;

  @HiveField(7)
  bool isPaid;

  Installment({
    required this.installmentNumber,
    required this.dueDate,
    this.paidDate,
    required this.totalAmount,
    required this.principal,
    required this.interest,
    required this.remainingAmount,
    this.isPaid = false,
  });
}