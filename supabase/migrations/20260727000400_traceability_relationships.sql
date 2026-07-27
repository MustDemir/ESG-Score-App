-- Evidence-backed subject identity and traceability relationships.
-- Relationships remain server-maintained and are score-ineligible by default.

create table if not exists public.traceability_entities (
  id text primary key,
  entity_type text not null
    check (
      entity_type in (
        'product',
        'category',
        'commodity',
        'country',
        'location',
        'brand',
        'legal_entity',
        'supply_chain_node'
      )
    ),
  display_name text not null,
  metadata jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (id ~ '^[a-z][a-z0-9_-]*:.+$')
);

create table if not exists public.traceability_entity_identifiers (
  entity_id text not null
    references public.traceability_entities(id) on delete cascade,
  scheme text not null
    check (
      scheme in (
        'gtin',
        'gs1_gpc',
        'open_food_facts_tag',
        'iso_3166_1_alpha_2',
        'lei',
        'brand_name',
        'scanfair_commodity',
        'hs_code',
        'internal'
      )
    ),
  identifier_value text not null,
  issuer text,
  is_primary boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (entity_id, scheme, identifier_value),
  unique (scheme, identifier_value)
);

create table if not exists public.traceability_relationships (
  id uuid primary key default extensions.gen_random_uuid(),
  from_entity_id text not null
    references public.traceability_entities(id) on delete restrict,
  to_entity_id text not null
    references public.traceability_entities(id) on delete restrict,
  relationship_type text not null
    check (
      relationship_type in (
        'contains_commodity',
        'has_product_origin',
        'commodity_has_origin',
        'marketed_by_brand',
        'responsible_legal_entity',
        'owned_by_legal_entity'
      )
    ),
  assertion_class text not null
    check (
      assertion_class in (
        'measured',
        'verified',
        'declared',
        'modeled',
        'category_average',
        'community_reported',
        'inferred',
        'unknown'
      )
    ),
  confidence text not null
    check (confidence in ('high', 'medium', 'low', 'unknown')),
  source_id text not null references public.data_sources(id) on delete restrict,
  source_record_id text not null,
  evidence_ids text[] not null default '{}',
  score_eligible boolean not null default false,
  retrieved_at timestamptz not null,
  observed_at timestamptz,
  valid_from timestamptz,
  valid_to timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint traceability_relationships_distinct_entities_check
    check (from_entity_id <> to_entity_id),
  constraint traceability_relationships_validity_check
    check (valid_to is null or valid_from is null or valid_to > valid_from),
  constraint traceability_relationships_score_eligible_check
    check (
      not score_eligible
      or (
        cardinality(evidence_ids) > 0
        and confidence in ('high', 'medium')
        and assertion_class in ('measured', 'verified', 'declared')
      )
    ),
  unique (
    from_entity_id,
    to_entity_id,
    relationship_type,
    source_id,
    source_record_id
  )
);

alter table public.score_snapshots
  add column if not exists data_confidence_score numeric(5, 2)
  check (data_confidence_score between 0 and 100),
  add column if not exists relationship_ids uuid[] not null default '{}',
  add column if not exists red_flag_evidence_ids text[] not null default '{}';

create index if not exists traceability_entities_type_idx
  on public.traceability_entities (entity_type);
create index if not exists traceability_identifiers_lookup_idx
  on public.traceability_entity_identifiers (scheme, identifier_value);
create index if not exists traceability_relationships_from_idx
  on public.traceability_relationships (
    from_entity_id,
    relationship_type,
    score_eligible
  );
create index if not exists traceability_relationships_to_idx
  on public.traceability_relationships (
    to_entity_id,
    relationship_type,
    score_eligible
  );

alter table public.traceability_entities enable row level security;
alter table public.traceability_entity_identifiers enable row level security;
alter table public.traceability_relationships enable row level security;

alter table public.traceability_entities force row level security;
alter table public.traceability_entity_identifiers force row level security;
alter table public.traceability_relationships force row level security;

revoke all on table public.traceability_entities from anon, authenticated;
revoke all on table public.traceability_entity_identifiers
  from anon, authenticated;
revoke all on table public.traceability_relationships
  from anon, authenticated;

grant select on table public.traceability_entities to anon, authenticated;
grant select on table public.traceability_entity_identifiers
  to anon, authenticated;
grant select on table public.traceability_relationships
  to anon, authenticated;

create policy "Published traceability entities are readable"
  on public.traceability_entities
  for select
  to anon, authenticated
  using (published_at is not null);

create policy "Identifiers of published entities are readable"
  on public.traceability_entity_identifiers
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.traceability_entities
      where traceability_entities.id =
        traceability_entity_identifiers.entity_id
        and traceability_entities.published_at is not null
    )
  );

create policy "Published traceability relationships are readable"
  on public.traceability_relationships
  for select
  to anon, authenticated
  using (
    published_at is not null
    and exists (
      select 1
      from public.traceability_entities
      where traceability_entities.id =
        traceability_relationships.from_entity_id
        and traceability_entities.published_at is not null
    )
    and exists (
      select 1
      from public.traceability_entities
      where traceability_entities.id =
        traceability_relationships.to_entity_id
        and traceability_entities.published_at is not null
    )
  );
