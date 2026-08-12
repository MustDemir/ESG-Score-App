import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data_sources/open_food_facts_product_mapper.dart';
import '../models/product.dart';

abstract class ProductCache {
  Future<ScanFairProduct?> findByBarcode(String barcode);
}

enum ProductCacheFailureType {
  invalidBarcode,
  noConnection,
  timeout,
  rateLimited,
  server,
  invalidResponse,
  stale,
}

class ProductCacheFailure implements Exception {
  const ProductCacheFailure({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final ProductCacheFailureType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'ProductCacheFailure($type, $message)';
}

class SupabaseProductCacheConfiguration {
  const SupabaseProductCacheConfiguration._({
    required this.projectOrigin,
    required this.publishableKey,
  });

  final Uri projectOrigin;
  final String publishableKey;

  static SupabaseProductCacheConfiguration? fromValues({
    required String projectUrl,
    required String publishableKey,
  }) {
    final normalizedUrl = projectUrl.trim();
    final normalizedKey = publishableKey.trim();
    if (normalizedUrl.isEmpty && normalizedKey.isEmpty) return null;
    if (normalizedUrl.isEmpty || normalizedKey.isEmpty) {
      throw const FormatException(
        'Supabase cache URL and publishable key must be configured together.',
      );
    }

    final origin = Uri.tryParse(normalizedUrl);
    if (origin == null ||
        origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.hasPort ||
        origin.userInfo.isNotEmpty ||
        origin.query.isNotEmpty ||
        origin.fragment.isNotEmpty ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw const FormatException(
        'Supabase cache URL must be an HTTPS project origin.',
      );
    }
    if (!_isPublishableKey(normalizedKey)) {
      throw const FormatException(
        'Only a Supabase publishable or legacy anon key is accepted.',
      );
    }

    return SupabaseProductCacheConfiguration._(
      projectOrigin: origin.replace(path: ''),
      publishableKey: normalizedKey,
    );
  }

  static bool _isPublishableKey(String key) {
    if (key.startsWith('sb_publishable_') && key.length >= 24) return true;
    final segments = key.split('.');
    if (segments.length != 3) return false;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map && decoded['role'] == 'anon';
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }
}

class SupabaseProductCacheService implements ProductCache {
  SupabaseProductCacheService({
    required this.configuration,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 4),
    this.maximumResponseBytes = 1100000,
    this.mapper = const OpenFoodFactsProductMapper(),
    DateTime Function()? clock,
  }) : assert(maximumResponseBytes > 0),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _clock = clock ?? DateTime.now;

  final SupabaseProductCacheConfiguration configuration;
  final Duration requestTimeout;
  final int maximumResponseBytes;
  final OpenFoodFactsProductMapper mapper;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _clock;

  @override
  Future<ScanFairProduct?> findByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (!RegExp(r'^\d{8,14}$').hasMatch(normalized)) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidBarcode,
        message: 'Der Barcode muss aus 8 bis 14 Ziffern bestehen.',
      );
    }

    final uri = configuration.projectOrigin.replace(
      pathSegments: const ['rest', 'v1', 'rpc', 'get_fresh_cached_product'],
    );
    final _BoundedCacheResponse response;
    try {
      response = await _request(
        uri,
        body: jsonEncode({
          'p_source_id': 'open-food-facts',
          'p_barcode': normalized,
        }),
      ).timeout(requestTimeout);
    } on TimeoutException catch (error) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.timeout,
        message: 'Der ScanFair-Datencache antwortet nicht rechtzeitig.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.noConnection,
        message: 'Der ScanFair-Datencache ist momentan nicht erreichbar.',
        cause: error,
      );
    }

    if (response.statusCode == 429) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.rateLimited,
        message: 'Der ScanFair-Datencache begrenzt die Anfrage momentan.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 500) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.server,
        message: 'Der ScanFair-Datencache ist voruebergehend nicht verfuegbar.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != 200) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Der ScanFair-Datencache hat die Anfrage abgelehnt.',
        statusCode: response.statusCode,
      );
    }
    final List<Object?> rows;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) throw const FormatException('Expected JSON list');
      rows = List<Object?>.from(decoded);
    } on FormatException catch (error) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Der ScanFair-Datencache hat unlesbare Daten geliefert.',
        cause: error,
      );
    }
    if (rows.isEmpty) return null;
    if (rows.length != 1 || rows.single is! Map) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Die Cache-Antwort verletzt die Einzeldatensatz-Grenze.',
      );
    }

    final row = Map<String, Object?>.from(rows.single as Map);
    final payload = row['payload'];
    final fetchedAt = DateTime.tryParse(row['fetched_at']?.toString() ?? '');
    final expiresAt = DateTime.tryParse(row['expires_at']?.toString() ?? '');
    if (payload is! Map || fetchedAt == null || expiresAt == null) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Die Cache-Antwort enthaelt nicht alle Pflichtfelder.',
      );
    }
    final now = _clock().toUtc();
    if (!expiresAt.toUtc().isAfter(now)) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.stale,
        message: 'Der gespeicherte Produktdatensatz ist abgelaufen.',
      );
    }
    if (fetchedAt.toUtc().isAfter(now.add(const Duration(minutes: 5)))) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Der Cache-Zeitstempel liegt unplausibel in der Zukunft.',
      );
    }

    try {
      return mapper.map(
        Map<String, Object?>.from(payload),
        barcode: normalized,
        retrievedAt: fetchedAt.toUtc(),
      );
    } on Object catch (error) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Der Cache-Datensatz passt nicht zum erwarteten Schema.',
        cause: error,
      );
    }
  }

  Future<_BoundedCacheResponse> _request(
    Uri uri, {
    required String body,
  }) async {
    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'apikey': configuration.publishableKey,
      })
      ..body = body;
    final response = await _client.send(request);
    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maximumResponseBytes) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Die Cache-Antwort ist groesser als erlaubt.',
      );
    }

    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maximumResponseBytes) {
        throw const ProductCacheFailure(
          type: ProductCacheFailureType.invalidResponse,
          message: 'Die Cache-Antwort ist groesser als erlaubt.',
        );
      }
      bytes.add(chunk);
    }
    return _BoundedCacheResponse(
      statusCode: response.statusCode,
      bodyBytes: bytes.takeBytes(),
    );
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class _BoundedCacheResponse {
  const _BoundedCacheResponse({
    required this.statusCode,
    required this.bodyBytes,
  });

  final int statusCode;
  final Uint8List bodyBytes;
}
