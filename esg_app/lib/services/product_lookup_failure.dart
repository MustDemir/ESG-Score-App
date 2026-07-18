enum ProductLookupFailureType {
  invalidBarcode,
  noConnection,
  timeout,
  rateLimited,
  server,
  invalidResponse,
}

class ProductLookupFailure implements Exception {
  const ProductLookupFailure({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final ProductLookupFailureType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  bool get canRetry => switch (type) {
    ProductLookupFailureType.noConnection ||
    ProductLookupFailureType.timeout ||
    ProductLookupFailureType.rateLimited ||
    ProductLookupFailureType.server => true,
    ProductLookupFailureType.invalidBarcode ||
    ProductLookupFailureType.invalidResponse => false,
  };

  @override
  String toString() => 'ProductLookupFailure($type): $message';
}
