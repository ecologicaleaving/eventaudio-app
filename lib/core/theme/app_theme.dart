import 'package:flutter/material.dart';

/// StageConnect Design System
/// Professional dark theme inspired by stage lighting and audio consoles
class AppTheme {
  AppTheme._();

  // ── Brand Colors ──────────────────────────────────────────
  static const Color stageGold = Color(0xFFFFAB00);
  static const Color stageAmber = Color(0xFFFF8F00);
  static const Color liveRed = Color(0xFFFF1744);
  static const Color connectedGreen = Color(0xFF00E676);
  static const Color techCyan = Color(0xFF00BCD4);
  static const Color stagePurple = Color(0xFF9C27B0);

  // ── Surface Palette ───────────────────────────────────────
  static const Color surfaceBlack = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF121218);
  static const Color surfaceCard = Color(0xFF1A1A22);
  static const Color surfaceElevated = Color(0xFF24242E);
  static const Color surfaceBorder = Color(0xFF2E2E3A);

  // ── Text Colors ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9E9EAE);
  static const Color textMuted = Color(0xFF6E6E7E);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [stageGold, stageAmber],
  );

  static const LinearGradient liveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceBlack, Color(0xFF0F0F18)],
  );

  // ── Theme Data ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: stageAmber,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF3D2E00),
        onPrimaryContainer: stageGold,
        secondary: techCyan,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF003D47),
        onSecondaryContainer: techCyan,
        tertiary: stagePurple,
        onTertiary: Colors.white,
        error: liveRed,
        onError: Colors.white,
        surface: surfaceDark,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: surfaceBorder,
        outlineVariant: Color(0xFF1E1E28),
      ),
      scaffoldBackgroundColor: surfaceBlack,
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: stageAmber,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: stageAmber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: stageAmber,
          side: const BorderSide(color: stageAmber, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: stageAmber,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stageAmber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: liveRed),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textMuted,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return stageAmber;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return stageAmber.withValues(alpha: 0.3);
          }
          return surfaceBorder;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceBorder),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: stageAmber,
      ),
    );
  }
}
