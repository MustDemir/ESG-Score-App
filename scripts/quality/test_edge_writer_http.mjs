#!/usr/bin/env node
// Runs the production Deno handler against disposable local PostgREST/SQL.
// Only the single synthetic Open Food Facts response is replaced.
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createHash, randomBytes } from 'node:crypto';
import * as fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildOpenFoodFactsUrl } from '../../supabase/functions/_shared/writer_contract.mjs';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const barcode = '99999999999992';
const source = 'open-food-facts';
const workerName = 'ingest-products-http-test';
const args = process.argv.slice(2);
assert(args.length === 2 && args[0] === '--workdir', 'Usage: node test_edge_writer_http.mjs --workdir DISPOSABLE_LOCAL_PROJECT');
const workdir = await fs.realpath(args[1]);
const config = await fs.readFile(path.join(workdir, 'supabase/config.toml'), 'utf8');
const projectId = config.match(/^project_id\s*=\s*"([A-Za-z0-9_-]+)"\s*$/m)?.[1];
const isolated = /^scanfair-http-review[.-]/.test(path.basename(workdir))
  && /^scanfair-http-review-[A-Za-z0-9_-]+$/.test(projectId ?? '');
const disposableCI = process.env.CI === 'true' && process.env.GITHUB_ACTIONS === 'true'
  && workdir === repo && projectId === 'scanfair-local';
assert(isolated || disposableCI, 'Refusing an unrecognized or nondisposable project');

function command(binary, argv, input) {
  const result = spawnSync(binary, argv, { input, encoding: 'utf8', timeout: 30_000, maxBuffer: 4_194_304 });
  // Never print CLI output: status and runtime errors may contain credentials.
  assert(result.status === 0, `${binary} local command failed (output withheld)`);
  return result.stdout.trim();
}

const status = JSON.parse(command('supabase', ['status', '--workdir', workdir, '-o', 'json']));
const api = new URL(status.API_URL);
assert(api.protocol === 'http:' && ['127.0.0.1', 'localhost', '[::1]'].includes(api.hostname)
  && !api.username && !api.password && api.pathname === '/', 'Only a local API origin is allowed');
assert(typeof status.ANON_KEY === 'string' && status.ANON_KEY.length > 20, 'Local anon key missing');
const container = `supabase_db_${projectId}`;
function sql(statement) {
  return command('docker', ['exec', '-i', container, 'psql', '-X', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-Atq'], statement);
}
const literal = (value) => `'${String(value).replaceAll("'", "''")}'`;
const nonce = randomBytes(12).toString('hex');
const requestId = `edge-http-${nonce}`;
const correlationId = `edge-http-correlation-${nonce}`;
const scheduledSecret = randomBytes(32).toString('hex');
const operatorSecret = randomBytes(32).toString('hex');
const endpoint = `${api.origin}/functions/v1/${workerName}`;
const product = {
  code: barcode,
  product_name: `Synthetic Edge integration ${nonce}`,
  brands: 'ScanFair synthetic fixture',
  last_updated_t: Math.floor(Date.now() / 1000) - 60,
  schema_version: 'edge-http-fixture-v1',
};

const counterSpecs = [
  { table: 'private.writer_rate_windows', keys: ['scope', 'actor_type', 'window_started_at'], where: "(scope = 'actor' and actor_type = 'scheduled_ingestion_job') or (scope = 'global' and actor_type = '*')" },
  { table: 'private.writer_daily_usage', keys: ['usage_date'], where: "usage_date = (clock_timestamp() at time zone 'UTC')::date" },
  { table: 'private.writer_circuit_state', keys: ['source_id'], where: "source_id = 'open-food-facts'" },
  { table: 'private.public_read_rate_windows', keys: ['subject_hash', 'window_started_at'], where: 'true' },
];
function counterSnapshot() {
  return counterSpecs.map((spec) => JSON.parse(sql(
    `select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from ${spec.table} t where ${spec.where};`,
  )));
}
function rowKey(row, spec) { return JSON.stringify(spec.keys.map((key) => row[key])); }
const canonical = (row) => JSON.stringify(Object.fromEntries(Object.entries(row).sort()));

// Restore only changed keys, conditional on their exact captured final contents.
// Unexpected concurrent writes fail cleanup instead of being overwritten.
function restoreCounters(before, after) {
  const statements = ['begin;'];
  counterSpecs.forEach((spec, index) => {
    const oldRows = new Map(before[index].map((row) => [rowKey(row, spec), row]));
    const newRows = new Map(after[index].map((row) => [rowKey(row, spec), row]));
    for (const [key, row] of newRows) {
      const old = oldRows.get(key);
      if (old && canonical(old) === canonical(row)) continue;
      const typedRow = `jsonb_populate_record(null::${spec.table}, ${literal(JSON.stringify(row))}::jsonb)`;
      const predicate = spec.keys.map((column) => `${column} is not distinct from (select ${column} from ${typedRow})`).join(' and ');
      const expected = `${literal(JSON.stringify(row))}::jsonb`;
      statements.push(`do $$ begin
        if not exists (select 1 from ${spec.table} t where ${predicate} and to_jsonb(t) = ${expected}) then
          raise exception 'Concurrent counter change; cleanup refused';
        end if;
      end $$;`);
      statements.push(`delete from ${spec.table} where ${predicate};`);
      if (old) statements.push(`insert into ${spec.table} select * from jsonb_populate_record(null::${spec.table}, ${literal(JSON.stringify(old))}::jsonb);`);
    }
  });
  statements.push('commit;');
  sql(statements.join('\n'));
}

function fixtureCount() {
  return Number(sql(`select
    (select count(*) from public.cached_products where source_id = '${source}' and barcode = '${barcode}') +
    (select count(*) from private.writer_idempotency_keys where source_id = '${source}' and source_record_id = '${barcode}') +
    (select count(*) from private.writer_record_watermarks where source_id = '${source}' and source_record_id = '${barcode}') +
    (select count(*) from private.writer_audit_log where source_id = '${source}' and target_record = '${barcode}');`));
}

function removeFixtures() {
  sql(`begin;
    set local scanfair.audit_retention_cleanup = 'enabled';
    delete from private.writer_audit_log where request_id = '${requestId}' and correlation_id = '${correlationId}' and target_record = '${barcode}';
    delete from public.cached_products where source_id = '${source}' and barcode = '${barcode}' and payload ->> 'product_name' = ${literal(product.product_name)};
    delete from private.writer_idempotency_keys where source_id = '${source}' and source_record_id = '${barcode}';
    delete from private.writer_record_watermarks where source_id = '${source}' and source_record_id = '${barcode}';
    commit;`);
  assert.equal(fixtureCount(), 0, 'Synthetic fixture cleanup incomplete');
}

async function writerRequest(actor, secret, body) {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-scanfair-writer-actor': actor, 'x-scanfair-writer-secret': secret },
    body: JSON.stringify(body), signal: AbortSignal.timeout(15_000),
  });
  return { status: response.status, body: await response.json() };
}

