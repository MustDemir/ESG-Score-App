import 'package:esg_app/models/product.dart';
import 'package:esg_app/services/product_lookup_failure.dart';
import 'package:esg_app/services/product_repository.dart';
import 'package:esg_app/services/supabase_product_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoProductRepository repository;

  setUp(() {
    repository = DemoProductRepository();
  });

  test('finds known demo product by barcode', () async {
    final product = await repository.findByBarcode('4000417025005');

    expect(product, isNotNull);
    expect(product!.name, contains('Schokolade'));
  });

  test('returns null for unknown barcode', () async {
    final product = await repository.findByBarcode('0000000000000');

    expect(product, isNull);
  });

  test('suggests an alternative in the same local product scope', () async {
    final product = await repository.findByBarcode('4337185353659');

    final alternative = repository.suggestAlternativeFor(product!);

    expect(alternative, isNotNull);
    expect(alternative!.barcode, isNot(product.barcode));
  });

  test('coffee pilot repository provides a declared local fallback', () async {
    final pilotRepository = CoffeePilotProductRepository(source: repository);

    final product = await pilotRepository.findByBarcode('4013320225196');

    expect(product, isNotNull);
    expect(product!.name, contains('Kolumbien'));
    expect(product.hasScoreEligibleCommodityOrigin, isTrue);
    expect(pilotRepository.recentProducts().single.barcode, product.barcode);
  });

  test(
    'coffee pilot repository does not synthesize unknown products',
    () async {
      final pilotRepository = CoffeePilotProductRepository(source: repository);

      final product = await pilotRepository.findByBarcode('0000000000000');

      expect(product, isNull);
    },
  );

  test('coffee pilot repository falls back when OFF lookup fails', () async {
    final pilotRepository = CoffeePilotProductRepository(
      source: const _FailingProductRepository(),
    );

    final product = await pilotRepository.findByBarcode('4013320225196');

    expect(product, isNotNull);
    expect(product!.name, contains('Kolumbien'));
    expect(product.dataQualityWarnings, contains('pilot-source-fallback'));
  });

  test('coffee pilot repository rethrows failures for unknown GTINs', () {
    final pilotRepository = CoffeePilotProductRepository(
      source: const _FailingProductRepository(),
    );

    expect(
      () => pilotRepository.findByBarcode('0000000000000'),
      throwsA(isA<ProductLookupFailure>()),
    );
  });

  test(
    'read-through repository uses a fresh cache hit without fallback',
    () async {
      final fallback = _TrackingProductRepository(repository);
      final outcomes = <ProductCacheOutcome>[];
      final readThrough = ReadThroughProductRepository(
        cache: _FixedProductCache(
          await repository.findByBarcode('4000417025005'),
        ),
        fallback: fallback,
        onCacheOutcome: outcomes.add,
      );

      final product = await readThrough.findByBarcode('4000417025005');

      expect(product, isNotNull);
      expect(fallback.lookups, 0);
      expect(outcomes, [ProductCacheOutcome.hit]);
    },
  );

  test(
    'read-through repository survives unexpected cache exceptions',
    () async {
      final fallback = _TrackingProductRepository(repository);
      final outcomes = <ProductCacheOutcome>[];
      final readThrough = ReadThroughProductRepository(
        cache: const _ThrowingProductCache(),
        fallback: fallback,
        onCacheOutcome: outcomes.add,
      );

      final product = await readThrough.findByBarcode('4000417025005');

      expect(product, isNotNull);
      expect(fallback.lookups, 1);
      expect(outcomes, [ProductCacheOutcome.error]);
    },
  );

  test(
    'read-through repository falls back on miss, stale and offline',
    () async {
      final staleProduct = await repository.findByBarcode('4000417025005');
      for (final scenario in [
        (
          cache: const _FixedProductCache(null),
          outcome: ProductCacheOutcome.miss,
        ),
        (
          cache: _FixedProductCache(staleProduct, isStale: true),
          outcome: ProductCacheOutcome.stale,
        ),
        (
          cache: const _FailingProductCache(
            ProductCacheFailureType.noConnection,
          ),
          outcome: ProductCacheOutcome.unavailable,
        ),
      ]) {
        final fallback = _TrackingProductRepository(repository);
        final outcomes = <ProductCacheOutcome>[];
        final readThrough = ReadThroughProductRepository(
          cache: scenario.cache,
          fallback: fallback,
          onCacheOutcome: outcomes.add,
        );

        final product = await readThrough.findByBarcode('4000417025005');

        expect(product, isNotNull);
        expect(fallback.lookups, 1);
        expect(outcomes.first, scenario.outcome);
      }
    },
  );

  test('read-through repository serves a labeled stale row when the '
      'fallback fails (ADR 0033)', () async {
    final staleProduct = await repository.findByBarcode('4000417025005');
    final outcomes = <ProductCacheOutcome>[];
    final readThrough = ReadThroughProductRepository(
      cache: _FixedProductCache(staleProduct, isStale: true),
      fallback: const _FailingProductRepository(),
      onCacheOutcome: outcomes.add,
    );

    final product = await readThrough.findByBarcode('4000417025005');

    expect(product, isNotNull);
    expect(product!.servedFromStaleCache, isTrue);
    expect(outcomes, [
      ProductCacheOutcome.stale,
      ProductCacheOutcome.staleServed,
    ]);
  });

  test(
    'read-through repository skips the cache after repeated failures',
    () async {
      var nowMillis = 0;
      final outcomes = <ProductCacheOutcome>[];
      final readThrough = ReadThroughProductRepository(
        cache: const _FailingProductCache(ProductCacheFailureType.timeout),
        fallback: repository,
        onCacheOutcome: outcomes.add,
        failureThreshold: 2,
        failureCooldown: const Duration(minutes: 2),
        clock: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
      );

      // Zwei Fehlversuche oeffnen den Breaker …
      await readThrough.findByBarcode('4000417025005');
      await readThrough.findByBarcode('4000417025005');
      // … der dritte Lookup ueberspringt den Cache …
      await readThrough.findByBarcode('4000417025005');
      // … und nach Ablauf des Cooldowns wird er wieder versucht.
      nowMillis = const Duration(minutes: 3).inMilliseconds;
      await readThrough.findByBarcode('4000417025005');

      expect(outcomes, [
        ProductCacheOutcome.unavailable,
        ProductCacheOutcome.unavailable,
        ProductCacheOutcome.skipped,
        ProductCacheOutcome.unavailable,
      ]);
    },
  );

  test('read-through repository rethrows the fallback failure without any '
      'cached row', () async {
    final readThrough = ReadThroughProductRepository(
      cache: const _FixedProductCache(null),
      fallback: const _FailingProductRepository(),
    );

    expect(
      () => readThrough.findByBarcode('4000417025005'),
      throwsA(isA<ProductLookupFailure>()),
    );
  });
}

