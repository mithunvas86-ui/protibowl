import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BauhausTheme {
  // Colors - Neo-Brutalist Palette
  static const Color primaryBlack = Color(0xFF000000);
  static const Color surfaceBlack = Color(0xFF1A1A1A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF808080);
  static const Color accentRed = Color(0xFFE63946);
  static const Color patternGrey = Color(0xFFE8E8E8);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: primaryBlack,
      scaffoldBackgroundColor: white,
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlack),
        titleTextStyle: GoogleFonts.chivo(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.chivo(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.chivo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          height: 1.2,
        ),
        headlineSmall: GoogleFonts.chivo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
        ),
        titleLarge: GoogleFonts.chivo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        bodyLarge: GoogleFonts.chivo(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryBlack,
        ),
        bodyMedium: GoogleFonts.chivo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryBlack,
        ),
        bodySmall: GoogleFonts.chivo(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mediumGrey,
        ),
        labelLarge: GoogleFonts.chivo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: primaryBlack, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.chivo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlack,
          side: const BorderSide(color: primaryBlack, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.chivo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: primaryBlack, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: primaryBlack, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
        labelStyle: GoogleFonts.chivo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primaryBlack,
          letterSpacing: 0.5,
        ),
        hintStyle: GoogleFonts.chivo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: mediumGrey,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: primaryBlack, width: 2),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryBlack,
        selectedItemColor: accentRed,
        unselectedItemColor: white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.chivo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accentRed,
        ),
        unselectedLabelStyle: GoogleFonts.chivo(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: white,
        ),
      ),
      dividerColor: primaryBlack,
      dividerTheme: const DividerThemeData(
        color: primaryBlack,
        thickness: 2,
        space: 0,
      ),
    );
  }
}
