import '../models/esg_evidence.dart';
import '../models/esg_relationship.dart';
import '../models/product.dart';

class CoffeePilotOrigin {
  const CoffeePilotOrigin({required this.countryCode, required this.nameDe});

  final String countryCode;
  final String nameDe;
}

class CoffeePilotDefinition {
  const CoffeePilotDefinition({
    required this.barcode,
    required this.articleNumber,
    required this.name,
    required this.origins,
  });

  final String barcode;
  final String articleNumber;
  final String name;
  final List<CoffeePilotOrigin> origins;
}

const coffeePilotDefinitions = <CoffeePilotDefinition>[
  CoffeePilotDefinition(
    barcode: '4013320225196',
    articleNumber: '4430901',
    name: 'Bio Café Kolumbien PUR, gemahlen',
    origins: [CoffeePilotOrigin(countryCode: 'CO', nameDe: 'Kolumbien')],
  ),
  CoffeePilotDefinition(
    barcode: '4013320114865',
    articleNumber: '1860901',
    name: 'Bio Café Maliba, gemahlen',
    origins: [CoffeePilotOrigin(countryCode: 'UG', nameDe: 'Uganda')],
  ),
  CoffeePilotDefinition(
    barcode: '4013320110539',
    articleNumber: '8900907',
    name: 'Bio Café Sereno, gemahlen',
    origins: [
      CoffeePilotOrigin(countryCode: 'GT', nameDe: 'Guatemala'),
      CoffeePilotOrigin(countryCode: 'NI', nameDe: 'Nicaragua'),
    ],
  ),
];

class CoffeePilotCatalog {
  const CoffeePilotCatalog();

  static const version = 'coffee-pilot-1.0';
  static const sourceRecordUrl =
      'https://wug.gepa-shop.de/media/wysiwyg/pdf/'
      'Preisliste_04_2025_web.pdf';
  static const sourceRecordSha256 =
      '74cc6607847090f5fb923f89b5a07e5542ec81a334ac9eef73876a4b28e6b150';
  static final _retrievedAt = DateTime.utc(2026, 8, 10, 14, 54, 3);
  static final _observedAt = DateTime.utc(2025, 4, 1);

  Set<String> get knownBarcodes => Set.unmodifiable(
    coffeePilotDefinitions.map((definition) => definition.barcode),
  );

  CoffeePilotDefinition? definitionFor(String barcode) {
    final normalized = barcode.trim();
    for (final definition in coffeePilotDefinitions) {
      if (definition.barcode == normalized) return definition;
    }
    return null;
  }

  ScanFairProduct? enrichOrCreate({
    required String barcode,
    ScanFairProduct? sourceProduct,
  }) {
    final definition = definitionFor(barcode);
    if (definition == null) return sourceProduct;

    final pilotEvidence = _evidenceFor(definition);
    final pilotRelationships = _relationshipsFor(definition);
    final product = sourceProduct ?? _fallbackProduct(definition);
    final pilotEvidenceIds = pilotEvidence.map((entry) => entry.id).toSet();
    final pilotRelationshipIds = pilotRelationships
        .map((entry) => entry.id)
        .toSet();

    return ScanFairProduct(
      barcode: product.barcode,
      name: product.name == 'Unbenanntes Produkt'
          ? definition.name
          : product.name,
      brand: product.hasKnownBrand ? product.brand : 'GEPA',
      category: product.category == 'Lebensmittel'
          ? 'Kaffee'
          : product.category,
      imageEmoji: product.imageEmoji,
      productType: product.productType,
      ecoscoreGrade: product.ecoscoreGrade,
      ecoscoreScore: product.ecoscoreScore,
      co2Total: product.co2Total,
      ingredientsText: product.ingredientsText,
      secondaryTitle: product.secondaryTitle,
      secondaryLabel: product.secondaryLabel,
      secondaryFacts: product.secondaryFacts,
      secondaryPosition: product.secondaryPosition,
      packagingTags: product.packagingTags,
      originTags: product.originTags,
      labelsTags: product.labelsTags,
      dataQualityTags: product.dataQualityTags,
      dataQualityWarnings: product.dataQualityWarnings,
      evidence: [
        ...product.evidence.where(
          (entry) => !pilotEvidenceIds.contains(entry.id),
        ),
        ...pilotEvidence,
      ],
      relationships: [
        ...product.relationships.where(
          (entry) => !pilotRelationshipIds.contains(entry.id),
        ),
        ...pilotRelationships,
      ],
    );
  }

