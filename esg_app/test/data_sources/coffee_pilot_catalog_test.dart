import 'package:esg_app/data_sources/coffee_pilot_catalog.dart';
import 'package:esg_app/models/esg_relationship.dart';
import 'package:esg_app/models/esg_score.dart';
import 'package:esg_app/services/esg_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const catalog = CoffeePilotCatalog();
  const calculator = ESGScoreCalculator();

  test('contains the three versioned coffee pilot GTINs', () {
    expect(catalog.knownBarcodes, {
      '4013320225196',
      '4013320114865',
      '4013320110539',
    });
    expect(CoffeePilotCatalog.version, 'coffee-pilot-1.0');
    expect(CoffeePilotCatalog.sourceRecordSha256, hasLength(64));
  });

  for (final definition in coffeePilotDefinitions) {
    test('${definition.barcode} has a context-bound coffee origin chain', () {
      final product = catalog.enrichOrCreate(barcode: definition.barcode)!;
      final commodityLinks = product
          .relationshipsOfType(ESGRelationshipType.containsCommodity)
          .where((relationship) => relationship.scoreEligible)
          .toList();
      final originLinks = product
          .relationshipsOfType(ESGRelationshipType.commodityHasOrigin)
          .where((relationship) => relationship.scoreEligible)
          .toList();

      expect(commodityLinks, hasLength(1));
      expect(commodityLinks.single.to.id, 'commodity:coffee');
      expect(originLinks, hasLength(definition.origins.length));
      expect(
        originLinks.map((relationship) => relationship.contextEntity?.id),
        everyElement('gtin:${definition.barcode}'),
      );
      expect(
        originLinks.map((relationship) => relationship.to.id).toSet(),
        definition.origins
            .map((origin) => 'country:${origin.countryCode}')
            .toSet(),
      );
      expect(product.hasScoreEligibleCommodityOrigin, isTrue);
      expect(
        product.evidence.every(
          (entry) =>
              entry.source.id == 'gepa-product-declarations' &&
              entry.sourceSchemaVersion ==
                  CoffeePilotCatalog.sourceRecordSha256,
        ),
        isTrue,
      );
    });
  }

  test('pilot evidence cannot create an overall ESG score by itself', () {
    final product = catalog.enrichOrCreate(barcode: '4013320225196')!;

    final score = calculator.calculate(product);

    expect(score.state, ScoreState.dataIncomplete);
    expect(score.environmental, isNull);
    expect(score.total, isNull);
  });

  test('unknown GTIN is not synthesized', () {
    expect(catalog.enrichOrCreate(barcode: '0000000000000'), isNull);
  });
}
