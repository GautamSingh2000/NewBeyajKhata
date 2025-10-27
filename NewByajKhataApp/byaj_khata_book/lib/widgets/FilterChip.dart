import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/AppColors.dart';

Widget filterChip({
  required String label,
  required bool isSelected,
  required VoidCallback onSelected,
}) {
  return GestureDetector(
    onTap: onSelected,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.gradientStart : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.gradientStart : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    ),
  );
}