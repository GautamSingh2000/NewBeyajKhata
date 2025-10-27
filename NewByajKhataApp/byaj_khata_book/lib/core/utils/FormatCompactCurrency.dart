import 'package:intl/intl.dart';

String formatCompactCurrency(double amount) {
  // Only abbreviate for amounts of 1 crore (10 million) or more
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
  }
  // For all other amounts, use proper Indian number formatting
  else {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return currencyFormat.format(amount);
  }
}