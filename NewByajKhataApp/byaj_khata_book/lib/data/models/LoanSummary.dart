class LoanSummary {
  final String userName;
  final int activeLoans;
  final double totalAmount;
  final double dueAmount;

  LoanSummary({
    required this.userName,
    required this.activeLoans,
    required this.totalAmount,
    required this.dueAmount,
  });
}