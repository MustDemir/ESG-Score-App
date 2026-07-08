import 'package:flutter/material.dart';

import '../models/esg_score.dart';
import '../models/product.dart';
import '../theme/scanfair_tokens.dart';
import '../widgets/score_widgets.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({required this.product, required this.score, super.key});

  final ScanFairProduct product;
  final ESGScore score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details & Quellen')),
      body: ListView(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        children: [
          ProductSummaryCard(product: product, compact: true),
          const SizedBox(height: ScanFairTokens.space4),
          ...score.availablePillars.map(
            (pillar) => Padding(
              padding: const EdgeInsets.only(bottom: ScanFairTokens.space3),
              child: FactorExpansionTile(pillar: pillar),
            ),
          ),
          const SizedBox(height: ScanFairTokens.space2),
          SecondaryInfoCard(product: product),
          const SizedBox(height: ScanFairTokens.space5),
          MethodFootnote(score: score),
        ],
      ),
    );
  }
}
