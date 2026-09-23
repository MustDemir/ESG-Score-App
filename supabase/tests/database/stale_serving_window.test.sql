begin;

create extension if not exists pgtap with schema extensions;

select plan(7);

select has_column(
  'public',
  'cached_products',
  'stale_after',
  'cached_products carries a freshness marker'
);

-- current_timestamp is stable within this transaction. Separate wall-clock
-- reads can accidentally exceed the seven-day bound by a microsecond.
-- The freshness window is computed server-side on every write.
select lives_ok($$
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
  current_timestamp,
  current_timestamp,
  current_timestamp + interval '7 days'
)
$$, 'cache TTL accepts exactly seven days');

select throws_ok(
  $$
    update public.cached_products
    set expires_at = fetched_at + interval '7 days 1 microsecond'
    where source_id = 'open-food-facts' and barcode = '40123400'
  $$,
  '23514',
  'new row for relation "cached_products" violates check constraint "cached_products_ttl_bound_check"',
  'cache TTL rejects seven days plus one microsecond'
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
  fetched_at = current_timestamp - interval '2 days',
  expires_at = current_timestamp + interval '1 day'
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
  fetched_at = current_timestamp - interval '3 days',
  expires_at = current_timestamp - interval '1 day'
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
