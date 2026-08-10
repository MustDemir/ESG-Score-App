import 'package:esg_app/main.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/screens/scanner_screen.dart';
import 'package:esg_app/services/product_lookup_failure.dart';
import 'package:esg_app/services/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDemoApp({ScannerViewportBuilder? scannerViewportBuilder}) {
    return ScanFairApp(
      repository: DemoProductRepository(),
      scannerViewportBuilder: scannerViewportBuilder,
    );
  }

  testWidgets('Home screen renders the local ScanFair flow', (tester) async {
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('ScanFair'), findsOneWidget);
    expect(find.text("Was gibt's heute im Wagen?"), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Barcode scannen'),
      findsOneWidget,
    );
    expect(find.text('Bio Edelbitter Schokolade'), findsOneWidget);
  });

  testWidgets('App declares German as its supported locale', (tester) async {
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final context = tester.element(find.text('ScanFair').first);

    expect(app.locale, const Locale('de'));
    expect(app.supportedLocales, const [Locale('de')]);
    expect(Localizations.localeOf(context), const Locale('de'));

    final localeSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('app-locale-semantics')),
    );
    expect(localeSemantics.localeForSubtree, const Locale('de'));
  });

  testWidgets('Scan action opens result screen for GEPA demo product', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDemoApp(
        scannerViewportBuilder: (context, onBarcodeDetected) => ColoredBox(
          color: Colors.black,
          child: Center(
            child: ElevatedButton(
              onPressed: () => onBarcodeDetected('4000417025005'),
              child: const Text('Testbarcode erfassen'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Barcode scannen'));
    await tester.pumpAndSettle();

    expect(find.text('Barcode in den Rahmen halten'), findsOneWidget);
    await tester.tap(find.text('Testbarcode erfassen'));
    await tester.pumpAndSettle();

    expect(find.text('Ergebnis'), findsOneWidget);
    expect(find.text('Positive Signale'), findsOneWidget);
    expect(find.text('7.4'), findsOneWidget);
  });

  testWidgets('Manual barcode can open low-data state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '4025500287955');
    await tester.tap(find.byTooltip('Barcode prüfen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Datengrundlage'), findsOneWidget);
    expect(find.text('Wir geben hier keinen Score.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Datengrundlage zu dünn. Wir geben hier keinen Score. '
        'Der Eco-Score fehlt oder ist als unbekannt markiert. '
        'Vorhandene Signale bleiben sichtbar und werden nicht geschätzt.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Manual barcode can open not-found state', (tester) async {
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0000000000000');
    await tester.tap(find.byTooltip('Barcode prüfen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Produkt nicht gefunden'), findsOneWidget);
    expect(find.text('Dieses Produkt kennen wir noch nicht.'), findsOneWidget);
  });

  testWidgets('Theme uses ScanFair primary and surface colors', (tester) async {
    await tester.pumpWidget(buildDemoApp());

    final context = tester.element(find.text('ScanFair').first);
    final scheme = Theme.of(context).colorScheme;

    expect(scheme.primary, const Color(0xFF0F7B5C));
    expect(scheme.surface, const Color(0xFFFBFAF6));
  });

  testWidgets('Network failure opens a retryable error state', (tester) async {
    await tester.pumpWidget(
      ScanFairApp(
        repository: _FailingProductRepository(),
        scannerViewportBuilder: (context, onBarcodeDetected) => ColoredBox(
          color: Colors.black,
          child: Center(
            child: ElevatedButton(
              onPressed: () => onBarcodeDetected('4000417025005'),
              child: const Text('Testbarcode erfassen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Barcode scannen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Testbarcode erfassen'));
    await tester.pumpAndSettle();

    expect(find.text('Keine Verbindung'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}

class _FailingProductRepository implements ProductRepository {
  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) {
    throw const ProductLookupFailure(
      type: ProductLookupFailureType.noConnection,
      message: 'Open Food Facts ist momentan nicht erreichbar.',
    );
  }

  @override
  List<ScanFairProduct> recentProducts() => const [];

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) => null;
}
