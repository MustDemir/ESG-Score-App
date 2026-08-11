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
}