class _FixedProductCache implements ProductCache {
  const _FixedProductCache(this.product, {this.isStale = false});

  final ScanFairProduct? product;
  final bool isStale;

  @override
  Future<ProductCacheLookup?> findByBarcode(String barcode) async {
    if (product == null) return null;
    return ProductCacheLookup(product: product!, isStale: isStale);
  }
}

class _ThrowingProductCache implements ProductCache {
  const _ThrowingProductCache();

  @override
  Future<ProductCacheLookup?> findByBarcode(String barcode) {
    throw StateError('unexpected cache bug');
  }
}

class _FailingProductCache implements ProductCache {
  const _FailingProductCache(this.type);

  final ProductCacheFailureType type;

  @override
  Future<ProductCacheLookup?> findByBarcode(String barcode) {
    throw ProductCacheFailure(type: type, message: 'cache test failure');
  }
}

class _TrackingProductRepository implements ProductRepository {
  _TrackingProductRepository(this.delegate);

  final ProductRepository delegate;
  int lookups = 0;

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) {
    lookups += 1;
    return delegate.findByBarcode(barcode);
  }

  @override
  List<ScanFairProduct> recentProducts() => delegate.recentProducts();

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) {
    return delegate.suggestAlternativeFor(product);
  }
}

class _FailingProductRepository implements ProductRepository {
  const _FailingProductRepository();

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) {
    throw const ProductLookupFailure(
      type: ProductLookupFailureType.server,
      message: 'Open Food Facts ist voruebergehend nicht verfuegbar.',
    );
  }

  @override
  List<ScanFairProduct> recentProducts() => const [];

  @override
  ScanFairProduct? suggestAlternativeFor(ScanFairProduct product) => null;
}
