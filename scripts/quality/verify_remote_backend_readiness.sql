do $verification$
declare
  constraint_definition text;
  evidence_count integer;
  evidence_id text;
  returned_score numeric;
  draft_count integer;
begin
  if pg_catalog.has_table_privilege(
    'anon', 'public.product_evidence', 'select'
  ) or pg_catalog.has_table_privilege(
    'authenticated', 'public.product_evidence', 'select'
  ) then
    raise exception 'client role still has direct product_evidence SELECT';
  end if;

  if pg_catalog.has_table_privilege(
    'anon', 'public.score_snapshots', 'select'
  ) or pg_catalog.has_table_privilege(
    'authenticated', 'public.score_snapshots', 'select'
  ) then
    raise exception 'client role still has direct score_snapshots SELECT';
  end if;

  if exists (
    select 1
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
  ) then
    raise exception 'service_role still has a direct application-table privilege';
  end if;

  if exists (
    select 1
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
        'service_role', relation.oid, privileges.privilege_name
      )
  ) then
    raise exception 'service_role still has a direct private-table privilege';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_class as sequence
    join pg_catalog.pg_namespace as namespace
      on namespace.oid = sequence.relnamespace
    where namespace.nspname in ('public', 'private')
      and sequence.relkind = 'S'
      and (
        pg_catalog.has_sequence_privilege('service_role', sequence.oid, 'USAGE')
        or pg_catalog.has_sequence_privilege('service_role', sequence.oid, 'SELECT')
        or pg_catalog.has_sequence_privilege('service_role', sequence.oid, 'UPDATE')
      )
  ) then
    raise exception 'service_role still has a direct application-sequence privilege';
  end if;

  if not pg_catalog.has_function_privilege(
    'service_role',
    'public.claim_writer_capacity(text,text,integer)',
    'execute'
  ) or not pg_catalog.has_function_privilege(
    'service_role',
    'public.record_writer_upstream_health(text,boolean)',
    'execute'
  ) or not pg_catalog.has_function_privilege(
    'service_role',
    'public.publish_off_product(text,text,text,text,jsonb,timestamptz,timestamptz,timestamptz,text)',
    'execute'
  ) or not pg_catalog.has_function_privilege(
    'service_role',
    'public.record_writer_outcome(text,text,text,text,text,text,integer)',
    'execute'
  ) then
    raise exception 'service_role cannot execute the complete bounded writer RPC set';
  end if;

  if not pg_catalog.has_function_privilege(
    'anon', 'public.get_published_product_evidence(text)', 'execute'
  ) or not pg_catalog.has_function_privilege(
    'anon', 'public.get_published_score_snapshot(text,text)', 'execute'
  ) then
    raise exception 'anon cannot execute a bounded read RPC';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename in ('product_evidence', 'score_snapshots')
  ) then
    raise exception 'direct evidence or snapshot read policy still exists';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_proc
    where oid in (
      'public.get_published_product_evidence(text)'::pg_catalog.regprocedure,
      'public.get_published_score_snapshot(text,text)'::pg_catalog.regprocedure
    )
      and not prosecdef
  ) then
    raise exception 'bounded read RPC is not SECURITY DEFINER';
  end if;

  select pg_catalog.pg_get_constraintdef(oid)
  into constraint_definition
  from pg_catalog.pg_constraint
  where conrelid = 'public.score_snapshots'::pg_catalog.regclass
    and conname = 'score_snapshots_score_state_check';

  if constraint_definition is null
    or pg_catalog.strpos(constraint_definition, 'partial_score') = 0
  then
    raise exception 'partial_score constraint is not deployed';
  end if;

  -- The exception block is a PostgreSQL subtransaction. The sentinel error
  -- rolls back every fixture and role change before it is handled as success.
  begin
    insert into public.product_evidence (
      id, source_id, subject_type, subject_id, source_record_id,
      source_record_url, source_field, metric, value_text, numeric_value, unit,
      pillars, scope, quality, retrieved_at, published_at
    ) values
      (
        'remote-verification-published', 'open-food-facts', 'product',
        '50999991', 'remote-verification-published',
        'https://world.openfoodfacts.org/product/50999991', 'ecoscore_score',
        'environmental_score', '81', 81, 'score', array['environmental'],
        'product', 'source_calculated', pg_catalog.clock_timestamp(),
        pg_catalog.clock_timestamp()
      ),
      (
        'remote-verification-draft', 'open-food-facts', 'product', '50999991',
        'remote-verification-draft',
        'https://world.openfoodfacts.org/product/50999991', 'labels_tags',
        'draft_signal', 'draft', null, null, array['social'], 'product',
        'community_provided', pg_catalog.clock_timestamp(), null
      );

    insert into public.score_snapshots (
      barcode, formula_version, score_state, environmental_score, total_score,
      data_completeness, input_fingerprint, calculated_at, published_at
    ) values
      (
        '50999991', '1.1', 'partial_score', 81, 81, 0.333,
        pg_catalog.repeat('9', 64),
        pg_catalog.clock_timestamp() - interval '1 minute',
        pg_catalog.clock_timestamp() - interval '1 minute'
      ),
      (
        '50999991', '1.2-draft', 'full_score', 99, 99, 1,
        pg_catalog.repeat('8', 64), pg_catalog.clock_timestamp(), null
      );

    execute 'set local role anon';

    select count(*)::integer, min(id)
    into evidence_count, evidence_id
    from public.get_published_product_evidence('50999991');

    if evidence_count <> 1
      or evidence_id <> 'remote-verification-published'
    then
      raise exception 'bounded evidence RPC leaked or omitted rows';
    end if;

    select total_score
    into returned_score
    from public.get_published_score_snapshot('50999991');

    if returned_score <> 81 then
      raise exception 'bounded score RPC returned draft or wrong snapshot';
    end if;

    select count(*)::integer
    into draft_count
    from public.get_published_score_snapshot('50999991', '1.2-draft');

    if draft_count <> 0 then
      raise exception 'unpublished score snapshot leaked';
    end if;

    if exists (
      select 1 from public.get_published_product_evidence('invalid')
    ) then
      raise exception 'invalid barcode returned evidence';
    end if;

    raise exception 'SCANFAIR_VERIFICATION_ROLLBACK';
  exception
    when raise_exception then
      if sqlerrm <> 'SCANFAIR_VERIFICATION_ROLLBACK' then
        raise;
      end if;
  end;
end
$verification$;
