import 'dart:convert';

import 'package:esg_app/data_sources/open_food_facts_product_mapper.dart';
import 'package:esg_app/models/product.dart';
import 'package:esg_app/services/supabase_product_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final publishableKey = const [
    'sb',
    'publishable',
    'test-fixture-only-000000000000',
  ].join('_');
  final configuration = SupabaseProductCacheConfiguration.fromValues(
    projectUrl: 'https://project.supabase.co',
    publishableKey: publishableKey,
  )!;
  final now = DateTime.utc(2026, 8, 12, 12);

  test('accepts only complete HTTPS public cache configuration', () {
    expect(
      configuration.projectOrigin.toString(),
      'https://project.supabase.co',
    );
    expect(
      SupabaseProductCacheConfiguration.fromValues(
        projectUrl: '',
        publishableKey: '',
      ),
      isNull,
    );
    expect(
      () => SupabaseProductCacheConfiguration.fromValues(
        projectUrl: 'http://project.supabase.co',
        publishableKey: publishableKey,
      ),
      throwsFormatException,
    );
    expect(
      () => SupabaseProductCacheConfiguration.fromValues(
        projectUrl: 'https://project.supabase.co',
        publishableKey: 'sb_secret_not_allowed_in_a_mobile_build',
      ),
      throwsFormatException,
    );
  });

  test('maps one fresh cache row through the OFF mapper', () async {
    late http.Request captured;
    final service = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode([
            {
              'payload': {
                'code': '4000417025005',
                'product_name': 'Cached product',
                'brands': 'Cache brand',
                'environmental_score_score': 73,
              },
              'fetched_at': '2026-08-12T11:00:00Z',
              'stale_after': '2026-08-13T11:00:00Z',
              'expires_at': '2026-08-19T11:00:00Z',
              'source_schema_version': 'v3',
            },
          ]),
          200,
        );
      }),
    );

    final lookup = await service.findByBarcode('4000417025005');

    expect(lookup!.product.name, 'Cached product');
    expect(lookup.product.ecoscoreScore, 73);
    expect(lookup.isStale, isFalse);
    expect(lookup.fetchedAt, DateTime.utc(2026, 8, 12, 11));
    expect(lookup.expiresAt, DateTime.utc(2026, 8, 19, 11));
    expect(captured.method, 'POST');
    expect(captured.url.path, '/rest/v1/rpc/get_fresh_cached_product');
    expect(captured.headers['apikey'], publishableKey);
    expect(captured.headers.containsKey('authorization'), isFalse);
    expect(jsonDecode(captured.body), {
      'p_source_id': 'open-food-facts',
      'p_barcode': '4000417025005',
    });
  });

  test('returns null for a cache miss', () async {
    final service = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      client: MockClient((_) async => http.Response('[]', 200)),
    );

    expect(await service.findByBarcode('4000417025005'), isNull);
  });

  for (final scenario in <String, Object?>{
    'missing': null,
    'null': null,
    'empty': '',
    'malformed': 'not-a-timestamp',
    'wrong type': 20260813,
    'calendar overflow': '2026-07-44T11:00:00Z',
    'hour overflow': '2026-08-12T25:00:00Z',
    'missing timezone': '2026-08-13T11:00:00',
    'date only': '2026-08-13',
    'before fetch': '2026-08-12T10:00:00Z',
    'equal to fetch': '2026-08-12T11:00:00Z',
    'after expiry': '2026-08-20T11:00:00Z',
  }.entries) {
    test('rejects ${scenario.key} stale_after as invalidResponse', () async {
      final row = <String, Object?>{
        'payload': {'product_name': 'Untrusted freshness'},
        'fetched_at': '2026-08-12T11:00:00Z',
        'expires_at': '2026-08-19T11:00:00Z',
        if (scenario.key != 'missing') 'stale_after': scenario.value,
      };
      final service = SupabaseProductCacheService(
        configuration: configuration,
        clock: () => now,
        client: MockClient((_) async => http.Response(jsonEncode([row]), 200)),
      );
      await expectLater(
        service.findByBarcode('4000417025005'),
        throwsA(
          isA<ProductCacheFailure>().having(
            (failure) => failure.type,
            'type',
            ProductCacheFailureType.invalidResponse,
          ),
        ),
      );
    });
  }

  test('labels stale cache rows inside the hard expiry window', () async {
    final service = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'payload': {'product_name': 'Stale product'},
              'fetched_at': '2026-08-10T11:00:00Z',
              'stale_after': '2026-08-11T11:00:00Z',
              'expires_at': '2026-08-17T11:00:00Z',
            },
          ]),
          200,
        ),
      ),
    );

    final lookup = await service.findByBarcode('4000417025005');

    expect(lookup!.isStale, isTrue);
    expect(lookup.product.name, 'Stale product');
  });

  for (final scenario in [
    (
      label: 'just before stale',
      at: now.subtract(const Duration(microseconds: 1)),
      stale: false,
    ),
    (label: 'exact stale boundary', at: now, stale: true),
    (
      label: 'exact hard expiry',
      at: now.add(const Duration(hours: 1)),
      stale: true,
    ),
  ]) {
    test('honors ${scenario.label}', () async {
      final service = SupabaseProductCacheService(
        configuration: configuration,
        clock: () => scenario.at,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              {
                'payload': {'product_name': 'Boundary product'},
                'fetched_at': '2026-08-12T11:00:00Z',
                'stale_after': now.toIso8601String(),
                'expires_at': now
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
              },
            ]),
            200,
          ),
        ),
      );
      final lookup = await service.findByBarcode('4000417025005');
      if (scenario.label == 'exact hard expiry') {
        expect(lookup, isNull);
      } else {
        expect(lookup!.isStale, scenario.stale);
      }
    });
  }

  test('allows stale_after equal to hard expiry before the deadline', () async {
    final service = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'payload': {'product_name': 'Short lived product'},
              'fetched_at': '2026-08-12T11:00:00Z',
              'stale_after': '2026-08-12T13:00:00Z',
              'expires_at': '2026-08-12T13:00:00Z',
            },
          ]),
          200,
        ),
      ),
    );
    expect((await service.findByBarcode('4000417025005'))!.isStale, isFalse);
  });

  test('normalizes explicit timezone offsets and fractional seconds', () async {
    final service = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'payload': {'product_name': 'Offset product'},
              'fetched_at': '2026-08-12T13:00:00.123456+02:00',
              'stale_after': '2026-08-12T14:00:00+02:00',
              'expires_at': '2026-08-12T15:00:00+02:00',
            },
          ]),
          200,
        ),
      ),
    );
    final lookup = await service.findByBarcode('4000417025005');
    expect(lookup!.isStale, isTrue);
    expect(lookup.fetchedAt, DateTime.utc(2026, 8, 12, 11, 0, 0, 123, 456));
    expect(lookup.expiresAt, DateTime.utc(2026, 8, 12, 13));
  });

  test('treats rows past the hard expiry as a miss', () async {
    final service = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'payload': {'product_name': 'Expired product'},
              'fetched_at': '2026-08-01T11:00:00Z',
              'stale_after': '2026-08-02T11:00:00Z',
              'expires_at': '2026-08-08T11:00:00Z',
            },
          ]),
          200,
        ),
      ),
    );

    expect(await service.findByBarcode('4000417025005'), isNull);
  });

  test(
    'classifies offline and server failures for fallback handling',
    () async {
      final offline = SupabaseProductCacheService(
        configuration: configuration,
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final server = SupabaseProductCacheService(
        configuration: configuration,
        client: MockClient((_) async => http.Response('{}', 503)),
      );

      await expectLater(
        offline.findByBarcode('4000417025005'),
        throwsA(
          isA<ProductCacheFailure>().having(
            (failure) => failure.type,
            'type',
            ProductCacheFailureType.noConnection,
          ),
        ),
      );
      await expectLater(
        server.findByBarcode('4000417025005'),
        throwsA(
          isA<ProductCacheFailure>().having(
            (failure) => failure.type,
            'type',
            ProductCacheFailureType.server,
          ),
        ),
      );
    },
  );

  test('rejects malformed, multiple and oversized cache responses', () async {
    final malformed = SupabaseProductCacheService(
      configuration: configuration,
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    final multiple = SupabaseProductCacheService(
      configuration: configuration,
      client: MockClient((_) async => http.Response('[{},{}]', 200)),
    );
    final oversized = SupabaseProductCacheService(
      configuration: configuration,
      maximumResponseBytes: 2,
      client: MockClient((_) async => http.Response('[] ', 200)),
    );
    final mapperFailure = SupabaseProductCacheService(
      configuration: configuration,
      clock: () => now,
      mapper: const _ThrowingMapper(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'payload': {'product_name': 'Schema drift'},
              'fetched_at': '2026-08-12T11:00:00Z',
              'stale_after': '2026-08-13T11:00:00Z',
              'expires_at': '2026-08-13T11:00:00Z',
            },
          ]),
          200,
        ),
      ),
    );

    for (final service in [malformed, multiple, oversized, mapperFailure]) {
      await expectLater(
        service.findByBarcode('4000417025005'),
        throwsA(isA<ProductCacheFailure>()),
      );
    }
  });
}

class _ThrowingMapper extends OpenFoodFactsProductMapper {
  const _ThrowingMapper();

  @override
  ScanFairProduct map(
    Map<String, Object?> json, {
    required String barcode,
    required DateTime retrievedAt,
  }) {
    throw const FormatException('simulated source schema drift');
  }
}
