import 'package:esg_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home screen renders the local ScanFair flow', (tester) async {
    await tester.pumpWidget(const ScanFairApp());
    await tester.pumpAndSettle();

    expect(find.text('ScanFair'), findsOneWidget);
    expect(find.text("Was gibt's heute im Wagen?"), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Barcode scannen'),
      findsOneWidget,
    );
    expect(find.text('Bio Edelbitter Schokolade'), findsOneWidget);
  });

  testWidgets('Scan action opens result screen for GEPA demo product', (
    tester,
  ) async {
    await tester.pumpWidget(const ScanFairApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Barcode scannen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Ergebnis'), findsOneWidget);
    expect(find.text('Empfehlung'), findsOneWidget);
    expect(find.text('7.4'), findsOneWidget);
  });

  testWidgets('Manual barcode can open low-data state', (tester) async {
    await tester.pumpWidget(const ScanFairApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '4025500287955');
    await tester.tap(find.byTooltip('Barcode prüfen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Datengrundlage'), findsOneWidget);
    expect(find.text('Wir geben hier keinen Score.'), findsOneWidget);
  });

  testWidgets('Manual barcode can open not-found state', (tester) async {
    await tester.pumpWidget(const ScanFairApp());
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
    await tester.pumpWidget(const ScanFairApp());

    final context = tester.element(find.text('ScanFair').first);
    final scheme = Theme.of(context).colorScheme;

    expect(scheme.primary, const Color(0xFF0F7B5C));
    expect(scheme.surface, const Color(0xFFFBFAF6));
  });
}
