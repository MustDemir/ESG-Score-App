export const WRITER_LIMITS = Object.freeze({
  maximumBatchSize: 25,
  maximumRequestBytes: 65_536,
  maximumResponseBytes: 1_048_576,
  requestTimeoutMs: 8_000,
  maximumAttempts: 3,
});

export const ALLOWED_ACTORS = Object.freeze([
  'scheduled_ingestion_job',
  'audited_operator_replay',
]);

const REQUEST_FIELDS = Object.freeze([
  'barcodes',
  'correlation_id',
  'request_id',
  'source_id',
]);

const OFF_PRODUCT_FIELDS = new Set([
  'brands',
  'categories_tags',
  'code',
  'data_quality_tags',
  'data_quality_warnings_tags',
  'ecoscore_data',
  'ecoscore_grade',
  'ecoscore_score',
  'environmental_score_data',
  'environmental_score_grade',
  'environmental_score_score',
  'image_front_small_url',
  'ingredients',
  'ingredients_text',
  'labels_tags',
  'last_modified_t',
  'last_updated_t',
  'nova_group',
  'nova_groups',
  'nutriments',
  'nutrition_grades',
  'nutriscore_grade',
  'origins_tags',
  'packaging_tags',
  'product_name',
  'schema_version',
]);

const BARCODE_PATTERN = /^[0-9]{8,14}$/;
const IDENTIFIER_PATTERN = /^[A-Za-z0-9._:-]{8,128}$/;

export class WriterContractError extends Error {
  constructor(code, message, statusCode = 400) {
    super(message);
    this.name = 'WriterContractError';
    this.code = code;
    this.statusCode = statusCode;
  }
}

export async function authenticateWriter({ candidate, expected, actor }) {
  if (!expected || !candidate || !ALLOWED_ACTORS.includes(actor)) {
    throw new WriterContractError(
      'writer_unauthorized',
      'Writer authentication failed.',
      401,
    );
  }

  const encoder = new TextEncoder();
  const [candidateDigest, expectedDigest] = await Promise.all([
    crypto.subtle.digest('SHA-256', encoder.encode(candidate)),
    crypto.subtle.digest('SHA-256', encoder.encode(expected)),
  ]);
  const candidateBytes = new Uint8Array(candidateDigest);
  const expectedBytes = new Uint8Array(expectedDigest);
  let difference = candidateBytes.length ^ expectedBytes.length;
  for (let index = 0; index < expectedBytes.length; index += 1) {
    difference |= candidateBytes[index] ^ (expectedBytes[index] ?? 0);
  }
  if (difference !== 0) {
    throw new WriterContractError(
      'writer_unauthorized',
      'Writer authentication failed.',
      401,
    );
  }
  return actor;
}

export async function parseWriterRequest(request) {
  if (request.method !== 'POST') {
    throw new WriterContractError(
      'method_not_allowed',
      'Only POST is accepted.',
      405,
    );
  }
  const contentType = request.headers.get('content-type') ?? '';
  if (!contentType.toLowerCase().startsWith('application/json')) {
    throw new WriterContractError(
      'unsupported_content_type',
      'Content-Type must be application/json.',
      415,
    );
  }
  const declaredLength = Number(request.headers.get('content-length') ?? 0);
  if (declaredLength > WRITER_LIMITS.maximumRequestBytes) {
    throw new WriterContractError(
      'request_too_large',
      'Writer request exceeds the configured limit.',
      413,
    );
  }

  const bodyBytes = await readBoundedBytes(
    request.body,
    WRITER_LIMITS.maximumRequestBytes,
    () => new WriterContractError(
      'request_too_large',
      'Writer request exceeds the configured limit.',
      413,
    ),
  );

  let body;
  try {
    body = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bodyBytes));
  } catch {
    throw new WriterContractError(
      'invalid_json',
      'Writer request is not valid UTF-8 JSON.',
    );
  }
  if (!isPlainObject(body)) {
    throw new WriterContractError('invalid_body', 'Writer request must be an object.');
  }
  const fields = Object.keys(body).sort();
  if (
    fields.length !== REQUEST_FIELDS.length ||
    fields.some((field, index) => field !== REQUEST_FIELDS[index])
  ) {
    throw new WriterContractError(
      'unknown_or_missing_fields',
      'Writer request fields do not match the contract.',
    );
  }
  if (body.source_id !== 'open-food-facts') {
    throw new WriterContractError('source_not_allowed', 'Source is not allowlisted.');
  }
  if (
    !IDENTIFIER_PATTERN.test(body.request_id) ||
    !IDENTIFIER_PATTERN.test(body.correlation_id)
  ) {
    throw new WriterContractError(
      'invalid_identifier',
      'Request and correlation identifiers are invalid.',
    );
  }
  if (
    !Array.isArray(body.barcodes) ||
    body.barcodes.length < 1 ||
    body.barcodes.length > WRITER_LIMITS.maximumBatchSize ||
    body.barcodes.some((barcode) =>
      typeof barcode !== 'string' || !BARCODE_PATTERN.test(barcode)
    )
  ) {
    throw new WriterContractError('invalid_barcodes', 'Barcode batch is invalid.');
  }
  if (new Set(body.barcodes).size !== body.barcodes.length) {
    throw new WriterContractError(
      'duplicate_barcodes',
      'Barcode batch contains duplicates.',
    );
  }
  return Object.freeze({
    barcodes: Object.freeze([...body.barcodes]),
    correlationId: body.correlation_id,
    requestId: body.request_id,
    sourceId: body.source_id,
  });
}

