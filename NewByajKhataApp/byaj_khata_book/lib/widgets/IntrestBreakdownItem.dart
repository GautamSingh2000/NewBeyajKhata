import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/utils/FormatCompactCurrency.dart';

Widget IntrestBreakdownItem({
  required String label,
  required double amount,
  required String iconData,
  required Color color,
}) {
  return  Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconData,
          width: 12,
          height: 12,
          colorFilter: ColorFilter.mode(
            color,
            BlendMode.srcIn,
          ),
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:GoogleFonts.poppins(
                  fontSize: 8,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Improved FittedBox with fixed height container
              SizedBox(
                height: 14,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCompactCurrency(amount),
                    style: GoogleFonts.poppins(
                      fontSize: amount >= 100000 ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
}