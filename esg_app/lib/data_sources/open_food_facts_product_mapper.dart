import '../models/esg_evidence.dart';
import '../models/esg_relationship.dart';
import '../models/product.dart';

class OpenFoodFactsProductMapper {
  const OpenFoodFactsProductMapper();

  ScanFairProduct map(
    Map<String, Object?> json, {
    required String barcode,
    required DateTime retrievedAt,
  }) {
    final nestedProduct = json['product'];
    final product = nestedProduct is Map
        ? Map<String, Object?>.from(nestedProduct)
        : json;
    final observedAt = _timestamp(
      product['last_updated_t'] ?? product['last_modified_t'],
    );
    final schemaVersion = _nullableString(product['schema_version']);
    final environmentalGradeField =
        product.containsKey('environmental_score_grade')
        ? 'environmental_score_grade'
        : 'ecoscore_grade';
    final environmentalScoreField =
        product.containsKey('environmental_score_score')
        ? 'environmental_score_score'
        : 'ecoscore_score';
    final environmentalDataField =
        product.containsKey('environmental_score_data')
        ? 'environmental_score_data.agribalyse.co2_total'
        : 'ecoscore_data.agribalyse.co2_total';

    final environmentalGrade = _nullableString(
      product['environmental_score_grade'] ?? product['ecoscore_grade'],
    );
    final environmentalScore = _double(
      product['environmental_score_score'] ?? product['ecoscore_score'],
    );
    final agribalyseData = _mapFromPaths(product, const [
      ['environmental_score_data', 'agribalyse'],
      ['ecoscore_data', 'agribalyse'],
    ]);
    final co2Total = _double(agribalyseData?['co2_total']);
    final agribalyseCode = _nullableString(
      agribalyseData?['code'] ?? agribalyseData?['agribalyse_proxy_food_code'],
    );
    final agribalyseVersion = _nullableString(agribalyseData?['version']);
    final agribalyseDqr = _double(agribalyseData?['dqr']);
    final hasValidatedAgribalyseMapping =
        agribalyseVersion == '3.2' &&
        agribalyseCode != null &&
        RegExp(r'^\d+$').hasMatch(agribalyseCode);
    final packagingTags = _stringList(product['packaging_tags']);
    final originTags = _stringList(product['origins_tags']);
    final labelsTags = _stringList(product['labels_tags']);
    final structuredIngredients = _mapList(product['ingredients']);
    final dataQualityTags = _stringList(product['data_quality_tags']);
    final dataQualityWarnings = _stringList(
      product['data_quality_warnings_tags'],
    );
    final ingredientsText = _nullableString(product['ingredients_text']);
    final brand = _string(product['brands'], fallback: 'Unbekannte Marke');
    final evidence = <ESGEvidence>[];

    void addEvidence({
      required String metric,
      required String sourceField,
      required String value,
      required List<EvidencePillar> pillars,
      required EvidenceQuality quality,
      double? numericValue,
      String? unit,
      ESGDataSource source = ESGDataSource.openFoodFacts,
      String? sourceRecordId,
      String? sourceRecordUrl,
      EvidenceScope scope = EvidenceScope.product,
      String? evidenceSchemaVersion,
      ESGDataSource? retrievedVia,
      bool includeProductObservedAt = true,
    }) {
      evidence.add(
        ESGEvidence(
          id: '${source.id}:${sourceRecordId ?? barcode}:$metric',
          source: source,
          sourceRecordId: sourceRecordId ?? barcode,
          sourceRecordUrl:
              sourceRecordUrl ??
              'https://world.openfoodfacts.org/product/$barcode',
          sourceField: sourceField,
          metric: metric,
          value: value,
          numericValue: numericValue,
          unit: unit,
          pillars: pillars,
          scope: scope,
          quality: quality,
          retrievedAt: retrievedAt.toUtc(),
          observedAt: includeProductObservedAt ? observedAt : null,
          sourceSchemaVersion: evidenceSchemaVersion ?? schemaVersion,
          retrievedVia: retrievedVia,
        ),
      );
    }

    if (environmentalScore != null) {
      addEvidence(
        metric: 'environmental_score',
        sourceField: environmentalScoreField,
        value: environmentalScore.toString(),
        numericValue: environmentalScore,
        unit: 'score_0_100',
        pillars: const [EvidencePillar.environmental],
        quality: EvidenceQuality.sourceCalculated,
      );
    } else if (environmentalGrade != null) {
      addEvidence(
        metric: 'environmental_score',
        sourceField: environmentalGradeField,
        value: environmentalGrade,
        pillars: const [EvidencePillar.environmental],
        quality: EvidenceQuality.sourceCalculated,
      );
    }
    if (co2Total != null) {
      if (hasValidatedAgribalyseMapping) {
        final recordUrl =
            'https://agribalyse.ademe.fr/app/aliments/$agribalyseCode';
        addEvidence(
          metric: 'ghg_intensity',
          sourceField: 'Changement climatique',
          value: co2Total.toString(),
          numericValue: co2Total,
          unit: 'kg_co2e_per_kg',
          pillars: const [EvidencePillar.environmental],
          quality: EvidenceQuality.official,
          source: ESGDataSource.agribalyse,
          sourceRecordId: agribalyseCode,
          sourceRecordUrl: recordUrl,
          scope: EvidenceScope.category,
          evidenceSchemaVersion: agribalyseVersion,
          retrievedVia: ESGDataSource.openFoodFacts,
          includeProductObservedAt: false,
        );
        if (agribalyseDqr != null) {
          addEvidence(
            metric: 'source_quality_dqr',
            sourceField: 'DQR',
            value: agribalyseDqr.toString(),
            numericValue: agribalyseDqr,
            unit: 'score_1_5_lower_is_better',
            pillars: const [EvidencePillar.environmental],
            quality: EvidenceQuality.official,
            source: ESGDataSource.agribalyse,
            sourceRecordId: agribalyseCode,
            sourceRecordUrl: recordUrl,
            scope: EvidenceScope.category,
            evidenceSchemaVersion: agribalyseVersion,
            retrievedVia: ESGDataSource.openFoodFacts,
            includeProductObservedAt: false,
          );
        }
      } else {
        addEvidence(
          metric: 'co2_total',
          sourceField: environmentalDataField,
          value: co2Total.toString(),
          numericValue: co2Total,
          unit: 'kg_co2e_per_kg',
          pillars: const [EvidencePillar.environmental],
          quality: EvidenceQuality.sourceCalculated,
        );
      }
    }
    if (packagingTags.isNotEmpty) {
      addEvidence(
        metric: 'packaging',
        sourceField: 'packaging_tags',
        value: packagingTags.join(', '),
        pillars: const [EvidencePillar.environmental],
        quality: EvidenceQuality.communityProvided,
      );
    }
    if (originTags.isNotEmpty) {
      addEvidence(
        metric: 'origin',
        sourceField: 'origins_tags',
        value: originTags.join(', '),
        pillars: const [EvidencePillar.environmental, EvidencePillar.social],
        quality: EvidenceQuality.communityProvided,
      );
    }
    if (labelsTags.isNotEmpty) {
      addEvidence(
        metric: 'labels',
        sourceField: 'labels_tags',
        value: labelsTags.join(', '),
        pillars: const [EvidencePillar.environmental, EvidencePillar.social],
        quality: EvidenceQuality.communityProvided,
      );
    }
    if (ingredientsText != null) {
      addEvidence(
        metric: 'ingredients',
        sourceField: 'ingredients_text',
        value: ingredientsText,
        pillars: const [EvidencePillar.social, EvidencePillar.governance],
        quality: EvidenceQuality.communityProvided,
      );
    }
    final commodityAssertions = _commodityAssertions(
      structuredIngredients: structuredIngredients,
      ingredientsText: ingredientsText,
    );
    for (final entry in commodityAssertions.entries) {
      addEvidence(
        metric: 'commodity_${entry.key}',
        sourceField: entry.value == ESGAssertionClass.communityReported
            ? 'ingredients[].id'
            : 'ingredients_text',
        value: entry.key,
        pillars: const [EvidencePillar.environmental, EvidencePillar.social],
        quality: entry.value == ESGAssertionClass.communityReported
            ? EvidenceQuality.communityProvided
            : EvidenceQuality.scanFairHeuristic,
      );
    }
    if (brand != 'Unbekannte Marke') {
      addEvidence(
        metric: 'brand',
        sourceField: 'brands',
        value: brand,
        pillars: const [EvidencePillar.governance],
        quality: EvidenceQuality.communityProvided,
      );
    }
    if (dataQualityTags.isNotEmpty) {
      addEvidence(
        metric: 'data_quality',
        sourceField: 'data_quality_tags',
        value: dataQualityTags.join(', '),
        pillars: const [EvidencePillar.governance],
        quality: EvidenceQuality.sourceCalculated,
      );
    }
    if (dataQualityWarnings.isNotEmpty) {
      addEvidence(
        metric: 'data_quality_warnings',
        sourceField: 'data_quality_warnings_tags',
        value: dataQualityWarnings.join(', '),
        pillars: const [EvidencePillar.governance],
        quality: EvidenceQuality.sourceCalculated,
      );
    }

    final productEntity = ESGEntity(
      id: 'gtin:$barcode',
      type: ESGEntityType.product,
      displayName: _string(
        product['product_name'],
        fallback: 'Unbenanntes Produkt',
      ),
      identifiers: [
        ESGEntityIdentifier(scheme: 'gtin', value: barcode, issuer: 'GS1'),
      ],
    );
    final relationships = <ESGRelationship>[];

    void addRelationship({
      required ESGEntity to,
      required ESGRelationshipType type,
      required ESGAssertionClass assertionClass,
      required ESGConfidence confidence,
      required List<String> evidenceIds,
    }) {
      relationships.add(
        ESGRelationship(
          id: 'open-food-facts:$barcode:${type.name}:${to.id}',
          from: productEntity,
          to: to,
          type: type,
          assertionClass: assertionClass,
          confidence: confidence,
          source: ESGDataSource.openFoodFacts,
          sourceRecordId: barcode,
          evidenceIds: evidenceIds,
          scoreEligible: false,
          retrievedAt: retrievedAt.toUtc(),
          observedAt: observedAt,
        ),
      );
    }

    if (brand != 'Unbekannte Marke') {
      addRelationship(
        to: ESGEntity(
          id: 'brand:${_slug(brand)}',
          type: ESGEntityType.brand,
          displayName: brand,
          identifiers: [
            ESGEntityIdentifier(scheme: 'brand_name', value: brand),
          ],
        ),
        type: ESGRelationshipType.marketedByBrand,
        assertionClass: ESGAssertionClass.communityReported,
        confidence: ESGConfidence.low,
        evidenceIds: _evidenceIds(evidence, 'brand'),
      );
    }

    for (final originTag in originTags) {
      final countryCode = _countryCode(originTag);
      final normalizedOrigin = _displayTag(originTag);
      addRelationship(
        to: ESGEntity(
          id: countryCode == null
              ? 'location:${_slug(normalizedOrigin)}'
              : 'country:$countryCode',
          type: countryCode == null
              ? ESGEntityType.location
              : ESGEntityType.country,
          displayName: normalizedOrigin,
          identifiers: [
            ESGEntityIdentifier(
              scheme: countryCode == null
                  ? 'open_food_facts_tag'
                  : 'iso_3166_1_alpha_2',
              value: countryCode ?? originTag,
              issuer: countryCode == null ? 'Open Food Facts' : 'ISO',
            ),
          ],
        ),
        type: ESGRelationshipType.hasProductOrigin,
        assertionClass: ESGAssertionClass.communityReported,
        confidence: ESGConfidence.low,
        evidenceIds: _evidenceIds(evidence, 'origin'),
      );
    }

    for (final entry in commodityAssertions.entries) {
      addRelationship(
        to: ESGEntity(
          id: 'commodity:${entry.key}',
          type: ESGEntityType.commodity,
          displayName: _commodityDisplayName(entry.key),
          identifiers: [
            ESGEntityIdentifier(scheme: 'scanfair_commodity', value: entry.key),
          ],
        ),
        type: ESGRelationshipType.containsCommodity,
        assertionClass: entry.value,
        confidence: ESGConfidence.low,
        evidenceIds: _evidenceIds(evidence, 'commodity_${entry.key}'),
      );
    }

    return ScanFairProduct(
      barcode: barcode,
      name: _string(product['product_name'], fallback: 'Unbenanntes Produkt'),
      brand: brand,
      category: _firstTag(product['categories_tags']) ?? 'Lebensmittel',
      imageEmoji: '□',
      productType: ProductType.food,
      ecoscoreGrade: environmentalGrade,
      ecoscoreScore: environmentalScore,
      co2Total: co2Total,
      ingredientsText: ingredientsText,
      packagingTags: packagingTags,
      originTags: originTags,
      labelsTags: labelsTags,
      dataQualityTags: dataQualityTags,
      dataQualityWarnings: dataQualityWarnings,
      evidence: evidence,
      relationships: relationships,
    );
  }

