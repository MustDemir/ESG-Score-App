begin;

create extension if not exists pgtap with schema extensions;

select plan(52);

select has_schema('private', 'private writer schema exists');
select has_table(
  'private',
  'writer_idempotency_keys',
  'writer idempotency table exists'
);
select has_table('private', 'writer_audit_log', 'writer audit table exists');
select has_table(
  'private',
  'writer_rate_windows',
  'writer rate-window table exists'
);
select has_table(
  'private',
  'writer_daily_usage',
  'writer daily-usage table exists'
);
select has_table(
  'private',
  'writer_circuit_state',
  'writer circuit-breaker table exists'
);
select has_column(
  'public',
  'cached_products',
  'source_observed_at',
  'cache stores the upstream observation time'
);
select has_function(
  'public',
  'get_fresh_cached_product',
  array['text', 'text'],
  'bounded cache-read function exists'
);
select has_function(
  'public',
  'claim_writer_capacity',
  array['text', 'text', 'integer'],
  'writer capacity function exists'
);
select has_function(
  'public',
  'publish_off_product',
  array[
    'text',
    'text',
    'text',
    'text',
    'jsonb',
    'timestamp with time zone',
    'timestamp with time zone',
    'timestamp with time zone',
    'text'
  ],
  'transactional OFF publication function exists'
);
select has_function(
  'public',
  'record_writer_outcome',
  array['text', 'text', 'text', 'text', 'text', 'text', 'integer'],
  'writer outcome audit function exists'
);
select has_function(
  'public',
  'record_writer_upstream_health',
  array['text', 'boolean'],
  'writer circuit-breaker function exists'
);

select is(
  has_table_privilege('anon', 'public.cached_products', 'SELECT'),
  false,
  'anon cannot enumerate the cache table'
);
select is(
  has_table_privilege('authenticated', 'public.cached_products', 'SELECT'),
  false,
  'authenticated cannot enumerate the cache table'
);
select is(
  has_function_privilege(
    'anon',
    'public.get_fresh_cached_product(text,text)',
    'EXECUTE'
  ),
  true,
  'anon can execute only the bounded cache read'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.get_fresh_cached_product(text,text)',
    'EXECUTE'
  ),
  true,
  'authenticated can execute the bounded cache read'
);
select is(
  has_function_privilege(
    'anon',
    'public.publish_off_product(text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text)',
    'EXECUTE'
  ),
  false,
  'anon cannot execute the writer publication function'
);
select is(
  has_function_privilege(
    'authenticated',
    'public.publish_off_product(text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text)',
    'EXECUTE'
  ),
  false,
  'authenticated cannot execute the writer publication function'
);
select is(
  has_function_privilege(
    'anon',
    'public.claim_writer_capacity(text,text,integer)',
    'EXECUTE'
  ),
  false,
  'anon cannot claim writer capacity'
);
select is(
  has_function_privilege(
    'service_role',
    'public.publish_off_product(text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text)',
    'EXECUTE'
  ),
  true,
  'server role can publish through the bounded function'
);
select is(
  has_function_privilege(
    'service_role',
    'public.claim_writer_capacity(text,text,integer)',
    'EXECUTE'
  ),
  true,
  'server role can claim bounded capacity'
);
select is(
  has_function_privilege(
    'anon',
    'public.record_writer_upstream_health(text,boolean)',
    'EXECUTE'
  ),
  false,
  'anon cannot change writer circuit state'
);
select is(
  has_function_privilege(
    'service_role',
    'public.record_writer_upstream_health(text,boolean)',
    'EXECUTE'
  ),
  true,
  'server role can record upstream health'
);

create temporary table writer_test_clock as
select
  clock_timestamp() - interval '1 hour' as observed_at,
  clock_timestamp() as fetched_at,
  clock_timestamp() + interval '1 day' as expires_at;

select lives_ok(
  $$
    select public.publish_off_product(
      'request-0001',
      'correlation-0001',
      'scheduled_ingestion_job',
      '4000417025005',
      '{"code":"4000417025005","product_name":"Fresh product"}'::jsonb,
      (select observed_at from writer_test_clock),
      (select fetched_at + interval '2 hours' from writer_test_clock),
      (select expires_at + interval '2 hours' from writer_test_clock),
      'v3'
    )
  $$,
  'server publication succeeds with bounded valid input'
);

select is(
  (
    public.publish_off_product(
      'request-0002',
      'correlation-0002',
      'scheduled_ingestion_job',
      '4000417025005',
      '{"code":"4000417025005","product_name":"Fresh product"}'::jsonb,
      (select observed_at from writer_test_clock),
      (select fetched_at from writer_test_clock),
      (select expires_at from writer_test_clock),
      'v3'
    ) ->> 'status'
  ),
  'duplicate_existing',
  'replayed payload does not create a new publication'
);
select is(
  (
    select fetched_at
    from public.cached_products
    where source_id = 'open-food-facts' and barcode = '4000417025005'
  ),
  (select fetched_at + interval '2 hours' from writer_test_clock),
  'idempotent replay advances the successful fetch time'
);
select is(
  (
    select expires_at
    from public.cached_products
    where source_id = 'open-food-facts' and barcode = '4000417025005'
  ),
  (select expires_at + interval '2 hours' from writer_test_clock),
  'idempotent replay renews cache freshness without a new key'
);
select is(
  (
    select payload ->> 'product_name'
    from public.get_fresh_cached_product(
      'open-food-facts',
      '4000417025005'
    )
  ),
  'Fresh product',
  'bounded read returns the fresh published product'
);
select is(
  (select count(*)::integer from private.writer_idempotency_keys),
  1,
  'replay creates only one idempotency record'
);
select is(
  (select count(*)::integer from private.writer_audit_log),
  2,
  'publication and replay both leave append-only audit evidence'
);
select is(
  (
    public.publish_off_product(
      'request-0003',
      'correlation-0003',
      'scheduled_ingestion_job',
      '4000417025005',
      '{"code":"4000417025005","product_name":"Older product"}'::jsonb,
      (select observed_at - interval '1 hour' from writer_test_clock),
      (select fetched_at from writer_test_clock),
      (select expires_at from writer_test_clock),
      'v3'
    ) ->> 'status'
  ),
  'rejected_older_observation',
  'out-of-order source data is rejected'
);
select is(
  (
    select payload ->> 'product_name'
    from public.cached_products
    where source_id = 'open-food-facts' and barcode = '4000417025005'
  ),
  'Fresh product',
  'out-of-order data cannot replace the fresh cache row'
);
select throws_ok(
  $$update private.writer_audit_log set outcome = 'tampered' where outcome = 'published'$$,
  'P0001',
  'writer audit records are append-only',
  'writer audit records cannot be modified'
);

