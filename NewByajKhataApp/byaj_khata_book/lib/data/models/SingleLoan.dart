import 'package:hive/hive.dart';
import 'Installment.dart';

part 'SingleLoan.g.dart';


@HiveType(typeId: 6)
class SingleLoan {
  @HiveField(0)
  String id;

  @HiveField(1)
  String loanType;

  @HiveField(2)
  String category;

  @HiveField(3)
  double loanAmount;

  @HiveField(4)
  double interestRate;

  @HiveField(5)
  int loanTerm;

  @HiveField(6)
  String status;

  @HiveField(7)
  double progress;

  @HiveField(8)
  DateTime startAt;

  @HiveField(9)
  DateTime firstPaymentDate;

  @HiveField(10)
  DateTime createdDate;

  @HiveField(11)
  DateTime? completionDate;

  @HiveField(12)
  List<Installment>? installments;

  @HiveField(13)
  String loanName;

  @HiveField(14)
  String? loanProvider;

  @HiveField(15)
  String? loanNumber;

  @HiveField(16)
  String? helplineNumber;

  @HiveField(17)
  String? managerNumber;

  @HiveField(18)
  String paymentMethod;

  @HiveField(19)
  String interestType;

  SingleLoan({
    required this.id,
    required this.loanType,
    required this.category,
    required this.loanAmount,
    required this.interestRate,
    required this.loanTerm,
    required this.status,
    required this.progress,
    required this.startAt,
    required this.firstPaymentDate,
    required this.createdDate,
    this.completionDate,
    this.installments,
    required this.loanName,
    this.loanProvider,
    this.loanNumber,
    this.helplineNumber,
    this.managerNumber,
    required this.paymentMethod,
    required this.interestType,
  });
}