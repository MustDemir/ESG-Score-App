begin;

create extension if not exists pgtap with schema extensions;

select plan(53);

-- Isolate counts from earlier HTTP fixtures. The enclosing rollback restores
-- every pre-existing row; this suite never commits a counter-table cleanup.
delete from private.public_read_rate_windows;

select has_table(
  'private',
  'public_read_rate_windows',
  'private public-read rate-window table exists'
);
select is(
  (select relrowsecurity from pg_class where oid = 'private.public_read_rate_windows'::regclass),
  true,
  'public-read rate-window table has RLS enabled'
);
select is(
  has_table_privilege('anon', 'private.public_read_rate_windows', 'SELECT'),
  false,
  'anon cannot read public-read rate windows'
);
select is(
  has_table_privilege('authenticated', 'private.public_read_rate_windows', 'SELECT'),
  false,
  'authenticated cannot read public-read rate windows'
);
select is(
  has_table_privilege('service_role', 'private.public_read_rate_windows', 'SELECT'),
  false,
  'service_role cannot read public-read rate windows'
);
select has_function(
  'private',
  'cleanup_public_read_rate_windows',
  array['timestamp with time zone'],
  'private public-read rate cleanup function exists'
);
select has_function(
  'public',
  'enforce_public_read_rate_limit',
  array[]::text[],
  'public-read pre-request enforcement function exists'
);
select is(
  has_function_privilege('anon', 'public.enforce_public_read_rate_limit()', 'EXECUTE'),
  true,
  'anon can execute the pre-request hook after role impersonation'
);
select is(
  has_function_privilege('authenticated', 'public.enforce_public_read_rate_limit()', 'EXECUTE'),
  true,
  'authenticated can execute the pre-request hook after role impersonation'
);
select is(
  has_function_privilege('service_role', 'public.enforce_public_read_rate_limit()', 'EXECUTE'),
  true,
  'service_role can execute the hook without breaking the writer path'
);
select is(
  has_function_privilege('authenticator', 'public.enforce_public_read_rate_limit()', 'EXECUTE'),
  true,
  'the PostgREST authenticator can execute the enforcement function'
);
select ok(
  exists (
    select 1
    from pg_db_role_setting as settings
    join pg_roles as roles on roles.oid = settings.setrole
    cross join lateral unnest(settings.setconfig) as setting
    where roles.rolname = 'authenticator'
      and setting = 'pgrst.db_pre_request=public.enforce_public_read_rate_limit'
  ),
  'PostgREST pre-request hook is configured for the authenticator role'
);
select is(
  (
    select username || ':' || database || ':' || schedule || ':' || command
    from cron.job
    where jobname = 'scanfair-public-read-rate-cleanup'
  ),
  'postgres:postgres:*/5 * * * *:select private.cleanup_public_read_rate_windows();',
  'private rate-window cleanup runs as postgres every five minutes'
);

select set_config('request.path', '/rpc/unrelated_function', true);
select set_config('request.method', 'GET', true);
select set_config('request.headers', '{}'::text, true);
select lives_ok(
  $$ select public.enforce_public_read_rate_limit() $$,
  'unrelated Data API requests are not affected by the public-read limiter'
);

set local role anon;
select set_config('request.path', '/rpc/get_fresh_cached_product', true);
select set_config('request.method', 'GET', true);
select set_config('request.headers', '{"x-forwarded-for":"203.0.113.7"}'::text, true);
select throws_ok(
  $$ select public.enforce_public_read_rate_limit() $$,
  'PGRST',
  '{"code" : "public_read_method_not_allowed", "message" : "Public read RPCs accept POST only."}',
  'public read RPCs reject non-POST requests before an unrate-limited read'
);

select set_config('request.method', 'POST', true);
select set_config('request.headers', '{}'::text, true);
select throws_ok(
  $$ select public.enforce_public_read_rate_limit() $$,
  'PGRST',
  '{"code" : "public_read_identity_unavailable", "message" : "A client IP is required for public read protection."}',
  'missing client identity fails closed'
);

select set_config('request.headers', '{"x-forwarded-for":"not-an-ip"}'::text, true);
select throws_ok(
  $$ select public.enforce_public_read_rate_limit() $$,
  'PGRST',
  '{"code" : "public_read_identity_invalid", "message" : "The public read client IP is invalid."}',
  'invalid client identity fails closed'
);

