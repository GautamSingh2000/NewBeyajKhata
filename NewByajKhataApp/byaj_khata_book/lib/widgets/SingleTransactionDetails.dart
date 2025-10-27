import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/models/Transaction.dart';

class SingleTransactionDetails extends StatelessWidget {
  final Transaction transaction; // pass computed balance

  const SingleTransactionDetails({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400; // responsive scaling

    final isPaymentSent = transaction.transactionType == "gave";
    final date = DateFormat("dd MMM yy").format(transaction.date);
    final time = DateFormat("hh:mm a").format(transaction.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== TOP ROW ==========
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Date, Time, Type ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    isPaymentSent ? "assets/icons/arrow_down.svg" : "assets/icons/arrow_up.svg",
                    width: 16 * scale,
                    height: 16 * scale,
                    colorFilter: ColorFilter.mode(
                      isPaymentSent ? Colors.red : Colors.green,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 10 * scale,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPaymentSent ? "Payment sent" : "Payment received",
                        style: GoogleFonts.poppins(
                          fontSize: 10 * scale,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ---- Amounts ----
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${transaction.amount.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      color: isPaymentSent ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "₹${transaction.balanceAfterTx.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      color: transaction.balanceAfterTx >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ========== IMAGE + RECEIPT ==========
          if (transaction.imagePath != null && transaction.imagePath!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(transaction.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "View Receipt",
                    style: GoogleFonts.poppins(
                      fontSize: 11 * scale,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

