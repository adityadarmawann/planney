import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Planney palette: deep navy base with aqua and pink highlights.
  static const Color primary = Color(0xFF011D5D);
  static const Color primaryLight = Color(0xFF0F4EA3);
  static const Color primaryLighter = Color(0xFF58D7E4);
  static const Color primaryLightest = Color(0xFFE7F8FC);
  static const Color primaryDark = Color(0xFF011342);

  static const Color secondary = Color(0xFFF378AB);
  static const Color secondaryLight = Color(0xFFFFE2EC);

  // Background
  static const Color background = Color(0xFFF8FBFF);
  static const Color backgroundSecondary = Color(0xFFEEF6FB);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF10213D);
  static const Color textSecondary = Color(0xFF5C6F92);
  static const Color textHint = Color(0xFF9CACCA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF1DBE4A);
  static const Color successLight = Color(0xFFE6F8E6);
  static const Color error = Color(0xFFE85547);
  static const Color errorLight = Color(0xFFFEE8E6);
  static const Color warning = Color(0xFFF378AB);
  static const Color warningLight = Color(0xFFFFE2EC);
  static const Color info = Color(0xFF0F4EA3);
  static const Color infoLight = Color(0xFFE7F8FC);

  // Income/Expense
  static const Color income = Color(0xFF1DBE4A);
  static const Color expense = Color(0xFFE85547);

  // Border & divider
  static const Color border = Color(0xFFD9E7F2);
  static const Color divider = Color(0xFFEAF1F7);

  // Shadow
  static const Color shadow = Color(0x0D000000);

  // Overlay
  static const Color overlay = Color(0x80000000);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF011342), Color(0xFF0F4EA3)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF011D5D), Color(0xFF2CA9D8)],
  );
}
