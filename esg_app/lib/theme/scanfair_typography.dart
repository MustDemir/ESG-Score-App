// =============================================================================
// ScanFair Typography
// =============================================================================
// Inter (UI) + Instrument Serif (Display) via google_fonts.
// Mapping der CSS-Type-Klassen (.sf-display, .sf-h1, ...) auf Material TextTheme.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scanfair_tokens.dart';

abstract final class ScanFairTypography {
  ScanFairTypography._();

  /// Inter — primaere UI-Schrift.
  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? ScanFairTokens.ink1,
    );
  }

  /// Instrument Serif — Display-Schrift fuer Hero-Texte.
  static TextStyle _display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.instrumentSerif(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? ScanFairTokens.ink1,
    );
  }

  /// Material 3 TextTheme — Mapping unserer Tokens auf Standard-Slots.
  static TextTheme get textTheme => TextTheme(
    // ---- Display Slots: Instrument Serif ----
    displayLarge: _display(
      fontSize: ScanFairTokens.fsDisplay, // 48
      height: ScanFairTokens.lhTight,
      letterSpacing: -0.96, // -0.02em * 48
    ),
    displayMedium: _display(
      fontSize: ScanFairTokens.fs3xl, // 34
      height: ScanFairTokens.lhTight,
      letterSpacing: -0.68,
    ),
    displaySmall: _display(
      fontSize: ScanFairTokens.fs2xl, // 28
      height: ScanFairTokens.lhSnug,
    ),

    // ---- Headline Slots: Inter Bold/Semibold ----
    headlineLarge: _sans(
      fontSize: ScanFairTokens.fs3xl, // 34
      fontWeight: FontWeight.w700,
      height: ScanFairTokens.lhTight,
      letterSpacing: -0.34, // -0.01em
    ),
    headlineMedium: _sans(
      fontSize: ScanFairTokens.fs2xl, // 28
      fontWeight: FontWeight.w700,
      height: ScanFairTokens.lhSnug,
    ),
    headlineSmall: _sans(
      fontSize: ScanFairTokens.fsXl, // 24
      fontWeight: FontWeight.w600,
      height: ScanFairTokens.lhSnug,
    ),

    // ---- Title Slots ----
    titleLarge: _sans(
      fontSize: ScanFairTokens.fsLg, // 20
      fontWeight: FontWeight.w600,
      height: ScanFairTokens.lhSnug,
    ),
    titleMedium: _sans(
      fontSize: ScanFairTokens.fsMd, // 17
      fontWeight: FontWeight.w600,
      height: ScanFairTokens.lhBase,
    ),
    titleSmall: _sans(
      fontSize: ScanFairTokens.fsBase, // 15
      fontWeight: FontWeight.w600,
      height: ScanFairTokens.lhBase,
    ),

    // ---- Body Slots ----
    bodyLarge: _sans(
      fontSize: ScanFairTokens.fsMd, // 17
      fontWeight: FontWeight.w400,
      height: ScanFairTokens.lhBase,
      color: ScanFairTokens.ink1,
    ),
    bodyMedium: _sans(
      fontSize: ScanFairTokens.fsBase, // 15
      fontWeight: FontWeight.w400,
      height: ScanFairTokens.lhBase,
      color: ScanFairTokens.ink2,
    ),
    bodySmall: _sans(
      fontSize: ScanFairTokens.fsSm, // 13
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: ScanFairTokens.ink3,
    ),

    // ---- Label Slots: Inter Buttons / Pills ----
    labelLarge: _sans(
      fontSize: ScanFairTokens.fsMd, // 17
      fontWeight: FontWeight.w600,
      height: 1,
    ),
    labelMedium: _sans(
      fontSize: ScanFairTokens.fsSm, // 13
      fontWeight: FontWeight.w600,
      height: 1,
    ),
    labelSmall: _sans(
      fontSize: ScanFairTokens.fsXs, // 11
      fontWeight: FontWeight.w700,
      letterSpacing: 0.88, // 0.08em * 11
      height: 1,
    ),
  );

  // ---------------------------------------------------------------------------
  // ScanFair-spezifische Custom-Styles (nicht in Material 3 TextTheme abbildbar)
  // Zugriff via ScanFairTypography.eyebrow, .scoreNumber, etc.
  // ---------------------------------------------------------------------------

  /// Eyebrow — kleine Uppercase-Labels ueber Headlines.
  static TextStyle get eyebrow => _sans(
    fontSize: ScanFairTokens.fsXs,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.88,
    height: 1,
    color: ScanFairTokens.green500,
  );

  /// Display-Italic — fuer „accent" Wort in Hero-Headlines.
  static TextStyle get displayItalic => _display(
    fontSize: ScanFairTokens.fsDisplay,
    fontStyle: FontStyle.italic,
    height: ScanFairTokens.lhTight,
  );

  /// Score-Number — sehr grosse Zahl im Result-Hero.
  static TextStyle get scoreNumber => _sans(
    fontSize: ScanFairTokens.fsScore, // 72
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -2.16, // -0.03em * 72
    color: ScanFairTokens.ink1,
  );

  /// Meta — kleiner muted Text (Quellen-Footnote etc.).
  static TextStyle get meta => _sans(
    fontSize: ScanFairTokens.fsSm,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ScanFairTokens.ink3,
  );

  /// Pill — kleine Tags / Badges.
  static TextStyle get pill => _sans(
    fontSize: ScanFairTokens.fsXs,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.22, // 0.02em * 11
    height: 1,
  );
}
