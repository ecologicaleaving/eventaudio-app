import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EventAudio Design System — light theme aligned to the visitor PWA.
/// All tokens mirror the CSS variables in visitor-pwa/src/styles.css.
class AppTheme {
  AppTheme._();

  // ── Background / Surface ──────────────────────────────────────────
  static const Color bg = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4F3EF);

  // ── Lines / borders ───────────────────────────────────────────────
  static const Color line = Color(0xFFE7E5DF);
  static const Color lineStrong = Color(0xFFD5D2CA);

  // ── Text / ink ────────────────────────────────────────────────────
  static const Color ink = Color(0xFF15130F);
  static const Color inkMuted = Color(0xFF5A574E);
  static const Color inkDim = Color(0xFF8A877D);

  // ── Accent (EventAudio teal) ──────────────────────────────────────
  static const Color accent = Color(0xFF0EA5A3);
  static const Color accentSoft = Color(0x1A0EA5A3); // rgba(14,165,163,0.10)
  static const Color accentInk = Color(0xFF0F766E);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color ok = Color(0xFF2E7D4F);
  static const Color warn = Color(0xFFC88A1A);
  static const Color err = Color(0xFFB3261E);

  // ── Border radius ─────────────────────────────────────────────────
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;

  // ── Legacy aliases kept for references in old code ────────────────
  /// @deprecated use [accent]
  static const Color stageAmber = accent;
  /// @deprecated use [err]
  static const Color liveRed = err;
  /// @deprecated use [ok]
  static const Color connectedGreen = ok;
  /// @deprecated use [surface]
  static const Color surfaceCard = surface;
  /// @deprecated use [bg]
  static const Color surfaceBlack = bg;
  /// @deprecated use [surfaceAlt]
  static const Color surfaceElevated = surfaceAlt;
  /// @deprecated use [line]
  static const Color surfaceBorder = line;
  /// @deprecated use [ink]
  static const Color textPrimary = ink;
  /// @deprecated use [inkMuted]
  static const Color textSecondary = inkMuted;
  /// @deprecated use [inkDim]
  static const Color textMuted = inkDim;

  // ── Typography helpers ────────────────────────────────────────────
  static TextStyle get sans => GoogleFonts.inter();
  static TextStyle get mono => GoogleFonts.jetBrainsMono();

  // ── Theme Data ────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: accentSoft,
        onPrimaryContainer: accentInk,
        secondary: accentInk,
        onSecondary: Colors.white,
        tertiary: ok,
        onTertiary: Colors.white,
        error: err,
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: inkMuted,
        outline: line,
        outlineVariant: lineStrong,
      ),
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: line, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkMuted,
          side: const BorderSide(color: line, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: err),
        ),
        labelStyle: GoogleFonts.inter(color: inkMuted),
        hintStyle: GoogleFonts.inter(color: inkDim),
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return inkDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentSoft;
          return line;
        }),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: accent,
        inactiveTrackColor: line,
        thumbColor: accent,
        overlayColor: accentSoft,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: line),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.inter(color: surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
      ),
    );
  }

  /// Keep darkTheme as alias to lightTheme so any ThemeMode.dark reference
  /// still renders correctly with the EventAudio palette.
  static ThemeData get darkTheme => lightTheme;
}
