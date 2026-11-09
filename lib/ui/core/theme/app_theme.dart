import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/core/utils/expense_utils.dart';

class AppTheme {
  // Brand colors
  static const Color primaryLight = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryDark = Color(0xFF818CF8);  // Vibrant Indigo-Lavender
  
  static const Color secondaryLight = Color(0xFF0D9488); // Teal
  static const Color secondaryDark = Color(0xFF2DD4BF);  // Bright Teal
  
  // Neutral colors - Light Mode
  static const Color bgLight = Color(0xFFF8FAFC);      // Off-white / light slate
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color borderLight = Color(0xFFE2E8F0);  // Slate-200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate-900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate-600
  
  // Neutral colors - Dark Mode
  static const Color bgDark = Color(0xFF0B0F19);       // Deep space / obsidian
  static const Color surfaceDark = Color(0xFF151D2F);  // Navy-slate card surface
  static const Color borderDark = Color(0xFF242F41);   // Slate-800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);  // Slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate-400

  // Category specific colors (used across lists, charts, and details)
  static Color getCategoryColor(String category) {
    return ExpenseUtils.getCategoryColor(category);
  }

  // Linear gradient helpers
  static List<Color> getPrimaryGradient(bool isDark) {
    return isDark 
      ? [const Color(0xFF818CF8), const Color(0xFF6366F1)]
      : [const Color(0xFF4F46E5), const Color(0xFF6366F1)];
  }

  static List<Color> getAccentGradient(bool isDark) {
    return isDark
      ? [const Color(0xFF2DD4BF), const Color(0xFF0D9488)]
      : [const Color(0xFF0D9488), const Color(0xFF14B8A6)];
  }

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        error: Color(0xFFEF4444),
        shadow: Color(0x05000000),
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryLight),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimaryLight),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryLight),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimaryLight),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimaryLight),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondaryLight),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate-100
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondaryLight, fontSize: 14),
        hintStyle: TextStyle(color: textSecondaryLight.withValues(alpha: 0.5), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        error: Color(0xFFEF4444),
        shadow: Color(0x10000000),
      ),
      scaffoldBackgroundColor: bgDark,
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryDark),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimaryDark),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimaryDark),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimaryDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondaryDark),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondaryDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B), // Slate-800
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondaryDark, fontSize: 14),
        hintStyle: TextStyle(color: textSecondaryDark.withValues(alpha: 0.5), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: bgDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: bgDark,
        elevation: 4,
      ),
    );
  }
}
