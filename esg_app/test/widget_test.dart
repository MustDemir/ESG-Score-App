// =============================================================================
// ScanFairApp — Smoke-Tests
// =============================================================================

import 'package:esg_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App rendert ohne Crash + Theme-Smoke-Screen sichtbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ScanFairApp());
    await tester.pumpAndSettle();

    // AppBar-Titel sichtbar
    expect(find.text('ScanFair — Theme Smoke'), findsOneWidget);

    // ESG-Pillar-Demo gerendert (E/S/G-Chips)
    expect(find.text('E'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);

    // Score-Hero-Mock zeigt Score
    expect(find.text('82'), findsOneWidget);
    expect(find.text('GEPA Bio Kaffee'), findsOneWidget);
  });

  testWidgets('Theme: MaterialApp nutzt ScanFairTheme.light', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ScanFairApp());

    final BuildContext context = tester.element(
      find.text('ScanFair — Theme Smoke'),
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // Primary muss Forest Green sein (#0F7B5C)
    expect(scheme.primary, const Color(0xFF0F7B5C));
    // Surface muss bg sein (#FBFAF6)
    expect(scheme.surface, const Color(0xFFFBFAF6));
  });

  testWidgets('Buttons existieren (Primary/Secondary/Tertiary)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ScanFairApp());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Primary'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Secondary'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Tertiary'), findsOneWidget);
  });
}
