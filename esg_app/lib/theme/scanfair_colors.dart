// =============================================================================
// ScanFair ColorScheme
// =============================================================================
// Mapping der Brand-Tokens auf Material 3 ColorScheme.
// MVP: nur Light-Theme. Dark-Theme als TODO geparkt.
// =============================================================================

import 'package:flutter/material.dart';
import 'scanfair_tokens.dart';

abstract final class ScanFairColors {
  ScanFairColors._();

  /// Light ColorScheme — Material 3 konform mit ScanFair-Tokens.
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    // Primary — Forest Green
    primary: ScanFairTokens.green500,
    onPrimary: ScanFairTokens.inkOnGreen,
    primaryContainer: ScanFairTokens.green100,
    onPrimaryContainer: ScanFairTokens.green900,

    // Secondary — Teal-Akzent
    secondary: ScanFairTokens.teal500,
    onSecondary: ScanFairTokens.inkOnGreen,
    secondaryContainer: Color(0xFFCFFAFE),
    onSecondaryContainer: Color(0xFF134E4A),

    // Tertiary — Clay/Terracotta (S-Pillar-Farbe)
    tertiary: ScanFairTokens.clay,
    onTertiary: ScanFairTokens.inkOnGreen,
    tertiaryContainer: Color(0xFFFDE6DC),
    onTertiaryContainer: Color(0xFF5C2F1F),

    // Error — Danger
    error: ScanFairTokens.dangerFg,
    onError: Colors.white,
    errorContainer: ScanFairTokens.dangerBg,
    onErrorContainer: ScanFairTokens.dangerFg,

    // Surface — warmes Off-White
    surface: ScanFairTokens.bg,
    onSurface: ScanFairTokens.ink1,
    surfaceContainerHighest: ScanFairTokens.bgAlt,
    surfaceContainerHigh: ScanFairTokens.bgCard,
    surfaceContainer: ScanFairTokens.bg,
    surfaceContainerLow: ScanFairTokens.bgCard,
    surfaceContainerLowest: ScanFairTokens.bgCard,
    onSurfaceVariant: ScanFairTokens.ink2,
    surfaceTint: ScanFairTokens.green500,

    // Outline / Border
    outline: ScanFairTokens.border,
    outlineVariant: ScanFairTokens.borderSoft,

    // Inverse (fuer Snackbar / Dark-Accents auf Light-Background)
    inverseSurface: ScanFairTokens.bgDeep,
    onInverseSurface: ScanFairTokens.inkOnDark,
    inversePrimary: ScanFairTokens.green200,

    // Scrim / Shadow
    shadow: Color(0xFF1A2622),
    scrim: Color(0xCC1A2622),
  );

  /// ESG-Score-Ampel-Farben — semantische Zuordnung.
  /// Schwellwerte aus ADR 0011 (ESG-Score-Formel).
  static Color forScoreValue(double score) {
    if (score >= 70) return ScanFairTokens.trafficGreen;
    if (score >= 40) return ScanFairTokens.trafficYellow;
    return ScanFairTokens.trafficRed;
  }

  /// Per-Pillar-Farbe fuer E/S/G-Bars.
  static const Color pillarE = ScanFairTokens.scoreE;
  static const Color pillarS = ScanFairTokens.scoreS;
  static const Color pillarG = ScanFairTokens.scoreG;
}
