import {
  WriterContractError,
  authenticateWriter,
  canonicalJson,
  fetchOpenFoodFactsProduct,
  parseWriterRequest,
  readBoundedBytes,
  sha256Hex,
  sourceObservedAt,
} from '../_shared/writer_contract.mjs';

const jsonHeaders = { 'content-type': 'application/json; charset=utf-8' };

Deno.serve(async (request: Request) => {
  try {
    const runtimeEnvironment = requiredEnvironment('SCANFAIR_ENVIRONMENT');
    const supabaseUrl = validateSupabaseUrl(
      requiredEnvironment('SUPABASE_URL'),
      runtimeEnvironment,
    );
    const privilegedKey = requiredEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    const requestedActor = request.headers.get('x-scanfair-writer-actor') ?? '';
    const writerSecret = secretForActor(requestedActor);
    const actor = await authenticateWriter({
      actor: requestedActor,
      candidate: request.headers.get('x-scanfair-writer-secret') ?? '',
      expected: writerSecret,
    });
    const input = await parseWriterRequest(request);
    const rpc = (name: string, body: Record<string, unknown>) =>
      callRpc({ name, body, supabaseUrl, privilegedKey });

    await rpc('claim_writer_capacity', {
      p_actor_type: actor,
      p_batch_size: input.barcodes.length,
      p_request_id: input.requestId,
    });

    const results: Array<Record<string, unknown>> = [];
    let circuitOpen = false;
    for (const [index, barcode] of input.barcodes.entries()) {
      if (index > 0) await new Promise((resolve) => setTimeout(resolve, 1_000));
      if (circuitOpen) {
        const inputDigest = await sha256Hex(`${input.sourceId}:${barcode}`);
        await rpc('record_writer_outcome', {
          p_actor_type: actor,
          p_barcode: barcode,
          p_correlation_id: input.correlationId,
          p_input_sha256: inputDigest,
          p_outcome: 'upstream_unavailable',
          p_request_id: input.requestId,
          p_status_code: 503,
        });
        results.push({
          barcode,
          error: 'upstream_circuit_open',
          status: 'failed',
          status_code: 503,
        });
        continue;
      }
      try {
        const product = await fetchOpenFoodFactsProduct({ barcode });
        await rpc('record_writer_upstream_health', {
          p_source_id: input.sourceId,
          p_succeeded: true,
        });
        if (product === null) {
          const inputDigest = await sha256Hex(`${input.sourceId}:${barcode}`);
          await rpc('record_writer_outcome', {
            p_actor_type: actor,
            p_barcode: barcode,
            p_correlation_id: input.correlationId,
            p_input_sha256: inputDigest,
            p_outcome: 'not_found',
            p_request_id: input.requestId,
            p_status_code: 404,
          });
          results.push({ barcode, status: 'not_found', status_code: 404 });
          continue;
        }

        const fetchedAt = new Date();
        const publication = await rpc('publish_off_product', {
          p_actor_type: actor,
          p_barcode: barcode,
          p_correlation_id: input.correlationId,
          p_expires_at: new Date(fetchedAt.getTime() + 86_400_000).toISOString(),
          p_fetched_at: fetchedAt.toISOString(),
          p_payload: JSON.parse(canonicalJson(product)),
          p_request_id: input.requestId,
          p_source_observed_at: sourceObservedAt(product, fetchedAt),
          p_source_schema_version:
            product.schema_version === undefined
              ? null
              : String(product.schema_version),
        });
        results.push({ barcode, ...publication });
      } catch (error) {
        const normalized = normalizeError(error);
        if (normalized.code.startsWith('upstream_')) {
          try {
            const health = await rpc('record_writer_upstream_health', {
              p_source_id: input.sourceId,
              p_succeeded: false,
            });
            circuitOpen = health.circuit_open === true;
          } catch {
            circuitOpen = true;
          }
        }
        const inputDigest = await sha256Hex(`${input.sourceId}:${barcode}`);
        try {
          await rpc('record_writer_outcome', {
            p_actor_type: actor,
            p_barcode: barcode,
            p_correlation_id: input.correlationId,
            p_input_sha256: inputDigest,
            p_outcome:
              normalized.statusCode === 503
                ? 'upstream_unavailable'
                : 'upstream_rejected',
            p_request_id: input.requestId,
            p_status_code: normalized.statusCode,
          });
        } catch {
          // The response still reports the failure when the audit backend is down.
        }
        results.push({
          barcode,
          error: normalized.code,
          status: 'failed',
          status_code: normalized.statusCode,
        });
      }
    }

    return new Response(
      JSON.stringify({
        correlation_id: input.correlationId,
        request_id: input.requestId,
        results,
      }),
      { status: 200, headers: jsonHeaders },
    );
  } catch (error) {
    const normalized = normalizeError(error);
    return new Response(
      JSON.stringify({ error: normalized.code }),
      { status: normalized.statusCode, headers: jsonHeaders },
    );
  }
});

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing runtime environment: ${name}`);
  return value;
}

function secretForActor(actor: string): string {
  if (actor === 'scheduled_ingestion_job') {
    return requiredEnvironment('SCANFAIR_SCHEDULED_WRITER_SECRET');
  }
  if (actor === 'audited_operator_replay') {
    return requiredEnvironment('SCANFAIR_OPERATOR_REPLAY_SECRET');
  }
  return '';
}

function validateSupabaseUrl(value: string, runtimeEnvironment: string): string {
  const url = new URL(value);
  const localHosts = new Set([
    '127.0.0.1',
    'host.docker.internal',
    'kong',
    'localhost',
  ]);
  const allowedLocalOrigin =
    runtimeEnvironment === 'local' &&
    url.protocol === 'http:' &&
    localHosts.has(url.hostname);
  if (
    (url.protocol !== 'https:' && !allowedLocalOrigin) ||
    url.username ||
    url.password
  ) {
    throw new Error('SUPABASE_URL must be an HTTPS project origin.');
  }
  return url.origin;
}

async function callRpc({
  name,
  body,
  supabaseUrl,
  privilegedKey,
}: {
  name: string;
  body: Record<string, unknown>;
  supabaseUrl: string;
  privilegedKey: string;
}): Promise<Record<string, unknown>> {
  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/${name}`, {
    method: 'POST',
    headers: {
      apikey: privilegedKey,
      authorization: `Bearer ${privilegedKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(8_000),
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new WriterContractError(
      'database_rpc_failed',
      'Privileged database operation failed.',
      response.status >= 500 ? 503 : response.status,
    );
  }
  const declaredLength = Number(response.headers.get('content-length') ?? 0);
  if (declaredLength > 65_536) {
    await response.body?.cancel();
    throw new WriterContractError(
      'database_rpc_response_too_large',
      'Privileged database response exceeded its limit.',
      503,
    );
  }
  const bytes = await readBoundedBytes(
    response.body,
    65_536,
    () =>
      new WriterContractError(
        'database_rpc_response_too_large',
        'Privileged database response exceeded its limit.',
        503,
      ),
  );
  if (bytes.byteLength === 0) return {};
  const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  const decoded = JSON.parse(text);
  return decoded && typeof decoded === 'object' && !Array.isArray(decoded)
    ? decoded
    : {};
}

function normalizeError(error: unknown): {
  code: string;
  statusCode: number;
} {
  if (error instanceof WriterContractError) {
    return { code: error.code, statusCode: error.statusCode };
  }
  return { code: 'writer_internal_error', statusCode: 500 };
}
