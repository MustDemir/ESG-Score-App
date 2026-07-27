-- ScanFair local data architecture.
-- Product facts are server-maintained and client-readable. User scans are private.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.data_sources (
  id text primary key,
  display_name text not null,
  source_url text not null check (source_url like 'https://%'),
  terms_url text not null check (terms_url like 'https://%'),
  dataset_license text not null,
  attribution text not null,
  api_version text,
  license_reviewed_on date not null,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (id ~ '^[a-z0-9][a-z0-9-]*$')
);

create table if not exists public.cached_products (
  source_id text not null references public.data_sources(id),
  barcode text not null check (barcode ~ '^[0-9]{8,14}$'),
  payload jsonb not null,
  source_schema_version text,
  payload_sha256 text not null check (payload_sha256 ~ '^[a-f0-9]{64}$'),
  fetched_at timestamptz not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (source_id, barcode),
  check (expires_at > fetched_at)
);

create table if not exists public.product_evidence (
  id text primary key,
  source_id text not null references public.data_sources(id),
  subject_type text not null
    check (subject_type in ('product', 'category', 'company', 'country')),
  subject_id text not null,
  source_record_id text not null,
  source_record_url text not null check (source_record_url like 'https://%'),
  source_field text not null,
  metric text not null,
  value_text text not null,
  numeric_value numeric,
  unit text,
  pillars text[] not null,
  scope text not null
    check (scope in ('product', 'category', 'company', 'country')),
  quality text not null
    check (
      quality in (
        'official',
        'audited',
        'source_calculated',
        'community_provided',
        'scanfair_heuristic'
      )
    ),
  retrieved_at timestamptz not null,
  observed_at timestamptz,
  source_schema_version text,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (cardinality(pillars) > 0),
  check (
    pillars <@ array['environmental', 'social', 'governance']::text[]
  ),
  unique (source_id, source_record_id, metric)
);

create table if not exists public.score_snapshots (
  id uuid primary key default extensions.gen_random_uuid(),
  barcode text not null check (barcode ~ '^[0-9]{8,14}$'),
  formula_version text not null,
  score_state text not null
    check (score_state in ('full_score', 'data_incomplete', 'not_found')),
  environmental_score numeric(5, 2)
    check (environmental_score between 0 and 100),
  social_score numeric(5, 2) check (social_score between 0 and 100),
  governance_score numeric(5, 2)
    check (governance_score between 0 and 100),
  total_score numeric(5, 2) check (total_score between 0 and 100),
  data_completeness numeric(4, 3) not null
    check (data_completeness between 0 and 1),
  evidence_ids text[] not null default '{}',
  input_fingerprint text not null
    check (input_fingerprint ~ '^[a-f0-9]{64}$'),
  calculated_at timestamptz not null default timezone('utc', now()),
  published_at timestamptz
);

create table if not exists public.scans (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  barcode text not null check (barcode ~ '^[0-9]{8,14}$'),
  score_snapshot_id uuid references public.score_snapshots(id)
    on delete set null,
  scanned_at timestamptz not null default timezone('utc', now()),
  client_created_at timestamptz
);

create index if not exists cached_products_expiry_idx
  on public.cached_products (expires_at);
create index if not exists product_evidence_subject_idx
  on public.product_evidence (subject_type, subject_id);
create index if not exists product_evidence_source_idx
  on public.product_evidence (source_id, retrieved_at desc);
create index if not exists score_snapshots_barcode_idx
  on public.score_snapshots (barcode, calculated_at desc);
create index if not exists scans_user_scanned_idx
  on public.scans (user_id, scanned_at desc);

alter table public.data_sources enable row level security;
alter table public.cached_products enable row level security;
alter table public.product_evidence enable row level security;
alter table public.score_snapshots enable row level security;
alter table public.scans enable row level security;

alter table public.data_sources force row level security;
alter table public.cached_products force row level security;
alter table public.product_evidence force row level security;
alter table public.score_snapshots force row level security;
alter table public.scans force row level security;

revoke all on table public.data_sources from anon, authenticated;
revoke all on table public.cached_products from anon, authenticated;
revoke all on table public.product_evidence from anon, authenticated;
revoke all on table public.score_snapshots from anon, authenticated;
revoke all on table public.scans from anon, authenticated;

grant select on table public.data_sources to anon, authenticated;
grant select on table public.cached_products to anon, authenticated;
grant select on table public.product_evidence to anon, authenticated;
grant select on table public.score_snapshots to anon, authenticated;
grant select, insert, delete on table public.scans to authenticated;

create policy "Active data sources are readable"
  on public.data_sources
  for select
  to anon, authenticated
  using (active);

create policy "Fresh product cache is readable"
  on public.cached_products
  for select
  to anon, authenticated
  using (expires_at > timezone('utc', now()));

create policy "Published evidence is readable"
  on public.product_evidence
  for select
  to anon, authenticated
  using (published_at is not null);

create policy "Published score snapshots are readable"
  on public.score_snapshots
  for select
  to anon, authenticated
  using (published_at is not null);

create policy "Users can read their own scans"
  on public.scans
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their own scans"
  on public.scans
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own scans"
  on public.scans
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

insert into public.data_sources (
  id,
  display_name,
  source_url,
  terms_url,
  dataset_license,
  attribution,
  api_version,
  license_reviewed_on
)
values (
  'open-food-facts',
  'Open Food Facts',
  'https://world.openfoodfacts.org',
  'https://world.openfoodfacts.org/terms-of-use',
  'ODbL-1.0',
  'Open Food Facts contributors',
  'v3',
  date '2026-07-27'
)
on conflict (id) do update set
  display_name = excluded.display_name,
  source_url = excluded.source_url,
  terms_url = excluded.terms_url,
  dataset_license = excluded.dataset_license,
  attribution = excluded.attribution,
  api_version = excluded.api_version,
  license_reviewed_on = excluded.license_reviewed_on,
  updated_at = timezone('utc', now());
