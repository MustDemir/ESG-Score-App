import 'package:esg_app/models/product.dart';
import 'package:esg_app/theme/scanfair_theme.dart';
import 'package:esg_app/widgets/score_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const product = ScanFairProduct(
    barcode: '4000417025005',
    name: 'Testprodukt',
    brand: 'Testmarke',
    category: 'Lebensmittel',
    imageEmoji: 'P',
    productType: ProductType.food,
    nutritionSourceLabel: 'Testdatenquelle',
    nutritionFacts: 'Nutri-Score D · Zucker 47 g/100 g · NOVA 4',
  );

  testWidgets('shows neutral nutrition facts without a score indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ScanFairTheme.light,
        home: const Scaffold(body: SecondaryInfoCard(product: product)),
      ),
    );

    expect(find.text('Nährwert-Hinweis'), findsOneWidget);
    expect(find.textContaining('kein Score'), findsOneWidget);
    expect(find.text('Testdatenquelle'), findsOneWidget);
    expect(
      find.text('Keine medizinische oder individuelle Ernährungsberatung.'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('remains readable at narrow width and 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: ScanFairTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SecondaryInfoCard(product: product),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Nährwert-Hinweis'), findsOneWidget);
  });
}