let runtime;
let runtimeError = false;
let runtimeLog = '';
let workerCreated = false;
let envDir;
let beforeCounters;
let cleanupOwned = false;
let failure;
let checks;
const workerDir = path.join(workdir, 'supabase/functions', workerName);
const body = { barcodes: [barcode], correlation_id: correlationId, request_id: requestId, source_id: source };
try {
  // Verify the copied handler and shared contract are exactly the repository code.
  for (const file of ['ingest-products/index.ts', '_shared/writer_contract.mjs']) {
    const actual = await fs.readFile(path.join(workdir, 'supabase/functions', file));
    const expected = await fs.readFile(path.join(repo, 'supabase/functions', file));
    assert.equal(createHash('sha256').update(actual).digest('hex'), createHash('sha256').update(expected).digest('hex'), `Stale copied source: ${file}`);
  }
  assert.equal(fixtureCount(), 0, 'Synthetic barcode already exists; refusing to overwrite');
  beforeCounters = counterSnapshot();
  cleanupOwned = true;
  await fs.mkdir(workerDir);
  workerCreated = true;
  const expectedUpstream = buildOpenFoodFactsUrl(barcode).href;
  await fs.writeFile(path.join(workerDir, 'index.ts'), `// Generated disposable test wrapper; production handler imported unchanged.
const realFetch = globalThis.fetch.bind(globalThis);
globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
  const url = new URL(input instanceof Request ? input.url : String(input));
  if (url.href === ${JSON.stringify(expectedUpstream)}) {
    return new Response(JSON.stringify({ product: ${JSON.stringify(product)} }), { status: 200, headers: { 'content-type': 'application/json' } });
  }
  if (url.origin === new URL(Deno.env.get('SUPABASE_URL')!).origin && url.pathname.startsWith('/rest/v1/rpc/')) {
    return realFetch(input, init);
  }
  throw new Error('Unexpected network target in isolated Edge integration');
};
await import('../ingest-products/index.ts');
`, { flag: 'wx' });
  envDir = await fs.mkdtemp(path.join(os.tmpdir(), 'scanfair-edge-http-env-'));
  const envFile = path.join(envDir, 'writer.env');
  await fs.writeFile(envFile, `SCANFAIR_ENVIRONMENT=local\nSCANFAIR_SCHEDULED_WRITER_SECRET=${scheduledSecret}\nSCANFAIR_OPERATOR_REPLAY_SECRET=${operatorSecret}\n`, { mode: 0o600, flag: 'wx' });
  runtime = spawn('supabase', ['functions', 'serve', workerName, '--workdir', workdir, '--env-file', envFile, '--no-verify-jwt'], { stdio: ['ignore', 'pipe', 'pipe'] });
  runtime.on('error', () => { runtimeError = true; });
  for (const stream of [runtime.stdout, runtime.stderr]) stream.on('data', (chunk) => { runtimeLog = (runtimeLog + chunk.toString()).slice(-65_536); });
  let unauthorized;
  for (let attempt = 0; attempt < 40; attempt++) {
    assert(!runtimeError && runtime.exitCode === null, 'Local Edge runtime exited; logs withheld');
    try {
      unauthorized = await writerRequest('scheduled_ingestion_job', 'incorrect-fixture-secret', body);
      if (unauthorized.status === 401 && unauthorized.body.error === 'writer_unauthorized') break;
    } catch { /* Runtime startup is retried within the bounded deadline. */ }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  assert.equal(unauthorized?.status, 401, 'Runtime did not reach handler authentication');
  assert.equal(unauthorized.body.error, 'writer_unauthorized');
  const crossActor = await writerRequest('audited_operator_replay', scheduledSecret, body);
  assert.equal(crossActor.status, 401);
  assert.equal(crossActor.body.error, 'writer_unauthorized');
  const invalid = await writerRequest('scheduled_ingestion_job', scheduledSecret, { ...body, arbitrary_url: 'https://example.invalid/' });
  assert.equal(invalid.status, 400);
  assert.equal(invalid.body.error, 'unknown_or_missing_fields');
  const first = await writerRequest('scheduled_ingestion_job', scheduledSecret, body);
  assert.equal(first.status, 200, 'Handler HTTP envelope');
  assert.equal(first.body.results?.length, 1, 'One publication result required');
  assert.equal(first.body.results[0].status_code, 201, `Publication failed: ${first.body.results[0].error ?? first.body.results[0].status}`);
  assert.equal(first.body.results[0].status, 'published');
  const replay = await writerRequest('scheduled_ingestion_job', scheduledSecret, body);
  assert.equal(replay.status, 200);
  assert.equal(replay.body.results?.[0]?.status_code, 200);
  assert.equal(replay.body.results[0].status, 'duplicate_existing');
  assert.equal(replay.body.results[0].idempotency_key, first.body.results[0].idempotency_key);
  const read = await fetch(`${api.origin}/rest/v1/rpc/get_fresh_cached_product`, {
    method: 'POST', headers: { apikey: status.ANON_KEY, authorization: `Bearer ${status.ANON_KEY}`, 'content-type': 'application/json' },
    body: JSON.stringify({ p_source_id: source, p_barcode: barcode }), signal: AbortSignal.timeout(10_000),
  });
  assert.equal(read.status, 200, 'Anonymous bounded RPC must read published fixture');
  const rows = await read.json();
  assert.equal(rows.length, 1);
  assert.deepEqual(rows[0].payload, product);
  const audits = JSON.parse(sql(`select jsonb_agg(jsonb_build_object('outcome', outcome, 'status_code', status_code) order by id) from private.writer_audit_log where request_id = '${requestId}' and correlation_id = '${correlationId}';`));
  assert.deepEqual(audits, [{ outcome: 'published', status_code: 201 }, { outcome: 'duplicate_existing', status_code: 200 }]);
  checks = { invalid_secret: 401, cross_actor: 401, invalid_schema: 400, handler_http: 200, publication_result: 201, replay_result: 200, anon_read: 200, audit_records: audits.length };
} catch (error) {
  failure = error;
} finally {
  if (runtime && runtime.exitCode === null) {
    const stopped = new Promise((resolve) => runtime.once('close', resolve));
    runtime.kill('SIGTERM');
    const timer = setTimeout(() => runtime.kill('SIGKILL'), 5_000);
    await stopped;
    clearTimeout(timer);
  }
  try {
    if (cleanupOwned) {
      const afterCounters = counterSnapshot();
      removeFixtures();
      restoreCounters(beforeCounters, afterCounters);
    }
  } catch (error) { failure ??= error; }
  if (workerCreated) {
    await fs.unlink(path.join(workerDir, 'index.ts')).catch((error) => { if (error.code !== 'ENOENT') throw error; });
    await fs.rmdir(workerDir);
  }
  if (envDir) {
    await fs.unlink(path.join(envDir, 'writer.env')).catch((error) => { if (error.code !== 'ENOENT') throw error; });
    await fs.rmdir(envDir);
  }
  runtimeLog = ''; // Captured diagnostics deliberately never print secrets.
}
if (failure) {
  console.error(`Edge writer HTTP integration FAIL: ${failure.message}`);
  process.exitCode = 1;
} else {
  console.log(JSON.stringify({ gate: 'G-BACKEND-EDGE', decision: 'PASS', project: projectId, upstream: 'exact synthetic OFF fixture', actual_deno_handler: true, actual_postgrest_database: true, checks, cleanup: 'exact synthetic records and captured counter changes removed', remote_activation: false }, null, 2));
}
