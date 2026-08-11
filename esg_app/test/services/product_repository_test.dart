import 'package:esg_app/models/product.dart';
import 'package:esg_app/services/product_lookup_failure.dart';
import 'package:esg_app/services/product_repository.dart';
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