select set_config('request.headers', '{"x-forwarded-for":"203.0.113.7, 10.0.0.1"}'::text, true);
select lives_ok(
  $$ select public.enforce_public_read_rate_limit() $$,
  'first public read with a client IP is admitted'
);
reset role;
select is(
  (select count(*)::integer from private.public_read_rate_windows),
  1,
  'one minute bucket is stored for the public read subject'
);
select is(
  (
    select count(*)::integer
    from private.public_read_rate_windows
    where subject_hash !~ '203\\.0\\.113\\.7'
      and subject_hash ~ '^[a-f0-9]{64}$'
  ),
  1,
  'the rate window retains only a fixed-length pseudonym, never the raw IP'
);
set local role anon;
select lives_ok(
  $test$
    do $block$
    begin
      for attempt in 1..29 loop
        perform public.enforce_public_read_rate_limit();
      end loop;
    end;
    $block$
  $test$,
  'thirty public reads in one client-minute are admitted'
);
reset role;
select is(
  (select request_count from private.public_read_rate_windows),
  30,
  'the per-IP minute bucket counts each admitted request atomically'
);
set local role anon;
select throws_ok(
  $$ select public.enforce_public_read_rate_limit() $$,
  'PGRST',
  '{"code" : "public_read_rate_limit_exceeded", "message" : "Public read rate limit exceeded."}',
  'the thirty-first public read is rate limited'
);
reset role;
select is(
  (select request_count from private.public_read_rate_windows),
  30,
  'a rejected request does not create an unbounded counter increment'
);

insert into private.public_read_rate_windows (
  subject_hash, window_started_at, request_count, expires_at
) values (
  repeat('b', 64),
  transaction_timestamp() - interval '2 hours',
  1,
  transaction_timestamp() - interval '1 hour'
);
select is(
  private.cleanup_public_read_rate_windows(),
  1,
  'private cleanup removes expired pseudonymous rate windows'
);
select is(
  (select count(*)::integer from private.public_read_rate_windows),
  1,
  'private cleanup retains the current active rate window'
);
select is(
  has_function_privilege('anon', 'private.cleanup_public_read_rate_windows(timestamptz)', 'EXECUTE'),
  false,
  'anon cannot invoke private public-read rate cleanup'
);

select is((select provolatile::text from pg_proc where oid = 'public.get_fresh_cached_product(text,text)'::regprocedure),
  'v', 'cache POST permits the hook counter write');
select is((select provolatile::text from pg_proc where oid = 'public.get_published_product_evidence(text)'::regprocedure),
  'v', 'evidence POST permits the hook counter write');
select is((select provolatile::text from pg_proc where oid = 'public.get_published_score_snapshot(text,text)'::regprocedure),
  'v', 'score POST permits the hook counter write');
select is(has_table_privilege('anon', 'private.public_read_rate_windows', 'INSERT,UPDATE,DELETE'),
  false, 'anon has no direct counter write privileges');
select is(has_table_privilege('authenticated', 'private.public_read_rate_windows', 'INSERT,UPDATE,DELETE'),
  false, 'authenticated has no direct counter write privileges');
select is(has_table_privilege('service_role', 'private.public_read_rate_windows', 'INSERT,UPDATE,DELETE'),
  false, 'service_role has no direct counter write privileges');

set local role anon;
select set_config('request.path', '/rpc/%67et_fresh_cached_product', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_path_invalid", "message" : "Encoded or ambiguous Data API paths are not allowed."}',
  'percent-encoded protected routes fail closed');
select set_config('request.path', '/rpc//get_fresh_cached_product', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_path_invalid", "message" : "Encoded or ambiguous Data API paths are not allowed."}',
  'duplicate slash routes fail closed');
select set_config('request.path', '/rpc/enforce_public_read_rate_limit', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_hook_not_callable", "message" : "The request hook cannot be invoked as an API RPC."}',
  'hook cannot be called through its own RPC route');
select set_config('request.method', 'GET', true);
select set_config('request.path', '/rpc/get_fresh_cached_product/', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_method_not_allowed", "message" : "Public read RPCs accept POST only."}',
  'trailing slash does not bypass method protection');
