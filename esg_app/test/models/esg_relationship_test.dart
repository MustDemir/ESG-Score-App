import 'package:esg_app/models/esg_evidence.dart';
import 'package:esg_app/models/esg_relationship.dart';
import 'package:esg_app/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final retrievedAt = DateTime.utc(2026, 7, 27);
  const product = ESGEntity(
    id: 'gtin:4000417025005',
    type: ESGEntityType.product,
    displayName: 'Testprodukt',
  );
  const commodity = ESGEntity(
    id: 'commodity:cocoa',
    type: ESGEntityType.commodity,
    displayName: 'Kakao',
  );
  const country = ESGEntity(
    id: 'country:GH',
    type: ESGEntityType.country,
    displayName: 'Ghana',
  );

  test('community-reported relationships cannot support contextual risk', () {
    final relationship = ESGRelationship(
      id: 'relationship:community-origin',
      from: commodity,
      to: country,
      type: ESGRelationshipType.commodityHasOrigin,
      assertionClass: ESGAssertionClass.communityReported,
      confidence: ESGConfidence.low,
      source: ESGDataSource.openFoodFacts,
      sourceRecordId: '4000417025005',
      evidenceIds: const ['off:origin'],
      retrievedAt: retrievedAt,
    );

    expect(relationship.scoreEligible, isFalse);
    expect(relationship.supportsContextualRisk, isFalse);
  });

  test('verified commodity and origin chain can support contextual risk', () {
    final containsCommodity = ESGRelationship(
      id: 'relationship:contains-cocoa',
      from: product,
      to: commodity,
      type: ESGRelationshipType.containsCommodity,
      assertionClass: ESGAssertionClass.verified,
      confidence: ESGConfidence.high,
      source: ESGDataSource.localDemo,
      sourceRecordId: 'verified-product-record',
      evidenceIds: const ['verified:commodity'],
      scoreEligible: true,
      retrievedAt: retrievedAt,
    );
    final commodityOrigin = ESGRelationship(
      id: 'relationship:cocoa-origin',
      from: commodity,
      to: country,
      type: ESGRelationshipType.commodityHasOrigin,
      assertionClass: ESGAssertionClass.verified,
      confidence: ESGConfidence.high,
      source: ESGDataSource.localDemo,
      sourceRecordId: 'verified-origin-record',
      evidenceIds: const ['verified:origin'],
      scoreEligible: true,
      retrievedAt: retrievedAt,
    );
    final scanFairProduct = ScanFairProduct(
      barcode: '4000417025005',
      name: 'Testprodukt',
      brand: 'Testmarke',
      category: 'Schokolade',
      imageEmoji: '□',
      productType: ProductType.food,
      relationships: [containsCommodity, commodityOrigin],
    );

    expect(scanFairProduct.hasScoreEligibleCommodityOrigin, isTrue);
    expect(commodityOrigin.supportsContextualRisk, isTrue);
    expect(
      commodityOrigin.toMap()['relationship_type'],
      'commodity_has_origin',
    );
  });

  test('inferred low-confidence link cannot be marked score-eligible', () {
    expect(
      () => ESGRelationship(
        id: 'relationship:invalid',
        from: product,
        to: commodity,
        type: ESGRelationshipType.containsCommodity,
        assertionClass: ESGAssertionClass.inferred,
        confidence: ESGConfidence.low,
        source: ESGDataSource.localDemo,
        sourceRecordId: 'inferred-record',
        evidenceIds: const ['heuristic:commodity'],
        scoreEligible: true,
        retrievedAt: retrievedAt,
      ),
      throwsAssertionError,
    );
  });
}
