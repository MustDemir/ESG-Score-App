// =============================================================================
// ScanFair Theme — komplettes ThemeData fuer MaterialApp
// =============================================================================
// Verwendung in main.dart:
//   MaterialApp(theme: ScanFairTheme.light, ...)
// =============================================================================

import 'package:flutter/material.dart';
import 'scanfair_colors.dart';
import 'scanfair_tokens.dart';
import 'scanfair_typography.dart';

abstract final class ScanFairTheme {
  ScanFairTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ScanFairColors.light,
    scaffoldBackgroundColor: ScanFairTokens.bg,
    textTheme: ScanFairTypography.textTheme,
    fontFamily: ScanFairTypography.textTheme.bodyMedium?.fontFamily,

    // ---- AppBar ----
    appBarTheme: AppBarTheme(
      backgroundColor: ScanFairTokens.bg,
      foregroundColor: ScanFairTokens.ink1,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: ScanFairTypography.textTheme.titleLarge?.copyWith(
        color: ScanFairTokens.ink1,
      ),
    ),

    // ---- Cards ----
    cardTheme: CardThemeData(
      color: ScanFairTokens.bgCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusLg),
        side: const BorderSide(color: ScanFairTokens.border),
      ),
    ),

    // ---- Buttons ----
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ScanFairTokens.green500,
        foregroundColor: ScanFairTokens.inkOnGreen,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: ScanFairTokens.space5,
          vertical: ScanFairTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
        ),
        textStyle: ScanFairTypography.textTheme.labelLarge,
        minimumSize: const Size(0, 48),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ScanFairTokens.ink1,
        side: const BorderSide(color: ScanFairTokens.borderStrong),
        padding: const EdgeInsets.symmetric(
          horizontal: ScanFairTokens.space5,
          vertical: ScanFairTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
        ),
        textStyle: ScanFairTypography.textTheme.labelLarge,
        minimumSize: const Size(0, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ScanFairTokens.green500,
        textStyle: ScanFairTypography.textTheme.labelLarge,
      ),
    ),

    // ---- Input Fields ----
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ScanFairTokens.bgCard,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ScanFairTokens.space4,
        vertical: ScanFairTokens.space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusMd),
        borderSide: const BorderSide(color: ScanFairTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusMd),
        borderSide: const BorderSide(color: ScanFairTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusMd),
        borderSide: const BorderSide(color: ScanFairTokens.green500, width: 2),
      ),
      labelStyle: ScanFairTypography.textTheme.bodyMedium,
      hintStyle: ScanFairTypography.textTheme.bodyMedium?.copyWith(
        color: ScanFairTokens.ink3,
      ),
    ),

    // ---- Dividers ----
    dividerTheme: const DividerThemeData(
      color: ScanFairTokens.borderSoft,
      thickness: 1,
      space: 1,
    ),

    // ---- Chips / Pills ----
    chipTheme: ChipThemeData(
      backgroundColor: ScanFairTokens.bgAlt,
      labelStyle: ScanFairTypography.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: ScanFairTokens.space3,
        vertical: ScanFairTokens.space2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
        side: const BorderSide(color: ScanFairTokens.border),
      ),
    ),

    // ---- Page Transitions / Splash ----
    splashFactory: InkRipple.splashFactory,
  );
}
