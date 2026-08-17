-- ADR 0033: decouple cache freshness from the upstream refresh budget.
-- Rows carry a freshness marker (stale_after, 24 hours) and a hard serving
-- bound (expires_at, at most 7 days per cached_products_ttl_bound_check).
-- The read function keeps serving rows until expires_at and exposes
-- stale_after so the client can label dated data instead of discarding it.

alter table public.cached_products
  add column if not exists stale_after timestamptz;

update public.cached_products
set stale_after = least(
  fetched_at + interval '24 hours',
  expires_at
)
where stale_after is null;

alter table public.cached_products
  alter column stale_after set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'cached_products_freshness_window_check'
      and conrelid = 'public.cached_products'::regclass
  ) then
    alter table public.cached_products
      add constraint cached_products_freshness_window_check
      check (stale_after > fetched_at and stale_after <= expires_at);
  end if;
end
$$;

-- The freshness window is a single server-side policy: every write path
-- (publication RPC, ops fixes) gets the same 24-hour marker, bounded by the
-- hard expiry. Writers cannot pin a row as permanently fresh.
create or replace function public.set_cache_freshness_window()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.stale_after := least(
    new.fetched_at + interval '24 hours',
    new.expires_at
  );
  return new;
end;
$$;

drop trigger if exists set_cache_freshness_window on public.cached_products;
create trigger set_cache_freshness_window
before insert or update of fetched_at, expires_at, stale_after
on public.cached_products
for each row execute function public.set_cache_freshness_window();

-- Return type changes (stale_after is added), so the function must be
-- dropped before it is recreated with the same grants as before.
drop function if exists public.get_fresh_cached_product(text, text);

create function public.get_fresh_cached_product(
  p_source_id text,
  p_barcode text
)
returns table (
  payload jsonb,
  fetched_at timestamptz,
  stale_after timestamptz,
  expires_at timestamptz,
  source_schema_version text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    cached.payload,
    cached.fetched_at,
    cached.stale_after,
    cached.expires_at,
    cached.source_schema_version
  from public.cached_products as cached
  join public.data_sources as source on source.id = cached.source_id
  where cached.source_id = p_source_id
    and cached.barcode = p_barcode
    and p_barcode ~ '^[0-9]{8,14}$'
    and cached.expires_at > clock_timestamp()
    and source.active
  limit 1
$$;

revoke all on function public.get_fresh_cached_product(text, text) from public;
grant execute on function public.get_fresh_cached_product(text, text)
  to anon, authenticated;
