import 'package:flutter/material.dart';

import '../accessibility/semantic_terminology.dart';
import '../models/esg_score.dart';
import '../models/product.dart';
import '../theme/scanfair_tokens.dart';
import '../theme/scanfair_typography.dart';
import '../widgets/score_widgets.dart';

class LowDataScreen extends StatelessWidget {
  const LowDataScreen({required this.product, required this.score, super.key});

  final ScanFairProduct product;
  final ESGScore score;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Datengrundlage')),
      body: ListView(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        children: [
          ProductSummaryCard(product: product),
          const SizedBox(height: ScanFairTokens.space4),
          DataFreshnessNotice(product: product),
          Semantics(
            container: true,
            attributedLabel: ScanFairSemanticTerminology.annotate(
              'Datengrundlage zu dünn. Wir geben hier keinen Score. '
              'Der Eco-Score fehlt oder ist als unbekannt markiert. '
              'Vorhandene Signale bleiben sichtbar und werden nicht geschätzt.',
            ),
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(ScanFairTokens.space5),
                decoration: BoxDecoration(
                  color: ScanFairTokens.warningBg,
                  borderRadius: BorderRadius.circular(ScanFairTokens.radiusXl),
                  border: Border.all(
                    color: ScanFairTokens.warningFg.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datengrundlage zu dünn',
                      style: ScanFairTypography.eyebrow,
                    ),
                    const SizedBox(height: ScanFairTokens.space3),
                    Text(
                      'Wir geben hier keinen Score.',
                      style: textTheme.displaySmall,
                    ),
                    const SizedBox(height: ScanFairTokens.space3),
                    Text(
                      'Der Eco-Score fehlt oder ist als unbekannt markiert. '
                      'Vorhandene Signale bleiben sichtbar, werden aber nicht geschätzt.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ScanFairTokens.space4),
          PillarBars(score: score),
          const SizedBox(height: ScanFairTokens.space4),
          SecondaryInfoCard(product: product),
          const SizedBox(height: ScanFairTokens.space4),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Zurück'),
          ),
          const SizedBox(height: ScanFairTokens.space5),
          MethodFootnote(score: score),
        ],
      ),
    );
  }
}