select set_config('request.path', '/rpc/get_published_product_evidence', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_method_not_allowed", "message" : "Public read RPCs accept POST only."}',
  'evidence route is protected');
select set_config('request.path', '/rpc/get_published_score_snapshot', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_method_not_allowed", "message" : "Public read RPCs accept POST only."}',
  'score route is protected');
select set_config('request.method', 'HEAD', true);
select throws_ok($$select public.enforce_public_read_rate_limit()$$, 'PGRST',
  '{"code" : "public_read_method_not_allowed", "message" : "Public read RPCs accept POST only."}',
  'HEAD cannot bypass protection');
select throws_ok($$select * from private.public_read_rate_windows$$, '42501',
  null, 'anon cannot read the counter even with hook execute permission');
reset role;

set local role authenticated;
select set_config('request.method', 'POST', true);
select set_config('request.headers', '{"x-forwarded-for":"203.0.113.8"}', true);
select lives_ok($$select public.enforce_public_read_rate_limit()$$,
  'authenticated request executes the counter hook successfully');
select throws_ok($$select * from private.public_read_rate_windows$$, '42501',
  null, 'authenticated cannot read the counter');
reset role;

set local role service_role;
select set_config('request.path', '/rpc/claim_writer_capacity', true);
select set_config('request.headers', '{}', true);
select lives_ok($$select public.enforce_public_read_rate_limit()$$,
  'writer RPC passes the hook as service_role without a public-read identity');
select throws_ok($$select * from private.public_read_rate_windows$$, '42501',
  null, 'service_role cannot read the counter');
reset role;

set local role anon;
select set_config('request.path', '/rpc/get_fresh_cached_product', true);
select set_config('request.method', 'POST', true);
select set_config('request.headers', '{"x-forwarded-for":"203.0.113.100, 192.0.2.10"}', true);
select lives_ok($$select public.enforce_public_read_rate_limit()$$,
  'trusted final ingress address is accepted with an untrusted prefix');
select set_config('request.headers', '{"x-forwarded-for":"203.0.113.101, 192.0.2.10"}', true);
select lives_ok($$select public.enforce_public_read_rate_limit()$$,
  'changing an untrusted forwarded prefix does not change the trusted peer');
reset role;
-- Resolve the keyed pseudonym with the key of the window's own hour (TKT-037-06).
select is(
  (select windows.request_count
   from private.public_read_rate_windows as windows
   join private.public_read_rate_keys as keys
     on keys.key_epoch = floor(extract(epoch from windows.window_started_at) / 3600)::bigint
   where windows.subject_hash = encode(extensions.hmac(
     convert_to('scanfair-public-read-rate-v2|' || '192.0.2.10'::inet::text, 'UTF8'),
     keys.secret, 'sha256'), 'hex')),
  2, 'spoofed forwarded prefixes share one trusted-peer rate bucket');

-- Expiration and physical removal are distinct; batch backlog survives one run.
delete from private.public_read_rate_windows;
insert into private.public_read_rate_windows(subject_hash, window_started_at, request_count, expires_at)
select encode(extensions.digest(i::text, 'sha256'), 'hex'),
  transaction_timestamp() - interval '2 hours', 1,
  transaction_timestamp() - interval '1 hour'
from generate_series(1, 10001) i;
select is(private.cleanup_public_read_rate_windows(transaction_timestamp() - interval '1 hour 1 microsecond'),
  0, 'cleanup does not remove a bucket before expiry');
select is(private.cleanup_public_read_rate_windows(transaction_timestamp() - interval '1 hour'),
  10000, 'cleanup at expiry is bounded to ten thousand rows');
select is((select count(*)::integer from private.public_read_rate_windows),
  1, 'expired backlog remains after one bounded cleanup run');
select is(private.cleanup_public_read_rate_windows(transaction_timestamp()),
  1, 'subsequent cleanup drains the expired backlog');
select throws_ok($$select private.cleanup_public_read_rate_windows(clock_timestamp() + interval '6 minutes')$$,
  '22023', 'public read rate cleanup clock cannot be in the future',
  'cleanup rejects a future clock beyond tolerance');

select * from finish();

rollback;
