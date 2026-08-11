begin;

create extension if not exists pgtap with schema extensions;

select plan(71);

select has_table('public', 'data_sources', 'data_sources table exists');
select has_table('public', 'cached_products', 'cached_products table exists');
select has_table('public', 'product_evidence', 'product_evidence table exists');
select has_table('public', 'score_snapshots', 'score_snapshots table exists');
select has_table('public', 'scans', 'scans table exists');
select has_table(
  'public',
  'methodology_versions',
  'methodology_versions table exists'
);
select has_table('public', 'parameters', 'parameters table exists');
select has_table(
  'public',
  'category_profiles',
  'category_profiles table exists'
);
select has_table(
  'public',
  'profile_parameters',
  'profile_parameters table exists'
);
select has_table('public', 'source_mappings', 'source_mappings table exists');
select has_table(
  'public',
  'traceability_entities',
  'traceability_entities table exists'
);
select has_table(
  'public',
  'traceability_entity_identifiers',
  'traceability_entity_identifiers table exists'
);
select has_table(
  'public',
  'traceability_relationships',
  'traceability_relationships table exists'
);
select has_column(
  'public',
  'product_evidence',
  'retrieved_via_source_id',
  'evidence records its retrieval channel'
);
select has_column(
  'public',
  'score_snapshots',
  'data_confidence_score',
  'score snapshot records separate confidence'
);
select has_column(
  'public',
  'score_snapshots',
  'relationship_ids',
  'score snapshot records relationship lineage'
);
select has_column(
  'public',
  'score_snapshots',
  'red_flag_evidence_ids',
  'score snapshot records red-flag lineage'
);
select has_column(
  'public',
  'traceability_relationships',
  'context_entity_id',
  'commodity-origin relationship records product context'
);
select has_column(
  'public',
  'data_sources',
  'content_license',
  'data source records content license separately'
);
select has_column(
  'public',
  'data_sources',
  'image_license',
  'data source records image license separately'
);
select has_column(
  'public',
  'data_sources',
  'database_license_url',
  'data source records database license URL'
);
select has_column(
  'public',
  'data_sources',
  'content_license_url',
  'data source records content license URL'
);
select has_column(
  'public',
  'data_sources',
  'image_license_url',
  'data source records image license URL'
);
select has_column(
  'public',
  'data_sources',
  'license_partition',
  'data source records its license partition'
);
select has_column(
  'public',
  'data_sources',
  'raw_cache_policy',
  'data source records its raw cache policy'
);
select has_column(
  'public',
  'data_sources',
  'public_redistribution_policy',
  'data source records its redistribution policy'
);

select is(
  (
    select count(*)::integer
    from pg_class
    where oid in (
      'public.data_sources'::regclass,
      'public.cached_products'::regclass,
      'public.product_evidence'::regclass,
      'public.score_snapshots'::regclass,
      'public.scans'::regclass,
      'public.methodology_versions'::regclass,
      'public.parameters'::regclass,
      'public.category_profiles'::regclass,
      'public.profile_parameters'::regclass,
      'public.source_mappings'::regclass,
      'public.traceability_entities'::regclass,
      'public.traceability_entity_identifiers'::regclass,
      'public.traceability_relationships'::regclass
    )
      and relrowsecurity
  ),
  13,
  'RLS is enabled on every application table'
);

select is(
  (
    select count(*)::integer
    from pg_class
    where oid in (
      'public.data_sources'::regclass,
      'public.cached_products'::regclass,
      'public.product_evidence'::regclass,
      'public.score_snapshots'::regclass,
      'public.scans'::regclass,
      'public.methodology_versions'::regclass,
      'public.parameters'::regclass,
      'public.category_profiles'::regclass,
      'public.profile_parameters'::regclass,
      'public.source_mappings'::regclass,
      'public.traceability_entities'::regclass,
      'public.traceability_entity_identifiers'::regclass,
      'public.traceability_relationships'::regclass
    )
      and relforcerowsecurity
  ),
  13,
  'RLS is forced on every application table'
);

select results_eq(
  $$
    select dataset_license
    from public.data_sources
    where id = 'open-food-facts'
  $$,
  array['ODbL-1.0'::text],
  'Open Food Facts license is registered'
);

select results_eq(
  $$
    select content_license
    from public.data_sources
    where id = 'open-food-facts'
  $$,
  array['DbCL-1.0'::text],
  'Open Food Facts content license is registered'
);

select results_eq(
  $$
    select database_license_url
    from public.data_sources
    where id = 'open-food-facts'
  $$,
  array['https://opendatacommons.org/licenses/odbl/1-0/'::text],
  'Open Food Facts ODbL URL is registered'
);

select results_eq(
  $$
    select image_license
    from public.data_sources
    where id = 'open-food-facts'
  $$,
  array['CC-BY-SA-3.0'::text],
  'Open Food Facts image license is registered'
);

