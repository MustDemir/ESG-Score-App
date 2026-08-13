import 'package:esg_app/data/demo_products.dart';
import 'package:esg_app/data_sources/open_food_facts_product_mapper.dart';
import 'package:esg_app/models/esg_score.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/services/esg_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ESGScoreCalculator();

  group('aggregate score precedence (Formel v1.1, ADR 0034)', () {
    test('calculates a full green score for GEPA chocolate', () {
      final product = demoProducts.firstWhere(
        (entry) => entry.barcode == '4000417025005',
      );

      final score = calculator.calculate(product);

      expect(score.state, ScoreState.fullScore);
      expect(score.trafficLight, TrafficLight.green);
      expect(score.environmental?.value, 55);
      expect(score.social?.value, 95);
      expect(score.governance?.value, 70);
      expect(score.total, closeTo(70, 0.01));
      expect(score.isPartial, isFalse);
      expect(score.partialNote, isNull);
    });

    test('marks an Environmental-only score as visible partial score', () {
      final score = calculator.calculate(_product(ecoscoreScore: 80));

      expect(score.state, ScoreState.partialScore);
      expect(score.isPartial, isTrue);
      expect(score.partialNote, isNotNull);
      expect(score.environmental?.value, 80);
      expect(score.social, isNull);
      expect(score.governance, isNull);
      expect(score.total, 80);
      expect(score.dataCompleteness, closeTo(1 / 3, 0.0001));
    });

    test('normalizes weights across Environmental and Social as partial', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 80, labelsTags: const ['en:vegan']),
      );

      expect(score.state, ScoreState.partialScore);
      expect(score.environmental?.value, 80);
      expect(score.social?.value, 60);
      expect(score.governance, isNull);
      expect(score.total, closeTo(72.5, 0.0001));
      expect(score.dataCompleteness, closeTo(2 / 3, 0.0001));
    });

    test('requires all three pillars for a full score', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 80,
          labelsTags: const ['en:fairtrade'],
          dataQualityTags: const ['en:complete'],
        ),
      );

      expect(score.state, ScoreState.fullScore);
      expect(score.isPartial, isFalse);
      expect(score.dataCompleteness, 1);
    });

    test('withholds total when Environmental is missing', () {
      final score = calculator.calculate(
        _product(brand: 'Testmarke', labelsTags: const ['en:fairtrade']),
      );

      expect(score.state, ScoreState.dataIncomplete);
      expect(score.environmental, isNull);
      expect(score.social?.value, 75);
      // Eine Marke allein ist keine Governance-Evidenz mehr (ADR 0034).
      expect(score.governance, isNull);
      expect(score.total, isNull);
      expect(score.trafficLight, TrafficLight.grey);
      expect(score.dataCompleteness, closeTo(1 / 3, 0.0001));
    });

    test('keeps missing Eco-Score as dataIncomplete instead of guessing', () {
      final product = demoProducts.firstWhere(
        (entry) => entry.barcode == '4025500287955',
      );

      final score = calculator.calculate(product);

      expect(score.state, ScoreState.dataIncomplete);
      expect(score.total, isNull);
      expect(score.environmental, isNull);
      expect(score.governance, isNotNull);
    });

    test('keeps a completely empty product dataIncomplete', () {
      final score = calculator.calculate(_product());

      expect(score.state, ScoreState.dataIncomplete);
      expect(score.availablePillars, isEmpty);
      expect(score.total, isNull);
      expect(score.dataCompleteness, 0);
      expect(score.trafficLight, TrafficLight.grey);
    });
  });

  group('Environmental decisions', () {
    const expectedGrades = <String, double>{
      'a-plus': 95,
      'a+': 95,
      'a': 85,
      'b': 70,
      'c': 55,
      'd': 40,
      'e': 25,
      'f': 10,
    };

    for (final entry in expectedGrades.entries) {
      test('maps Eco-Score grade ${entry.key}', () {
        final score = calculator.calculate(_product(ecoscoreGrade: entry.key));

        expect(score.environmental?.value, entry.value);
        expect(score.total, entry.value);
        expect(score.state, ScoreState.partialScore);
      });
    }

    test('prefers a numeric score over the grade mapping', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 42, ecoscoreGrade: 'a'),
      );

      expect(score.environmental?.value, 42);
      expect(score.total, 42);
    });

    test('clamps a negative mapped OFF score to zero', () {
      final product = const OpenFoodFactsProductMapper().map(
        const {
          'product_name': 'Negative Umweltbewertung',
          'environmental_score_score': -20,
        },
        barcode: 'negative-score',
        retrievedAt: DateTime.utc(2026, 8, 10),
      );

      final score = calculator.calculate(product);

      expect(product.ecoscoreScore, -20);
      expect(score.environmental?.value, 0);
      expect(score.total, 0);
      expect(score.trafficLight, TrafficLight.red);
    });

    test('clamps an Environmental score above 100', () {
      final score = calculator.calculate(_product(ecoscoreScore: 120));

      expect(score.environmental?.value, 100);
      expect(score.total, 100);
    });

    test('rejects non-finite mapped scores as missing evidence', () {
      for (final rawValue in ['NaN', 'Infinity', '-Infinity']) {
        final product = const OpenFoodFactsProductMapper().map(
          {'environmental_score_score': rawValue},
          barcode: 'non-finite-$rawValue',
          retrievedAt: DateTime.utc(2026, 8, 10),
        );

        final score = calculator.calculate(product);

        expect(product.ecoscoreScore, isNull, reason: rawValue);
        expect(score.state, ScoreState.dataIncomplete, reason: rawValue);
        expect(score.total, isNull, reason: rawValue);
      }
    });
  });

  group('Social decisions', () {
    const labelCases = <String, double>{
      'en:fairtrade': 75,
      'en:organic': 70,
      'en:vegan': 60,
      'en:rainforest-alliance': 70,
      'en:utz': 70,
    };

    for (final entry in labelCases.entries) {
      test('applies ${entry.key} social branch', () {
        final score = calculator.calculate(
          _product(ecoscoreScore: 70, labelsTags: [entry.key]),
        );

        expect(score.social?.value, entry.value);
      });
    }

    test('applies regional or EU origin boost', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, originTags: const ['en:germany']),
      );

      expect(score.social?.value, 65);
    });

    test('applies palm oil penalty without RSPO signal', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          labelsTags: const ['en:eu-organic'],
          ingredientsText: 'palm oil, sugar',
        ),
      );

      expect(score.social?.value, 55);
    });

    test('treats an RSPO label as its own certified factor', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          labelsTags: const ['en:rspo-certified'],
          ingredientsText: 'palm oil, sugar',
        ),
      );

      // +10 RSPO-Faktor, keine Palmoel-Strafe.
      expect(score.social?.value, 60);
    });

    test('withholds the Social pillar without any real signal', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, ingredientsText: 'water, oats'),
      );

      // Eine blosse Zutatenliste erzeugt keine Social-Saeule (ADR 0034).
      expect(score.social, isNull);
      expect(score.state, ScoreState.partialScore);
    });

    test('does not read "bio" inside "antibiotics" (exact tag match)', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, labelsTags: const ['en:no-antibiotics']),
      );

      expect(score.social, isNull);
    });

    test('does not read "palm" inside "palmitate"', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          labelsTags: const ['en:vegan'],
          ingredientsText: 'sodium palmitate, palmitic acid',
        ),
      );

      // Nur der Vegan-Faktor, keine Palmoel-Strafe.
      expect(score.social?.value, 60);
    });

    test('still detects German palm-oil ingredients', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          labelsTags: const ['en:vegan'],
          ingredientsText: 'Zucker, Palmöl, Kakao',
        ),
      );

      expect(score.social?.value, 45);
    });

    test('strips non-English tag prefixes before matching', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, labelsTags: const ['de:bio']),
      );

      expect(score.social?.value, 70);
    });

    test('clamps combined Social bonuses at 100', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          labelsTags: const [
            'en:fairtrade',
            'en:organic',
            'en:vegan',
            'en:rainforest-alliance',
          ],
          originTags: const ['en:european-union'],
        ),
      );

      expect(score.social?.value, 100);
    });
  });

  group('Governance decisions', () {
    test('applies data-completeness bonus in isolation', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, dataQualityTags: const ['en:complete']),
      );

      expect(score.governance?.value, 70);
    });

    test('does not read "complete" inside "incomplete"', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          dataQualityTags: const ['en:nutrition-facts-incomplete'],
        ),
      );

      expect(score.governance, isNull);
    });

    test('a brand alone yields no Governance pillar', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, brand: 'Testmarke'),
      );

      expect(score.governance, isNull);
    });

    test('an ingredients list alone yields no Governance pillar', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, ingredientsText: 'water'),
      );

      expect(score.governance, isNull);
    });

    test('applies missing-data warning penalty in isolation', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          dataQualityWarnings: const ['en:missing-data'],
        ),
      );

      expect(score.governance?.value, 40);
    });

    test('an unmatched quality tag yields no Governance pillar', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, dataQualityTags: const ['en:checked']),
      );

      // Kein Neutralwert mehr — ohne wertbare Evidenz keine Saeule
      // (ADR 0034).
      expect(score.governance, isNull);
    });
  });

  group('traffic-light boundaries', () {
    const cases = <({double score, TrafficLight trafficLight})>[
      (score: 0, trafficLight: TrafficLight.red),
      (score: 39.99, trafficLight: TrafficLight.red),
      (score: 40, trafficLight: TrafficLight.yellow),
      (score: 69.99, trafficLight: TrafficLight.yellow),
      (score: 70, trafficLight: TrafficLight.green),
      (score: 100, trafficLight: TrafficLight.green),
    ];

    for (final entry in cases) {
      test('${entry.score} maps to ${entry.trafficLight.name}', () {
        final score = calculator.calculate(
          _product(ecoscoreScore: entry.score),
        );

        expect(score.trafficLight, entry.trafficLight);
      });
    }
  });

  test('maps Open Food Facts JSON into the local product model', () {
    final product = const OpenFoodFactsProductMapper().map(
      {
        'product_name': 'Haferdrink',
        'brands': 'Beispielmarke',
        'ecoscore_grade': 'b',
        'packaging_tags': ['en:carton'],
        'origins_tags': ['en:germany'],
        'labels_tags': ['en:eu-organic'],
        'ingredients_text': 'water, oats',
      },
      barcode: '123',
      retrievedAt: DateTime.utc(2026, 7, 27),
    );

    expect(product.name, 'Haferdrink');
    expect(product.brand, 'Beispielmarke');
    expect(product.ecoscoreGrade, 'b');
    expect(product.originTags, contains('en:germany'));
    expect(product.evidenceFor('environmental_score'), hasLength(1));
  });

  test('prefers the German product name when present', () {
    final product = const OpenFoodFactsProductMapper().map(
      {'product_name': 'Oat drink', 'product_name_de': 'Haferdrink'},
      barcode: '123',
      retrievedAt: DateTime.utc(2026, 8, 13),
    );

    expect(product.name, 'Haferdrink');
  });

  test('evidence sourceField follows the field that supplied the value', () {
    // v3-Feld vorhanden aber null, Legacy-Feld liefert den Wert (F-14).
    final product = const OpenFoodFactsProductMapper().map(
      {
        'product_name': 'Mischpayload',
        'environmental_score_grade': null,
        'ecoscore_grade': 'b',
      },
      barcode: '123',
      retrievedAt: DateTime.utc(2026, 8, 13),
    );

    final evidence = product.evidenceFor('environmental_score').single;
    expect(evidence.value, 'b');
    expect(evidence.sourceField, 'ecoscore_grade');
  });
}

ScanFairProduct _product({
  double? ecoscoreScore,
  String? ecoscoreGrade,
  String brand = 'Unbekannte Marke',
  List<String> labelsTags = const [],
  List<String> originTags = const [],
  String? ingredientsText,
  List<String> dataQualityTags = const [],
  List<String> dataQualityWarnings = const [],
}) {
  return ScanFairProduct(
    barcode: 'test',
    name: 'Testprodukt',
    brand: brand,
    category: 'Lebensmittel',
    imageEmoji: '[]',
    productType: ProductType.food,
    ecoscoreScore: ecoscoreScore,
    ecoscoreGrade: ecoscoreGrade,
    labelsTags: labelsTags,
    originTags: originTags,
    ingredientsText: ingredientsText,
    dataQualityTags: dataQualityTags,
    dataQualityWarnings: dataQualityWarnings,
  );
}
