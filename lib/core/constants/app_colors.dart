import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================
  // LIGHT MODE COLORS
  // ============================================
  
  // Primary palette: deep navy and magenta with soft gray support.
  static const Color primary = Color(0xFF15173D);
  static const Color primaryLight = Color(0xFF2F357A);
  static const Color primaryLighter = Color(0xFF73C8DF);
  static const Color primaryLightest = Color(0xFFF1ECF2);
  static const Color primaryDark = Color(0xFF0F102F);

  static const Color secondary = Color(0xFF982598);
  static const Color secondaryLight = Color(0xFFE5B9DF);
  static const Color accentPink = Color(0xFFD757A9);

  // Background - Light mode
  static const Color background = Color(0xFFF4F0F2);
  static const Color backgroundSecondary = Color(0xFFEAE3E7);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Text - Light mode
  static const Color textPrimary = Color(0xFF1E1B30);
  static const Color textSecondary = Color(0xFF625A73);
  static const Color textHint = Color(0xFFA096AD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors - Light mode
  static const Color success = Color(0xFF22A884);
  static const Color successLight = Color(0xFFE2F5EF);
  static const Color error = Color(0xFFD14A69);
  static const Color errorLight = Color(0xFFFBE8ED);
  static const Color warning = Color(0xFFB26722);
  static const Color warningLight = Color(0xFFF8EBDD);
  static const Color info = Color(0xFF2F357A);
  static const Color infoLight = Color(0xFFE5E8F9);

  // Income/Expense
  static const Color income = Color(0xFF22A884);
  static const Color expense = Color(0xFFD14A69);

  // Border & divider - Light mode
  static const Color border = Color(0xFFD7CFD8);
  static const Color divider = Color(0xFFE5DEE5);

  // Shadow
  static const Color shadow = Color(0x0D000000);

  // Overlay
  static const Color overlay = Color(0x80000000);

  // ============================================
  // DARK MODE COLORS
  // ============================================
  
  // Background - Dark mode
  static const Color darkBackground = Color(0xFF110E1A);
  static const Color darkSurface = Color(0xFF1A1625);
  static const Color darkSurfaceAlt = Color(0xFF241D33);
  static const Color darkCard = Color(0xFF1A1625);

  // Text - Dark mode (improved contrast)
  static const Color darkText = Color(0xFFF2EBFA);      // Higher contrast white
  static const Color darkTextSecondary = Color(0xFFB8AFCB);  // Lighter secondary
  static const Color darkTextHint = Color(0xFF8F85A5);

  // Primary/Secondary - Dark mode (adjusted for visibility)
  static const Color darkPrimary = Color(0xFFB086D9);
  static const Color darkSecondary = Color(0xFFD879C8);

  // Border & divider - Dark mode
  static const Color darkBorder = Color(0xFF393049);
  static const Color darkDivider = Color(0xFF393049);

  // ============================================
  // GRADIENTS
  // ============================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15173D), Color(0xFF982598)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15173D), Color(0xFF6E2D8E)],
  );

  // Dark mode gradient
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF241D33), Color(0xFF3D2952)],
  );

  // ============================================
  // HELPER METHODS FOR DARK/LIGHT MODE
  // ============================================

  /// Get the appropriate text primary color based on brightness
  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkText : textPrimary;
  }

  /// Get the appropriate text secondary color based on brightness
  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  /// Get the appropriate text hint color based on brightness
  static Color getTextHint(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextHint : textHint;
  }

  /// Get the appropriate background color based on brightness
  static Color getBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkBackground : background;
  }

  /// Get the appropriate surface color based on brightness
  static Color getSurface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : backgroundCard;
  }

  /// Get the appropriate border color based on brightness
  static Color getBorder(Brightness brightness) {
    return brightness == Brightness.dark ? darkBorder : border;
  }

  /// Get the appropriate divider color based on brightness
  static Color getDivider(Brightness brightness) {
    return brightness == Brightness.dark ? darkDivider : divider;
  }

  /// Get the appropriate primary color based on brightness
  static Color getPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkPrimary : primary;
  }

  /// Get the appropriate secondary color based on brightness
  static Color getSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkSecondary : secondary;
  }
}