select results_eq(
  $$
    select license_partition
    from public.data_sources
    where id = 'open-food-facts'
  $$,
  array['off-odbl'::text],
  'Open Food Facts uses a dedicated license partition'
);

select results_eq(
  $$
    select raw_cache_policy
    from public.data_sources
    where id = 'agribalyse'
  $$,
  array['dedicated_store_required'::text],
  'AGRIBALYSE requires a dedicated raw-data store'
);

select results_eq(
  $$
    select raw_cache_policy
    from public.data_sources
    where id = 'gepa-product-declarations'
  $$,
  array['forbidden'::text],
  'GEPA raw publication caching is forbidden'
);

select lives_ok(
  $$
    insert into public.cached_products (
      source_id,
      barcode,
      payload,
      payload_sha256,
      fetched_at,
      expires_at
    ) values (
      'open-food-facts',
      '12345678',
      '{"product_name":"ODbL fixture"}'::jsonb,
      repeat('a', 64),
      timezone('utc', now()),
      timezone('utc', now()) + interval '1 day'
    )
  $$,
  'OFF payload can enter the isolated product cache'
);

select throws_ok(
  $$
    insert into public.cached_products (
      source_id,
      barcode,
      payload,
      payload_sha256,
      fetched_at,
      expires_at
    ) values (
      'agribalyse',
      '87654321',
      '{"name":"external fixture"}'::jsonb,
      repeat('b', 64),
      timezone('utc', now()),
      timezone('utc', now()) + interval '1 day'
    )
  $$,
  '23514',
  'external product data requires a dedicated license store',
  'external raw data cannot enter the OFF product cache'
);

select results_eq(
  $$
    select dataset_license
    from public.data_sources
    where id = 'agribalyse'
  $$,
  array['Etalab-2.0'::text],
  'AGRIBALYSE open-data license is registered'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.cached_products',
    'INSERT'
  ),
  false,
  'authenticated cannot insert cached products'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.product_evidence',
    'INSERT'
  ),
  false,
  'authenticated cannot insert evidence'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.score_snapshots',
    'INSERT'
  ),
  false,
  'authenticated cannot insert score snapshots'
);

select is(
  has_table_privilege('anon', 'public.cached_products', 'INSERT'),
  false,
  'anon cannot insert cached products'
);

select is(
  has_table_privilege('anon', 'public.data_sources', 'SELECT'),
  true,
  'anon can read active source metadata'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.methodology_versions',
    'INSERT'
  ),
  false,
  'authenticated cannot insert methodology versions'
);

select is(
  has_table_privilege('authenticated', 'public.parameters', 'INSERT'),
  false,
  'authenticated cannot insert parameters'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.category_profiles',
    'INSERT'
  ),
  false,
  'authenticated cannot insert category profiles'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.profile_parameters',
    'INSERT'
  ),
  false,
  'authenticated cannot insert profile parameters'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.source_mappings',
    'INSERT'
  ),
  false,
  'authenticated cannot insert source mappings'
);

select is(
  has_table_privilege('anon', 'public.methodology_versions', 'SELECT'),
  true,
  'anon can read published methodology metadata'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.traceability_entities',
    'INSERT'
  ),
  false,
  'authenticated cannot insert traceability entities'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.traceability_entity_identifiers',
    'INSERT'
  ),
  false,
  'authenticated cannot insert traceability identifiers'
);

select is(
  has_table_privilege(
    'authenticated',
    'public.traceability_relationships',
    'INSERT'
  ),
  false,
  'authenticated cannot insert traceability relationships'
);

select is(
  has_table_privilege('anon', 'public.traceability_relationships', 'SELECT'),
  true,
  'anon can read published traceability relationships'
);

insert into public.parameters (
  methodology_version_id,
  id,
  pillar,
  display_name_de,
  display_name_en,
  description_de,
  description_en,
  scope,
  result_kind,
  unit,
  missing_behavior,
  customer_claim_rule,
  status
)
values
  (
    '1.0',
    'E-TEST-PUBLISHED',
    'environmental',
    'Test veroeffentlicht',
    'Test published',
    'Published policy test parameter.',
    'Published policy test parameter.',
    'product',
    'performance',
    'score_0_100',
    'reduce_confidence',
    'evidence_only',
    'published'
  ),
  (
    '1.0',
    'E-TEST-DRAFT',
    'environmental',
    'Test Entwurf',
    'Test draft',
    'Draft policy test parameter.',
    'Draft policy test parameter.',
    'product',
    'performance',
    'score_0_100',
    'reduce_confidence',
    'evidence_only',
    'draft'
  );

