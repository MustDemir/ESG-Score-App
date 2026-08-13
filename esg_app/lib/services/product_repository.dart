import '../data/demo_products.dart';
import '../data_sources/coffee_pilot_catalog.dart';
import '../models/product.dart';
import 'open_food_facts_service.dart';
import 'product_lookup_failure.dart';
import 'supabase_product_cache_service.dart';

abstract class ProductRepository {
  Future<ScanFairProduct?> findByBarcode(String barcode);

  List<ScanFairProduct> recentProducts();

  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product);
}

class DemoProductRepository implements ProductRepository {
  DemoProductRepository({List<ScanFairProduct> products = demoProducts})
    : _products = List.unmodifiable(products);

  final List<ScanFairProduct> _products;

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalized = barcode.trim();
    for (final product in _products) {
      if (product.barcode == normalized) return product;
    }
    return null;
  }

  @override
  List<ScanFairProduct> recentProducts() => _products.take(3).toList();

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) {
    final candidates = _products.where(
      (candidate) =>
          candidate.barcode != product.barcode &&
          candidate.productType == product.productType &&
          candidate.ecoscoreGrade != null,
    );

    if (candidates.isEmpty) return null;
    return candidates.firstWhere(
      (candidate) => candidate.labelsTags.any(
        (tag) => tag.contains('fairtrade') || tag.contains('organic'),
      ),
      orElse: () => candidates.first,
    );
  }
}

class OpenFoodFactsProductRepository implements ProductRepository {
  OpenFoodFactsProductRepository({required this.service});

  final OpenFoodFactsService service;
  final List<ScanFairProduct> _recentProducts = [];

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) async {
    final product = await service.findByBarcode(barcode);
    if (product == null) return null;

    _recentProducts.removeWhere((entry) => entry.barcode == product.barcode);
    _recentProducts.insert(0, product);
    if (_recentProducts.length > 10) _recentProducts.removeLast();
    return product;
  }

  @override
  List<ScanFairProduct> recentProducts() {
    return List.unmodifiable(_recentProducts.take(3));
  }

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) => null;

  void close() => service.close();
}

enum ProductCacheOutcome {
  hit,
  miss,
  stale,
  staleServed,
  unavailable,
  invalidResponse,
  error,
  skipped,
}

typedef ProductCacheObserver = void Function(ProductCacheOutcome outcome);

class ReadThroughProductRepository implements ProductRepository {
  ReadThroughProductRepository({
    required this.cache,
    required this.fallback,
    this.onCacheOutcome,
    this.failureThreshold = 3,
    this.failureCooldown = const Duration(minutes: 2),
    DateTime Function()? clock,
  }) : assert(failureThreshold > 0),
       _clock = clock ?? DateTime.now;

  final ProductCache cache;
  final ProductRepository fallback;
  final ProductCacheObserver? onCacheOutcome;

  /// Circuit Breaker (Audit-Finding F-15): nach so vielen Cache-Fehlern in
  /// Folge wird der Cache fuer [failureCooldown] uebersprungen, statt jeden
  /// Scan mit dem Cache-Timeout zu belasten.
  final int failureThreshold;
  final Duration failureCooldown;
  final DateTime Function() _clock;

