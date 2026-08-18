begin;

create extension if not exists pgtap with schema extensions;

select plan(33);

select has_table(
  'private',
  'writer_record_watermarks',
  'durable writer watermark table exists'
);
select ok(
  (select relrowsecurity
   from pg_catalog.pg_class
   where oid = 'private.writer_record_watermarks'::pg_catalog.regclass),
  'writer watermark table has row level security enabled'
);
select is(
  pg_catalog.has_table_privilege(
    'service_role',
    'private.writer_record_watermarks',
    'SELECT'
  ),
  false,
  'service_role cannot read durable writer watermarks directly'
);
select has_function(
  'private',
  'run_retention_cleanup',
  array['timestamp with time zone'],
  'private retention cleanup function exists'
);
select is(
  pg_catalog.has_function_privilege(
    'service_role',
    'private.run_retention_cleanup(timestamptz)',
    'EXECUTE'
  ),
  false,
  'service_role cannot invoke retention cleanup'
);
select ok(
  exists (
    select 1 from pg_catalog.pg_extension where extname = 'pg_cron'
  ),
  'pg_cron is installed by the migration'
);
select is(
  (
    select count(*)::integer
    from cron.job
    where jobname = 'scanfair-retention-cleanup'
  ),
  1,
  'exactly one named retention cron job exists'
);
select is(
  (
    select database || ':' || username || ':' || schedule || ':' || command
    from cron.job
    where jobname = 'scanfair-retention-cleanup'
  ),
  'postgres:postgres:20 3 * * *:select private.run_retention_cleanup();',
  'retention cleanup runs as postgres in postgres daily at 03:20 UTC'
);

create temporary table retention_test_clock as
select clock_timestamp() as now;

select throws_ok(
  $$
    select public.publish_off_product(
      'request-retention-future',
      'correlation-retention-future',
      'scheduled_ingestion_job',
      '59000009',
      '{"code":"59000009","product_name":"Future cache"}'::jsonb,
      clock_timestamp(),
      clock_timestamp() + interval '1 day',
      clock_timestamp() + interval '2 days',
      'v3'
    )
  $$,
  '22023',
  'invalid writer timestamps',
  'writer cannot extend retention with a future fetch timestamp'
);

select lives_ok(
  $$
    select public.publish_off_product(
      'request-retention-old',
      'correlation-retention-old',
      'scheduled_ingestion_job',
      '59000001',
      '{"code":"59000001","product_name":"Old cache"}'::jsonb,
      (select now - interval '6 days' from retention_test_clock),
      (select now - interval '5 days' from retention_test_clock),
      (select now - interval '25 hours' from retention_test_clock),
      'v3'
    )
  $$,
  'old cache fixture is published through the bounded writer RPC'
);
select lives_ok(
  $$
    select public.publish_off_product(
      'request-retention-fresh',
      'correlation-retention-fresh',
      'scheduled_ingestion_job',
      '59000002',
      '{"code":"59000002","product_name":"Fresh cache"}'::jsonb,
      (select now - interval '1 hour' from retention_test_clock),
      (select now from retention_test_clock),
      (select now + interval '6 days' from retention_test_clock),
      'v3'
    )
  $$,
  'fresh cache fixture is published through the bounded writer RPC'
);

update private.writer_idempotency_keys
set created_at = (select now - interval '31 days' from retention_test_clock)
where source_record_id = '59000001';

insert into private.writer_rate_windows (
  scope, actor_type, window_started_at, request_count
) values
  (
    'actor', 'retention-old',
    (select now - interval '2 hours' from retention_test_clock), 1
  ),
  (
    'actor', 'retention-fresh',
    (select now - interval '30 minutes' from retention_test_clock), 1
  );

insert into private.writer_daily_usage (usage_date, upstream_request_count)
values
  (
    (select (now at time zone 'UTC')::date - 401 from retention_test_clock),
    1
  ),
  (
    (select (now at time zone 'UTC')::date - 399 from retention_test_clock),
    1
  );

insert into private.writer_audit_log (
  request_id, idempotency_key, actor_type, action, source_id, target_record,
  input_sha256, outcome, status_code, started_at, completed_at,
  correlation_id, created_at
) values (
  'request-retention-expired',
  pg_catalog.repeat('e', 64),
  'scheduled_ingestion_job',
  'fetch_product_cache',
  'open-food-facts',
  '59000003',
  pg_catalog.repeat('e', 64),
  'not_found',
  404,
  (select now - interval '91 days' from retention_test_clock),
  (select now - interval '91 days' from retention_test_clock),
  'correlation-retention-expired',
  (select now - interval '91 days' from retention_test_clock)
);

