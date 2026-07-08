import 'package:flutter/material.dart';

import '../models/esg_score.dart';
import '../models/product.dart';
import '../theme/scanfair_tokens.dart';
import '../widgets/score_widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    required this.product,
    required this.score,
    required this.onOpenDetails,
    this.alternative,
    super.key,
  });

  final ScanFairProduct product;
  final ESGScore score;
  final ScanFairProduct? alternative;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ergebnis')),
      body: ListView(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        children: [
          ProductSummaryCard(product: product),
          const SizedBox(height: ScanFairTokens.space4),
          ScoreHero(score: score),
          const SizedBox(height: ScanFairTokens.space4),
          PillarBars(score: score),
          const SizedBox(height: ScanFairTokens.space4),
          SecondaryInfoCard(product: product),
          const SizedBox(height: ScanFairTokens.space4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: ScanFairTokens.space2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  label: const Text('Erneut'),
                ),
              ),
            ],
          ),
          if (alternative != null) ...[
            const SizedBox(height: ScanFairTokens.space5),
            Text(
              'Bessere Alternative',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ScanFairTokens.space3),
            ProductSummaryCard(product: alternative!, compact: true),
          ],
          const SizedBox(height: ScanFairTokens.space5),
          MethodFootnote(score: score),
        ],
      ),
    );
  }
}
