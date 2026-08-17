begin;

create extension if not exists pgtap with schema extensions;

select plan(23);

-- F-10: service_role must not write the cache table directly; all writes go
-- through the SECURITY DEFINER publication function.
select is(
  has_table_privilege('service_role', 'public.cached_products', 'INSERT'),
  false,
  'service_role cannot insert into the cache table directly'
);
select is(
  has_table_privilege('service_role', 'public.cached_products', 'UPDATE'),
  false,
  'service_role cannot update the cache table directly'
);
select is(
  has_table_privilege('service_role', 'public.cached_products', 'DELETE'),
  false,
  'service_role cannot delete from the cache table directly'
);

-- F-18: the orphaned permissive read policy is gone; a future select grant
-- alone can no longer re-open the enumerable list endpoint.
select is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public'
      and tablename = 'cached_products'
  ),
  0,
  'cached_products carries no permissive read policy'
);

-- F-18: the cache TTL is bounded at the table level.
select throws_ok(
  $$
    insert into public.cached_products (
      source_id,
      barcode,
      payload,
      payload_sha256,
      source_observed_at,
      fetched_at,
      expires_at
    ) values (
      'open-food-facts',
      '40123455',
      '{"product_name":"ttl fixture"}'::jsonb,
      repeat('c', 64),
      timezone('utc', now()),
      timezone('utc', now()),
      timezone('utc', now()) + interval '8 days'
    )
  $$,
  '23514',
  null,
  'cache rows cannot be published with an unbounded ttl'
);

-- F-19: updated_at is maintained by trigger, not by caller discipline.
create temporary table hardening_updated_probe as
select updated_at
from public.data_sources
where id = 'open-food-facts';

update public.data_sources
set attribution = attribution
where id = 'open-food-facts';

select ok(
  (
    select sources.updated_at > probe.updated_at
    from public.data_sources sources, hardening_updated_probe probe
    where sources.id = 'open-food-facts'
  ),
  'updates refresh data_sources.updated_at through the trigger'
);

-- F-24: identical score inputs cannot create duplicate snapshots.
insert into public.score_snapshots (
  barcode,
  formula_version,
  score_state,
  data_completeness,
  input_fingerprint
) values (
  '40123455',
  '1.0',
  'data_incomplete',
  0.333,
  repeat('d', 64)
);

select throws_ok(
  $$
    insert into public.score_snapshots (
      barcode,
      formula_version,
      score_state,
      data_completeness,
      input_fingerprint
    ) values (
      '40123455',
      '1.0',
      'data_incomplete',
      0.333,
      repeat('d', 64)
    )
  $$,
  '23505',
  null,
  'identical score inputs cannot create duplicate snapshots'
);

-- F-12: covering indexes for the previously unindexed foreign keys.
select has_index(
  'public',
  'scans',
  'scans_score_snapshot_idx',
  'scans.score_snapshot_id has a covering index'
);
select has_index(
  'public',
  'traceability_relationships',
  'traceability_relationships_source_idx',
  'traceability_relationships.source_id has a covering index'
);
select has_index(
  'public',
  'source_mappings',
  'source_mappings_data_source_idx',
  'source_mappings.data_source_id has a covering index'
);
select has_index(
  'public',
  'profile_parameters',
  'profile_parameters_parameter_idx',
  'profile_parameters parameter FK has a covering index'
);
select has_index(
  'public',
  'category_profiles',
  'category_profiles_extends_idx',
  'category_profiles self reference has a covering index'
);
select has_index(
  'private',
  'writer_idempotency_keys',
  'writer_idempotency_keys_source_idx',
  'writer_idempotency_keys.source_id has a covering index'
);

-- F-12: the redundant indexes are gone.
select hasnt_index(
  'public',
  'profile_parameters',
  'profile_parameters_profile_idx',
  'redundant prefix index of the profile_parameters primary key is dropped'
);
select hasnt_index(
  'public',
  'traceability_entity_identifiers',
  'traceability_identifiers_lookup_idx',
  'redundant duplicate of the identifier unique constraint is dropped'
);

-- F-18: second defense layer on the private writer tables (enabled, not
-- forced, so the definer-owned writer functions keep working).
select ok(
  (select relrowsecurity from pg_class
   where oid = 'private.writer_idempotency_keys'::regclass),
  'writer_idempotency_keys has row level security enabled'
);
select ok(
  (select relrowsecurity from pg_class
   where oid = 'private.writer_audit_log'::regclass),
  'writer_audit_log has row level security enabled'
);
select ok(
  (select relrowsecurity from pg_class
   where oid = 'private.writer_rate_windows'::regclass),
  'writer_rate_windows has row level security enabled'
);
select ok(
  (select relrowsecurity from pg_class
   where oid = 'private.writer_daily_usage'::regclass),
  'writer_daily_usage has row level security enabled'
);
select ok(
  (select relrowsecurity from pg_class
   where oid = 'private.writer_circuit_state'::regclass),
  'writer_circuit_state has row level security enabled'
);
select ok(
  (select not relforcerowsecurity from pg_class
   where oid = 'private.writer_audit_log'::regclass),
  'private row level security is not forced onto the owning writer functions'
);

-- F-19: validation triggers no longer depend on the caller''s row visibility.
select ok(
  (select prosecdef from pg_proc
   where oid = 'public.enforce_traceability_context_type()'::regprocedure),
  'context type validation runs as definer'
);
select ok(
  (select prosecdef from pg_proc
   where oid = 'public.enforce_cached_product_license_boundary()'::regprocedure),
  'license boundary validation runs as definer'
);

select * from finish();
rollback;
