import 'package:esg_app/models/esg_score.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/widgets/score_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScoreHero exposes one complete spoken summary', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScoreHero(score: _completeScore)),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'E S G-Gesamtscore 7.4 von 10. Positive Signale. '
        'Datenvollständigkeit 100 Prozent. '
        'Starke E S G-Signale mit nachvollziehbarer Datenbasis.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('PillarBars expose values and missing-data states', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PillarBars(score: _partialScore)),
      ),
    );

    final environmental = tester.getSemantics(
      find.bySemanticsLabel('Environmental'),
    );
    expect(environmental.value, '7.6 von 10');
    expect(
      (environmental.attributedLabel.attributes.single as LocaleStringAttribute)
          .locale,
      const Locale('en'),
    );
    expect(
      (environmental.attributedValue.attributes.single as LocaleStringAttribute)
          .locale,
      const Locale('de'),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Social')).value,
      '6.5 von 10',
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Governance')).value,
      'Keine Daten',
    );
    semantics.dispose();
  });

  testWidgets('decorative product emoji is excluded from semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductSummaryCard(product: _product)),
      ),
    );

    expect(find.bySemanticsLabel('chocolate bar'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Testmarke')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Testschokolade')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('score widgets remain layout-safe at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ScoreHero(score: _completeScore),
                  PillarBars(score: _partialScore),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

const _completeScore = ESGScore(
  state: ScoreState.fullScore,
  dataCompleteness: 1,
  total: 74,
);

const _partialScore = ESGScore(
  state: ScoreState.fullScore,
  dataCompleteness: 2 / 3,
  total: 71,
  environmental: PillarScore(
    pillar: ScorePillar.environmental,
    value: 76,
    label: 'Environmental',
    factors: [],
  ),
  social: PillarScore(
    pillar: ScorePillar.social,
    value: 65,
    label: 'Social',
    factors: [],
  ),
);

const _product = ScanFairProduct(
  barcode: '1234567890123',
  name: 'Testschokolade',
  brand: 'Testmarke',
  category: 'Schokolade',
  imageEmoji: 'chocolate bar',
  productType: ProductType.food,
);
