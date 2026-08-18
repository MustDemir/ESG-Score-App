begin;

create extension if not exists pgtap with schema extensions;

select plan(21);

select lives_ok(
  $$
    insert into public.score_snapshots (
      barcode,
      formula_version,
      score_state,
      environmental_score,
      total_score,
      data_completeness,
      input_fingerprint
    ) values (
      '50123456',
      '1.1',
      'partial_score',
      75,
      75,
      0.333,
      repeat('1', 64)
    )
  $$,
  'formula v1.1 partial_score can be persisted'
);

select is(
  has_table_privilege('anon', 'public.product_evidence', 'SELECT'),
  false,
  'anon cannot enumerate product evidence directly'
);
select is(
  has_table_privilege('authenticated', 'public.product_evidence', 'SELECT'),
  false,
  'authenticated cannot enumerate product evidence directly'
);
select is(
  has_table_privilege('anon', 'public.score_snapshots', 'SELECT'),
  false,
  'anon cannot enumerate score snapshots directly'
);
select is(
  has_table_privilege('authenticated', 'public.score_snapshots', 'SELECT'),
  false,
  'authenticated cannot enumerate score snapshots directly'
);

select is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public'
      and tablename = 'product_evidence'
  ),
  0,
  'product evidence has no permissive direct-read policy'
);
select is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public'
      and tablename = 'score_snapshots'
  ),
  0,
  'score snapshots have no permissive direct-read policy'
);

select has_function(
  'public',
  'get_published_product_evidence',
  array['text'],
  'bounded evidence function exists'
);
select has_function(
  'public',
  'get_published_score_snapshot',
  array['text', 'text'],
  'bounded score snapshot function exists'
);
select ok(
  has_function_privilege(
    'anon',
    'public.get_published_product_evidence(text)',
    'EXECUTE'
  ),
  'anon can execute the bounded evidence function'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_published_product_evidence(text)',
    'EXECUTE'
  ),
  'authenticated can execute the bounded evidence function'
);
select ok(
  has_function_privilege(
    'anon',
    'public.get_published_score_snapshot(text,text)',
    'EXECUTE'
  ),
  'anon can execute the bounded score function'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_published_score_snapshot(text,text)',
    'EXECUTE'
  ),
  'authenticated can execute the bounded score function'
);

select is(
  (select count(*)::integer from public.get_published_product_evidence('bad')),
  0,
  'invalid evidence barcode returns no rows'
);
select is(
  (select count(*)::integer from public.get_published_score_snapshot('bad')),
  0,
  'invalid score barcode returns no rows'
);

insert into public.product_evidence (
  id,
  source_id,
  subject_type,
  subject_id,
  source_record_id,
  source_record_url,
  source_field,
  metric,
  value_text,
  numeric_value,
  unit,
  pillars,
  scope,
  quality,
  retrieved_at,
  published_at
) values
  (
    'remote-ready-published',
    'open-food-facts',
    'product',
    '50123456',
    'remote-ready-published',
    'https://world.openfoodfacts.org/product/50123456',
    'ecoscore_score',
    'environmental_score',
    '75',
    75,
    'score',
    array['environmental'],
    'product',
    'source_calculated',
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    'remote-ready-draft',
    'open-food-facts',
    'product',
    '50123456',
    'remote-ready-draft',
    'https://world.openfoodfacts.org/product/50123456',
    'labels_tags',
    'organic_label',
    'draft',
    null,
    null,
    array['environmental'],
    'product',
    'community_provided',
    timezone('utc', now()),
    null
  ),
  (
    'remote-ready-other-product',
    'open-food-facts',
    'product',
    '50123457',
    'remote-ready-other-product',
    'https://world.openfoodfacts.org/product/50123457',
    'ecoscore_score',
    'environmental_score',
    '20',
    20,
    'score',
    array['environmental'],
    'product',
    'source_calculated',
    timezone('utc', now()),
    timezone('utc', now())
  );

set local role anon;

select results_eq(
  $$
    select id
    from public.get_published_product_evidence('50123456')
  $$,
  array['remote-ready-published'::text],
  'evidence function returns only published rows for the exact product'
);
select is(
  (select count(*)::integer from public.get_published_product_evidence('50123458')),
  0,
  'unknown product barcode does not leak evidence'
);

reset role;

insert into public.score_snapshots (
  barcode,
  formula_version,
  score_state,
  environmental_score,
  social_score,
  governance_score,
  total_score,
  data_completeness,
  input_fingerprint,
  calculated_at,
  published_at
) values
  (
    '50123456', '1.0', 'full_score', 70, 70, 70, 70, 1,
    repeat('2', 64), timezone('utc', now()) - interval '2 hours',
    timezone('utc', now()) - interval '2 hours'
  ),
  (
    '50123456', '1.1', 'full_score', 80, 80, 80, 80, 1,
    repeat('3', 64), timezone('utc', now()) - interval '1 hour',
    timezone('utc', now()) - interval '1 hour'
  ),
  (
    '50123456', '1.2-draft', 'full_score', 99, 99, 99, 99, 1,
    repeat('4', 64), timezone('utc', now()), null
  );

set local role anon;

select results_eq(
  $$
    select total_score
    from public.get_published_score_snapshot('50123456')
  $$,
  array[80::numeric],
  'score function returns the latest published snapshot, not a newer draft'
);
select results_eq(
  $$
    select total_score
    from public.get_published_score_snapshot('50123456', '1.0')
  $$,
  array[70::numeric],
  'score function can select a published formula version'
);
select is(
  (
    select count(*)::integer
    from public.get_published_score_snapshot('50123456', '1.2-draft')
  ),
  0,
  'unpublished formula versions stay hidden'
);
select is(
  (select count(*)::integer from public.get_published_score_snapshot('50123458')),
  0,
  'unknown product barcode does not leak a score snapshot'
);

reset role;

select * from finish();
rollback;
