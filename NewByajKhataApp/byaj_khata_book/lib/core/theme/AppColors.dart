import 'package:flutter/material.dart';

class AppColors {
  // Background gradients
  static const Color gradientStart = Color(0xFF1565C0); // Blue 800
  static const Color gradientMid   = Color(0xFF0D47A1); // Blue 900
  static const Color gradientEnd   = Color(0xFF1A237E); // Indigo 900
  static final Color blue0001   = Colors.blue.shade700 ; // Indigo 900
  static final Color blue0002   = Colors.blue.shade600; // Indigo 900
  static final Color blue0003   = Colors.blue.shade500; // Indigo 900
  static final Color blue0004   = Colors.blue.shade200; // Indigo 900

  // Logo
  static const Color logoCircle = Colors.white;

  // Shadows
  static const Color shadowDark = Colors.black54;
  static const Color shadowLight = Color(0x420000FF); // semi blue

  // Texts
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static final Color gray0001 = Colors.grey.shade600;
  static final Color gray0002 = Color(0xE4E3E3FF);
  static const Color textShadow = Colors.black45;
  static const Color textGray = Colors.black45;
  static const Color gray = Color(0xFFEEEEEE);


  static const Color yellow = Color(0xFFFFE230);
  static const Color yellow0001 = Color(0xFFD80101);

  // Progress Indicator
  static const Color loader = Colors.white70;

  static const Gradient mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMid,
      AppColors.gradientEnd,
    ],
  );

  static final Gradient lightBlueGradient = LinearGradient(
    colors: [blue0002, gradientStart],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  static const Color primaryColor = gradientMid ; // Deep purple
  static const Color secondaryColor = Color(0xFF1FB6B0); // Teal
  static const Color accentColor = Color(0xFFFF6B6B); // Coral
  static const Color backgroundColor = Color(0xFFF9FAFC); // Light gray background

  // Text colors
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color lightTextColor = Color(0xFFEEEEEE);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7D3AC1), Color(0xFF6A2FBA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme:  TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
