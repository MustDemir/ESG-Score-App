import '../data/demo_products.dart';
import '../models/product.dart';

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
