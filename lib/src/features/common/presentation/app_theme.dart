import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF6C4CF5);
  static const Color _lightBackground = Color(0xFFF8F9FD); // Slightly cooler/brighter
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _darkBackground = Color(0xFF12121A); // Deeper dark

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        surface: _lightSurface,
        surfaceTint: Colors.transparent, // Remove surface tint for cleaner look
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF1A1A24),
        displayColor: const Color(0xFF1A1A24),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: _lightBackground,
        foregroundColor: Color(0xFF1A1A24),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(24),
           borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: _seedColor.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFF2F1F9),
        selectedColor: _seedColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        highlightElevation: 8,
        splashColor: Colors.white.withValues(alpha: 0.2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent, // Transparent for floating look
        indicatorColor: _seedColor.withValues(alpha: 0.15),
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? _seedColor : Colors.grey.shade500,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected) ? _seedColor : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E28),
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E28),
        hintStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E28),
        indicatorColor: Colors.white.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? Colors.white : Colors.grey.shade600,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? Colors.white : Colors.grey.shade600,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
      ),
    );
  }
  
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.outfit(textStyle: base.displayLarge, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.outfit(textStyle: base.displayMedium, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.outfit(textStyle: base.displaySmall, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.outfit(textStyle: base.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.outfit(textStyle: base.headlineMedium, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.outfit(textStyle: base.headlineSmall, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.outfit(textStyle: base.titleLarge, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.outfit(textStyle: base.titleMedium, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.outfit(textStyle: base.titleSmall, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.inter(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.inter(textStyle: base.labelLarge, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(textStyle: base.labelMedium, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(textStyle: base.labelSmall, fontWeight: FontWeight.w500),
    );
  }
}

