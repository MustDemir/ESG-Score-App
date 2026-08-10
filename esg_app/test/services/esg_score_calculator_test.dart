import 'package:esg_app/data/demo_products.dart';
import 'package:esg_app/data_sources/open_food_facts_product_mapper.dart';
import 'package:esg_app/models/esg_score.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/services/esg_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ESGScoreCalculator();

  group('aggregate score precedence', () {
    test('calculates a full green score for GEPA chocolate', () {
      final product = demoProducts.firstWhere(
        (entry) => entry.barcode == '4000417025005',
      );

      final score = calculator.calculate(product);

      expect(score.state, ScoreState.fullScore);
      expect(score.trafficLight, TrafficLight.green);
      expect(score.environmental?.value, 55);
      expect(score.social?.value, 95);
      expect(score.governance?.value, 90);
      expect(score.total, closeTo(74, 0.01));
    });

    test('allows an Environmental-only score with visible completeness', () {
      final score = calculator.calculate(_product(ecoscoreScore: 80));

      expect(score.state, ScoreState.fullScore);
      expect(score.environmental?.value, 80);
      expect(score.social, isNull);
      expect(score.governance, isNull);
      expect(score.total, 80);
      expect(score.dataCompleteness, closeTo(1 / 3, 0.0001));
    });

    test('normalizes weights across Environmental and Social', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 80, labelsTags: const ['en:vegan']),
      );

      expect(score.environmental?.value, 80);
      expect(score.social?.value, 60);
      expect(score.governance, isNull);
      expect(score.total, closeTo(72.5, 0.0001));
      expect(score.dataCompleteness, closeTo(2 / 3, 0.0001));
    });

    test('withholds total when Environmental is missing but S and G exist', () {
      final score = calculator.calculate(
        _product(brand: 'Testmarke', labelsTags: const ['en:fairtrade']),
      );

      expect(score.state, ScoreState.dataIncomplete);
      expect(score.environmental, isNull);
      expect(score.social?.value, 75);
      expect(score.governance?.value, 60);
      expect(score.total, isNull);
      expect(score.trafficLight, TrafficLight.grey);
      expect(score.dataCompleteness, closeTo(2 / 3, 0.0001));
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

    test('does not apply palm oil penalty with RSPO signal', () {
      final score = calculator.calculate(
        _product(
          ecoscoreScore: 70,
          labelsTags: const ['en:rspo-certified'],
          ingredientsText: 'palm oil, sugar',
        ),
      );

      expect(score.social?.value, 50);
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

    test('applies known single-brand bonus in isolation', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, brand: 'Testmarke'),
      );

      expect(score.governance?.value, 60);
    });

    test('applies ingredients transparency bonus in isolation', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, ingredientsText: 'water'),
      );

      expect(score.governance?.value, 60);
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

    test('uses neutral Governance baseline for an unmatched quality tag', () {
      final score = calculator.calculate(
        _product(ecoscoreScore: 70, dataQualityTags: const ['en:checked']),
      );

      expect(score.governance?.value, 50);
      expect(score.governance?.factors.single.value, 'Neutraler Startwert');
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
