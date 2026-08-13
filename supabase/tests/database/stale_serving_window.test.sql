begin;

create extension if not exists pgtap with schema extensions;

select plan(5);

select has_column(
  'public',
  'cached_products',
  'stale_after',
  'cached_products carries a freshness marker'
);

-- The freshness window is computed server-side on every write.
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
  '40123400',
  '{"product_name":"fresh fixture"}'::jsonb,
  repeat('e', 64),
  clock_timestamp(),
  clock_timestamp(),
  clock_timestamp() + interval '7 days'
);

select is(
  (
    select stale_after
    from public.cached_products
    where source_id = 'open-food-facts' and barcode = '40123400'
  ),
  (
    select fetched_at + interval '24 hours'
    from public.cached_products
    where source_id = 'open-food-facts' and barcode = '40123400'
  ),
  'trigger derives stale_after as fetched_at plus 24 hours'
);

-- A stale-but-unexpired row keeps being served (ADR 0033) …
update public.cached_products
set
  fetched_at = clock_timestamp() - interval '2 days',
  expires_at = clock_timestamp() + interval '1 day'
where source_id = 'open-food-facts' and barcode = '40123400';

select is(
  (
    select count(*)::integer
    from public.get_fresh_cached_product('open-food-facts', '40123400')
  ),
  1,
  'bounded read serves a stale row inside the hard expiry window'
);

select ok(
  (
    select stale_after < clock_timestamp()
    from public.get_fresh_cached_product('open-food-facts', '40123400')
  ),
  'the served row exposes its staleness to the client'
);

-- … while a row past its hard expiry stays hidden.
update public.cached_products
set
  fetched_at = clock_timestamp() - interval '3 days',
  expires_at = clock_timestamp() - interval '1 day'
where source_id = 'open-food-facts' and barcode = '40123400';

select is(
  (
    select count(*)::integer
    from public.get_fresh_cached_product('open-food-facts', '40123400')
  ),
  0,
  'bounded read hides rows past the hard expiry'
);

select * from finish();
rollback;
