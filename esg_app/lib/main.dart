import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/esg_score_calculator.dart';
import 'services/product_repository.dart';
import 'theme/scanfair_theme.dart';

void main() {
  runApp(const ScanFairApp());
}

class ScanFairApp extends StatelessWidget {
  const ScanFairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanFair',
      debugShowCheckedModeBanner: false,
      theme: ScanFairTheme.light,
      home: HomeScreen(
        repository: DemoProductRepository(),
        calculator: const ESGScoreCalculator(),
      ),
    );
  }
}
