import 'package:flutter/material.dart';

/// ProMarket Color Palette
/// Premium colors for the role-aware e-commerce platform
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==================== PRIMARY COLORS ====================
  
  /// Deep Indigo - Primary brand color
  static const Color primaryIndigo = Color(0xFF1A237E);
  static const Color primaryIndigoLight = Color(0xFF534BAE);
  static const Color primaryIndigoDark = Color(0xFF000051);
  
  /// Electric Purple - Accent color
  static const Color electricPurple = Color(0xFF7C4DFF);
  static const Color electricPurpleLight = Color(0xFFB47CFF);
  static const Color electricPurpleDark = Color(0xFF3F1DCB);
  
  // ==================== ACCENT COLORS ====================
  
  /// Neon Blue/Cyan - Highlights and CTAs
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonBlueLight = Color(0xFF6EFFFF);
  static const Color neonBlueDark = Color(0xFF00B2CC);
  
  // ==================== SEMANTIC COLORS ====================
  
  /// Success - Emerald green
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFF5EFC82);
  static const Color successDark = Color(0xFF009624);
  
  /// Error - Soft red
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFFFF867F);
  static const Color errorDark = Color(0xFFC50E29);
  
  /// Warning - Amber
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningLight = Color(0xFFFFE97D);
  static const Color warningDark = Color(0xFFC88719);
  
  /// Info - Light blue
  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFF73E8FF);
  static const Color infoDark = Color(0xFF0086C3);
  
  // ==================== DARK THEME BACKGROUNDS ====================
  
  /// Background gradient - Navy to Black
  static const Color darkNavy = Color(0xFF0A192F);
  static const Color darkBlack = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1A1F36);
  static const Color darkCard = Color(0xFF252D47);
  static const Color darkBackground = Color(0xFF121212); // Added darkBackground
  
  // ==================== LIGHT THEME BACKGROUNDS ====================
  
  /// Light backgrounds
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8F9FC);
  
  // ==================== NEUTRAL COLORS ====================
  
  /// Grays for text and borders
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
  
  // ==================== ROLE-SPECIFIC COLORS ====================
  
  /// Role indicator colors
  static const Color roleUser = Color(0xFF00E5FF); // Neon Blue
  static const Color roleEmployee = Color(0xFF7C4DFF); // Electric Purple
  static const Color roleAdmin = Color(0xFFFF5252); // Soft Red
  
  // ==================== GLASSMORPHISM ====================
  
  /// Glass effect colors
  static Color glassWhite = Colors.white.withOpacity(0.1);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  static Color glassGradientStart = Colors.white.withOpacity(0.15);
  static Color glassGradientEnd = Colors.white.withOpacity(0.05);
  
  // ==================== GRADIENTS ====================
  
  /// Primary gradient (Indigo to Purple)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryIndigo, electricPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Accent gradient (Purple to Neon Blue)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [electricPurple, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Dark background gradient
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [darkNavy, darkBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Error gradient
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== SHADOWS ====================
  
  /// Soft shadow for cards
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Strong shadow for elevated cards
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
  
  /// Neon glow effect
  static List<BoxShadow> neonGlow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
