-- Versioned ScanFair methodology catalog.
-- Only published versions are client-readable. Catalog writes are server-only.

create table if not exists public.methodology_versions (
  id text primary key,
  display_name text not null,
  status text not null
    check (status in ('draft', 'review', 'published', 'deprecated')),
  formula_schema_version integer not null
    check (formula_schema_version > 0),
  description text not null,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (id ~ '^[0-9]+\.[0-9]+(-[a-z0-9-]+)?$'),
  check (
    (status = 'published' and published_at is not null)
    or (status <> 'published' and published_at is null)
  )
);

create table if not exists public.parameters (
  methodology_version_id text not null
    references public.methodology_versions(id) on delete restrict,
  id text not null,
  pillar text not null
    check (
      pillar in (
        'environmental',
        'social',
        'governance',
        'data_confidence'
      )
    ),
  display_name_de text not null,
  display_name_en text not null,
  description_de text not null,
  description_en text not null,
  scope text not null
    check (
      scope in (
        'product',
        'category',
        'commodity_country',
        'company',
        'supply_chain'
      )
    ),
  result_kind text not null
    check (
      result_kind in ('performance', 'risk', 'assurance', 'confidence')
    ),
  unit text not null,
  missing_behavior text not null
    check (
      missing_behavior in (
        'reduce_confidence',
        'not_applicable_when_out_of_scope',
        'block_factor_assessment'
      )
    ),
  customer_claim_rule text not null
    check (
      customer_claim_rule in (
        'evidence_only',
        'risk_not_product_finding',
        'assurance_only',
        'confidence_only'
      )
    ),
  status text not null
    check (status in ('draft', 'review', 'published', 'deprecated')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (methodology_version_id, id),
  check (id ~ '^[ESGD]-[A-Z0-9-]+$'),
  check (
    (pillar = 'data_confidence' and result_kind = 'confidence')
    or (pillar <> 'data_confidence' and result_kind <> 'confidence')
  ),
  check (
    result_kind <> 'risk'
    or customer_claim_rule in ('evidence_only', 'risk_not_product_finding')
  )
);

create table if not exists public.category_profiles (
  methodology_version_id text not null
    references public.methodology_versions(id) on delete restrict,
  id text not null,
  display_name_de text not null,
  display_name_en text not null,
  description_de text not null,
  description_en text not null,
  extends_profile_id text,
  status text not null
    check (status in ('draft', 'review', 'published', 'deprecated')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (methodology_version_id, id),
  foreign key (methodology_version_id, extends_profile_id)
    references public.category_profiles(methodology_version_id, id)
    on delete restrict,
  check (id ~ '^[a-z0-9][a-z0-9-]*$'),
  check (extends_profile_id is null or extends_profile_id <> id)
);

create table if not exists public.profile_parameters (
  methodology_version_id text not null,
  profile_id text not null,
  parameter_id text not null,
  applicability text not null
    check (applicability in ('required', 'conditional', 'not_applicable')),
  priority text not null check (priority in ('high', 'medium', 'low')),
  condition_note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (methodology_version_id, profile_id, parameter_id),
  foreign key (methodology_version_id, profile_id)
    references public.category_profiles(methodology_version_id, id)
    on delete cascade,
  foreign key (methodology_version_id, parameter_id)
    references public.parameters(methodology_version_id, id)
    on delete restrict
);

create table if not exists public.source_mappings (
  id uuid primary key default extensions.gen_random_uuid(),
  methodology_version_id text not null,
  parameter_id text not null,
  data_source_id text not null references public.data_sources(id)
    on delete restrict,
  source_metric text not null,
  mapping_rule jsonb not null,
  status text not null
    check (status in ('candidate', 'validated', 'active', 'rejected')),
  validated_on date,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  foreign key (methodology_version_id, parameter_id)
    references public.parameters(methodology_version_id, id)
    on delete restrict,
  unique (
    methodology_version_id,
    parameter_id,
    data_source_id,
    source_metric
  ),
  check (
    (status in ('validated', 'active') and validated_on is not null)
    or (status in ('candidate', 'rejected'))
  )
);

create index if not exists parameters_pillar_idx
  on public.parameters (methodology_version_id, pillar);
create index if not exists profile_parameters_profile_idx
  on public.profile_parameters (methodology_version_id, profile_id);
create index if not exists source_mappings_parameter_idx
  on public.source_mappings (methodology_version_id, parameter_id);

alter table public.methodology_versions enable row level security;
alter table public.parameters enable row level security;
alter table public.category_profiles enable row level security;
alter table public.profile_parameters enable row level security;
alter table public.source_mappings enable row level security;

alter table public.methodology_versions force row level security;
alter table public.parameters force row level security;
alter table public.category_profiles force row level security;
alter table public.profile_parameters force row level security;
alter table public.source_mappings force row level security;

revoke all on table public.methodology_versions from anon, authenticated;
revoke all on table public.parameters from anon, authenticated;
revoke all on table public.category_profiles from anon, authenticated;
revoke all on table public.profile_parameters from anon, authenticated;
revoke all on table public.source_mappings from anon, authenticated;

grant select on table public.methodology_versions to anon, authenticated;
grant select on table public.parameters to anon, authenticated;
grant select on table public.category_profiles to anon, authenticated;
grant select on table public.profile_parameters to anon, authenticated;
grant select on table public.source_mappings to anon, authenticated;

create policy "Published methodology versions are readable"
  on public.methodology_versions
  for select
  to anon, authenticated
  using (status = 'published');

create policy "Published parameters are readable"
  on public.parameters
  for select
  to anon, authenticated
  using (
    status = 'published'
    and exists (
      select 1
      from public.methodology_versions
      where methodology_versions.id = parameters.methodology_version_id
        and methodology_versions.status = 'published'
    )
  );

create policy "Published category profiles are readable"
  on public.category_profiles
  for select
  to anon, authenticated
  using (
    status = 'published'
    and exists (
      select 1
      from public.methodology_versions
      where methodology_versions.id =
        category_profiles.methodology_version_id
        and methodology_versions.status = 'published'
    )
  );

create policy "Published profile parameters are readable"
  on public.profile_parameters
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.category_profiles
      where category_profiles.methodology_version_id =
        profile_parameters.methodology_version_id
        and category_profiles.id = profile_parameters.profile_id
        and category_profiles.status = 'published'
    )
  );

create policy "Published source mappings are readable"
  on public.source_mappings
  for select
  to anon, authenticated
  using (
    status = 'active'
    and exists (
      select 1
      from public.methodology_versions
      where methodology_versions.id =
        source_mappings.methodology_version_id
        and methodology_versions.status = 'published'
    )
    and exists (
      select 1
      from public.parameters
      where parameters.methodology_version_id =
        source_mappings.methodology_version_id
        and parameters.id = source_mappings.parameter_id
        and parameters.status = 'published'
    )
  );

insert into public.methodology_versions (
  id,
  display_name,
  status,
  formula_schema_version,
  description,
  published_at
)
values
  (
    '1.0',
    'ScanFair MVP formula',
    'published',
    1,
    'Current local MVP formula defined by ADR 0011.',
    timestamptz '2026-05-19T00:00:00Z'
  ),
  (
    '2.0-draft',
    'Hierarchical food methodology',
    'draft',
    1,
    'Draft parameter catalog. Not approved for customer-facing scores.',
    null
  )
on conflict (id) do update set
  display_name = excluded.display_name,
  status = excluded.status,
  formula_schema_version = excluded.formula_schema_version,
  description = excluded.description,
  published_at = excluded.published_at,
  updated_at = timezone('utc', now());
