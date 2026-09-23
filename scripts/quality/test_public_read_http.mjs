#!/usr/bin/env node
// TKT-037-05: exercise the real gateway/PostgREST transaction and role context.
// Only a dedicated disposable local stack (or the disposable CI stack) is allowed.
import { execFileSync } from 'node:child_process';
import { createHmac, randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import assert from 'node:assert/strict';

const barcode = '99999999999991';
const source = 'open-food-facts';
let checks = 0;

function command(program, args, input) {
  try {
    return execFileSync(program, args, {
      input, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'], timeout: 30000,
    }).trim();
  } catch {
    // CLI output can contain credentials. Never print child process errors.
    throw new Error(`${program} prerequisite or fixture operation failed (output withheld)`);
  }
}

async function main() {
  assert.equal(process.argv.length, 4, 'usage: node test_public_read_http.mjs --workdir DISPOSABLE_STACK');
  assert.equal(process.argv[2], '--workdir', '--workdir is mandatory');
  const workdir = resolve(process.argv[3]);
  const config = readFileSync(resolve(workdir, 'supabase/config.toml'), 'utf8');
  const project = config.match(/^project_id\s*=\s*"([A-Za-z0-9_-]+)"\s*$/m)?.[1];
  assert.ok(project && (/^scanfair-http-review-[A-Za-z0-9_-]+$/.test(project)
    || (process.env.CI === 'true' && process.env.GITHUB_ACTIONS === 'true' && project === 'scanfair-local')),
  'refusing a non-disposable project');
  let status;
  try {
    status = JSON.parse(command('supabase', ['status', '--workdir', workdir, '-o', 'json']));
  } catch {
    throw new Error('local Supabase status unavailable (output withheld)');
  }
  const api = new URL(status.API_URL);
  assert.ok(['http:', 'https:'].includes(api.protocol)
    && ['localhost', '127.0.0.1', '[::1]'].includes(api.hostname)
    && !api.username && !api.password && !api.search && !api.hash,
  'refusing non-loopback API URL');
  for (const field of ['ANON_KEY', 'SERVICE_ROLE_KEY', 'JWT_SECRET']) {
    assert.ok(typeof status[field] === 'string' && status[field].length > 0, `missing local ${field}`);
  }
  const sql = (text) => command('docker', [
    'exec', '-i', `supabase_db_${project}`, 'psql', '-X', '-qAt',
    '-v', 'ON_ERROR_STOP=1', '-U', 'postgres', '-d', 'postgres',
  ], text);
  const fixtureCount = () => Number(sql(`select
    (select count(*) from public.cached_products where source_id='${source}' and barcode='${barcode}') +
    (select count(*) from private.writer_record_watermarks where source_id='${source}' and source_record_id='${barcode}') +
    (select count(*) from private.writer_idempotency_keys where source_id='${source}' and source_record_id='${barcode}') +
    (select count(*) from private.writer_audit_log where source_id='${source}' and target_record='${barcode}');`));
  assert.equal(fixtureCount(), 0, 'refusing pre-existing synthetic product/writer fixture');
  assert.equal(sql('select count(*) from private.public_read_rate_windows;'), '0',
    'refusing a nonempty rate table; use a dedicated disposable stack');
  assert.equal(sql(`select count(*) from public.data_sources where id='${source}' and active;`), '1',
    'OFF source must be active in the disposable database');

  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const epoch = Math.floor(Date.now() / 1000);
  const unsigned = `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode({
    role: 'authenticated', aud: 'authenticated', sub: randomUUID(), iat: epoch, exp: epoch + 3600,
  })}`;
  const authenticated = `${unsigned}.${createHmac('sha256', status.JWT_SECRET).update(unsigned).digest('base64url')}`;
  const roles = { anon: status.ANON_KEY, authenticated };
  const routes = [
    ['get_fresh_cached_product', { p_source_id: source, p_barcode: barcode }],
    ['get_published_product_evidence', { p_barcode: barcode }],
    ['get_published_score_snapshot', { p_barcode: barcode, p_formula_version: null }],
  ];
  async function request(path, token, body, method = 'POST', extra = {}) {
    const url = new URL(`/rest/v1/${path}`, api);
    if (method === 'GET' && body) {
      for (const [key, value] of Object.entries(body)) {
        if (value !== null) url.searchParams.set(key, value);
      }
    }
    const response = await fetch(url, {
      method, redirect: 'manual', signal: AbortSignal.timeout(10000),
      headers: {
        apikey: status.ANON_KEY, Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json', ...extra,
      },
      body: method === 'POST' ? JSON.stringify(body ?? {}) : undefined,
    });
    const text = await response.text();
    let data;
    try { data = JSON.parse(text); } catch { data = null; }
    return { status: response.status, retryAfter: response.headers.get('retry-after'), data };
  }
  function equal(actual, expected, label) {
    // Only status/count/fixture values are passed here, never credentials.
    assert.equal(actual, expected, label);
    checks++;
  }
  // The table was verified empty. Delete only exact keys created during this
  // disposable run; never use TRUNCATE or remove a pre-existing table population.
  function clearRateFixtures() {
    const rows = sql('select subject_hash || \':\' || extract(epoch from window_started_at)::bigint from private.public_read_rate_windows;');
    for (const row of rows.split('\n').filter(Boolean)) {
      const match = row.match(/^([0-9a-f]{64}):(\d+)$/);
      assert.ok(match, 'unexpected rate fixture identity');
      sql(`delete from private.public_read_rate_windows where subject_hash='${match[1]}' and window_started_at=to_timestamp(${match[2]});`);
    }
  }
  async function stableMinute() {
    // Keep the 31-request assertion inside one real database minute window.
    const remaining = Number(sql("select 60 - extract(second from clock_timestamp());"));
    if (remaining < 20) await new Promise((done) => setTimeout(done, (remaining + 0.1) * 1000));
    return sql("select date_trunc('minute', clock_timestamp())::text;");
  }
  try {
    for (const [role, token] of Object.entries(roles)) {
      for (const [route, body] of routes) {
        equal((await request(`rpc/${route}`, token, body)).status, 200, `${role} POST ${route}`);
        equal((await request(`rpc/${route}`, token, body, 'GET')).status, 405, `${role} GET ${route}`);
        for (const alias of [`rpc/%67${route.slice(1)}`, `rpc//${route}`]) {
          const before = Number(sql('select coalesce(sum(request_count), 0) from private.public_read_rate_windows;'));
          const result = await request(alias, token, body);
          // Kong may normalize before PostgREST. Normalized aliases must consume
          // the same quota; an alias still visible to the hook must fail closed.
          assert.ok([200, 403, 404].includes(result.status), `${role} unexpected alias response`);
          equal(Number(sql('select coalesce(sum(request_count), 0) from private.public_read_rate_windows;')),
            before + (result.status === 200 ? 1 : 0), `${role} alias cannot bypass counting`);
        }
      }
      equal((await request('rpc/enforce_public_read_rate_limit', token, {})).status, 403,
        `${role} direct hook invocation`);
    }
    clearRateFixtures();
    for (const [role, token] of Object.entries(roles)) {
      for (const [route, body] of routes) {
        const minute = await stableMinute();
        for (let count = 1; count <= 30; count++) {
          equal((await request(`rpc/${route}`, token, body)).status, 200, `${role} ${route} request ${count}`);
        }
        const rejected = await request(`rpc/${route}`, token, body);
        equal(rejected.status, 429, `${role} ${route} request 31`);
        equal(rejected.retryAfter, '60', `${role} ${route} Retry-After`);
        equal(sql('select sum(request_count) from private.public_read_rate_windows;'), '30',
          'thirty admitted requests persist; rejected transaction does not increment');
        for (const alias of [`rpc/%67${route.slice(1)}`, `rpc//${route}`, `rpc/${route}/`]) {
          const denied = await request(alias, token, body);
          assert.ok([403, 404, 429].includes(denied.status), 'alias cannot bypass exhausted quota');
          checks++;
        }
        equal(sql("select date_trunc('minute', clock_timestamp())::text;"), minute,
          'rate scenario crossed a minute boundary; rerun in an idle stack');
        clearRateFixtures();
      }
    }
    const minute = await stableMinute();
    for (let count = 0; count < 30; count++) {
      const [route, body] = routes[count % routes.length];
      equal((await request(`rpc/${route}`, count % 2 ? authenticated : roles.anon, body)).status,
        200, 'quota is shared across roles and read RPCs');
    }
    const [route, body] = routes[0];
    for (const forged of ['198.51.100.10', '198.51.100.11, 203.0.113.9']) {
      const result = await request(`rpc/${route}`, roles.anon, body, 'POST', { 'x-forwarded-for': forged });
      equal(result.status, 429, 'forged forwarding prefix must not bypass gateway identity quota');
      equal(result.retryAfter, '60', 'forged forwarding prefix Retry-After');
    }
    equal(sql("select date_trunc('minute', clock_timestamp())::text;"), minute,
      'shared quota scenario crossed a minute boundary');
    clearRateFixtures();

    const now = new Date();
    const fixtureName = 'ScanFair local HTTP integration fixture';
    const publication = await request('rpc/publish_off_product', status.SERVICE_ROLE_KEY, {
      p_request_id: `http-review-${randomUUID()}`, p_correlation_id: `http-review-${randomUUID()}`,
      p_actor_type: 'audited_operator_replay', p_barcode: barcode,
      p_payload: { code: barcode, product_name: fixtureName },
      p_source_observed_at: new Date(now.getTime() - 60000).toISOString(),
      p_fetched_at: now.toISOString(), p_expires_at: new Date(now.getTime() + 3600000).toISOString(),
      p_source_schema_version: 'v3',
    });
    equal(publication.status, 200, 'service-role publication RPC HTTP status');
    equal(publication.data?.status, 'published', 'service-role publication result');
    const read = await request(`rpc/${routes[0][0]}`, roles.anon, routes[0][1]);
    equal(read.status, 200, 'anon reads service-role published fixture');
    equal(read.data?.length, 1, 'exactly one published fixture');
    equal(read.data?.[0]?.payload?.product_name, fixtureName, 'published payload survives writer/read roundtrip');
    for (const [role, token] of Object.entries(roles)) {
      const direct = await request(`cached_products?barcode=eq.${barcode}&select=barcode`, token, null, 'GET');
      assert.ok([401, 403].includes(direct.status), `${role} direct table access must be denied`);
      checks++;
    }
  } finally {
    clearRateFixtures();
    sql(`begin;
      set local scanfair.audit_retention_cleanup = 'enabled';
      delete from private.writer_audit_log where source_id='${source}' and target_record='${barcode}';
      delete from private.writer_idempotency_keys where source_id='${source}' and source_record_id='${barcode}';
      delete from private.writer_record_watermarks where source_id='${source}' and source_record_id='${barcode}';
      delete from public.cached_products where source_id='${source}' and barcode='${barcode}';
      commit;`);
    equal(fixtureCount(), 0, 'synthetic writer/product fixture cleaned up');
    equal(sql('select count(*) from private.public_read_rate_windows;'), '0', 'rate fixtures cleaned up');
  }
  console.log(`PASS: ${checks} local HTTP assertions (gateway, roles, methods, aliases, quotas, writer/read, cleanup)`);
}

main().catch((error) => {
  console.error(`FAIL: ${error instanceof Error ? error.message : 'local HTTP integration failed'}`);
  process.exitCode = 1;
});
