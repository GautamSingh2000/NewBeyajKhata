String formatSmallCurrency(double amount) {
  // Handle zero
  if (amount == 0) return "₹0";

  // Integer part only for formatting (ignore paise)
  int value = amount.round();

  final int crore = value ~/ 10000000;
  final int lakh = (value % 10000000) ~/ 100000;
  final int thousand = (value % 100000) ~/ 1000;
  final int remainder = value % 1000;

  final List<String> parts = [];

  if (crore > 0) parts.add("${crore}Cr");
  if (lakh > 0) parts.add("${lakh}L");
  if (thousand > 0) parts.add("${thousand}K");
  if (remainder > 0 && parts.isEmpty) {
    // only show remainder if below 1000 or others empty
    parts.add("$remainder");
  } else if (remainder > 0) {
    parts.add("$remainder");
  }

  return "₹${parts.join(' ')}";
}