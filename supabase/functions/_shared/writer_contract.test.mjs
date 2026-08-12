import assert from 'node:assert/strict';
import test from 'node:test';

import {
  WriterContractError,
  auditOutcomeForFailure,
  authenticateWriter,
  buildOpenFoodFactsUrl,
  canonicalJson,
  fetchOpenFoodFactsProduct,
  parseWriterRequest,
  sha256Hex,
  sourceObservedAt,
  validateUpstreamUrl,
} from './writer_contract.mjs';

const validBody = {
  barcodes: ['4000417025005'],
  correlation_id: 'correlation-001',
  request_id: 'request-001',
  source_id: 'open-food-facts',
};

function writerRequest(body = validBody, headers = {}) {
  return new Request('https://writer.example.test/ingest-products', {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
}

test('authenticates only a named actor with the exact secret', async () => {
  assert.equal(
    await authenticateWriter({
      actor: 'scheduled_ingestion_job',
      candidate: 'correct-secret',
      expected: 'correct-secret',
    }),
    'scheduled_ingestion_job',
  );
  await assert.rejects(
    authenticateWriter({
      actor: 'mobile_application',
      candidate: 'correct-secret',
      expected: 'correct-secret',
    }),
    (error) => error.code === 'writer_unauthorized' && error.statusCode === 401,
  );
  await assert.rejects(
    authenticateWriter({
      actor: 'scheduled_ingestion_job',
      candidate: 'wrong-secret',
      expected: 'correct-secret',
    }),
    (error) => error.code === 'writer_unauthorized',
  );
});

test('parses a bounded allowlisted request', async () => {
  const parsed = await parseWriterRequest(writerRequest());
  assert.deepEqual(parsed.barcodes, ['4000417025005']);
  assert.equal(parsed.sourceId, 'open-food-facts');
});

test('rejects unknown fields, duplicate barcodes and oversized bodies', async () => {
  await assert.rejects(
    parseWriterRequest(writerRequest({ ...validBody, arbitrary_url: 'http://127.0.0.1' })),
    (error) => error.code === 'unknown_or_missing_fields',
  );
  await assert.rejects(
    parseWriterRequest(
      writerRequest({
        ...validBody,
        barcodes: ['4000417025005', '4000417025005'],
      }),
    ),
    (error) => error.code === 'duplicate_barcodes',
  );
  await assert.rejects(
    parseWriterRequest(writerRequest(validBody, { 'content-length': '65537' })),
    (error) => error.code === 'request_too_large' && error.statusCode === 413,
  );
  await assert.rejects(
    parseWriterRequest(
      new Request('https://writer.example.test/ingest-products', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: 'x'.repeat(65_537),
      }),
    ),
    (error) => error.code === 'request_too_large' && error.statusCode === 413,
  );
});

test('builds only the fixed HTTPS Open Food Facts target', () => {
  const url = buildOpenFoodFactsUrl('4000417025005');
  assert.equal(url.protocol, 'https:');
  assert.equal(url.hostname, 'world.openfoodfacts.org');
  assert.match(url.pathname, /4000417025005/);
  assert.throws(
    () => validateUpstreamUrl('http://127.0.0.1/internal'),
    (error) => error.code === 'upstream_not_allowed',
  );
  assert.throws(
    () => validateUpstreamUrl('https://world.openfoodfacts.org.evil.test/product'),
    (error) => error.code === 'upstream_not_allowed',
  );
});

test('accepts a valid product and removes unsupported upstream fields', async () => {
  const product = await fetchOpenFoodFactsProduct({
    barcode: '4000417025005',
    fetchImpl: async (_url, options) => {
      assert.equal(options.redirect, 'manual');
      return Response.json({
        product: {
          code: '4000417025005',
          product_name: 'Test product',
          brands: 'Test',
          injected_admin_flag: true,
        },
      });
    },
  });
  assert.equal(product.product_name, 'Test product');
  assert.equal('injected_admin_flag' in product, false);
});

test('retries bounded temporary failures and then succeeds', async () => {
  let attempts = 0;
  const delays = [];
  const product = await fetchOpenFoodFactsProduct({
    barcode: '4000417025005',
    fetchImpl: async () => {
      attempts += 1;
      if (attempts < 3) return new Response('', { status: 503 });
      return Response.json({ product: { code: '4000417025005' } });
    },
    delay: async (milliseconds) => delays.push(milliseconds),
    random: () => 0,
  });
  assert.equal(attempts, 3);
  assert.deepEqual(delays, [1000, 2000]);
  assert.equal(product.code, '4000417025005');

  let networkAttempts = 0;
  await assert.rejects(
    fetchOpenFoodFactsProduct({
      barcode: '4000417025005',
      fetchImpl: async () => {
        networkAttempts += 1;
        throw new TypeError('network unavailable');
      },
      maximumAttempts: 2,
      delay: async () => {},
      random: () => 0,
    }),
    (error) =>
      error.code === 'upstream_temporary_failure' && error.statusCode === 503,
  );
  assert.equal(networkAttempts, 2);
});

test('returns null for a missing product without retrying', async () => {
  let attempts = 0;
  const product = await fetchOpenFoodFactsProduct({
    barcode: '4000417025005',
    fetchImpl: async () => {
      attempts += 1;
      return new Response('', { status: 404 });
    },
  });
  assert.equal(product, null);
  assert.equal(attempts, 1);
});

test('rejects redirects, oversized responses and barcode mismatches', async () => {
  await assert.rejects(
    fetchOpenFoodFactsProduct({
      barcode: '4000417025005',
      fetchImpl: async () =>
        new Response('', { status: 302, headers: { location: 'http://127.0.0.1' } }),
    }),
    (error) => error.code === 'upstream_redirect_rejected',
  );
  await assert.rejects(
    fetchOpenFoodFactsProduct({
      barcode: '4000417025005',
      fetchImpl: async () =>
        new Response('{}', {
          status: 200,
          headers: { 'content-length': '1048577' },
        }),
    }),
    (error) => error.code === 'upstream_response_too_large',
  );
  await assert.rejects(
    fetchOpenFoodFactsProduct({
      barcode: '4000417025005',
      fetchImpl: async () =>
        new Response(
          new ReadableStream({
            start(controller) {
              controller.enqueue(new Uint8Array(1_048_577));
              controller.close();
            },
          }),
          { status: 200 },
        ),
    }),
    (error) => error.code === 'upstream_response_too_large',
  );
  await assert.rejects(
    fetchOpenFoodFactsProduct({
      barcode: '4000417025005',
      fetchImpl: async () =>
        Response.json({ product: { code: '12345678' } }),
    }),
    (error) => error.code === 'upstream_barcode_mismatch',
  );
});

test('canonical JSON and SHA-256 are deterministic', async () => {
  const first = canonicalJson({ b: 2, a: { y: true, x: 1 } });
  const second = canonicalJson({ a: { x: 1, y: true }, b: 2 });
  assert.equal(first, second);
  assert.equal(await sha256Hex(first), await sha256Hex(second));
  assert.match(await sha256Hex(first), /^[a-f0-9]{64}$/);
});

test('uses the source observation timestamp with a controlled fallback', () => {
  assert.equal(
    sourceObservedAt({ last_updated_t: 1785100000 }),
    '2026-07-26T21:06:40.000Z',
  );
  assert.equal(
    sourceObservedAt({}, new Date('2026-08-12T10:00:00Z')),
    '2026-08-12T10:00:00.000Z',
  );
});

test('contract errors retain stable machine-readable codes', () => {
  const error = new WriterContractError('test_code', 'Test message', 422);
  assert.equal(error.code, 'test_code');
  assert.equal(error.statusCode, 422);
});

test('classifies audit failures by dependency boundary', () => {
  assert.equal(
    auditOutcomeForFailure({ code: 'upstream_temporary_failure', statusCode: 503 }),
    'upstream_unavailable',
  );
  assert.equal(
    auditOutcomeForFailure({ code: 'upstream_invalid_schema', statusCode: 502 }),
    'upstream_rejected',
  );
  assert.equal(
    auditOutcomeForFailure({ code: 'database_rpc_failed', statusCode: 503 }),
    'database_unavailable',
  );
  assert.equal(
    auditOutcomeForFailure({ code: 'database_rpc_failed', statusCode: 404 }),
    'database_rejected',
  );
  assert.equal(
    auditOutcomeForFailure({ code: 'writer_internal_error', statusCode: 500 }),
    'writer_internal_error',
  );
});
