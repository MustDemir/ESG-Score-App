import 'package:esg_app/data_sources/coffee_pilot_catalog.dart';
import 'package:esg_app/models/esg_evidence.dart';
import 'package:esg_app/models/esg_relationship.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/widgets/score_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows unresolved relationship state without inventing a join', (
    tester,
  ) async {
    const productEntity = ESGEntity(
      id: 'gtin:4000417025005',
      type: ESGEntityType.product,
      displayName: 'Testschokolade',
    );
    const cocoa = ESGEntity(
      id: 'commodity:cocoa',
      type: ESGEntityType.commodity,
      displayName: 'Kakao',
    );
    final relationship = ESGRelationship(
      id: 'relationship:community-cocoa',
      from: productEntity,
      to: cocoa,
      type: ESGRelationshipType.containsCommodity,
      assertionClass: ESGAssertionClass.communityReported,
      confidence: ESGConfidence.low,
      source: ESGDataSource.openFoodFacts,
      sourceRecordId: '4000417025005',
      evidenceIds: const ['off:commodity-cocoa'],
      retrievedAt: DateTime.utc(2026, 7, 27),
    );
    final product = ScanFairProduct(
      barcode: '4000417025005',
      name: 'Testschokolade',
      brand: 'Testmarke',
      category: 'Schokolade',
      imageEmoji: '□',
      productType: ProductType.food,
      relationships: [relationship],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TraceabilityCard(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Kakao'), findsOneWidget);
    expect(find.text('Hinweis · noch nicht score-aktiv'), findsOneWidget);
    expect(
      find.text(
        'Vorhandene Hinweise reichen noch nicht für eine '
        'Rohstoff-Länder-Risikobewertung.',
      ),
      findsOneWidget,
    );
    expect(find.text('Rechtsträger noch nicht aufgelöst'), findsOneWidget);
  });

  testWidgets('shows declared coffee origins with source and confidence', (
    tester,
  ) async {
    const catalog = CoffeePilotCatalog();
    final product = catalog.enrichOrCreate(barcode: '4013320110539')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TraceabilityCard(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Kaffee'), findsOneWidget);
    expect(find.text('Rohstoffherkunft'), findsOneWidget);
    expect(find.text('Guatemala, Nicaragua'), findsOneWidget);
    expect(
      find.text(
        'belegt · Herstellerangabe · mittlere Sicherheit · '
        'GEPA Produktangaben',
      ),
      findsNWidgets(2),
    );
    expect(
      find.text(
        'Rohstoff und Herkunft sind für kontextuelle '
        'Risikodaten freigegeben.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides commodity origins scoped to another GTIN', (tester) async {
    const productEntity = ESGEntity(
      id: 'gtin:4000417025005',
      type: ESGEntityType.product,
      displayName: 'Testschokolade',
    );
    const otherProduct = ESGEntity(
      id: 'gtin:4013320225196',
      type: ESGEntityType.product,
      displayName: 'Anderes Produkt',
    );
    const cocoa = ESGEntity(
      id: 'commodity:cocoa',
      type: ESGEntityType.commodity,
      displayName: 'Kakao',
    );
    const ghana = ESGEntity(
      id: 'country:GH',
      type: ESGEntityType.country,
      displayName: 'Ghana',
    );
    final product = ScanFairProduct(
      barcode: '4000417025005',
      name: 'Testschokolade',
      brand: 'Testmarke',
      category: 'Schokolade',
      imageEmoji: '□',
      productType: ProductType.food,
      relationships: [
        ESGRelationship(
          id: 'relationship:contains-cocoa',
          from: productEntity,
          to: cocoa,
          type: ESGRelationshipType.containsCommodity,
          assertionClass: ESGAssertionClass.verified,
          confidence: ESGConfidence.high,
          source: ESGDataSource.localDemo,
          sourceRecordId: 'verified-product-record',
          evidenceIds: const ['verified:commodity'],
          scoreEligible: true,
          retrievedAt: DateTime.utc(2026, 8, 11),
        ),
        ESGRelationship(
          id: 'relationship:other-product-origin',
          from: cocoa,
          to: ghana,
          type: ESGRelationshipType.commodityHasOrigin,
          assertionClass: ESGAssertionClass.declared,
          confidence: ESGConfidence.medium,
          source: ESGDataSource.localDemo,
          sourceRecordId: 'declared-origin-record',
          evidenceIds: const ['declared:origin'],
          scoreEligible: true,
          contextEntity: otherProduct,
          retrievedAt: DateTime.utc(2026, 8, 11),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TraceabilityCard(product: product),
          ),
        ),
      ),
    );

    expect(find.text('Ghana'), findsNothing);
    expect(find.text('Keine Rohstoffherkunft belegt'), findsOneWidget);
    expect(
      find.text(
        'Vorhandene Hinweise reichen noch nicht für eine '
        'Rohstoff-Länder-Risikobewertung.',
      ),
      findsOneWidget,
    );
  });
}
