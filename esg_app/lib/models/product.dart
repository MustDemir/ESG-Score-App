import 'esg_evidence.dart';
import 'esg_relationship.dart';

enum ProductType { food, clothing, cosmetics }

class ScanFairProduct {
  const ScanFairProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageEmoji,
    required this.productType,
    this.ecoscoreGrade,
    this.ecoscoreScore,
    this.co2Total,
    this.ingredientsText,
    this.nutritionSourceLabel = 'Produktdatenquelle',
    this.nutritionFacts = 'Keine belastbaren Nährwertangaben verfügbar.',
    this.packagingTags = const [],
    this.originTags = const [],
    this.labelsTags = const [],
    this.dataQualityTags = const [],
    this.dataQualityWarnings = const [],
    this.evidence = const [],
    this.relationships = const [],
  });

  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String imageEmoji;
  final ProductType productType;
  final String? ecoscoreGrade;
  final double? ecoscoreScore;
  final double? co2Total;
  final String? ingredientsText;
  final String nutritionSourceLabel;
  final String nutritionFacts;
  final List<String> packagingTags;
  final List<String> originTags;
  final List<String> labelsTags;
  final List<String> dataQualityTags;
  final List<String> dataQualityWarnings;
  final List<ESGEvidence> evidence;
  final List<ESGRelationship> relationships;

  /// Kennzeichnung fuer Daten, die aus einem veralteten Cache-Eintrag
  /// stammen, weil die Live-Quelle nicht erreichbar war (ADR 0033).
  static const staleCacheWarning = 'stale-cache';

  bool get servedFromStaleCache =>
      dataQualityWarnings.contains(staleCacheWarning);

  /// Liefert eine Kopie mit einer zusaetzlichen Datenqualitaets-Warnung.
  ScanFairProduct withDataQualityWarning(String warning) {
    if (dataQualityWarnings.contains(warning)) return this;
    return ScanFairProduct(
      barcode: barcode,
      name: name,
      brand: brand,
      category: category,
      imageEmoji: imageEmoji,
      productType: productType,
      ecoscoreGrade: ecoscoreGrade,
      ecoscoreScore: ecoscoreScore,
      co2Total: co2Total,
      ingredientsText: ingredientsText,
      nutritionSourceLabel: nutritionSourceLabel,
      nutritionFacts: nutritionFacts,
      packagingTags: packagingTags,
      originTags: originTags,
      labelsTags: labelsTags,
      dataQualityTags: dataQualityTags,
      dataQualityWarnings: [...dataQualityWarnings, warning],
      evidence: evidence,
      relationships: relationships,
    );
  }

  bool get hasEnvironmentalSignal =>
      ecoscoreScore != null ||
      (ecoscoreGrade != null && ecoscoreGrade!.trim().isNotEmpty);

  // Eine blosse Zutatenliste oder ein Markenname sind keine wertbare
  // Social-/Governance-Evidenz (ADR 0034).
  bool get hasSocialSignal => labelsTags.isNotEmpty || originTags.isNotEmpty;

  bool get hasGovernanceSignal =>
      dataQualityTags.isNotEmpty || dataQualityWarnings.isNotEmpty;

  bool get hasKnownBrand {
    final normalized = brand.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'unbekannte marke';
  }

  Iterable<ESGEvidence> evidenceFor(String metric) {
    return evidence.where((entry) => entry.metric == metric);
  }

  Iterable<ESGRelationship> relationshipsOfType(ESGRelationshipType type) {
    return relationships.where((entry) => entry.type == type);
  }

  bool get hasScoreEligibleCommodityOrigin {
    final productEntityId = 'gtin:$barcode';
    final eligibleCommodityIds = relationships
        .where(
          (entry) =>
              entry.type == ESGRelationshipType.containsCommodity &&
              entry.scoreEligible,
        )
        .map((entry) => entry.to.id)
        .toSet();
    return relationships.any(
      (entry) =>
          entry.supportsContextualRiskFor(productEntityId) &&
          eligibleCommodityIds.contains(entry.from.id),
    );
  }

  bool get hasScoreEligibleLegalEntity => relationships.any(
    (entry) =>
        entry.type == ESGRelationshipType.responsibleLegalEntity &&
        entry.scoreEligible,
  );

  List<ESGDataSource> get dataSources {
    final sourcesById = <String, ESGDataSource>{};
    for (final entry in evidence) {
      sourcesById[entry.source.id] = entry.source;
    }
    return sourcesById.values.toList(growable: false);
  }

  DateTime? get latestRetrievedAt {
    if (evidence.isEmpty) return null;
    return evidence
        .map((entry) => entry.retrievedAt)
        .reduce((latest, next) => next.isAfter(latest) ? next : latest);
  }
}
