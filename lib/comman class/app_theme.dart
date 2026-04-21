// ignore_for_file: deprecated_member_use
// lib/Constant/AppTheme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Brand colours (invariant) ─────────────────────────────────────────────
  static const Color brandPink    = Color(0xFFE91E63);
  static const Color brandOrange  = Color(0xFFFF6B35);
  static const Color brandCyan    = Color(0xFF00BCD4);
  static const Color brandPurple  = Color(0xFF9C27B0);
  static const Color brandBlue    = Color(0xFF2196F3);
  static const Color brandGold    = Color(0xFFFFD700);
  static const Color brandGreen   = Color(0xFF25D366);
  static const Color brandGifFrom = Color(0xFF6C63FF);
  static const Color brandGifTo   = Color(0xFFFF6584);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandOrange, brandPink, brandPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [brandPurple, brandBlue, brandCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [brandPink, brandPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData light() {
    const bg = Color(0xFFF8F9FA);
    const surface = Color(0xFFFFFFFF);
    const surfaceAlt = Color(0xFFF0F2F5);
    const border = Color(0xFFE5E7EB);
    const txtPri = Color(0xFF1A1A1A);
    const txtSec = Color(0xFF6B7280);
    const txtTer = Color(0xFF9CA3AF);
    const err = Color(0xFFEF4444);
    return _build(
      brightness: Brightness.light,
      bg: bg, surface: surface, surfaceAlt: surfaceAlt,
      border: border, txtPri: txtPri, txtSec: txtSec, txtTer: txtTer, err: err,
      cs: ColorScheme(
        brightness: Brightness.light,
        primary: brandPink, onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFE0EC), onPrimaryContainer: brandPink,
        secondary: brandOrange, onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFEDE6), onSecondaryContainer: brandOrange,
        tertiary: brandCyan, onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFE0F7FA), onTertiaryContainer: brandCyan,
        error: err, onError: Colors.white,
        errorContainer: Color(0xFFFFEDED), onErrorContainer: err,
        background: bg, onBackground: txtPri,
        surface: surface, onSurface: txtPri,
        surfaceVariant: surfaceAlt, onSurfaceVariant: txtSec,
        outline: border, outlineVariant: Color(0xFFF3F4F6),
        shadow: Color(0x14000000), scrim: Colors.black54,
        inverseSurface: Color(0xFF1A1A1A), onInverseSurface: Colors.white,
        inversePrimary: brandPink, surfaceTint: Colors.transparent,
      ),
    );
  }

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData dark() {
    const bg = Color(0xFF0A0E1A);
    const surface = Color(0xFF111827);
    const surfaceAlt = Color(0xFF1F2937);
    const border = Color(0xFF2D3748);
    const txtPri = Color(0xFFFFFFFF);
    const txtSec = Color(0xFFB0BAC4);
    const txtTer = Color(0xFF6B7280);
    const err = Color(0xFFEF5350);
    return _build(
      brightness: Brightness.dark,
      bg: bg, surface: surface, surfaceAlt: surfaceAlt,
      border: border, txtPri: txtPri, txtSec: txtSec, txtTer: txtTer, err: err,
      cs: ColorScheme(
        brightness: Brightness.dark,
        primary: brandPink, onPrimary: Colors.white,
        primaryContainer: Color(0xFF4A0020), onPrimaryContainer: Color(0xFFFFB3C6),
        secondary: brandOrange, onSecondary: Colors.white,
        secondaryContainer: Color(0xFF3D1500), onSecondaryContainer: Color(0xFFFFCCB3),
        tertiary: brandCyan, onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF003740), onTertiaryContainer: Color(0xFFB2EBF2),
        error: err, onError: Colors.white,
        errorContainer: Color(0xFF3D0000), onErrorContainer: Color(0xFFFFCDD2),
        background: bg, onBackground: txtPri,
        surface: surface, onSurface: txtPri,
        surfaceVariant: surfaceAlt, onSurfaceVariant: txtSec,
        outline: border, outlineVariant: Color(0xFF374151),
        shadow: Colors.black, scrim: Colors.black87,
        inverseSurface: Colors.white, onInverseSurface: bg,
        inversePrimary: brandPink, surfaceTint: Colors.transparent,
      ),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme cs,
    required Color bg, required Color surface, required Color surfaceAlt,
    required Color border, required Color txtPri, required Color txtSec,
    required Color txtTer, required Color err,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: txtPri,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: TextStyle(color: txtPri, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: txtPri),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brandPink,
        unselectedItemColor: txtTer,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
        elevation: 0, type: BottomNavigationBarType.fixed, showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceAlt : Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: brandPink, width: 2)),
        hintStyle: TextStyle(color: txtTer, fontSize: 14),
        labelStyle: TextStyle(color: txtSec),
      ),
      textTheme: TextTheme(
        displayLarge:  TextStyle(color: txtPri, fontSize: 57, fontWeight: FontWeight.w800, letterSpacing: -2),
        displayMedium: TextStyle(color: txtPri, fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -1.5),
        displaySmall:  TextStyle(color: txtPri, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineLarge: TextStyle(color: txtPri, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium:TextStyle(color: txtPri, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineSmall: TextStyle(color: txtPri, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: txtPri, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: txtPri, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall:    TextStyle(color: txtSec, fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(color: txtPri, fontSize: 16, height: 1.5),
        bodyMedium:    TextStyle(color: txtPri, fontSize: 14, height: 1.5),
        bodySmall:     TextStyle(color: txtSec, fontSize: 12, height: 1.4),
        labelLarge:    TextStyle(color: txtPri, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(color: txtSec, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall:    TextStyle(color: txtTer, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: brandPink,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: brandPink.withOpacity(isDark ? 0.2 : 0.12),
        labelStyle: TextStyle(color: txtPri, fontSize: 13),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected) ? brandPink : (isDark ? txtTer : Colors.white)),
        trackColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected) ? brandPink.withOpacity(0.4) : border),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brandPink, inactiveTrackColor: border,
        thumbColor: brandPink, overlayColor: brandPink.withOpacity(0.15), trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brandPink, linearTrackColor: border),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceAlt : Color(0xFF1A1A1A),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(color: txtPri, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: txtSec, fontSize: 14),
      ),
      iconTheme: IconThemeData(color: txtSec, size: 22),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandPink, foregroundColor: Colors.white, elevation: 4, shape: CircleBorder(),
      ),
    );
  }
}