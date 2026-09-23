import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data_sources/open_food_facts_product_mapper.dart';
import '../models/product.dart';

/// Ergebnis eines Cache-Treffers: das Produkt plus Frische-Metadaten, damit
/// veraltete Daten gekennzeichnet statt verworfen werden (ADR 0033).
class ProductCacheLookup {
  const ProductCacheLookup({
    required this.product,
    required this.isStale,
    required this.expiresAt,
    this.fetchedAt,
  });

  final ScanFairProduct product;
  final bool isStale;
  final DateTime expiresAt;
  final DateTime? fetchedAt;
}

abstract class ProductCache {
  Future<ProductCacheLookup?> findByBarcode(String barcode);
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
  Future<ProductCacheLookup?> findByBarcode(String barcode) async {
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
    final fetchedAt = _parseTimestamp(row['fetched_at']);
    final staleAfter = _parseTimestamp(row['stale_after']);
    final expiresAt = _parseTimestamp(row['expires_at']);
    if (payload is! Map ||
        fetchedAt == null ||
        staleAfter == null ||
        expiresAt == null) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Die Cache-Antwort enthaelt nicht alle Pflichtfelder.',
      );
    }
    // Mirror the database freshness contract; malformed metadata is never fresh.
    if (!staleAfter.isAfter(fetchedAt) || staleAfter.isAfter(expiresAt)) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Die Frische-Zeitstempel des Caches sind widerspruechlich.',
      );
    }
    final now = _clock().toUtc();
    // Der Server liefert keine Zeilen nach expires_at; wenn doch eine
    // ankommt, ist das ein Uhren-/Serverproblem und zaehlt als Miss.
    if (!expiresAt.toUtc().isAfter(now)) return null;
    if (fetchedAt.toUtc().isAfter(now.add(const Duration(minutes: 5)))) {
      throw const ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Der Cache-Zeitstempel liegt unplausibel in der Zukunft.',
      );
    }

    try {
      final product = mapper.map(
        Map<String, Object?>.from(payload),
        barcode: normalized,
        retrievedAt: fetchedAt.toUtc(),
      );
      // Veraltete Daten werden gekennzeichnet serviert statt verworfen
      // (ADR 0033).
      final isStale = !now.isBefore(staleAfter);
      return ProductCacheLookup(
        product: product,
        isStale: isStale,
        expiresAt: expiresAt,
        fetchedAt: fetchedAt.toUtc(),
      );
    } on ProductCacheFailure {
      rethrow;
    } on Object catch (error) {
      throw ProductCacheFailure(
        type: ProductCacheFailureType.invalidResponse,
        message: 'Der Cache-Datensatz passt nicht zum erwarteten Schema.',
        cause: error,
      );
    }
  }

  static final _timestampPattern = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[Tt ](\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(?:[zZ]|[+-](\d{2}):(\d{2}))$',
  );

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String) return null;
    final match = _timestampPattern.firstMatch(value);
    if (match == null) return null;
    final parts = List.generate(
      6,
      (index) => int.parse(match.group(index + 1)!),
    );
    // DateTime.tryParse normalizes invalid dates (e.g. day 44). Reject that
    // normalization, and require the explicit timezone emitted by PostgREST.
    final wall = DateTime.utc(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
      parts[4],
      parts[5],
    );
    final normalized = [
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    ];
    for (var index = 0; index < parts.length; index++) {
      if (parts[index] != normalized[index]) return null;
    }
    if (match.group(7) != null &&
        (int.parse(match.group(7)!) > 23 || int.parse(match.group(8)!) > 59)) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
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
