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
}
