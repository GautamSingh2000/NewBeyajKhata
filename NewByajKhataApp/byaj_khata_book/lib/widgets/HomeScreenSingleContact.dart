import 'package:byaj_khata_book/core/constants/InterestType.dart';
import 'package:byaj_khata_book/core/constants/RouteNames.dart';
import 'package:byaj_khata_book/data/models/Transaction.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../core/constants/ContactType.dart';
import '../core/constants/InterestPeriod.dart';
import '../core/theme/AppColors.dart';
import '../core/utils/FormatCompactCurrency.dart';
import '../core/utils/FormatTime.dart';
import '../data/models/Contact.dart';
import '../providers/TransactionProviderr.dart';
import 'IntrestBreakdownItem.dart';

Widget HomeScreenSingleContact(
  Contact contact,
  BuildContext context,
  bool isWithInterest,
) {
  final isGet = contact.isGet;
  final contactId = contact.contactId;

  final logger = new Logger();
  logger.e("principal and interets due for contact ${contact.name} : ${contact.principal}  ${contact.interestDue}");


  // Get last edited time and format it (update this to ensure consistent formatting)
  String timeText;

  timeText = formatRelativeTime(contact.lastEditedAt);
  // Truncate long names to prevent pixel overflow
  final String originalName = contact.name;
  final String displayName = originalName.length > 15
      ? "${originalName.substring(0, 15)}..."
      : originalName;

  // Get transaction provider
  final transactionProvider = Provider.of<TransactionProviderr>(context);

  // Get balance from transactions

  double principalAmount = contact.principal;
  double displayAmount = principalAmount;
  double totalInterestDue = _calculateUpdatedInterestDue(contact);
final transactions = transactionProvider.getTransactionsForContact(contactId);
  // Get updated balance from transactions if available
  if (transactions.isNotEmpty) {

    final lastBalance = transactions.last.balanceAfterTx;
    if (lastBalance == -1) {
      displayAmount = contact.displayAmount + totalInterestDue;
    } else {
      displayAmount = (lastBalance.abs()) + totalInterestDue;
    }
  } else {
    // No transactions yet — just show principal + interest
    displayAmount = principalAmount + totalInterestDue;
  }

  // contact.displayAmount = displayAmount;

  // Format amount for display with compact notation for large values
  String amountText = formatCompactCurrency(displayAmount);
  // Determine font size based on amount value
  double fontSize = 15.0;
  if (displayAmount >= 1000000) {
    // More than 10 lakhs
    fontSize = 13.0;
  } else if (displayAmount >= 100000) {
    // More than 1 lakh
    fontSize = 14.0;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Dismissible(
      key: Key(contact.contactId),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        final bool? confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              "Delete Contact?",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                children: [
                  const TextSpan(text: "Are you sure you want to delete "),
                  TextSpan(
                    text: contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, // 🔹 make name bold
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(
                    text: "?\n\nThis will remove all associated transactions.",
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Delete",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (direction) async {
        // Delete contact and related transactions
        await transactionProvider.deleteContact(contact.contactId);
        // Optional: show feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${contact.name} deleted"),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      },

      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              isGet ? Colors.green.shade50 : Colors.red.shade50,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.push(
                RouteNames.contestDetails,
                extra: {
                  'isWithInterest': isWithInterest,
                  'contactId': contactId,
                  'dailyInterestNote':
                      '(${_getMonthAbbreviation()} - ${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day} days)',
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'avatar_${contact.contactId}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: contact.color?.withOpacity(0.3) != null
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: contact.color,
                            child: Text(
                              contact.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isWithInterest) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.amber.shade200,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.percent,
                                          size: 10,
                                          color: Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${contact.interestRate} ${contact.interestPeriod == InterestPeriod.yearly ? "P.A.":"P.M."}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.amber.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100, // Fixed width container
                            height: 22, // Fixed height for consistent UI
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                amountText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                  color: isGet
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isGet
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isGet
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGet
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  size: 12,
                                  color: isGet
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isGet ? 'Receive' : 'Pay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isGet
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (isWithInterest) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: IntrestBreakdownItem(
                              label: 'Principal',
                              amount: principalAmount,
                              iconData: "assets/icons/rupee_icon.svg",
                              color: Colors.indigo,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: IntrestBreakdownItem(
                              label: 'Interest Due',
                              amount: totalInterestDue,
                              iconData: "assets/icons/interest_icon.svg",
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: IntrestBreakdownItem(
                              label: 'Total',
                              amount: principalAmount + totalInterestDue,
                              iconData: "assets/icons/wallet.svg",
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Helper method to calculate interest for an individual contact
double _calculateUpdatedInterestDue(Contact contact) {
  if (contact.interestType != InterestType.withInterest) return 0.0;
  if (contact.principal <= 0) return 0.0;

  final double principal = contact.principal;
  final double rate = contact.interestRate;
  final InterestPeriod period = contact.interestPeriod ?? InterestPeriod.yearly;
  final DateTime now = DateTime.now();
  final DateTime lastCycleDate = contact.lastInterestCycleDate ?? now;
  final int daysPassed = now.difference(lastCycleDate).inDays;

  // ✅ Skip if same day (no new growth)
  if (daysPassed <= 0) return contact.interestDue;

  double newInterest = 0.0;
  switch (period) {
    case InterestPeriod.daily:
      newInterest = principal * (rate / 100) * daysPassed;
      break;
    case InterestPeriod.weekly:
      final weeks = daysPassed / 7.0;
      newInterest = principal * (rate / 100) * weeks;
      break;
    case InterestPeriod.monthly:
      final months = daysPassed / 30.0;
      newInterest = principal * (rate / 100) * months;
      break;
    case InterestPeriod.yearly:
      final years = daysPassed / 365.0;
      newInterest = principal * (rate / 100) * years;
      break;
  }

  // ✅ Add new interest to existing unpaid interest
  double totalInterest = contact.interestDue + newInterest;

  return totalInterest;
}


String _getMonthAbbreviation() {
  final now = DateTime.now();
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[now.month - 1]; // Month is 1-based, array is 0-based
}
