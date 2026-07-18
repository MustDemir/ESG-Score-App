import 'package:esg_app/screens/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeScannedBarcode', () {
    test('accepts and trims product barcodes', () {
      expect(normalizeScannedBarcode(' 4000417025005 '), '4000417025005');
      expect(normalizeScannedBarcode('12345678'), '12345678');
      expect(normalizeScannedBarcode('12345678901234'), '12345678901234');
    });

    test('rejects empty, non-numeric and unsupported lengths', () {
      expect(normalizeScannedBarcode(null), isNull);
      expect(normalizeScannedBarcode(''), isNull);
      expect(normalizeScannedBarcode('SCANFAIR'), isNull);
      expect(normalizeScannedBarcode('1234567'), isNull);
      expect(normalizeScannedBarcode('123456789012345'), isNull);
    });
  });

  testWidgets('returns the first valid barcode to the calling screen', (
    tester,
  ) async {
    String? scannedBarcode;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                scannedBarcode = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => ScannerScreen(
                      viewportBuilder: (context, onBarcodeDetected) =>
                          ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  onBarcodeDetected('4000417025005');
                                  onBarcodeDetected('4316268476546');
                                },
                                child: const Text('Barcode erkennen'),
                              ),
                            ),
                          ),
                    ),
                  ),
                );
              },
              child: const Text('Scanner öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scanner öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barcode erkennen'));
    await tester.pumpAndSettle();

    expect(scannedBarcode, '4000417025005');
    expect(find.text('Scanner öffnen'), findsOneWidget);
  });

  testWidgets('explains denied camera permission and offers fallback', (
    tester,
  ) async {
    var wentBack = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ScannerErrorView(
          failure: ScannerFailureType.permissionDenied,
          onBack: () => wentBack = true,
        ),
      ),
    );

    expect(find.text('Kamerazugriff fehlt'), findsOneWidget);
    expect(find.textContaining('speichert keine Bilder'), findsOneWidget);
    expect(find.text('Barcode manuell eingeben'), findsOneWidget);

    await tester.ensureVisible(find.text('Barcode manuell eingeben'));
    await tester.tap(find.text('Barcode manuell eingeben'));
    expect(wentBack, isTrue);
  });
}
