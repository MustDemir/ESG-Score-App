import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data_sources/open_food_facts_product_mapper.dart';
import '../models/product.dart';
import 'product_lookup_failure.dart';

typedef RetryDelay = Future<void> Function(Duration duration);

class OpenFoodFactsService {
  OpenFoodFactsService({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 8),
    this.maxAttempts = 3,
    this.retryBaseDelay = const Duration(milliseconds: 250),
    this.userAgent = defaultUserAgent,
    this.mapper = const OpenFoodFactsProductMapper(),
    RetryDelay? delay,
  }) : assert(maxAttempts > 0),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _delay = delay ?? _defaultDelay;

  static const defaultUserAgent =
      'ScanFair/0.1 (https://github.com/MustDemir/ESG-Score-App)';

  static const _host = 'world.openfoodfacts.org';
  static const _fields = <String>[
    'code',
    'product_name',
    'brands',
    'categories_tags',
    'image_front_small_url',
    'environmental_score_grade',
    'environmental_score_score',
    'environmental_score_data',
    'ecoscore_grade',
    'ecoscore_score',
    'ecoscore_data',
    'ingredients',
    'ingredients_text',
    'nutrition_grades',
    'nutriscore_grade',
    'nutriments',
    'nova_group',
    'nova_groups',
    'packaging_tags',
    'origins_tags',
    'labels_tags',
    'data_quality_tags',
    'data_quality_warnings_tags',
    'schema_version',
    'last_modified_t',
    'last_updated_t',
  ];

  final http.Client _client;
  final bool _ownsClient;
  final RetryDelay _delay;
  final Duration requestTimeout;
  final int maxAttempts;
  final Duration retryBaseDelay;
  final String userAgent;
  final OpenFoodFactsProductMapper mapper;

  Future<ScanFairProduct?> findByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (!RegExp(r'^\d{8,14}$').hasMatch(normalized)) {
      throw const ProductLookupFailure(
        type: ProductLookupFailureType.invalidBarcode,
        message: 'Der Barcode muss aus 8 bis 14 Ziffern bestehen.',
      );
    }

    ProductLookupFailure? lastFailure;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _requestProduct(normalized);
      } on ProductLookupFailure catch (failure) {
        lastFailure = failure;
        if (!failure.canRetry || attempt == maxAttempts) rethrow;
      } on TimeoutException catch (error) {
        lastFailure = ProductLookupFailure(
          type: ProductLookupFailureType.timeout,
          message: 'Open Food Facts hat nicht rechtzeitig geantwortet.',
          cause: error,
        );
        if (attempt == maxAttempts) throw lastFailure;
      } on http.ClientException catch (error) {
        lastFailure = ProductLookupFailure(
          type: ProductLookupFailureType.noConnection,
          message: 'Open Food Facts ist momentan nicht erreichbar.',
          cause: error,
        );
        if (attempt == maxAttempts) throw lastFailure;
      }

      await _delay(_backoffFor(attempt));
    }

    throw lastFailure!;
  }

  Future<ScanFairProduct?> _requestProduct(String barcode) async {
    final uri = Uri.https(_host, '/api/v3/product/$barcode.json', {
      'fields': _fields.join(','),
    });
    final response = await _client
        .get(
          uri,
          headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
        )
        .timeout(requestTimeout);

    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) {
      throw ProductLookupFailure(
        type: ProductLookupFailureType.rateLimited,
        message: 'Zu viele Produktabfragen. Bitte kurz warten.',
        statusCode: response.statusCode,
      );
    }
    if (_isTemporaryServerError(response.statusCode)) {
      throw ProductLookupFailure(
        type: ProductLookupFailureType.server,
        message: 'Open Food Facts ist voruebergehend nicht verfuegbar.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != 200) {
      throw ProductLookupFailure(
        type: ProductLookupFailureType.invalidResponse,
        message: 'Unerwartete Antwort von Open Food Facts.',
        statusCode: response.statusCode,
      );
    }

    final Map<String, Object?> payload;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const FormatException('Expected JSON object');
      payload = Map<String, Object?>.from(decoded);
    } on FormatException catch (error) {
      throw ProductLookupFailure(
        type: ProductLookupFailureType.invalidResponse,
        message: 'Open Food Facts hat unlesbare Produktdaten geliefert.',
        cause: error,
      );
    }

    final product = payload['product'];
    if (product is Map) {
      return mapper.map(
        Map<String, Object?>.from(product),
        barcode: barcode,
        retrievedAt: DateTime.now().toUtc(),
      );
    }

    final result = payload['result'];
    final resultMap = result is Map ? Map<String, Object?>.from(result) : null;
    if (resultMap?['id'] == 'product_not_found') return null;

    throw const ProductLookupFailure(
      type: ProductLookupFailureType.invalidResponse,
      message: 'Die Produktantwort enthaelt keine Produktdaten.',
    );
  }

  Duration _backoffFor(int completedAttempt) {
    return retryBaseDelay * (1 << (completedAttempt - 1));
  }

  bool _isTemporaryServerError(int statusCode) {
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  static Future<void> _defaultDelay(Duration duration) {
    return Future<void>.delayed(duration);
  }
}
