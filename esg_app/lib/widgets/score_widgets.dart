import 'package:flutter/material.dart';

import '../models/esg_relationship.dart';
import '../models/esg_score.dart';
import '../models/product.dart';
import '../theme/scanfair_colors.dart';
import '../theme/scanfair_tokens.dart';
import '../theme/scanfair_typography.dart';

class ProductSummaryCard extends StatelessWidget {
  const ProductSummaryCard({
    required this.product,
    this.compact = false,
    super.key,
  });

  final ScanFairProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          compact ? ScanFairTokens.space3 : ScanFairTokens.space4,
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 48 : 64,
              height: compact ? 48 : 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ScanFairTokens.green50,
                borderRadius: BorderRadius.circular(ScanFairTokens.radiusLg),
              ),
              child: Text(
                product.imageEmoji,
                style: TextStyle(fontSize: compact ? 24 : 34),
              ),
            ),
            const SizedBox(width: ScanFairTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.brand, style: ScanFairTypography.meta),
                  const SizedBox(height: ScanFairTokens.space1),
                  Text(
                    product.name,
                    style: textTheme.titleMedium,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: ScanFairTokens.space1),
                  Text(product.category, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreHero extends StatelessWidget {
  const ScoreHero({required this.score, super.key});

  final ESGScore score;

  @override
  Widget build(BuildContext context) {
    final color = _trafficColor(score.trafficLight);
    final textTheme = Theme.of(context).textTheme;
    final displayScore = score.total == null
        ? null
        : (score.total! / 10).toStringAsFixed(1);

    return Container(
      width: double.infinity,
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
          Container(
            width: 72,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
            ),
          ),
          const SizedBox(height: ScanFairTokens.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayScore ?? '—',
                style: ScanFairTypography.scoreNumber.copyWith(color: color),
              ),
              const SizedBox(width: ScanFairTokens.space2),
              Padding(
                padding: const EdgeInsets.only(bottom: ScanFairTokens.space2),
                child: Text('/10', style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: ScanFairTokens.space2),
          Wrap(
            spacing: ScanFairTokens.space2,
            runSpacing: ScanFairTokens.space2,
            children: [
              _Pill(label: score.verdictLabel, color: color),
              _Pill(
                label: 'Daten ${(score.dataCompleteness * 100).round()}%',
                color: ScanFairTokens.ink3,
              ),
            ],
          ),
          const SizedBox(height: ScanFairTokens.space3),
          Text(score.tagline, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class PillarBars extends StatelessWidget {
  const PillarBars({required this.score, super.key});

  final ESGScore score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Column(
          children: [
            _PillarBar(
              label: 'Environmental',
              shortLabel: 'E',
              pillar: score.environmental,
              color: ScanFairColors.pillarE,
            ),
            const Divider(height: ScanFairTokens.space5),
            _PillarBar(
              label: 'Social',
              shortLabel: 'S',
              pillar: score.social,
              color: ScanFairColors.pillarS,
            ),
            const Divider(height: ScanFairTokens.space5),
            _PillarBar(
              label: 'Governance',
              shortLabel: 'G',
              pillar: score.governance,
              color: ScanFairColors.pillarG,
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryInfoCard extends StatelessWidget {
  const SecondaryInfoCard({required this.product, super.key});

  final ScanFairProduct product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final position = (product.secondaryPosition / 10).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.secondaryTitle, style: textTheme.titleMedium),
            const SizedBox(height: ScanFairTokens.space1),
            Text(
              'Begleithinweis · kein ESG-Score',
              style: ScanFairTypography.meta,
            ),
            const SizedBox(height: ScanFairTokens.space3),
            ClipRRect(
              borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: position,
                backgroundColor: ScanFairTokens.bgAlt,
                color: ScanFairTokens.green500,
              ),
            ),
            const SizedBox(height: ScanFairTokens.space3),
            Text(product.secondaryLabel, style: textTheme.titleSmall),
            const SizedBox(height: ScanFairTokens.space1),
            Text(product.secondaryFacts, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class MethodFootnote extends StatelessWidget {
  const MethodFootnote({required this.score, super.key});

  final ESGScore score;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Daten: ${score.sources.join(', ')}. Formel ${ESGScore.formulaVersion}. '
      'Fehlende Daten werden nicht geschätzt. Orientierung, keine '
      'Zertifizierung.',
      style: ScanFairTypography.meta,
    );
  }
}

class DataProvenanceCard extends StatelessWidget {
  const DataProvenanceCard({required this.product, super.key});

  final ScanFairProduct product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sources = product.dataSources;
    final retrievedAt = product.latestRetrievedAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datenherkunft', style: textTheme.titleMedium),
            const SizedBox(height: ScanFairTokens.space2),
            if (sources.isEmpty)
              Text(
                'Lokale Demo-Daten · keine externe Abfrage',
                style: textTheme.bodySmall,
              )
            else
              ...sources.map(
                (source) => Padding(
                  padding: const EdgeInsets.only(bottom: ScanFairTokens.space2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.dataset_outlined, size: 20),
                      const SizedBox(width: ScanFairTokens.space2),
                      Expanded(
                        child: Text(
                          '${source.name} · ${source.datasetLicense}\n'
                          '${source.attribution}',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              '${product.evidence.length} Evidenzpunkte'
              '${retrievedAt == null ? '' : ' · Abruf ${_date(retrievedAt)}'}',
              style: ScanFairTypography.meta,
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }
}

class TraceabilityCard extends StatelessWidget {
  const TraceabilityCard({required this.product, super.key});

  final ScanFairProduct product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final commodities = product
        .relationshipsOfType(ESGRelationshipType.containsCommodity)
        .toList(growable: false);
    final origins = product
        .relationshipsOfType(ESGRelationshipType.hasProductOrigin)
        .toList(growable: false);
    final legalEntities = product
        .relationshipsOfType(ESGRelationshipType.responsibleLegalEntity)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zuordnungen', style: textTheme.titleMedium),
            const SizedBox(height: ScanFairTokens.space3),
            _TraceabilityRow(
              icon: Icons.grain_outlined,
              label: 'Rohstoffe',
              relationships: commodities,
              missingLabel: 'Nicht belastbar zugeordnet',
            ),
            const Divider(height: ScanFairTokens.space4),
            _TraceabilityRow(
              icon: Icons.public_outlined,
              label: 'Produktherkunft',
              relationships: origins,
              missingLabel: 'Keine Herkunft belegt',
            ),
            const Divider(height: ScanFairTokens.space4),
            _TraceabilityRow(
              icon: Icons.corporate_fare_outlined,
              label: 'Verantwortliches Unternehmen',
              relationships: legalEntities,
              missingLabel: 'Rechtsträger noch nicht aufgelöst',
            ),
            if (commodities.isNotEmpty || origins.isNotEmpty) ...[
              const SizedBox(height: ScanFairTokens.space3),
              Text(
                product.hasScoreEligibleCommodityOrigin
                    ? 'Rohstoff und Herkunft sind für kontextuelle '
                          'Risikodaten freigegeben.'
                    : 'Vorhandene Hinweise reichen noch nicht für eine '
                          'Rohstoff-Länder-Risikobewertung.',
                style: ScanFairTypography.meta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TraceabilityRow extends StatelessWidget {
  const _TraceabilityRow({
    required this.icon,
    required this.label,
    required this.relationships,
    required this.missingLabel,
  });

  final IconData icon;
  final String label;
  final List<ESGRelationship> relationships;
  final String missingLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final values = relationships
        .map((entry) => entry.to.displayName)
        .join(', ');
    final hasEligibleRelationship = relationships.any(
      (entry) => entry.scoreEligible,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: ScanFairTokens.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleSmall),
              const SizedBox(height: ScanFairTokens.space1),
              Text(
                relationships.isEmpty ? missingLabel : values,
                style: textTheme.bodySmall,
              ),
              if (relationships.isNotEmpty)
                Text(
                  hasEligibleRelationship
                      ? 'belegt'
                      : 'Hinweis · noch nicht score-aktiv',
                  style: ScanFairTypography.meta,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class FactorExpansionTile extends StatelessWidget {
  const FactorExpansionTile({required this.pillar, super.key});

  final PillarScore pillar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: pillar.pillar == ScorePillar.environmental,
        title: Text(pillar.label),
        subtitle: Text('${(pillar.value / 10).toStringAsFixed(1)} / 10'),
        children: pillar.factors.map((factor) {
          return ListTile(
            dense: true,
            leading: Icon(
              factor.available
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: factor.available
                  ? ScanFairTokens.green500
                  : ScanFairTokens.warningFg,
            ),
            title: Text(factor.label),
            subtitle: Text('${factor.value} · ${factor.source}'),
          );
        }).toList(),
      ),
    );
  }
}

class _PillarBar extends StatelessWidget {
  const _PillarBar({
    required this.label,
    required this.shortLabel,
    required this.pillar,
    required this.color,
  });

  final String label;
  final String shortLabel;
  final PillarScore? pillar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = pillar?.value;
    final progress = value == null ? 0.0 : value / 100;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(ScanFairTokens.radiusMd),
          ),
          child: Text(
            shortLabel,
            style: textTheme.titleSmall?.copyWith(color: color),
          ),
        ),
        const SizedBox(width: ScanFairTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: textTheme.titleSmall)),
                  Text(
                    value == null
                        ? 'Keine Daten'
                        : '${(value / 10).toStringAsFixed(1)}/10',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: ScanFairTokens.space2),
              ClipRRect(
                borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: ScanFairTokens.bgAlt,
                  color: value == null ? ScanFairTokens.ink3 : color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ScanFairTokens.space3,
        vertical: ScanFairTokens.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusPill),
      ),
      child: Text(label, style: ScanFairTypography.pill.copyWith(color: color)),
    );
  }
}

Color _trafficColor(TrafficLight light) {
  switch (light) {
    case TrafficLight.green:
      return ScanFairTokens.trafficGreen;
    case TrafficLight.yellow:
      return ScanFairTokens.trafficYellow;
    case TrafficLight.red:
      return ScanFairTokens.trafficRed;
    case TrafficLight.grey:
      return ScanFairTokens.ink3;
  }
}
