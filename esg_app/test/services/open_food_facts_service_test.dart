import 'dart:convert';

import 'package:esg_app/services/open_food_facts_service.dart';
import 'package:esg_app/services/product_lookup_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('maps a v3 product response and sends required headers', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'result': {'id': 'product_found'},
          'product': {
            'product_name': 'Test Schokolade',
            'brands': 'ScanFair Test',
            'categories_tags': ['en:dark-chocolates'],
            'environmental_score_grade': 'b',
            'environmental_score_score': 72,
            'environmental_score_data': {
              'agribalyse': {'co2_total': 3.4},
            },
            'labels_tags': ['en:organic'],
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = OpenFoodFactsService(client: client);

    final product = await service.findByBarcode('4000417025005');

    expect(product, isNotNull);
    expect(product!.name, 'Test Schokolade');
    expect(product.ecoscoreGrade, 'b');
    expect(product.ecoscoreScore, 72);
    expect(product.co2Total, 3.4);
    expect(capturedRequest.url.scheme, 'https');
    expect(capturedRequest.url.path, '/api/v3/product/4000417025005.json');
    expect(capturedRequest.headers['User-Agent'], contains('ScanFair/0.1'));
    expect(
      capturedRequest.url.queryParameters['fields'],
      contains('product_name'),
    );
  });

  test('keeps compatibility with legacy ecoscore fields', () async {
    final service = OpenFoodFactsService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'success',
            'product': {
              'product_name': 'Legacy Product',
              'brands': 'Legacy Brand',
              'ecoscore_grade': 'c',
              'ecoscore_score': 54,
              'ecoscore_data': {
                'agribalyse': {'co2_total': 2.2},
              },
            },
          }),
          200,
        ),
      ),
    );

    final product = await service.findByBarcode('4000417025005');

    expect(product!.ecoscoreGrade, 'c');
    expect(product.ecoscoreScore, 54);
    expect(product.co2Total, 2.2);
  });

  test('returns null when Open Food Facts returns 404', () async {
    final service = OpenFoodFactsService(
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(await service.findByBarcode('0000000000000'), isNull);
  });

  test('retries temporary server errors with exponential backoff', () async {
    var attempts = 0;
    final delays = <Duration>[];
    final service = OpenFoodFactsService(
      client: MockClient((_) async {
        attempts++;
        if (attempts < 3) return http.Response('', 503);
        return http.Response(
          jsonEncode({
            'status': 'success',
            'product': {'product_name': 'Recovered Product', 'brands': 'Test'},
          }),
          200,
        );
      }),
      retryBaseDelay: const Duration(milliseconds: 100),
      delay: (duration) async => delays.add(duration),
    );

    final product = await service.findByBarcode('4000417025005');

    expect(product!.name, 'Recovered Product');
    expect(attempts, 3);
    expect(delays, [
      const Duration(milliseconds: 100),
      const Duration(milliseconds: 200),
    ]);
  });

  test('classifies a timeout after the configured attempts', () async {
    var attempts = 0;
    final service = OpenFoodFactsService(
      client: MockClient((_) async {
        attempts++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
      requestTimeout: const Duration(milliseconds: 1),
      maxAttempts: 2,
      retryBaseDelay: Duration.zero,
      delay: (_) async {},
    );

    await expectLater(
      service.findByBarcode('4000417025005'),
      throwsA(
        isA<ProductLookupFailure>().having(
          (failure) => failure.type,
          'type',
          ProductLookupFailureType.timeout,
        ),
      ),
    );
    expect(attempts, 2);
  });

  test('rejects malformed barcodes without sending a request', () async {
    var requests = 0;
    final service = OpenFoodFactsService(
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service.findByBarcode('ABC-123'),
      throwsA(
        isA<ProductLookupFailure>().having(
          (failure) => failure.type,
          'type',
          ProductLookupFailureType.invalidBarcode,
        ),
      ),
    );
    expect(requests, 0);
  });

  test('does not retry malformed JSON', () async {
    var attempts = 0;
    final service = OpenFoodFactsService(
      client: MockClient((_) async {
        attempts++;
        return http.Response('not-json', 200);
      }),
      delay: (_) async {},
    );

    await expectLater(
      service.findByBarcode('4000417025005'),
      throwsA(
        isA<ProductLookupFailure>().having(
          (failure) => failure.type,
          'type',
          ProductLookupFailureType.invalidResponse,
        ),
      ),
    );
    expect(attempts, 1);
  });
}
