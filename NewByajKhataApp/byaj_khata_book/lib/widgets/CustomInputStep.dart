import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomInputStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? hintText;
  final String? labelText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final int maxLength;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? extraWidget; // e.g. "Resend OTP" button or info text
  final bool autoFocus;
  final TextAlign textAlign;

  const CustomInputStep({
    super.key,
    required this.title,
    this.subtitle,
    this.hintText,
    this.labelText,
    required this.controller,
    this.focusNode,
    required this.keyboardType,
    required this.maxLength,
    this.textStyle,
    this.decoration,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.extraWidget,
    this.autoFocus = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textAlign: textAlign,
          autofocus: autoFocus,
          style: textStyle ??
              GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
          scrollPadding: const EdgeInsets.only(bottom: 240),
          decoration: decoration ??
              InputDecoration(
                hintText: hintText,
                labelText: labelText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.gradientMid, // 👈 default border color
                    width: 1.2,
                  ),
                ),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              inputFormatters: inputFormatters ??
              [
                LengthLimitingTextInputFormatter(maxLength),
              ],
          validator: validator,
          onChanged: onChanged,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
        if (extraWidget != null) ...[
          const SizedBox(height: 12),
          extraWidget!,
        ],
      ],
    );
  }
}
