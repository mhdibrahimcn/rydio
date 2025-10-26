import 'package:flutter/material.dart';

class AppColors {
  // Primary Dark Theme Colors
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color secondaryDark = Color(0xFF1B263B);
  static const Color tertiaryDark = Color(0xFF415A77);

  // Accent Colors
  static const Color accentCyan = Color(0xFF00D9FF);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentPurple = Color(0xFF9D4EDD);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textTertiary = Color(0xFF78909C);

  // Background Colors
  static const Color backgroundPrimary = Color(0xFF0D1B2A);
  static const Color backgroundSecondary = Color(0xFF1B263B);
  static const Color backgroundCard = Color(0x1AFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF40C4FF);

  // Service Brand Colors
  static const Color uberBlack = Color(0xFF000000);
  static const Color uberWhite = Color(0xFFFFFFFF);
  static const Color olaGreen = Color(0xFF00BFA5);
  static const Color rapidoYellow = Color(0xFFFFD600);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentPurple],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accentCyan, accentPurple],
  );

  // Glassmorphism Colors
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Shadow Colors
  static const Color shadowColor = Color(0x40000000);

  // Location Indicator Colors
  static const Color pickupColor = accentGreen;
  static const Color dropColor = accentOrange;
}