  static ScanFairProduct _fallbackProduct(CoffeePilotDefinition definition) {
    return ScanFairProduct(
      barcode: definition.barcode,
      name: definition.name,
      brand: 'GEPA',
      category: 'Kaffee',
      imageEmoji: '☕',
      productType: ProductType.food,
      ecoscoreGrade: 'unknown',
      dataQualityWarnings: const [
        'missing-environmental-score',
        'pilot-source-fallback',
      ],
      secondaryFacts: 'Keine belastbaren Gesundheitsdaten im Pilotdatensatz.',
    );
  }

  static List<ESGEvidence> _evidenceFor(CoffeePilotDefinition definition) {
    final sourceRecordId = _sourceRecordId(definition);
    return [
      ESGEvidence(
        id: _commodityEvidenceId(definition),
        source: ESGDataSource.gepaProductDeclarations,
        sourceRecordId: sourceRecordId,
        sourceRecordUrl: sourceRecordUrl,
        sourceField: 'Bezeichnung und Produktbeschreibung',
        metric: 'commodity_coffee',
        value: 'coffee',
        pillars: const [EvidencePillar.environmental, EvidencePillar.social],
        scope: EvidenceScope.product,
        quality: EvidenceQuality.official,
        retrievedAt: _retrievedAt,
        observedAt: _observedAt,
        sourceSchemaVersion: sourceRecordSha256,
      ),
      for (final origin in definition.origins)
        ESGEvidence(
          id: _originEvidenceId(definition, origin),
          source: ESGDataSource.gepaProductDeclarations,
          sourceRecordId: sourceRecordId,
          sourceRecordUrl: sourceRecordUrl,
          sourceField: 'Ursprung',
          metric: 'commodity_origin',
          value: origin.countryCode,
          pillars: const [EvidencePillar.environmental, EvidencePillar.social],
          scope: EvidenceScope.product,
          quality: EvidenceQuality.official,
          retrievedAt: _retrievedAt,
          observedAt: _observedAt,
          sourceSchemaVersion: sourceRecordSha256,
        ),
    ];
  }

  static List<ESGRelationship> _relationshipsFor(
    CoffeePilotDefinition definition,
  ) {
    final product = ESGEntity(
      id: 'gtin:${definition.barcode}',
      type: ESGEntityType.product,
      displayName: definition.name,
      identifiers: [
        ESGEntityIdentifier(
          scheme: 'gtin',
          value: definition.barcode,
          issuer: 'GS1',
        ),
      ],
    );
    const commodity = ESGEntity(
      id: 'commodity:coffee',
      type: ESGEntityType.commodity,
      displayName: 'Kaffee',
      identifiers: [
        ESGEntityIdentifier(
          scheme: 'scanfair_commodity',
          value: 'coffee',
          issuer: 'ScanFair',
        ),
      ],
    );
    final sourceRecordId = _sourceRecordId(definition);

    return [
      ESGRelationship(
        id: 'gepa:${definition.barcode}:contains-coffee',
        from: product,
        to: commodity,
        type: ESGRelationshipType.containsCommodity,
        assertionClass: ESGAssertionClass.declared,
        confidence: ESGConfidence.medium,
        source: ESGDataSource.gepaProductDeclarations,
        sourceRecordId: sourceRecordId,
        evidenceIds: [_commodityEvidenceId(definition)],
        scoreEligible: true,
        contextEntity: product,
        retrievedAt: _retrievedAt,
        observedAt: _observedAt,
      ),
      for (final origin in definition.origins)
        ESGRelationship(
          id:
              'gepa:${definition.barcode}:coffee-origin-'
              '${origin.countryCode.toLowerCase()}',
          from: commodity,
          to: ESGEntity(
            id: 'country:${origin.countryCode}',
            type: ESGEntityType.country,
            displayName: origin.nameDe,
            identifiers: [
              ESGEntityIdentifier(
                scheme: 'iso_3166_1_alpha_2',
                value: origin.countryCode,
                issuer: 'ISO',
              ),
            ],
          ),
          type: ESGRelationshipType.commodityHasOrigin,
          assertionClass: ESGAssertionClass.declared,
          confidence: ESGConfidence.medium,
          source: ESGDataSource.gepaProductDeclarations,
          sourceRecordId: sourceRecordId,
          evidenceIds: [_originEvidenceId(definition, origin)],
          scoreEligible: true,
          contextEntity: product,
          retrievedAt: _retrievedAt,
          observedAt: _observedAt,
        ),
    ];
  }

  static String _sourceRecordId(CoffeePilotDefinition definition) {
    return 'price-list-2025-04:${definition.articleNumber}';
  }

  static String _commodityEvidenceId(CoffeePilotDefinition definition) {
    return 'gepa:${definition.barcode}:commodity-coffee';
  }

  static String _originEvidenceId(
    CoffeePilotDefinition definition,
    CoffeePilotOrigin origin,
  ) {
    return 'gepa:${definition.barcode}:commodity-origin-'
        '${origin.countryCode.toLowerCase()}';
  }
}