  static String _string(Object? value, {required String fallback}) {
    final parsed = _nullableString(value);
    return parsed == null || parsed.isEmpty ? fallback : parsed;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((entry) => entry.toString().toLowerCase()).toList();
    }
    final text = _nullableString(value);
    if (text == null) return const [];
    return text
        .split(',')
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static String? _firstTag(Object? value) {
    final tags = _stringList(value);
    if (tags.isEmpty) return null;
    return tags.first.replaceAll('en:', '').replaceAll('-', ' ');
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, Object?>? _mapFromPaths(
    Map<String, Object?> map,
    List<List<String>> paths,
  ) {
    for (final path in paths) {
      Object? current = map;
      for (final segment in path) {
        if (current is! Map) {
          current = null;
          break;
        }
        current = current[segment];
      }
      if (current is Map) return Map<String, Object?>.from(current);
    }
    return null;
  }

  static List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, Object?>.from(entry))
        .toList(growable: false);
  }

  static Map<String, ESGAssertionClass> _commodityAssertions({
    required List<Map<String, Object?>> structuredIngredients,
    required String? ingredientsText,
  }) {
    final assertions = <String, ESGAssertionClass>{};
    for (final ingredient in structuredIngredients) {
      final searchable = [
        ingredient['id'],
        ingredient['text'],
      ].whereType<Object>().join(' ').toLowerCase();
      final commodity = _commodityFor(searchable);
      if (commodity != null) {
        assertions[commodity] = ESGAssertionClass.communityReported;
      }
    }

    final normalizedText = ingredientsText?.toLowerCase();
    if (normalizedText != null) {
      for (final commodity in _commodityTerms.keys) {
        if (assertions.containsKey(commodity)) continue;
        if (_commodityTerms[commodity]!.any(normalizedText.contains)) {
          assertions[commodity] = ESGAssertionClass.inferred;
        }
      }
    }
    return assertions;
  }

  static String? _commodityFor(String text) {
    for (final entry in _commodityTerms.entries) {
      if (entry.value.any(text.contains)) return entry.key;
    }
    return null;
  }

  static String _commodityDisplayName(String commodity) {
    return switch (commodity) {
      'coffee' => 'Kaffee',
      'cocoa' => 'Kakao',
      'banana' => 'Banane',
      _ => commodity,
    };
  }

  static List<String> _evidenceIds(List<ESGEvidence> evidence, String metric) {
    return evidence
        .where((entry) => entry.metric == metric)
        .map((entry) => entry.id)
        .toList(growable: false);
  }

  static String _displayTag(String tag) {
    final normalized = tag.replaceFirst(RegExp(r'^[a-z]{2}:'), '');
    return normalized
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String? _countryCode(String tag) {
    final normalized = tag.toLowerCase().replaceFirst(
      RegExp(r'^[a-z]{2}:'),
      '',
    );
    return _countryCodes[normalized];
  }

  static DateTime? _timestamp(Object? value) {
    final seconds = _double(value);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000).round(),
      isUtc: true,
    );
  }

  static const _commodityTerms = <String, List<String>>{
    'coffee': ['en:coffee', 'coffee', 'kaffee', 'café', 'cafe'],
    'cocoa': ['en:cocoa', 'cocoa', 'kakao', 'cacao'],
    'banana': ['en:banana', 'banana', 'banane'],
  };

  static const _countryCodes = <String, String>{
    'austria': 'AT',
    'belgium': 'BE',
    'brazil': 'BR',
    'colombia': 'CO',
    'costa-rica': 'CR',
    'cote-d-ivoire': 'CI',
    'ecuador': 'EC',
    'ethiopia': 'ET',
    'france': 'FR',
    'germany': 'DE',
    'ghana': 'GH',
    'guatemala': 'GT',
    'honduras': 'HN',
    'india': 'IN',
    'indonesia': 'ID',
    'italy': 'IT',
    'kenya': 'KE',
    'mexico': 'MX',
    'netherlands': 'NL',
    'nicaragua': 'NI',
    'peru': 'PE',
    'spain': 'ES',
    'switzerland': 'CH',
    'uganda': 'UG',
    'united-kingdom': 'GB',
    'vietnam': 'VN',
  };
}
