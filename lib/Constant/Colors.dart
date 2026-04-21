// colors.dart
// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND — invariant (same in light & dark)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryPink   = Color(0xFFE91E63);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryBlue   = Color(0xFF2196F3);
  static const Color primaryCyan   = Color(0xFF00BCD4);

  // ─────────────────────────────────────────────────────────────────────────
  // GRADIENTS — invariant
  // ─────────────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryPink, primaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // STATIC LIGHT-MODE VALUES  (identical to your original — zero breaking changes)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color backgroundColor    = Color(0xFFF8F9FA);
  static const Color cardBackground     = Color(0xFFFFFFFF);
  static const Color darkBackground     = Color(0xFF1A1A1A);
  static const Color darkCardBackground = Color(0xFF2D2D2D);

  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor   = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor    = Color(0xFF3B82F6);

  static const Color borderLight  = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color borderDark   = Color(0xFF9CA3AF);

  static const Color shadowLight  = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowDark   = Color(0x1F000000);

  static const Color glassBackground      = Color(0x1AFFFFFF);
  static const Color glassBorder          = Color(0x33FFFFFF);
  static const Color glassBackgroundwhite = Colors.white;

  // ─────────────────────────────────────────────────────────────────────────
  // DARK-MODE STATIC VALUES
  // ─────────────────────────────────────────────────────────────────────────
  static const Color darkBg           = Color(0xFF0A0E1A);
  static const Color darkSurface      = Color(0xFF111827);
  static const Color darkSurfaceAlt   = Color(0xFF1F2937);
  static const Color darkBorderColor  = Color(0xFF2D3748);
  static const Color darkBorderBright = Color(0xFF374151);
  static const Color darkTextPrimary  = Color(0xFFFFFFFF);
  static const Color darkTextSec      = Color(0xFFB0BAC4);
  static const Color darkTextTer      = Color(0xFF6B7280);

  // ─────────────────────────────────────────────────────────────────────────
  // CONTEXT-AWARE HELPERS
  // Use these in widgets so they auto-flip between light & dark.
  // ─────────────────────────────────────────────────────────────────────────

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkBg : backgroundColor;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : cardBackground;

  static Color surfaceAlt(BuildContext context) =>
      isDark(context) ? darkSurfaceAlt : const Color(0xFFF0F2F5);

  static Color txtPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color txtSecondary(BuildContext context) =>
      isDark(context) ? darkTextSec : textSecondary;

  static Color txtTertiary(BuildContext context) =>
      isDark(context) ? darkTextTer : textTertiary;

  static Color adaptiveBorder(BuildContext context) =>
      isDark(context) ? darkBorderColor : borderLight;

  static Color adaptiveShadow(BuildContext context) =>
      isDark(context) ? Colors.black.withOpacity(0.4) : shadowMedium;

  // ─────────────────────────────────────────────────────────────────────────
  // ADAPTIVE DECORATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Standard card box decoration
  static BoxDecoration cardDecoration(
      BuildContext context, {
        double radius = 16,
        bool elevated = false,
        Color? overrideColor,
      }) {
    final dark = isDark(context);
    return BoxDecoration(
      color: overrideColor ?? surface(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: dark ? darkBorderColor : borderLight,
        width: 1,
      ),
      boxShadow: elevated
          ? [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(0.35)
              : Colors.black.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ]
          : null,
    );
  }

  /// Gradient-tinted card (feature cards, banners)
  static BoxDecoration gradientCardDecoration(
      BuildContext context, {
        required List<Color> colors,
        double radius = 16,
        double lightOpacity = 0.10,
        double darkOpacity = 0.16,
      }) {
    final dark = isDark(context);
    final op = dark ? darkOpacity : lightOpacity;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.map((c) => c.withOpacity(op)).toList(),
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: colors.first.withOpacity(dark ? 0.28 : 0.18),
        width: 1.2,
      ),
    );
  }

  /// AppBar / header — always brand gradient
  static BoxDecoration appBarDecoration() => const BoxDecoration(
    gradient: primaryGradient,
    boxShadow: [
      BoxShadow(color: shadowMedium, blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  /// Glass-morphism panel
  static BoxDecoration glassDecoration(
      BuildContext context, {
        double radius = 20,
      }) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark
          ? Colors.white.withOpacity(0.07)
          : Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: dark
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.6),
        width: 1,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHIMMER
  // ─────────────────────────────────────────────────────────────────────────
  static Color shimmerBase(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F2937) : const Color(0xFFE9EDF1);

  static Color shimmerHighlight(BuildContext context) =>
      isDark(context) ? const Color(0xFF374151) : const Color(0xFFF8F9FA);
}