insert into public.category_profiles (
  methodology_version_id,
  id,
  display_name_de,
  display_name_en,
  description_de,
  description_en,
  status
)
values
  (
    '1.0',
    'test-published',
    'Test veroeffentlicht',
    'Test published',
    'Published policy test profile.',
    'Published policy test profile.',
    'published'
  ),
  (
    '1.0',
    'test-draft',
    'Test Entwurf',
    'Test draft',
    'Draft policy test profile.',
    'Draft policy test profile.',
    'draft'
  );

insert into public.profile_parameters (
  methodology_version_id,
  profile_id,
  parameter_id,
  applicability,
  priority
)
values
  (
    '1.0',
    'test-published',
    'E-TEST-PUBLISHED',
    'required',
    'high'
  ),
  (
    '1.0',
    'test-draft',
    'E-TEST-DRAFT',
    'required',
    'high'
  );

insert into public.source_mappings (
  methodology_version_id,
  parameter_id,
  data_source_id,
  source_metric,
  mapping_rule,
  status,
  validated_on
)
values
  (
    '1.0',
    'E-TEST-PUBLISHED',
    'open-food-facts',
    'published_test_metric',
    '{}'::jsonb,
    'active',
    date '2026-07-27'
  ),
  (
    '1.0',
    'E-TEST-PUBLISHED',
    'open-food-facts',
    'candidate_test_metric',
    '{}'::jsonb,
    'candidate',
    null
  );

insert into public.traceability_entities (
  id,
  entity_type,
  display_name,
  published_at
)
values
  (
    'gtin:4000417025005',
    'product',
    'Published test product',
    timestamptz '2026-07-27T00:00:00Z'
  ),
  (
    'commodity:cocoa',
    'commodity',
    'Cocoa',
    timestamptz '2026-07-27T00:00:00Z'
  ),
  (
    'country:GH',
    'country',
    'Ghana',
    timestamptz '2026-07-27T00:00:00Z'
  ),
  (
    'legal_entity:draft-company',
    'legal_entity',
    'Draft company',
    null
  );

insert into public.traceability_entity_identifiers (
  entity_id,
  scheme,
  identifier_value,
  issuer,
  is_primary
)
values
  (
    'gtin:4000417025005',
    'gtin',
    '4000417025005',
    'GS1',
    true
  ),
  (
    'commodity:cocoa',
    'scanfair_commodity',
    'cocoa',
    'ScanFair',
    true
  ),
  (
    'country:GH',
    'iso_3166_1_alpha_2',
    'GH',
    'ISO',
    true
  ),
  (
    'legal_entity:draft-company',
    'internal',
    'draft-company',
    'ScanFair',
    true
  );

insert into public.traceability_relationships (
  from_entity_id,
  to_entity_id,
  relationship_type,
  assertion_class,
  confidence,
  source_id,
  source_record_id,
  evidence_ids,
  score_eligible,
  retrieved_at,
  published_at
)
values (
  'gtin:4000417025005',
  'commodity:cocoa',
  'contains_commodity',
  'community_reported',
  'low',
  'open-food-facts',
  '4000417025005',
  array['open-food-facts:4000417025005:commodity_cocoa'],
  false,
  timestamptz '2026-07-27T00:00:00Z',
  timestamptz '2026-07-27T00:00:00Z'
);

select throws_ok(
  $$
    insert into public.traceability_relationships (
      from_entity_id,
      to_entity_id,
      relationship_type,
      assertion_class,
      confidence,
      source_id,
      source_record_id,
      evidence_ids,
      score_eligible,
      retrieved_at
    )
    values (
      'gtin:4000417025005',
      'commodity:cocoa',
      'contains_commodity',
      'inferred',
      'low',
      'open-food-facts',
      'invalid-score-link',
      array['heuristic:commodity'],
      true,
      timestamptz '2026-07-27T00:00:00Z'
    )
  $$,
  '23514',
  'new row for relation "traceability_relationships" violates check constraint "traceability_relationships_score_eligible_check"',
  'inferred low-confidence relationship cannot be score-eligible'
);

select throws_ok(
  $$
    insert into public.traceability_relationships (
      from_entity_id,
      to_entity_id,
      relationship_type,
      assertion_class,
      confidence,
      source_id,
      source_record_id,
      evidence_ids,
      score_eligible,
      retrieved_at
    )
    values (
      'commodity:cocoa',
      'country:GH',
      'commodity_has_origin',
      'declared',
      'medium',
      'gepa-product-declarations',
      'missing-context',
      array['gepa:test:origin-gh'],
      true,
      timestamptz '2026-08-10T00:00:00Z'
    )
  $$,
  '23514',
  'new row for relation "traceability_relationships" violates check constraint "traceability_relationships_context_check"',
  'score-eligible commodity origin requires product context'
);

