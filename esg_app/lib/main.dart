import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/esg_score_calculator.dart';
import 'services/open_food_facts_service.dart';
import 'services/product_repository.dart';
import 'services/supabase_product_cache_service.dart';
import 'theme/scanfair_theme.dart';

void main() {
  // Brand-Fonts muessen aus den gebuendelten Assets kommen. Ein unbemerkter
  // Laufzeitabruf waere ein zusaetzlicher, nicht freigegebener Datenfluss.
  GoogleFonts.config.allowRuntimeFetching = false;
  final directSource = OpenFoodFactsProductRepository(
    service: OpenFoodFactsService(),
  );
  final cacheConfiguration = _cacheConfiguration();
  final ProductRepository productSource = cacheConfiguration == null
      ? directSource
      : ReadThroughProductRepository(
          cache: SupabaseProductCacheService(configuration: cacheConfiguration),
          fallback: directSource,
          onCacheOutcome: _logCacheOutcome,
        );
  runApp(
    ScanFairApp(
      repository: CoffeePilotProductRepository(source: productSource),
    ),
  );
}

SupabaseProductCacheConfiguration? _cacheConfiguration() {
  const projectUrl = String.fromEnvironment('SCANFAIR_SUPABASE_URL');
  const publishableKey = String.fromEnvironment(
    'SCANFAIR_SUPABASE_PUBLISHABLE_KEY',
  );
  try {
    return SupabaseProductCacheConfiguration.fromValues(
      projectUrl: projectUrl,
      publishableKey: publishableKey,
    );
  } on FormatException catch (error) {
    // developer.log bleibt im Gegensatz zu debugPrint auch in Release-Builds
    // ueber das VM-Service/os_log sichtbar (Cache-Ausfall darf nicht stumm
    // bleiben, Audit-Finding F-06).
    developer.log(
      'Remote product cache disabled: ${error.message}',
      name: 'scanfair.cache',
      level: 1000,
    );
    return null;
  }
}

void _logCacheOutcome(ProductCacheOutcome outcome) {
  developer.log(
    'product cache outcome: ${outcome.name}',
    name: 'scanfair.cache',
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
