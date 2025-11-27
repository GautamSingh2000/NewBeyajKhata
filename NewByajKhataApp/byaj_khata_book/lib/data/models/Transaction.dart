import 'package:hive/hive.dart';

part 'Transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String transactionType; // gave / got

  @HiveField(3)
  String note;

  @HiveField(4)
  List<String>? imagePath;

  @HiveField(5)
  bool isInterestPayment;

  @HiveField(6)
  String contactId;

  @HiveField(7)
  bool isPrincipal;

  @HiveField(8)
  double? interestRate;

  @HiveField(9)
  double balanceAfterTx;

  Transaction({
    required this.date,
    required this.amount,
    required this.contactId,
    required this.transactionType,
    this.note = "",
    this.imagePath,
    this.isInterestPayment = false,
    this.isPrincipal = true,
    this.interestRate,
    this.balanceAfterTx = 0.0,
  });
}
