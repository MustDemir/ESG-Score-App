begin;

create extension if not exists pgtap with schema extensions;

select plan(8);

select is(
  (
    select count(*)::integer
    from (
      values
        ('public.data_sources'),
        ('public.cached_products'),
        ('public.product_evidence'),
        ('public.score_snapshots'),
        ('public.scans'),
        ('public.methodology_versions'),
        ('public.parameters'),
        ('public.category_profiles'),
        ('public.profile_parameters'),
        ('public.source_mappings'),
        ('public.traceability_entities'),
        ('public.traceability_entity_identifiers'),
        ('public.traceability_relationships')
    ) as application_tables(table_name)
    cross join (
      values
        ('SELECT'),
        ('INSERT'),
        ('UPDATE'),
        ('DELETE'),
        ('TRUNCATE'),
        ('REFERENCES'),
        ('TRIGGER')
    ) as privileges(privilege_name)
    where pg_catalog.has_table_privilege(
      'service_role',
      application_tables.table_name,
      privileges.privilege_name
    )
  ),
  0,
  'service_role has no direct privileges on public application tables'
);

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_class as relation
    join pg_catalog.pg_namespace as namespace
      on namespace.oid = relation.relnamespace
    cross join (
      values
        ('SELECT'),
        ('INSERT'),
        ('UPDATE'),
        ('DELETE'),
        ('TRUNCATE'),
        ('REFERENCES'),
        ('TRIGGER')
    ) as privileges(privilege_name)
    where namespace.nspname = 'private'
      and relation.relkind in ('r', 'p')
      and pg_catalog.has_table_privilege(
        'service_role',
        relation.oid,
        privileges.privilege_name
      )
  ),
  0,
  'service_role has no direct privileges on private writer tables'
);

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_class as sequence
    join pg_catalog.pg_namespace as namespace
      on namespace.oid = sequence.relnamespace
    where namespace.nspname in ('public', 'private')
      and sequence.relkind = 'S'
      and (
        pg_catalog.has_sequence_privilege(
          'service_role', sequence.oid, 'USAGE'
        )
        or pg_catalog.has_sequence_privilege(
          'service_role', sequence.oid, 'SELECT'
        )
        or pg_catalog.has_sequence_privilege(
          'service_role', sequence.oid, 'UPDATE'
        )
      )
  ),
  0,
  'service_role has no direct public or private sequence privileges'
);

select ok(
  pg_catalog.has_function_privilege(
    'service_role',
    'public.claim_writer_capacity(text,text,integer)',
    'EXECUTE'
  ),
  'service_role can execute writer capacity RPC'
);
select ok(
  pg_catalog.has_function_privilege(
    'service_role',
    'public.record_writer_upstream_health(text,boolean)',
    'EXECUTE'
  ),
  'service_role can execute upstream health RPC'
);
select ok(
  pg_catalog.has_function_privilege(
    'service_role',
    'public.publish_off_product(text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text)',
    'EXECUTE'
  ),
  'service_role can execute product publication RPC'
);
select ok(
  pg_catalog.has_function_privilege(
    'service_role',
    'public.record_writer_outcome(text,text,text,text,text,text,integer)',
    'EXECUTE'
  ),
  'service_role can execute writer outcome RPC'
);
select ok(
  pg_catalog.has_function_privilege(
    'anon',
    'public.get_published_product_evidence(text)',
    'EXECUTE'
  ),
  'public bounded read RPC remains executable after writer hardening'
);

select * from finish();
rollback;
