// =============================================================================
// ScanFair — App-Einstiegspunkt
// =============================================================================
// Phase 1 MVP: noch keine echten Screens — Theme-Smoke-Screen zeigt dass
// Theme korrekt geladen ist und Fonts/Farben/Spacings funktionieren.
//
// Naechste Steps (siehe implementation-plan.yaml):
//   S13: Datenmodelle (Freezed)
//   S14: OFF-Service + ESGScoreCalculator
//   S15: S3 Result-Screen
//   S16: S1 Scanner + S2 Loading + S4 Alternativen
// =============================================================================

import 'package:flutter/material.dart';
import 'theme/scanfair_colors.dart';
import 'theme/scanfair_theme.dart';
import 'theme/scanfair_tokens.dart';
import 'theme/scanfair_typography.dart';

void main() {
  runApp(const ScanFairApp());
}

class ScanFairApp extends StatelessWidget {
  const ScanFairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanFair',
      debugShowCheckedModeBanner: false,
      theme: ScanFairTheme.light,
      home: const ThemeSmokeScreen(),
    );
  }
}

/// Smoke-Screen — zeigt visuelle Theme-Bausteine fuer manuellen Sichtcheck.
/// Wird in Sprint 1 durch echte Screens (Scanner/Result) ersetzt.
class ThemeSmokeScreen extends StatelessWidget {
  const ThemeSmokeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('ScanFair — Theme Smoke')),
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eyebrow', style: ScanFairTypography.eyebrow),
            const SizedBox(height: ScanFairTokens.space2),
            Text('Display Heading', style: textTheme.displayMedium),
            const SizedBox(height: ScanFairTokens.space2),
            Text('Headline Medium', style: textTheme.headlineMedium),
            const SizedBox(height: ScanFairTokens.space2),
            Text(
              'Body Large — Inter Regular, fuer laengere Texte.',
              style: textTheme.bodyLarge,
            ),
            Text(
              'Body Medium — Inter Regular, fuer Secondary-Text.',
              style: textTheme.bodyMedium,
            ),
            Text('Meta-Footnote', style: ScanFairTypography.meta),
            const SizedBox(height: ScanFairTokens.space5),

            // ESG-Pillar-Demo
            Text('ESG-Pillar-Farben', style: textTheme.titleLarge),
            const SizedBox(height: ScanFairTokens.space3),
            const Row(
              children: [
                _ColorChip(label: 'E', color: ScanFairColors.pillarE),
                SizedBox(width: ScanFairTokens.space2),
                _ColorChip(label: 'S', color: ScanFairColors.pillarS),
                SizedBox(width: ScanFairTokens.space2),
                _ColorChip(label: 'G', color: ScanFairColors.pillarG),
              ],
            ),
            const SizedBox(height: ScanFairTokens.space5),

            // Score-Hero-Demo
            Text('Score-Hero (Mock)', style: textTheme.titleLarge),
            const SizedBox(height: ScanFairTokens.space3),
            Container(
              padding: const EdgeInsets.all(ScanFairTokens.space5),
              decoration: BoxDecoration(
                color: ScanFairTokens.bgCard,
                borderRadius: BorderRadius.circular(ScanFairTokens.radiusXl),
                border: Border.all(color: ScanFairTokens.border),
                boxShadow: ScanFairTokens.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GEPA Bio Kaffee', style: textTheme.titleMedium),
                  const SizedBox(height: ScanFairTokens.space1),
                  Text('Beispiel-Produkt', style: ScanFairTypography.meta),
                  const SizedBox(height: ScanFairTokens.space3),
                  Text(
                    '82',
                    style: ScanFairTypography.scoreNumber.copyWith(
                      color: ScanFairColors.forScoreValue(82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ScanFairTokens.space5),

            // Buttons-Demo
            Text('Buttons', style: textTheme.titleLarge),
            const SizedBox(height: ScanFairTokens.space3),
            Wrap(
              spacing: ScanFairTokens.space2,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Primary')),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Secondary'),
                ),
                TextButton(onPressed: () {}, child: const Text('Tertiary')),
              ],
            ),
            const SizedBox(height: ScanFairTokens.space8),
            Text('Powered by Open Food Facts', style: ScanFairTypography.meta),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusMd),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: ScanFairTypography.textTheme.titleLarge?.copyWith(
          color: ScanFairTokens.inkOnGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