insert into cron.job_run_details (
  jobid, runid, database, username, command, status, start_time, end_time
) values
  (
    (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
    -9001, current_database(), current_user, 'retention-old', 'succeeded',
    (select now - interval '31 days' from retention_test_clock),
    (select now - interval '31 days' from retention_test_clock)
  ),
  (
    (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
    -9002, current_database(), current_user, 'retention-fresh', 'succeeded',
    (select now - interval '29 days' from retention_test_clock),
    (select now - interval '29 days' from retention_test_clock)
  );

select throws_ok(
  $$
    delete from private.writer_audit_log
    where request_id = 'request-retention-expired'
  $$,
  'P0001',
  'writer audit records are append-only',
  'direct audit deletion remains blocked'
);
select throws_ok(
  $$
    select private.run_retention_cleanup(clock_timestamp() + interval '1 day')
  $$,
  '22023',
  'cleanup clock cannot be in the future',
  'cleanup rejects a caller-controlled future clock'
);

create temporary table retention_cleanup_result as
select private.run_retention_cleanup(
  (select now from retention_test_clock)
) as value;

select is(
  (select (value ->> 'rate_windows_deleted')::integer
   from retention_cleanup_result),
  1,
  'cleanup removes rate windows older than one hour'
);
select is(
  (select (value ->> 'cached_products_deleted')::integer
   from retention_cleanup_result),
  1,
  'cleanup removes cache rows expired for more than one day'
);
select is(
  (select (value ->> 'idempotency_keys_deleted')::integer
   from retention_cleanup_result),
  1,
  'cleanup removes idempotency events older than thirty days'
);
select is(
  (select (value ->> 'audit_records_deleted')::integer
   from retention_cleanup_result),
  1,
  'cleanup removes audit records older than ninety days'
);
select is(
  (select (value ->> 'daily_usage_deleted')::integer
   from retention_cleanup_result),
  1,
  'cleanup removes daily usage older than four hundred days'
);
select is(
  (select (value ->> 'cron_history_deleted')::integer
   from retention_cleanup_result),
  1,
  'cleanup removes cron history older than thirty days'
);

select is(
  (select count(*)::integer
   from private.writer_rate_windows
   where actor_type like 'retention-%'),
  1,
  'rate-window boundary retains the recent row'
);
select is(
  (select count(*)::integer
   from public.cached_products
   where barcode in ('59000001', '59000002')),
  1,
  'cache boundary retains the fresh row'
);
select is(
  (select count(*)::integer
   from private.writer_idempotency_keys
   where source_record_id in ('59000001', '59000002')),
  1,
  'idempotency boundary retains the recent event'
);
select is(
  (select count(*)::integer
   from private.writer_daily_usage
   where usage_date in (
     select (now at time zone 'UTC')::date - offset_days
     from retention_test_clock
     cross join (values (401), (399)) as offsets(offset_days)
   )),
  1,
  'daily-usage boundary retains the newer row'
);
select is(
  (select count(*)::integer
   from cron.job_run_details
   where command in ('retention-old', 'retention-fresh')),
  1,
  'cron-history boundary retains the newer run'
);
select is(
  (select count(*)::integer
   from private.writer_audit_log
   where request_id = 'request-retention-expired'),
  0,
  'approved cleanup removes the expired append-only audit record'
);
select is(
  (select count(*)::integer
   from private.writer_record_watermarks
   where source_record_id = '59000001'),
  1,
  'durable watermark survives cache and idempotency cleanup'
);

select is(
  (
    public.publish_off_product(
      'request-retention-replay',
      'correlation-retention-replay',
      'scheduled_ingestion_job',
      '59000001',
      '{"code":"59000001","product_name":"Old cache"}'::jsonb,
      (select now - interval '6 days' from retention_test_clock),
      (select now from retention_test_clock),
      (select now + interval '6 days' from retention_test_clock),
      'v3'
    ) ->> 'status'
  ),
  'duplicate_existing',
  'exact replay safely repopulates a cleaned cache from the watermark'
);
select is(
  (select count(*)::integer
   from public.cached_products
   where barcode = '59000001'),
  1,
  'exact replay restores exactly one cache row'
);
update public.cached_products
set payload = '{"code":"59000001","product_name":"Corrupted cache"}'::jsonb
where barcode = '59000001';
select lives_ok(
  $$
    select public.publish_off_product(
      'request-retention-repair',
      'correlation-retention-repair',
      'scheduled_ingestion_job',
      '59000001',
      '{"code":"59000001","product_name":"Old cache"}'::jsonb,
      (select now - interval '6 days' from retention_test_clock),
      (select now from retention_test_clock),
      (select now + interval '6 days' from retention_test_clock),
      'v3'
    )
  $$,
  'exact replay can repair cache content from the durable watermark'
);
select is(
  (select payload ->> 'product_name'
   from public.cached_products
   where barcode = '59000001'),
  'Old cache',
  'exact replay restores the hash-bound cache payload'
);
select is(
  (
    public.publish_off_product(
      'request-retention-older',
      'correlation-retention-older',
      'scheduled_ingestion_job',
      '59000001',
      '{"code":"59000001","product_name":"Older replay"}'::jsonb,
      (select now - interval '7 days' from retention_test_clock),
      (select now from retention_test_clock),
      (select now + interval '6 days' from retention_test_clock),
      'v3'
    ) ->> 'status'
  ),
  'rejected_older_observation',
  'watermark rejects an older observation after cleanup'
);
select is(
  (
    public.publish_off_product(
      'request-retention-conflict',
      'correlation-retention-conflict',
      'scheduled_ingestion_job',
      '59000001',
      '{"code":"59000001","product_name":"Conflicting replay"}'::jsonb,
      (select now - interval '6 days' from retention_test_clock),
      (select now from retention_test_clock),
      (select now + interval '6 days' from retention_test_clock),
      'v3'
    ) ->> 'status'
  ),
  'rejected_conflicting_observation',
  'watermark rejects a different payload at the same observation time'
);
select is(
  (select count(*)::integer
   from private.writer_record_watermarks
   where source_record_id in ('59000001', '59000002')),
  2,
  'cleanup and replay keep one watermark per source record'
);

select * from finish();
rollback;
