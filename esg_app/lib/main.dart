import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
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
    this.scannerViewportBuilder,
    super.key,
  });

  final ProductRepository repository;
  final ESGScoreCalculator calculator;
  final ScannerViewportBuilder? scannerViewportBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanFair',
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Semantics(
        key: const ValueKey('app-locale-semantics'),
        localeForSubtree: const Locale('de'),
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ScanFairTheme.light,
      home: HomeScreen(
        repository: repository,
        calculator: calculator,
        scannerViewportBuilder: scannerViewportBuilder,
      ),
    );
  }
}
