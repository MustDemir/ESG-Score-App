-- Backend hardening from the 2026-08-13 technical risk audit
-- (docs/project/audits/2026-08-13-technical-risk-audit.md, findings
-- F-10/F-12/F-18/F-19/F-24). Mechanical fixes only; budget/TTL sizing and
-- audit-log retention need their own ADRs and stay out of this migration.

-- ---------------------------------------------------------------------------
-- 1. Covering indexes for foreign keys (F-12). Parent deletes and key updates
--    otherwise sequential-scan the child table under an FK-check lock.
-- ---------------------------------------------------------------------------

create index if not exists scans_score_snapshot_idx
  on public.scans (score_snapshot_id);

create index if not exists traceability_relationships_source_idx
  on public.traceability_relationships (source_id);

create index if not exists source_mappings_data_source_idx
  on public.source_mappings (data_source_id);

create index if not exists profile_parameters_parameter_idx
  on public.profile_parameters (methodology_version_id, parameter_id);

create index if not exists category_profiles_extends_idx
  on public.category_profiles (methodology_version_id, extends_profile_id)
  where extends_profile_id is not null;

create index if not exists writer_idempotency_keys_source_idx
  on private.writer_idempotency_keys (source_id);

-- ---------------------------------------------------------------------------
-- 2. Drop redundant indexes (F-12). One is a strict prefix of the primary
--    key, the other duplicates a unique constraint on the same columns.
-- ---------------------------------------------------------------------------

drop index if exists public.profile_parameters_profile_idx;
drop index if exists public.traceability_identifiers_lookup_idx;

-- ---------------------------------------------------------------------------
-- 3. Partial indexes matching the publication-state read predicates (F-12).
-- ---------------------------------------------------------------------------

create index if not exists score_snapshots_published_barcode_idx
  on public.score_snapshots (barcode, calculated_at desc)
  where published_at is not null;

create index if not exists product_evidence_published_subject_idx
  on public.product_evidence (subject_type, subject_id)
  where published_at is not null;

-- ---------------------------------------------------------------------------
-- 4. Forensics indexes for the append-only writer audit log (F-11). The log
--    only had its identity primary key; incident lookups by request,
--    correlation or time range were sequential scans.
-- ---------------------------------------------------------------------------

create index if not exists writer_audit_log_request_idx
  on private.writer_audit_log (request_id);

create index if not exists writer_audit_log_correlation_idx
  on private.writer_audit_log (correlation_id);

create index if not exists writer_audit_log_created_idx
  on private.writer_audit_log (created_at);

-- ---------------------------------------------------------------------------
-- 5. Drop the orphaned cache read policy (F-18). Its select grant was revoked
--    in 20260812000100; leaving the permissive policy in place would silently
--    re-open the enumerable list endpoint on any future grant.
-- ---------------------------------------------------------------------------

drop policy if exists "Fresh product cache is readable"
  on public.cached_products;

-- ---------------------------------------------------------------------------
-- 6. Remove direct table writes from service_role on the cache (F-10). All
--    writes must flow through the SECURITY DEFINER publication function,
--    which enforces idempotency, out-of-order rejection, the payload bound
--    and the append-only audit insert. The definer functions execute as the
--    migration owner, so they keep working after this revoke.
-- ---------------------------------------------------------------------------

revoke insert, update, delete on table public.cached_products
  from service_role;

-- ---------------------------------------------------------------------------
-- 7. Bound the cache TTL at the table level (F-18). Without an upper bound a
--    buggy or hostile writer could pin a poisoned row as permanently fresh.
--    The Edge writer uses 24 hours; 7 days leaves headroom for future policy.
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'cached_products_ttl_bound_check'
      and conrelid = 'public.cached_products'::regclass
  ) then
    alter table public.cached_products
      add constraint cached_products_ttl_bound_check
      check (expires_at <= fetched_at + interval '7 days');
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- 8. Maintain updated_at through a trigger (F-19). Migration 6 itself left
--    data_sources.updated_at stale after a bulk update; without a trigger the
--    column is unusable for change detection.
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := timezone('utc', pg_catalog.now());
  return new;
end;
$$;

drop trigger if exists set_updated_at on public.data_sources;
create trigger set_updated_at
before update on public.data_sources
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.cached_products;
create trigger set_updated_at
before update on public.cached_products
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.product_evidence;
create trigger set_updated_at
before update on public.product_evidence
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.methodology_versions;
create trigger set_updated_at
before update on public.methodology_versions
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.parameters;
create trigger set_updated_at
before update on public.parameters
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.category_profiles;
create trigger set_updated_at
before update on public.category_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.profile_parameters;
create trigger set_updated_at
before update on public.profile_parameters
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.source_mappings;
create trigger set_updated_at
before update on public.source_mappings
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.traceability_entities;
create trigger set_updated_at
before update on public.traceability_entities
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at on public.traceability_relationships;
create trigger set_updated_at
before update on public.traceability_relationships
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 9. Decouple validation triggers from RLS visibility (F-19). Both functions
--    read tables whose select policies only expose published or active rows.
--    As SECURITY INVOKER they only work today because the writer bypasses RLS;
--    a future least-privilege writer role would see valid inserts fail with
--    misleading errors. SECURITY DEFINER keeps the validation semantics
--    independent of the caller's row visibility. search_path stays pinned and
--    both bodies are unchanged.
-- ---------------------------------------------------------------------------

create or replace function public.enforce_traceability_context_type()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.context_entity_id is not null
    and not exists (
      select 1
      from public.traceability_entities
      where id = new.context_entity_id
        and entity_type = 'product'
    )
  then
    raise exception 'context_entity_id must reference a product entity'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create or replace function public.enforce_cached_product_license_boundary()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_partition text;
  source_cache_policy text;
begin
  select license_partition, raw_cache_policy
  into source_partition, source_cache_policy
  from public.data_sources
  where id = new.source_id;

  if not found then
    raise exception 'cached product source is not registered'
      using errcode = '23503';
  end if;

  if new.source_id <> 'open-food-facts'
    or source_partition <> 'off-odbl'
    or source_cache_policy <> 'isolated_source_only'
  then
    raise exception 'external product data requires a dedicated license store'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 10. Second defense layer for the private schema (F-18). Row level security
--     without policies denies everything for non-owner roles; the definer
--     functions run as the table owner and stay unaffected. RLS is not
--     forced, because forcing would subject the owner itself and break the
--     writer RPCs. Default privileges are revoked so future private tables
--     do not inherit client grants.
-- ---------------------------------------------------------------------------

alter table private.writer_idempotency_keys enable row level security;
alter table private.writer_audit_log enable row level security;
alter table private.writer_rate_windows enable row level security;
alter table private.writer_daily_usage enable row level security;
alter table private.writer_circuit_state enable row level security;

alter default privileges in schema private
  revoke select, insert, update, delete on tables
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 11. Natural-key uniqueness for score snapshots (F-24). Recomputing the same
--     inputs must update or reuse the existing snapshot instead of creating
--     unbounded duplicates that make "which snapshot did the user see"
--     ambiguous.
-- ---------------------------------------------------------------------------

create unique index if not exists score_snapshots_natural_key_idx
  on public.score_snapshots (barcode, formula_version, input_fingerprint);