export function buildOpenFoodFactsUrl(barcode) {
  if (!BARCODE_PATTERN.test(barcode)) {
    throw new WriterContractError('invalid_barcode', 'Barcode is invalid.');
  }
  const fields = [...OFF_PRODUCT_FIELDS].sort().join(',');
  return new URL(
    `/api/v3/product/${barcode}.json?fields=${encodeURIComponent(fields)}`,
    'https://world.openfoodfacts.org',
  );
}

export function validateUpstreamUrl(input) {
  const url = input instanceof URL ? input : new URL(input);
  if (
    url.protocol !== 'https:' ||
    url.hostname !== 'world.openfoodfacts.org' ||
    url.port !== '' ||
    url.username !== '' ||
    url.password !== ''
  ) {
    throw new WriterContractError(
      'upstream_not_allowed',
      'Upstream target is not allowlisted.',
      502,
    );
  }
  return url;
}

export async function fetchOpenFoodFactsProduct({
  barcode,
  fetchImpl = fetch,
  delay = defaultDelay,
  random = Math.random,
  timeoutMs = WRITER_LIMITS.requestTimeoutMs,
  maximumAttempts = WRITER_LIMITS.maximumAttempts,
}) {
  const url = validateUpstreamUrl(buildOpenFoodFactsUrl(barcode));
  let lastError;
  for (let attempt = 1; attempt <= maximumAttempts; attempt += 1) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetchImpl(url, {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          'User-Agent':
            'ScanFair-Server-Writer/0.1 (https://github.com/MustDemir/ESG-Score-App)',
        },
        redirect: 'manual',
        signal: controller.signal,
      });
      if (response.status === 404) return null;
      if (response.status >= 300 && response.status < 400) {
        throw new WriterContractError(
          'upstream_redirect_rejected',
          'Upstream redirects are rejected.',
          502,
        );
      }
      if (response.status === 429 || response.status >= 500) {
        throw new WriterContractError(
          'upstream_temporary_failure',
          'Upstream is temporarily unavailable.',
          503,
        );
      }
      if (response.status !== 200) {
        throw new WriterContractError(
          'upstream_rejected',
          'Upstream returned an unexpected status.',
          502,
        );
      }
      const declaredLength = Number(response.headers.get('content-length') ?? 0);
      if (declaredLength > WRITER_LIMITS.maximumResponseBytes) {
        throw new WriterContractError(
          'upstream_response_too_large',
          'Upstream response exceeds the configured limit.',
          502,
        );
      }
      const responseBytes = await readBoundedBytes(
        response.body,
        WRITER_LIMITS.maximumResponseBytes,
        () => new WriterContractError(
          'upstream_response_too_large',
          'Upstream response exceeds the configured limit.',
          502,
        ),
      );
      let decoded;
      try {
        decoded = JSON.parse(
          new TextDecoder('utf-8', { fatal: true }).decode(responseBytes),
        );
      } catch {
        throw new WriterContractError(
          'upstream_invalid_json',
          'Upstream response is not valid UTF-8 JSON.',
          502,
        );
      }
      if (!isPlainObject(decoded) || !isPlainObject(decoded.product)) {
        throw new WriterContractError(
          'upstream_invalid_schema',
          'Upstream response does not contain a product object.',
          502,
        );
      }
      if (decoded.product.code && String(decoded.product.code) !== barcode) {
        throw new WriterContractError(
          'upstream_barcode_mismatch',
          'Upstream product does not match the requested barcode.',
          502,
        );
      }
      return sanitizeProduct(decoded.product);
    } catch (error) {
      lastError = error;
      const retryable =
        error?.name === 'AbortError' ||
        (error instanceof WriterContractError &&
          error.code === 'upstream_temporary_failure') ||
        error instanceof TypeError;
      if (!retryable) throw error;
      if (attempt === maximumAttempts) {
        throw new WriterContractError(
          'upstream_temporary_failure',
          'Upstream is temporarily unavailable.',
          503,
        );
      }
      const baseDelay = 1_000 * 2 ** (attempt - 1);
      await delay(baseDelay + Math.floor(random() * Math.max(1, baseDelay / 2)));
    } finally {
      clearTimeout(timer);
    }
  }
  throw lastError;
}

export function sourceObservedAt(product, fallbackDate = new Date()) {
  const timestamp = product.last_updated_t ?? product.last_modified_t;
  const seconds = Number(timestamp);
  if (Number.isFinite(seconds) && seconds > 0) {
    return new Date(seconds * 1000).toISOString();
  }
  return fallbackDate.toISOString();
}

export function canonicalJson(value) {
  if (Array.isArray(value)) {
    return `[${value.map((entry) => canonicalJson(entry)).join(',')}]`;
  }
  if (isPlainObject(value)) {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value);
}

export async function sha256Hex(value) {
  const bytes = new TextEncoder().encode(value);
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return [...digest].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export function auditOutcomeForFailure({ code, statusCode }) {
  if (code.startsWith('upstream_')) {
    return statusCode === 503 ? 'upstream_unavailable' : 'upstream_rejected';
  }
  if (code.startsWith('database_')) {
    return statusCode === 503 ? 'database_unavailable' : 'database_rejected';
  }
  return 'writer_internal_error';
}

export async function readBoundedBytes(stream, maximumBytes, errorFactory) {
  if (!stream) return new Uint8Array();
  const reader = stream.getReader();
  const chunks = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > maximumBytes) {
        await reader.cancel();
        throw errorFactory();
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const result = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return result;
}

function sanitizeProduct(product) {
  const sanitized = {};
  for (const [field, value] of Object.entries(product)) {
    if (OFF_PRODUCT_FIELDS.has(field)) sanitized[field] = value;
  }
  return sanitized;
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function defaultDelay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}
