// =============================================================================
// ScanFair Design Tokens
// =============================================================================
// 1:1-Abbildung von design_handoff_scanfair/tokens.css.
// Bei Token-Aenderung: dort zuerst aendern, dann hier nachpflegen.
//
// Referenz: ADR 0001 (Flutter Frontend), feature/results/state.yaml
// =============================================================================

import 'package:flutter/material.dart';

/// Raw-Tokens als typsichere Konstanten.
/// Niemand sollte diese Klasse direkt in Widgets verwenden — nutze stattdessen
/// `Theme.of(context).colorScheme` oder `Theme.of(context).textTheme`.
/// Diese Klasse ist die Single Source of Truth fuer Token-Werte.
abstract final class ScanFairTokens {
  ScanFairTokens._();

  // ---------------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------------
  static const Color bg = Color(0xFFFBFAF6);
  static const Color bgAlt = Color(0xFFF4F2EB);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgDeep = Color(0xFF0E1B17);

  // ---------------------------------------------------------------------------
  // Foreground / Text
  // ---------------------------------------------------------------------------
  static const Color ink1 = Color(0xFF1A2622);
  static const Color ink2 = Color(0xFF4A5650);
  static const Color ink3 = Color(0xFF66716B);
  static const Color inkOnDark = Color(0xFFFBFAF6);
  static const Color inkOnGreen = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Borders
  // ---------------------------------------------------------------------------
  static const Color border = Color(0xFFE5E2D8);
  static const Color borderSoft = Color(0xFFEFEDE5);
  static const Color borderStrong = Color(0xFFC7C3B6);

  // ---------------------------------------------------------------------------
  // Brand / Primary — Forest Green
  // ---------------------------------------------------------------------------
  static const Color green50 = Color(0xFFE8F2EE);
  static const Color green100 = Color(0xFFC5DFD3);
  static const Color green200 = Color(0xFF8FC2A8);
  static const Color green400 = Color(0xFF3D9B76);
  static const Color green500 = Color(0xFF0F7B5C); // ⭐ PRIMARY
  static const Color green600 = Color(0xFF0A6248);
  static const Color green700 = Color(0xFF074A36);
  static const Color green900 = Color(0xFF042A1E);

  // ---------------------------------------------------------------------------
  // Secondary Accents
  // ---------------------------------------------------------------------------
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color amber500 = Color(0xFFD97706);
  static const Color clay = Color(0xFFC97B5C);

  // ---------------------------------------------------------------------------
  // E/S/G Pillar Colors (aus Hausarbeit)
  // ---------------------------------------------------------------------------
  static const Color scoreE = Color(0xFF0F7B5C); // E = Forest Green
  static const Color scoreS = Color(0xFFC97B5C); // S = Clay/Terracotta
  static const Color scoreG = Color(0xFF4F46E5); // G = Indigo

  // ---------------------------------------------------------------------------
  // Ampel-Score Colors — 0-10 mapped zu green/yellow/red
  // siehe ADR 0011 (ESG-Score-Formel) fuer Schwellwerte
  // ---------------------------------------------------------------------------
  static const Color trafficGreen = Color(0xFF0F7B5C); // 7.0-10
  static const Color trafficYellow = Color(0xFFA64B08); // 4.0-6.9
  static const Color trafficRed = Color(0xFFC2410C); // 0-3.9   · "Vermeiden"

  // ---------------------------------------------------------------------------
  // Status Colors
  // ---------------------------------------------------------------------------
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successFg = Color(0xFF15803D);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningFg = Color(0xFFB45309);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerFg = Color(0xFF991B1B);
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color infoFg = Color(0xFF1E40AF);

  // ---------------------------------------------------------------------------
  // Shadows — subtil, warm
  // ---------------------------------------------------------------------------
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color.fromRGBO(26, 38, 34, 0.04),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color.fromRGBO(26, 38, 34, 0.06),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color.fromRGBO(26, 38, 34, 0.08),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color.fromRGBO(26, 38, 34, 0.10),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color.fromRGBO(26, 38, 34, 0.14),
      offset: Offset(0, 24),
      blurRadius: 48,
    ),
  ];

  static const List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: Color.fromRGBO(15, 123, 92, 0.20),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Radii
  // ---------------------------------------------------------------------------
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 28;
  static const double radiusPill = 999;

  // ---------------------------------------------------------------------------
  // Spacing — 1rem = 16px Annahme (Flutter Default)
  // ---------------------------------------------------------------------------
  static const double space1 = 4; // 0.25rem
  static const double space2 = 8; // 0.5rem
  static const double space3 = 12; // 0.75rem
  static const double space4 = 16; // 1rem
  static const double space5 = 24; // 1.5rem
  static const double space6 = 32; // 2rem
  static const double space7 = 40; // 2.5rem
  static const double space8 = 64; // 4rem

  // ---------------------------------------------------------------------------
  // Font Sizes — kalibriert fuer 390px iPhone-Frame
  // ---------------------------------------------------------------------------
  static const double fsXs = 11; // caption
  static const double fsSm = 13; // footnote
  static const double fsBase = 15; // body
  static const double fsMd = 17; // callout / button
  static const double fsLg = 20; // title 3
  static const double fsXl = 24; // title 2
  static const double fs2xl = 28; // title 1
  static const double fs3xl = 34; // large title
  static const double fsDisplay = 48; // hero-display
  static const double fsScore = 72; // score-number

  // ---------------------------------------------------------------------------
  // Line Heights
  // ---------------------------------------------------------------------------
  static const double lhTight = 1.1;
  static const double lhSnug = 1.25;
  static const double lhBase = 1.45;
  static const double lhLoose = 1.6;

  // ---------------------------------------------------------------------------
  // Letter Spacing
  // ---------------------------------------------------------------------------
  static const double trackingEyebrow = 0.08; // em (in CSS 0.08em)
  static const double trackingDisplay = -0.02; // em

  // ---------------------------------------------------------------------------
  // Motion — Durations & Easing
  // ---------------------------------------------------------------------------
  static const Duration durFast = Duration(milliseconds: 200);
  static const Duration durBase = Duration(milliseconds: 300);
  static const Duration durSlow = Duration(milliseconds: 450);

  static const Curve ease = Cubic(0.4, 0, 0.2, 1);
  static const Curve easeBounce = Cubic(0.175, 0.885, 0.32, 1.275);

  // ---------------------------------------------------------------------------
  // Gradients — als Helper, da Flutter LinearGradient nicht const sein kann
  // ---------------------------------------------------------------------------
  static LinearGradient gradHero = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F7B5C), Color(0xFF074A36)],
  );

  static LinearGradient gradWarm = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBFAF6), Color(0xFFF4F2EB)],
  );
}
