enum EvidencePillar { environmental, social, governance }

enum EvidenceScope { product, category, company, country }

enum EvidenceQuality {
  official,
  audited,
  sourceCalculated,
  communityProvided,
  scanFairHeuristic,
}

class ESGDataSource {
  const ESGDataSource({
    required this.id,
    required this.name,
    required this.datasetLicense,
    required this.attribution,
    required this.sourceUrl,
    required this.termsUrl,
    this.apiVersion,
  });

  static const openFoodFacts = ESGDataSource(
    id: 'open-food-facts',
    name: 'Open Food Facts',
    datasetLicense: 'ODbL-1.0',
    attribution: 'Open Food Facts contributors',
    sourceUrl: 'https://world.openfoodfacts.org',
    termsUrl: 'https://world.openfoodfacts.org/terms-of-use',
    apiVersion: 'v3',
  );

  static const agribalyse = ESGDataSource(
    id: 'agribalyse',
    name: 'AGRIBALYSE',
    datasetLicense: 'Etalab-2.0',
    attribution: 'Source ADEME, AGRIBALYSE v3.2',
    sourceUrl:
        'https://entrepot.recherche.data.gouv.fr/dataset.xhtml'
        '?persistentId=doi:10.57745/XTENSJ',
    termsUrl:
        'https://doc.agribalyse.fr/documentation/utiliser-agribalyse/'
        'precautions-et-conditions-dusage',
    apiVersion: '3.2',
  );

  static const gepaProductDeclarations = ESGDataSource(
    id: 'gepa-product-declarations',
    name: 'GEPA Produktangaben',
    datasetLicense: 'Proprietary-publication',
    attribution: 'GEPA - The Fair Trade Company',
    sourceUrl: 'https://www.gepa-shop.de',
    termsUrl: 'https://www.gepa-shop.de/agb',
    apiVersion: 'price-list-2025-04',
  );

  static const localDemo = ESGDataSource(
    id: 'local-demo',
    name: 'Lokale Demo-Daten',
    datasetLicense: 'Project-internal',
    attribution: 'ScanFair development fixtures',
    sourceUrl: 'https://github.com/MustDemir/ESG-Score-App',
    termsUrl: 'https://github.com/MustDemir/ESG-Score-App',
  );

  final String id;
  final String name;
  final String datasetLicense;
  final String attribution;
  final String sourceUrl;
  final String termsUrl;
  final String? apiVersion;
}

class ESGEvidence {
  const ESGEvidence({
    required this.id,
    required this.source,
    required this.sourceRecordId,
    required this.sourceRecordUrl,
    required this.sourceField,
    required this.metric,
    required this.value,
    required this.pillars,
    required this.scope,
    required this.quality,
    required this.retrievedAt,
    this.numericValue,
    this.unit,
    this.observedAt,
    this.sourceSchemaVersion,
    this.retrievedVia,
  });

  final String id;
  final ESGDataSource source;
  final String sourceRecordId;
  final String sourceRecordUrl;
  final String sourceField;
  final String metric;
  final String value;
  final double? numericValue;
  final String? unit;
  final List<EvidencePillar> pillars;
  final EvidenceScope scope;
  final EvidenceQuality quality;
  final DateTime retrievedAt;
  final DateTime? observedAt;
  final String? sourceSchemaVersion;
  final ESGDataSource? retrievedVia;

  bool supports(EvidencePillar pillar) => pillars.contains(pillar);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'source_id': source.id,
      'source_record_id': sourceRecordId,
      'source_record_url': sourceRecordUrl,
      'source_field': sourceField,
      'metric': metric,
      'value_text': value,
      'numeric_value': numericValue,
      'unit': unit,
      'pillars': pillars.map((pillar) => pillar.name).toList(),
      'scope': scope.name,
      'quality': _qualityWireName(quality),
      'retrieved_at': retrievedAt.toUtc().toIso8601String(),
      'observed_at': observedAt?.toUtc().toIso8601String(),
      'source_schema_version': sourceSchemaVersion,
      'retrieved_via_source_id': retrievedVia?.id,
    };
  }

  static String _qualityWireName(EvidenceQuality quality) {
    return switch (quality) {
      EvidenceQuality.official => 'official',
      EvidenceQuality.audited => 'audited',
      EvidenceQuality.sourceCalculated => 'source_calculated',
      EvidenceQuality.communityProvided => 'community_provided',
      EvidenceQuality.scanFairHeuristic => 'scanfair_heuristic',
    };
  }
}