select throws_ok(
  $$
    insert into public.traceability_relationships (
      from_entity_id,
      to_entity_id,
      relationship_type,
      assertion_class,
      confidence,
      source_id,
      source_record_id,
      evidence_ids,
      score_eligible,
      context_entity_id,
      retrieved_at
    )
    values (
      'commodity:cocoa',
      'country:GH',
      'commodity_has_origin',
      'declared',
      'medium',
      'gepa-product-declarations',
      'wrong-context-type',
      array['gepa:test:origin-gh'],
      true,
      'legal_entity:draft-company',
      timestamptz '2026-08-10T00:00:00Z'
    )
  $$,
  '23514',
  'context_entity_id must reference a product entity',
  'commodity origin context must reference a product entity'
);

select lives_ok(
  $$
    insert into public.traceability_relationships (
      from_entity_id,
      to_entity_id,
      relationship_type,
      assertion_class,
      confidence,
      source_id,
      source_record_id,
      evidence_ids,
      score_eligible,
      context_entity_id,
      retrieved_at,
      published_at
    )
    values (
      'commodity:cocoa',
      'country:GH',
      'commodity_has_origin',
      'declared',
      'medium',
      'gepa-product-declarations',
      'valid-product-context',
      array['gepa:test:origin-gh'],
      true,
      'gtin:4000417025005',
      timestamptz '2026-08-10T00:00:00Z',
      timestamptz '2026-08-10T00:00:00Z'
    )
  $$,
  'declared product-scoped commodity origin is accepted'
);

set local role anon;

select results_eq(
  $$
    select id
    from public.methodology_versions
    order by id
  $$,
  array['1.0'::text],
  'anon sees published formula v1.0 but not methodology v2.0-draft'
);

select results_eq(
  $$
    select id
    from public.parameters
    order by id
  $$,
  array['E-TEST-PUBLISHED'::text],
  'anon sees only published parameters'
);

select results_eq(
  $$
    select id
    from public.category_profiles
    order by id
  $$,
  array['test-published'::text],
  'anon sees only published category profiles'
);

select results_eq(
  $$
    select profile_id
    from public.profile_parameters
    order by profile_id
  $$,
  array['test-published'::text],
  'anon sees mappings for published profiles only'
);

select results_eq(
  $$
    select source_metric
    from public.source_mappings
    order by source_metric
  $$,
  array['published_test_metric'::text],
  'anon sees active source mappings only'
);

select results_eq(
  $$
    select id
    from public.traceability_entities
    order by id
  $$,
  array[
    'commodity:cocoa'::text,
    'country:GH'::text,
    'gtin:4000417025005'::text
  ],
  'anon sees only published traceability entities'
);

select results_eq(
  $$
    select identifier_value
    from public.traceability_entity_identifiers
    order by lower(identifier_value), identifier_value
  $$,
  array['4000417025005'::text, 'cocoa'::text, 'GH'::text],
  'anon sees identifiers of published entities only'
);

select results_eq(
  $$
    select relationship_type
    from public.traceability_relationships
    order by relationship_type
  $$,
  array['commodity_has_origin'::text, 'contains_commodity'::text],
  'anon sees published traceability relationships only'
);

reset role;

insert into auth.users (id, email)
values
  ('10000000-0000-0000-0000-000000000001', 'user1@scanfair.local'),
  ('20000000-0000-0000-0000-000000000002', 'user2@scanfair.local');

insert into public.scans (user_id, barcode)
values
  ('10000000-0000-0000-0000-000000000001', '4000417025005'),
  ('20000000-0000-0000-0000-000000000002', '4337185353659');

set local role authenticated;
set local "request.jwt.claim.sub" =
  '10000000-0000-0000-0000-000000000001';

select results_eq(
  'select count(*)::bigint from public.scans',
  array[1::bigint],
  'user sees only own scans'
);

select lives_ok(
  $$
    insert into public.scans (user_id, barcode)
    values (
      '10000000-0000-0000-0000-000000000001',
      '4316268476546'
    )
  $$,
  'user can insert own scan'
);

select throws_ok(
  $$
    insert into public.scans (user_id, barcode)
    values (
      '20000000-0000-0000-0000-000000000002',
      '4006381333924'
    )
  $$,
  '42501',
  'new row violates row-level security policy for table "scans"',
  'user cannot insert another user scan'
);

select results_eq(
  'select count(*)::bigint from public.scans',
  array[2::bigint],
  'own insert remains visible without exposing other scans'
);

select lives_ok(
  $$
    delete from public.scans
    where user_id = '10000000-0000-0000-0000-000000000001'
  $$,
  'user can delete own scans'
);

select results_eq(
  $$
    delete from public.scans
    where user_id = '20000000-0000-0000-0000-000000000002'
    returning 1
  $$,
  $$ values (null::integer) limit 0 $$,
  'user cannot delete another user scan'
);

select * from finish();

rollback;