update public.cached_products
set
  fetched_at = clock_timestamp() - interval '2 days',
  expires_at = clock_timestamp() - interval '1 day'
where source_id = 'open-food-facts' and barcode = '4000417025005';
select is(
  (
    select count(*)::integer
    from public.get_fresh_cached_product(
      'open-food-facts',
      '4000417025005'
    )
  ),
  0,
  'bounded read hides stale cache rows'
);

select lives_ok(
  $$
    select public.claim_writer_capacity(
      'request-capacity-0001',
      'scheduled_ingestion_job',
      1
    )
  $$,
  'authorized writer can claim bounded capacity'
);
select lives_ok(
  $$
    select public.record_writer_upstream_health(
      'open-food-facts',
      false
    )
    from generate_series(1, 5)
  $$,
  'five consecutive upstream failures are recorded'
);
select is(
  (
    select opened_until > clock_timestamp()
    from private.writer_circuit_state
    where source_id = 'open-food-facts'
  ),
  true,
  'five consecutive failures open the writer circuit'
);
select throws_ok(
  $$
    select public.claim_writer_capacity(
      'request-capacity-circuit',
      'scheduled_ingestion_job',
      1
    )
  $$,
  'P0001',
  'writer upstream circuit is open',
  'open circuit blocks another upstream batch'
);
select lives_ok(
  $$
    select public.record_writer_upstream_health(
      'open-food-facts',
      true
    )
  $$,
  'successful health signal resets the circuit'
);
select is(
  (
    select consecutive_failures = 0 and opened_until is null
    from private.writer_circuit_state
    where source_id = 'open-food-facts'
  ),
  true,
  'circuit reset clears failures and open time'
);
select throws_ok(
  $$
    select public.claim_writer_capacity(
      'request-capacity-0002',
      'mobile_application',
      1
    )
  $$,
  '42501',
  'writer actor is not authorized',
  'unknown writer actor is rejected'
);
select throws_ok(
  $$
    select public.claim_writer_capacity(
      'request-capacity-0003',
      'scheduled_ingestion_job',
      26
    )
  $$,
  '22023',
  'writer batch size is outside the allowed range',
  'oversized writer batch is rejected'
);

update private.writer_rate_windows
set request_count = 10
where scope = 'actor' and actor_type = 'scheduled_ingestion_job';
select throws_ok(
  $$
    select public.claim_writer_capacity(
      'request-capacity-0004',
      'scheduled_ingestion_job',
      1
    )
  $$,
  'P0001',
  'writer actor rate limit exceeded',
  'per-actor minute rate limit is fail-closed'
);

delete from private.writer_rate_windows;
update private.writer_daily_usage set upstream_request_count = 500;
select throws_ok(
  $$
    select public.claim_writer_capacity(
      'request-capacity-0005',
      'scheduled_ingestion_job',
      1
    )
  $$,
  'P0001',
  'writer daily upstream budget exceeded',
  'daily upstream budget is fail-closed'
);

select lives_ok(
  $$
    select public.record_writer_outcome(
      'request-outcome-0001',
      'correlation-outcome-0001',
      'audited_operator_replay',
      '12345678',
      repeat('a', 64),
      'not_found',
      404
    )
  $$,
  'bounded non-publication outcome can be audited'
);
select is(
  (
    select count(*)::integer
    from private.writer_audit_log
    where outcome = 'not_found'
  ),
  1,
  'non-publication outcome is present in the audit trail'
);
select lives_ok(
  $$
    select public.record_writer_outcome(
      'request-outcome-0002',
      'correlation-outcome-0002',
      'scheduled_ingestion_job',
      '12345678',
      repeat('b', 64),
      'database_rejected',
      409
    )
  $$,
  'database publication failure can be audited separately'
);
select is(
  (
    select action || ':' || outcome
    from private.writer_audit_log
    where request_id = 'request-outcome-0002'
  ),
  'publish_product_cache:database_rejected',
  'database failure evidence identifies the publication boundary'
);
select hasnt_column(
  'private',
  'writer_audit_log',
  'authorization_header',
  'audit table cannot store authorization headers'
);
select hasnt_column(
  'private',
  'writer_audit_log',
  'secret_or_service_key',
  'audit table cannot store privileged keys'
);
select hasnt_column(
  'private',
  'writer_audit_log',
  'raw_personal_payload',
  'audit table cannot store raw personal payloads'
);
select hasnt_column(
  'private',
  'writer_audit_log',
  'full_upstream_response',
  'audit table cannot store full upstream responses'
);

select * from finish();
rollback;
