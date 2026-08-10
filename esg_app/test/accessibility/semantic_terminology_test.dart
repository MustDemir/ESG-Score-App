import 'package:esg_app/accessibility/semantic_terminology.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains one definition for every supported semantic term', () {
    expect(
      ScanFairSemanticTerminology.definitions.map((entry) => entry.id).toSet(),
      SemanticTermId.values.toSet(),
    );
    expect(
      ScanFairSemanticTerminology.definitions
          .map((entry) => entry.displayText)
          .toSet()
          .length,
      ScanFairSemanticTerminology.definitions.length,
    );
  });

  test(
    'mixed German and English domain text receives stable speech locales',
    () {
      final attributed = ScanFairSemanticTerminology.annotate(
        'ESG: Environmental, Social und Governance. '
        'Daten: Open Food Facts. Palmöl ohne RSPO-Signal.',
      );

      expect(
        attributed.string,
        'E S G: Environmental, Social und Governance. '
        'Daten: Open Food Facts. Palmöl ohne R S P O-Signal.',
      );
      expect(_localeAt(attributed, 'Environmental'), const Locale('en'));
      expect(_localeAt(attributed, 'Social'), const Locale('en'));
      expect(_localeAt(attributed, 'Governance'), const Locale('en'));
      expect(_localeAt(attributed, 'Open Food Facts'), const Locale('en'));
      expect(_localeAt(attributed, 'E S G'), const Locale('de'));
      expect(_localeAt(attributed, 'R S P O'), const Locale('de'));
      expect(_localeAt(attributed, 'Daten'), const Locale('de'));
    },
  );

  test('longer catalog entries win over embedded shorter terms', () {
    final attributed = ScanFairSemanticTerminology.annotate(
      'Open Food Facts contributors',
    );

    expect(attributed.string, 'Open Food Facts contributors');
    expect(attributed.attributes, hasLength(1));
    expect(
      (attributed.attributes.single as LocaleStringAttribute).locale,
      const Locale('en'),
    );
  });

  testWidgets('TerminologyText exposes speech text without changing display', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TerminologyText('ScanFair'))),
    );

    expect(find.text('ScanFair'), findsOneWidget);
    expect(find.bySemanticsLabel('Scan Fair'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('Scan Fair'));
    expect(
      (node.attributedLabel.attributes.single as LocaleStringAttribute).locale,
      const Locale('en'),
    );
    semantics.dispose();
  });
}

Locale _localeAt(AttributedString attributed, String fragment) {
  final index = attributed.string.indexOf(fragment);
  expect(index, isNonNegative, reason: 'Missing fragment: $fragment');

  return attributed.attributes
      .whereType<LocaleStringAttribute>()
      .singleWhere(
        (attribute) =>
            attribute.range.start <= index && attribute.range.end > index,
      )
      .locale;
}
