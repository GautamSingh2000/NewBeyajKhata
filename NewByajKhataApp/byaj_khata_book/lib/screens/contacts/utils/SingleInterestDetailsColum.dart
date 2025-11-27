import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

Widget singleInterestDetailsColum({
  required String title,
  required String amount,
  String? icon,
  String? subtitle,
  bool showBgShape = true,
  double titleSize = 10 ,
  double amountSize = 14,
  bool alignStart = false,
}) {
  // Format large numbers in a compact way
  double parsedAmount = double.tryParse(amount) ?? 0.0;
  String formattedAmount = parsedAmount.toStringAsFixed(2);

  return Row(
    mainAxisAlignment:  alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Column(
        children: [
          if(icon!=null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              icon!,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 06),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      if (subtitle != null)
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      const SizedBox(height: 2),
      // Use FittedBox to ensure text fits in its container
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            "₹ $formattedAmount",
            style: GoogleFonts.poppins(
              fontSize: amountSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
          ),
        ),
      ),
    ],
  );
}
