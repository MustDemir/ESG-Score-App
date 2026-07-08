import 'package:esg_app/data/demo_products.dart';
import 'package:esg_app/models/esg_score.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/services/esg_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ESGScoreCalculator();

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

  test('applies organic and fair-trade social boosts', () {
    const product = ScanFairProduct(
      barcode: 'test',
      name: 'Signalprodukt',
      brand: 'Test',
      category: 'Lebensmittel',
      imageEmoji: '□',
      productType: ProductType.food,
      ecoscoreGrade: 'a',
      labelsTags: ['en:eu-organic', 'en:fairtrade'],
      ingredientsText: 'cocoa, sugar',
    );

    final score = calculator.calculate(product);

    expect(score.social?.value, 95);
  });

  test('applies palm oil penalty without RSPO signal', () {
    const product = ScanFairProduct(
      barcode: 'test',
      name: 'Palmprodukt',
      brand: 'Test',
      category: 'Lebensmittel',
      imageEmoji: '□',
      productType: ProductType.food,
      ecoscoreGrade: 'b',
      labelsTags: ['en:eu-organic'],
      ingredientsText: 'palm oil, sugar',
    );

    final score = calculator.calculate(product);

    expect(score.social?.value, 55);
  });

  test('maps Open Food Facts JSON into the local product model', () {
    final product = ScanFairProduct.fromOpenFoodFactsJson({
      'product': {
        'product_name': 'Haferdrink',
        'brands': 'Beispielmarke',
        'ecoscore_grade': 'b',
        'packaging_tags': ['en:carton'],
        'origins_tags': ['en:germany'],
        'labels_tags': ['en:eu-organic'],
        'ingredients_text': 'water, oats',
      },
    }, barcode: '123');

    expect(product.name, 'Haferdrink');
    expect(product.brand, 'Beispielmarke');
    expect(product.ecoscoreGrade, 'b');
    expect(product.originTags, contains('en:germany'));
  });
}
