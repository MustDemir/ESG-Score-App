import 'package:esg_app/models/esg_evidence.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/widgets/score_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows OFF database, content and image license separately', (
    tester,
  ) async {
    final product = _offProduct();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DataProvenanceCard(product: product),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Datenquellen-Lizenz: ODbL-1.0'),
      findsOneWidget,
    );
    expect(find.textContaining('Inhalte: DbCL-1.0'), findsOneWidget);
    expect(find.textContaining('Produktbilder: CC-BY-SA-3.0'), findsOneWidget);
    expect(find.textContaining('Open Food Facts contributors'), findsOneWidget);
    expect(
      find.textContaining('Enthält Informationen aus Open Food Facts'),
      findsOneWidget,
    );
    expect(
      find.textContaining('https://opendatacommons.org/licenses/odbl/1-0/'),
      findsOneWidget,
    );
    expect(
      find.textContaining('https://opendatacommons.org/licenses/dbcl/1-0/'),
      findsOneWidget,
    );
    expect(
      find.textContaining('https://creativecommons.org/licenses/by-sa/3.0/'),
      findsOneWidget,
    );
  });

  testWidgets('license notice remains layout-safe at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: DataProvenanceCard(product: _offProduct()),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('Datenquellen-Lizenz: ODbL-1.0'),
      findsOneWidget,
    );
  });
}

ScanFairProduct _offProduct() {
  return ScanFairProduct(
    barcode: '4000417025005',
    name: 'Testprodukt',
    brand: 'Testmarke',
    category: 'Lebensmittel',
    imageEmoji: '[]',
    productType: ProductType.food,
    evidence: [
      ESGEvidence(
        id: 'off:test',
        source: ESGDataSource.openFoodFacts,
        sourceRecordId: '4000417025005',
        sourceRecordUrl:
            'https://world.openfoodfacts.org/product/4000417025005',
        sourceField: 'product_name',
        metric: 'product_name',
        value: 'Testprodukt',
        pillars: const [EvidencePillar.governance],
        scope: EvidenceScope.product,
        quality: EvidenceQuality.communityProvided,
        retrievedAt: DateTime.utc(2026, 8, 11),
      ),
    ],
  );
}
