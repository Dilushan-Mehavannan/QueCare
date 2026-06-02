import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette - Premium Teal and Mint (HSL derived)
  static const Color primaryTeal = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLightTeal = Color(0xFF14B8A6); // Bright Teal
  static const Color accentMint = Color(0xFF10B981); // Mint
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Colors.white;
  
  // Status Colors
  static const Color statusPendingText = Color(0xFFB45309); // Amber 700
  static const Color statusPendingBg = Color(0xFFFEF3C7); // Amber 100
  
  static const Color statusQueueText = Color(0xFF1D4ED8); // Blue 700
  static const Color statusQueueBg = Color(0xFFDBEAFE); // Blue 100
  
  static const Color statusCompletedText = Color(0xFF047857); // Emerald 700
  static const Color statusCompletedBg = Color(0xFFD1FAE5); // Emerald 100
  
  static const Color statusCancelledText = Color(0xFFB91C1C); // Red 700
  static const Color statusCancelledBg = Color(0xFFFEE2E2); // Red 100

  // Text Style Helpers
  static TextStyle get heading1 => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A), // Slate 900
      );

  static TextStyle get heading2 => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B), // Slate 800
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        color: const Color(0xFF334155), // Slate 700
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF475569), // Slate 600
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF64748B), // Slate 500
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: primaryLightTeal,
        tertiary: accentMint,
        background: backgroundLight,
        surface: cardLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: TextTheme(
        headlineLarge: heading1,
        headlineMedium: heading2,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: heading2.copyWith(color: primaryTeal),
        iconTheme: const IconThemeData(color: primaryTeal),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 4,
        shadowColor: const Color(0x0A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
      ),
    );
  }
}