  final List<ScanFairProduct> _recentProducts = [];
  var _consecutiveCacheFailures = 0;
  DateTime? _skipCacheUntil;

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) async {
    ProductCacheLookup? cached;
    ScanFairProduct? product;
    final skipUntil = _skipCacheUntil;
    if (skipUntil != null && _clock().isBefore(skipUntil)) {
      onCacheOutcome?.call(ProductCacheOutcome.skipped);
    } else {
      try {
        cached = await cache.findByBarcode(barcode);
        _consecutiveCacheFailures = 0;
        _skipCacheUntil = null;
        if (cached == null) {
          onCacheOutcome?.call(ProductCacheOutcome.miss);
        } else if (cached.isStale) {
          onCacheOutcome?.call(ProductCacheOutcome.stale);
        } else {
          onCacheOutcome?.call(ProductCacheOutcome.hit);
          product = cached.product;
        }
      } on ProductCacheFailure catch (failure) {
        _registerCacheFailure();
        onCacheOutcome?.call(_outcomeFor(failure.type));
      } on Object {
        // Der optionale Cache darf die Pflichtquelle nie mitreissen (FM-17):
        // auch unerwartete Fehler muessen im OFF-Fallback landen.
        _registerCacheFailure();
        onCacheOutcome?.call(ProductCacheOutcome.error);
      }
    }

    if (product == null) {
      try {
        product = await fallback.findByBarcode(barcode);
      } on ProductLookupFailure {
        // Ein veralteter Cache-Eintrag ist besser als gar keine Antwort:
        // gekennzeichnet servieren statt Fehler zeigen (ADR 0033).
        if (cached == null) rethrow;
        onCacheOutcome?.call(ProductCacheOutcome.staleServed);
        product = cached.product.withDataQualityWarning(
          ScanFairProduct.staleCacheWarning,
        );
      }
    }
    if (product == null) return null;

    _recentProducts.removeWhere((entry) => entry.barcode == product!.barcode);
    _recentProducts.insert(0, product);
    if (_recentProducts.length > 10) _recentProducts.removeLast();
    return product;
  }

  @override
  List<ScanFairProduct> recentProducts() {
    if (_recentProducts.isNotEmpty) {
      return List.unmodifiable(_recentProducts.take(3));
    }
    return fallback.recentProducts();
  }

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) {
    return fallback.suggestAlternativeFor(product);
  }

  void _registerCacheFailure() {
    _consecutiveCacheFailures += 1;
    if (_consecutiveCacheFailures >= failureThreshold) {
      _skipCacheUntil = _clock().add(failureCooldown);
    }
  }

  ProductCacheOutcome _outcomeFor(ProductCacheFailureType type) {
    return switch (type) {
      ProductCacheFailureType.stale => ProductCacheOutcome.stale,
      ProductCacheFailureType.invalidBarcode ||
      ProductCacheFailureType.invalidResponse =>
        ProductCacheOutcome.invalidResponse,
      ProductCacheFailureType.noConnection ||
      ProductCacheFailureType.timeout ||
      ProductCacheFailureType.rateLimited ||
      ProductCacheFailureType.server => ProductCacheOutcome.unavailable,
    };
  }
}

class CoffeePilotProductRepository implements ProductRepository {
  CoffeePilotProductRepository({
    required this.source,
    this.catalog = const CoffeePilotCatalog(),
  });

  final ProductRepository source;
  final CoffeePilotCatalog catalog;
  final List<ScanFairProduct> _recentProducts = [];

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) async {
    final normalized = barcode.trim();
    ScanFairProduct? sourceProduct;
    try {
      sourceProduct = await source.findByBarcode(normalized);
    } on ProductLookupFailure {
      if (catalog.definitionFor(normalized) == null) rethrow;
    }
    final product = catalog.enrichOrCreate(
      barcode: normalized,
      sourceProduct: sourceProduct,
    );
    if (product == null) return null;

    _recentProducts.removeWhere((entry) => entry.barcode == product.barcode);
    _recentProducts.insert(0, product);
    if (_recentProducts.length > 10) _recentProducts.removeLast();
    return product;
  }

  @override
  List<ScanFairProduct> recentProducts() {
    if (_recentProducts.isNotEmpty) {
      return List.unmodifiable(_recentProducts.take(3));
    }
    return source
        .recentProducts()
        .map(
          (product) =>
              catalog.enrichOrCreate(
                barcode: product.barcode,
                sourceProduct: product,
              ) ??
              product,
        )
        .take(3)
        .toList(growable: false);
  }

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) {
    final alternative = source.suggestAlternativeFor(product);
    if (alternative == null) return null;
    return catalog.enrichOrCreate(
          barcode: alternative.barcode,
          sourceProduct: alternative,
        ) ??
        alternative;
  }
}
