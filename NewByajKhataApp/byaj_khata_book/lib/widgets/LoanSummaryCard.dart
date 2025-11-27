
import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoanSummaryCard extends StatelessWidget {
  final String userName;
  final int activeLoans;
  final double totalAmount;
  final double dueAmount;

  const LoanSummaryCard({
    Key? key,
    required this.userName,
    required this.activeLoans,
    required this.totalAmount,
    required this.dueAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue0003,
            AppColors.blue0001,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue0004.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User greeting section - without icon
          Text(
            'Loan summary, $userName',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: context.screenWidth*0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Loan details in row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetail('Active Loans', activeLoans.toString(),context),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                ),
                child: SizedBox(
                  width: 1,
                  height: 30,
                ),
              ),
              _buildDetail('Total Amount', '₹${_formatAmount(totalAmount)}',context),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                ),
                child: SizedBox(
                  width: 1,
                  height: 30,
                ),
              ),
              _buildDetail('Due this month', '₹${_formatAmount(dueAmount)}',context),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value ,BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: context.screenWidth * 0.025,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: context.screenWidth * 0.03,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return amount.toInt().toString();
  }
}