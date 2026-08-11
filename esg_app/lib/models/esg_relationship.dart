import 'esg_evidence.dart';

enum ESGEntityType {
  product,
  category,
  commodity,
  country,
  location,
  brand,
  legalEntity,
  supplyChainNode,
}

enum ESGRelationshipType {
  containsCommodity,
  hasProductOrigin,
  commodityHasOrigin,
  marketedByBrand,
  responsibleLegalEntity,
  ownedByLegalEntity,
}

enum ESGAssertionClass {
  measured,
  verified,
  declared,
  modeled,
  categoryAverage,
  communityReported,
  inferred,
  unknown,
}

enum ESGConfidence { high, medium, low, unknown }

class ESGEntityIdentifier {
  const ESGEntityIdentifier({
    required this.scheme,
    required this.value,
    this.issuer,
  });

  final String scheme;
  final String value;
  final String? issuer;

  Map<String, Object?> toMap() {
    return {'scheme': scheme, 'value': value, 'issuer': issuer};
  }
}

class ESGEntity {
  const ESGEntity({
    required this.id,
    required this.type,
    required this.displayName,
    this.identifiers = const [],
  });

  final String id;
  final ESGEntityType type;
  final String displayName;
  final List<ESGEntityIdentifier> identifiers;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'entity_type': _wireName(type),
      'display_name': displayName,
      'identifiers': identifiers.map((entry) => entry.toMap()).toList(),
    };
  }

  static String _wireName(ESGEntityType type) {
    return switch (type) {
      ESGEntityType.product => 'product',
      ESGEntityType.category => 'category',
      ESGEntityType.commodity => 'commodity',
      ESGEntityType.country => 'country',
      ESGEntityType.location => 'location',
      ESGEntityType.brand => 'brand',
      ESGEntityType.legalEntity => 'legal_entity',
      ESGEntityType.supplyChainNode => 'supply_chain_node',
    };
  }
}

class ESGRelationship {
  ESGRelationship({
    required this.id,
    required this.from,
    required this.to,
    required this.type,
    required this.assertionClass,
    required this.confidence,
    required this.source,
    required this.sourceRecordId,
    required this.retrievedAt,
    this.evidenceIds = const [],
    bool scoreEligible = false,
    this.contextEntity,
    this.observedAt,
    this.validFrom,
    this.validTo,
  }) : _scoreEligibleRequested = scoreEligible,
       assert(
         !scoreEligible ||
             (evidenceIds.isNotEmpty &&
                 (confidence == ESGConfidence.high ||
                     confidence == ESGConfidence.medium) &&
                 (assertionClass == ESGAssertionClass.measured ||
                     assertionClass == ESGAssertionClass.verified ||
                     assertionClass == ESGAssertionClass.declared)),
         'Score-eligible relationships need evidence, sufficient confidence, '
         'and a measured, verified, or declared assertion.',
       ) {
    final context = contextEntity;
    if (scoreEligible &&
        type == ESGRelationshipType.commodityHasOrigin &&
        context == null) {
      throw ArgumentError(
        'Score-eligible commodity origins need a product context.',
      );
    }
    if (context != null && context.type != ESGEntityType.product) {
      throw ArgumentError('Relationship context must be a product entity.');
    }
    if (context != null && (context.id == from.id || context.id == to.id)) {
      throw ArgumentError(
        'Relationship context must differ from both endpoints.',
      );
    }
  }

  final String id;
  final ESGEntity from;
  final ESGEntity to;
  final ESGRelationshipType type;
  final ESGAssertionClass assertionClass;
  final ESGConfidence confidence;
  final ESGDataSource source;
  final String sourceRecordId;
  final List<String> evidenceIds;
  final bool _scoreEligibleRequested;
  final ESGEntity? contextEntity;
  final DateTime retrievedAt;
  final DateTime? observedAt;
  final DateTime? validFrom;
  final DateTime? validTo;

  bool get scoreEligible =>
      _scoreEligibleRequested &&
      evidenceIds.isNotEmpty &&
      (confidence == ESGConfidence.high ||
          confidence == ESGConfidence.medium) &&
      (assertionClass == ESGAssertionClass.measured ||
          assertionClass == ESGAssertionClass.verified ||
          assertionClass == ESGAssertionClass.declared);

  bool get supportsContextualRisk =>
      type == ESGRelationshipType.commodityHasOrigin &&
      scoreEligible &&
      contextEntity != null;

  bool supportsContextualRiskFor(String productEntityId) {
    return supportsContextualRisk && contextEntity!.id == productEntityId;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'from_entity_id': from.id,
      'to_entity_id': to.id,
      'relationship_type': _relationshipWireName(type),
      'assertion_class': _assertionWireName(assertionClass),
      'confidence': confidence.name,
      'source_id': source.id,
      'source_record_id': sourceRecordId,
      'evidence_ids': evidenceIds,
      'score_eligible': scoreEligible,
      'context_entity_id': contextEntity?.id,
      'retrieved_at': retrievedAt.toUtc().toIso8601String(),
      'observed_at': observedAt?.toUtc().toIso8601String(),
      'valid_from': validFrom?.toUtc().toIso8601String(),
      'valid_to': validTo?.toUtc().toIso8601String(),
    };
  }

  static String _relationshipWireName(ESGRelationshipType type) {
    return switch (type) {
      ESGRelationshipType.containsCommodity => 'contains_commodity',
      ESGRelationshipType.hasProductOrigin => 'has_product_origin',
      ESGRelationshipType.commodityHasOrigin => 'commodity_has_origin',
      ESGRelationshipType.marketedByBrand => 'marketed_by_brand',
      ESGRelationshipType.responsibleLegalEntity => 'responsible_legal_entity',
      ESGRelationshipType.ownedByLegalEntity => 'owned_by_legal_entity',
    };
  }

  static String _assertionWireName(ESGAssertionClass assertionClass) {
    return switch (assertionClass) {
      ESGAssertionClass.measured => 'measured',
      ESGAssertionClass.verified => 'verified',
      ESGAssertionClass.declared => 'declared',
      ESGAssertionClass.modeled => 'modeled',
      ESGAssertionClass.categoryAverage => 'category_average',
      ESGAssertionClass.communityReported => 'community_reported',
      ESGAssertionClass.inferred => 'inferred',
      ESGAssertionClass.unknown => 'unknown',
    };
  }
}
