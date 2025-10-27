import 'package:byaj_khata_book/core/constants/InterestType.dart';
import 'package:byaj_khata_book/core/constants/RouteNames.dart';
import 'package:byaj_khata_book/data/models/Transaction.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  double originalBalance = contact.principal;
  double displayAmount = originalBalance;
final transactions = transactionProvider.getTransactionsForContact(contactId);
  // Get updated balance from transactions if available
  if (transactions.isNotEmpty) {
    final balance = transactions[transactions.length - 1].balanceAfterTx;
    if(balance == -1){
      displayAmount = contact.displayAmount;
    }else{
      displayAmount = balance.abs();
    }
  }

  // Calculate interest details if this is an interest-based contact
  double totalInterestDue = 0.0;
  double principalAmount = contact.principal;

  if (contact.interestType == InterestType.withInterest && transactions.isNotEmpty) {
    // Get interest rate from contact
    final double interestRate = contact.interestRate;
    final ContactType contactType = contact.contactType;
    final bool isMonthly = contact.interestPeriod == InterestPeriod.monthly;

    // Get interest due from contact or calculate it if missing
    totalInterestDue = contact.interestDue as double? ?? 0.0;

    // If interest due is missing, calculate it
    if (totalInterestDue <= 0) {
      // Call calculateInterestForContact to get accurate interest
      totalInterestDue = _calculateInterestForContact(
        contact,
        transactionProvider.getTransactionsForContact(contactId),
        interestRate,
        isMonthly,
        contactType,
      );

      // Store it in the contact for future use
      contact.interestDue = totalInterestDue;
    }

    // Update the display amount to include interest
    contact.displayAmount = principalAmount + totalInterestDue;
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${contact.name} deleted"),
            backgroundColor: Colors.red.shade600,
          ),
        );
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
double _calculateInterestForContact(
  Contact contact,
  List<Transaction> transactions,
  double interestRate,
  bool isMonthly,
  ContactType contactType,
) {
  // If there are no transactions, return 0
  if (transactions.isEmpty) {
    return 0.0;
  }

  // Sort transactions chronologically
  transactions.sort(
    (a, b) => (a.date as DateTime).compareTo(b.date as DateTime),
  );

  // Calculate interest using the transaction history
  DateTime? lastInterestDate = transactions.first.date as DateTime;
  double runningPrincipal = 0.0;
  double accumulatedInterest = 0.0;
  double interestPaid = 0.0;

  for (var tx in transactions) {
    final note = (tx.note ?? '').toLowerCase();
    final amount = tx.amount as double;
    final isGave = tx.transactionType == 'gave';
    final txDate = tx.date as DateTime;

    // Calculate interest up to this transaction
    if (lastInterestDate != null && runningPrincipal > 0) {
      final daysSinceLastCalculation = txDate
          .difference(lastInterestDate)
          .inDays;
      if (daysSinceLastCalculation > 0) {
        // Calculate interest based on complete months and remaining days
        double interestForPeriod = 0.0;

        if (isMonthly) {
          // Monthly interest calculation logic
          int completeMonths = 0;
          DateTime tempDate = DateTime(
            lastInterestDate.year,
            lastInterestDate.month,
            lastInterestDate.day,
          );

          while (true) {
            // Try to add one month
            DateTime nextMonth = DateTime(
              tempDate.year,
              tempDate.month + 1,
              tempDate.day,
            );

            // If adding one month exceeds the transaction date, break
            if (nextMonth.isAfter(txDate)) {
              break;
            }

            // Count this month and move to next
            completeMonths++;
            tempDate = nextMonth;
          }

          // Apply full monthly interest for complete months
          if (completeMonths > 0) {
            interestForPeriod +=
                runningPrincipal * (interestRate / 100) * completeMonths;
          }

          // Add remaining days as fraction of a month
          final remainingDays = txDate.difference(tempDate).inDays;
          if (remainingDays > 0) {
            final daysInMonth = DateTime(
              tempDate.year,
              tempDate.month + 1,
              0,
            ).day;
            double monthProportion = remainingDays / daysInMonth;
            interestForPeriod +=
                runningPrincipal * (interestRate / 100) * monthProportion;
          }
        } else {
          // Yearly interest calculation converted to daily rate
          final dailyRate = interestRate / 365;
          interestForPeriod +=
              runningPrincipal * (dailyRate / 100) * daysSinceLastCalculation;
        }

        accumulatedInterest += interestForPeriod;
      }
    }

    // Update based on transaction type
    if (note.contains('interest:')) {
      if (isGave) {
        // Interest payment made
        if (contactType == ContactType.borrower) {
          // For borrowers: interest payment adds to accumulated interest
          accumulatedInterest += amount;
        } else {
          // For lenders: interest payment reduces accumulated interest
          accumulatedInterest = (accumulatedInterest - amount > 0)
              ? accumulatedInterest - amount
              : 0;
        }
      } else {
        // Interest payment received
        interestPaid += amount;
      }
    } else {
      // Principal transaction
      if (isGave) {
        // Payment sent
        if (contactType == ContactType.borrower) {
          // For borrowers: principal payment adds to debt
          runningPrincipal += amount;
        } else {
          // For lenders: principal payment reduces debt
          runningPrincipal = (runningPrincipal - amount > 0)
              ? runningPrincipal - amount
              : 0;
        }
      } else {
        // Payment received
        if (contactType == ContactType.borrower) {
          // For borrowers, receiving payment decreases principal
          runningPrincipal = (runningPrincipal - amount > 0)
              ? runningPrincipal - amount
              : 0;
        } else {
          // For lenders, receiving payment increases principal (lender gave money)
          runningPrincipal += amount;
        }
      }
    }

    lastInterestDate = txDate;
  }

  // Calculate interest from last transaction to now
  if (lastInterestDate != null && runningPrincipal > 0) {
    // Calculate interest from last transaction to today
    double interestFromLastTx = 0.0;
    final now = DateTime.now();

    if (isMonthly) {
      // Monthly interest calculation logic for current period
      int completeMonths = 0;
      DateTime tempDate = DateTime(
        lastInterestDate.year,
        lastInterestDate.month,
        lastInterestDate.day,
      );

      while (true) {
        DateTime nextMonth = DateTime(
          tempDate.year,
          tempDate.month + 1,
          tempDate.day,
        );
        if (nextMonth.isAfter(now)) {
          break;
        }
        completeMonths++;
        tempDate = nextMonth;
      }

      if (completeMonths > 0) {
        interestFromLastTx +=
            runningPrincipal * (interestRate / 100) * completeMonths;
      }

      final remainingDays = now.difference(tempDate).inDays;
      if (remainingDays > 0) {
        final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
        double monthProportion = remainingDays / daysInMonth;
        interestFromLastTx +=
            runningPrincipal * (interestRate / 100) * monthProportion;
      }
    } else {
      // Yearly interest calculation for current period
      final daysSinceLastTx = now.difference(lastInterestDate).inDays;
      final dailyRate = interestRate / 365;
      interestFromLastTx +=
          runningPrincipal * (dailyRate / 100) * daysSinceLastTx;
    }

    accumulatedInterest += interestFromLastTx;
  }

  // Adjust for interest already paid - show net interest due
  double totalInterestDue = (accumulatedInterest - interestPaid > 0)
      ? accumulatedInterest - interestPaid
      : 0;

  return totalInterestDue;
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
