import 'package:flutter/material.dart';

import '../accessibility/semantic_terminology.dart';
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
              child: ExcludeSemantics(
                child: Text(
                  product.imageEmoji,
                  style: TextStyle(fontSize: compact ? 24 : 34),
                ),
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

    final semanticsLabel = displayScore == null
        ? 'Kein ESG-Gesamtscore verfügbar'
        : 'ESG-Gesamtscore $displayScore von 10';
    final partialNote = score.partialNote;

    return Semantics(
      container: true,
      attributedLabel: ScanFairSemanticTerminology.annotate(
        '$semanticsLabel. ${score.verdictLabel}. '
        '${partialNote == null ? '' : '$partialNote '}'
        'Datenvollständigkeit ${(score.dataCompleteness * 100).round()} Prozent. '
        '${score.tagline}',
      ),
      child: ExcludeSemantics(
        child: Container(
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
                  borderRadius: BorderRadius.circular(
                    ScanFairTokens.radiusPill,
                  ),
                ),
              ),
              const SizedBox(height: ScanFairTokens.space4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: ScanFairTokens.space2,
                runSpacing: ScanFairTokens.space1,
                children: [
                  Text(
                    displayScore ?? '—',
                    style: ScanFairTypography.scoreNumber.copyWith(
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: ScanFairTokens.space2,
                    ),
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
                  if (score.isPartial)
                    const _Pill(label: 'Teilscore', color: ScanFairTokens.ink3),
                  _Pill(
                    label: 'Daten ${(score.dataCompleteness * 100).round()}%',
                    color: ScanFairTokens.ink3,
                  ),
                ],
              ),
              const SizedBox(height: ScanFairTokens.space3),
              if (score.partialNote != null) ...[
                Text(score.partialNote!, style: textTheme.bodyMedium),
                const SizedBox(height: ScanFairTokens.space1),
              ],
              Text(score.tagline, style: textTheme.bodyMedium),
            ],
          ),
        ),
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
              termId: SemanticTermId.environmental,
              shortLabel: 'E',
              pillar: score.environmental,
              color: ScanFairColors.pillarE,
            ),
            const Divider(height: ScanFairTokens.space5),
            _PillarBar(
              termId: SemanticTermId.social,
              shortLabel: 'S',
              pillar: score.social,
              color: ScanFairColors.pillarS,
            ),
            const Divider(height: ScanFairTokens.space5),
            _PillarBar(
              termId: SemanticTermId.governance,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nährwert-Hinweis', style: textTheme.titleMedium),
            const SizedBox(height: ScanFairTokens.space1),
            TerminologyText(
              'Fakten aus der angegebenen Produktdatenquelle · kein Score',
              style: ScanFairTypography.meta,
            ),
            const SizedBox(height: ScanFairTokens.space3),
            Text(product.nutritionSourceLabel, style: textTheme.titleSmall),
            const SizedBox(height: ScanFairTokens.space1),
            TerminologyText(product.nutritionFacts, style: textTheme.bodySmall),
            const SizedBox(height: ScanFairTokens.space3),
            TerminologyText(
              'Keine medizinische oder individuelle Ernährungsberatung.',
              style: ScanFairTypography.meta,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kennzeichnet Ergebnisse, die nicht aus einer erreichbaren Live-Quelle
/// stammen: veralteter Cache-Eintrag (ADR 0033) oder lokaler
/// Pilot-Fallback (Audit-Finding F-17). Rendert nichts, wenn die Daten
/// aktuell sind.
class DataFreshnessNotice extends StatelessWidget {
  const DataFreshnessNotice({required this.product, super.key});

  final ScanFairProduct product;

  @override
  Widget build(BuildContext context) {
    final String message;
    if (product.servedFromStaleCache) {
      message =
          'Live-Daten waren nicht erreichbar. Angezeigt wird der zuletzt '
          'gespeicherte Datenstand.';
    } else if (product.dataQualityWarnings.contains('pilot-source-fallback')) {
      message =
          'Die Produktdatenquelle war nicht erreichbar. Angezeigt werden '
          'lokal hinterlegte Basisdaten.';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: ScanFairTokens.space4),
      padding: const EdgeInsets.all(ScanFairTokens.space3),
      decoration: BoxDecoration(
        color: ScanFairTokens.warningBg,
        borderRadius: BorderRadius.circular(ScanFairTokens.radiusLg),
        border: Border.all(
          color: ScanFairTokens.warningFg.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, color: ScanFairTokens.warningFg),
          const SizedBox(width: ScanFairTokens.space3),
          Expanded(
            child: TerminologyText(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class MethodFootnote extends StatelessWidget {
  const MethodFootnote({required this.score, super.key});

  final ESGScore score;

  @override
  Widget build(BuildContext context) {
    return TerminologyText(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TerminologyText(
                              '${source.name}\n'
                              'Datenquellen-Lizenz: ${source.datasetLicense}\n'
                              '${source.contentLicense == null ? '' : 'Inhalte: ${source.contentLicense}\n'}'
                              '${source.imageLicense == null ? '' : 'Produktbilder: ${source.imageLicense}\n'}'
                              '${source.attribution}'
                              '${source.publicUseNotice == null ? '' : '\n${source.publicUseNotice}'}',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: ScanFairTokens.space1),
                            Text(
                              'Lizenz: ${source.databaseLicenseUrl}'
                              '${source.contentLicenseUrl == null ? '' : '\nInhaltslizenz: ${source.contentLicenseUrl}'}'
                              '${source.imageLicenseUrl == null ? '' : '\nBildlizenz: ${source.imageLicenseUrl}'}',
                              style: ScanFairTypography.meta,
                            ),
                          ],
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
    final productEntityId = 'gtin:${product.barcode}';
    final commodityOrigins = product
        .relationshipsOfType(ESGRelationshipType.commodityHasOrigin)
        .where(
          (relationship) =>
              relationship.contextEntity == null ||
              relationship.contextEntity!.id == productEntityId,
        )
        .toList(growable: false);
    final productOrigins = product
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
              label: 'Rohstoffherkunft',
              relationships: commodityOrigins,
              missingLabel: 'Keine Rohstoffherkunft belegt',
            ),
            if (productOrigins.isNotEmpty) ...[
              const Divider(height: ScanFairTokens.space4),
              _TraceabilityRow(
                icon: Icons.inventory_2_outlined,
                label: 'Allgemeine Produktherkunft',
                relationships: productOrigins,
                missingLabel: 'Keine Produktherkunft belegt',
              ),
            ],
            const Divider(height: ScanFairTokens.space4),
            _TraceabilityRow(
              icon: Icons.corporate_fare_outlined,
              label: 'Verantwortliches Unternehmen',
              relationships: legalEntities,
              missingLabel: 'Rechtsträger noch nicht aufgelöst',
            ),
            if (commodities.isNotEmpty ||
                commodityOrigins.isNotEmpty ||
                productOrigins.isNotEmpty) ...[
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
        .toSet()
        .join(', ');
    final eligibleRelationships = relationships
        .where((entry) => entry.scoreEligible)
        .toList(growable: false);

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
                  eligibleRelationships.isEmpty
                      ? 'Hinweis · noch nicht score-aktiv'
                      : _evidenceSummary(eligibleRelationships),
                  style: ScanFairTypography.meta,
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _evidenceSummary(List<ESGRelationship> relationships) {
    final assertionClasses = relationships
        .map((entry) => entry.assertionClass)
        .toSet();
    final confidences = relationships.map((entry) => entry.confidence).toSet();
    final sources = relationships.map((entry) => entry.source.name).toSet();
    final assertion = assertionClasses.length == 1
        ? _assertionLabel(assertionClasses.single)
        : 'mehrere Nachweisarten';
    final confidence = confidences.length == 1
        ? _confidenceLabel(confidences.single)
        : 'gemischte Sicherheit';
    final source = sources.length == 1 ? sources.single : 'mehrere Quellen';
    return 'belegt · $assertion · $confidence · $source';
  }

  static String _assertionLabel(ESGAssertionClass assertionClass) {
    return switch (assertionClass) {
      ESGAssertionClass.measured => 'Messwert',
      ESGAssertionClass.verified => 'verifiziert',
      ESGAssertionClass.declared => 'Herstellerangabe',
      ESGAssertionClass.modeled => 'modelliert',
      ESGAssertionClass.categoryAverage => 'Kategoriewert',
      ESGAssertionClass.communityReported => 'Community-Hinweis',
      ESGAssertionClass.inferred => 'abgeleitet',
      ESGAssertionClass.unknown => 'unklar',
    };
  }

  static String _confidenceLabel(ESGConfidence confidence) {
    return switch (confidence) {
      ESGConfidence.high => 'hohe Sicherheit',
      ESGConfidence.medium => 'mittlere Sicherheit',
      ESGConfidence.low => 'niedrige Sicherheit',
      ESGConfidence.unknown => 'Sicherheit unbekannt',
    };
  }
}

class FactorExpansionTile extends StatelessWidget {
  const FactorExpansionTile({required this.pillar, super.key});

  final PillarScore pillar;

  @override
  Widget build(BuildContext context) {
    final label = pillar.label;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: pillar.pillar == ScorePillar.environmental,
        title: TerminologyText(label),
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
            title: TerminologyText(factor.label),
            subtitle: TerminologyText('${factor.value} · ${factor.source}'),
          );
        }).toList(),
      ),
    );
  }
}

class _PillarBar extends StatelessWidget {
  const _PillarBar({
    required this.termId,
    required this.shortLabel,
    required this.pillar,
    required this.color,
  });

  final SemanticTermId termId;
  final String shortLabel;
  final PillarScore? pillar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = ScanFairSemanticTerminology.definition(termId).displayText;
    final value = pillar?.value;
    final progress = value == null ? 0.0 : value / 100;
    final textTheme = Theme.of(context).textTheme;

    final spokenValue = value == null
        ? 'Keine Daten'
        : '${(value / 10).toStringAsFixed(1)} von 10';

    return TerminologySemantics(
      container: true,
      label: label,
      value: spokenValue,
      child: Row(
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
                    Flexible(
                      child: Text(
                        value == null
                            ? 'Keine Daten'
                            : '${(value / 10).toStringAsFixed(1)}/10',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ScanFairTokens.space2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ScanFairTokens.radiusPill,
                  ),
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
      ),
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
