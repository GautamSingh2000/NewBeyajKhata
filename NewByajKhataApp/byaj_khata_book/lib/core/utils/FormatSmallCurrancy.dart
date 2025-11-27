String formatSmallCurrency(double amount) {
  String format(double value) =>
      value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);

  if (amount >= 10000000) return '₹${format(amount / 10000000)}Cr';
  if (amount >= 100000) return '₹${format(amount / 100000)}L';
  if (amount >= 1000) return '₹${format(amount / 1000)}K';
  return '₹${format(amount)}';
}