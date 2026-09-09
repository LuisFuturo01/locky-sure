import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { emerald, ocean, rose, pearl, obsidian, red }

class AppTheme {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.emerald:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF34D399),
          background: const Color(0xFF0F1A15),
          surface: const Color(0xFF1A2E26),
          onSurface: const Color(0xFFE2E8F0),
        );
      case AppThemeMode.ocean:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF3B82F6),
          secondary: const Color(0xFF60A5FA),
          background: const Color(0xFF0C1222),
          surface: const Color(0xFF1A2744),
          onSurface: const Color(0xFFE2E8F0),
        );
      case AppThemeMode.rose:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFF472B6),
          secondary: const Color(0xFFFB7185),
          background: const Color(0xFF1A0F15),
          surface: const Color(0xFF2E1A26),
          onSurface: const Color(0xFFFCE7F3),
        );
      case AppThemeMode.pearl:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF818CF8),
          background: const Color(0xFFF8FAFC),
          surface: Colors.white,
          onSurface: const Color(0xFF334155),
        );
      case AppThemeMode.obsidian:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFA78BFA),
          secondary: const Color(0xFFC4B5FD),
          background: const Color(0xFF09090B),
          surface: const Color(0xFF18181B),
          onSurface: const Color(0xFFF4F4F5),
        );
      case AppThemeMode.red:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFEF4444),
          secondary: const Color(0xFFF87171),
          background: const Color(0xFF180A0A),
          surface: const Color(0xFF2D1212),
          onSurface: const Color(0xFFFEE2E2),
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color onSurface,
  }) {
    final baseTextTheme = GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      textTheme: baseTextTheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
