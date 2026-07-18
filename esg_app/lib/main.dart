import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/esg_score_calculator.dart';
import 'services/open_food_facts_service.dart';
import 'services/product_repository.dart';
import 'theme/scanfair_theme.dart';

void main() {
  runApp(
    ScanFairApp(
      repository: OpenFoodFactsProductRepository(
        service: OpenFoodFactsService(),
      ),
    ),
  );
}

class ScanFairApp extends StatelessWidget {
  const ScanFairApp({
    required this.repository,
    this.calculator = const ESGScoreCalculator(),
    super.key,
  });

  final ProductRepository repository;
  final ESGScoreCalculator calculator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanFair',
      debugShowCheckedModeBanner: false,
      theme: ScanFairTheme.light,
      home: HomeScreen(repository: repository, calculator: calculator),
    );
  }
}
