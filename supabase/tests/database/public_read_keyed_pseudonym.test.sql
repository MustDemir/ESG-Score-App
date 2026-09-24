begin;

create extension if not exists pgtap with schema extensions;

select plan(25);

-- TKT-037-06: keyed, hourly rotating IP pseudonym. Fixed timestamps in the
-- past keep every assertion independent of wall-clock hour boundaries.
delete from private.public_read_rate_windows;
delete from private.public_read_rate_keys;

create temporary table keyed_clock on commit drop as
select
  date_trunc('hour', transaction_timestamp()) - interval '2 hours' as hour_start,
  floor(extract(epoch from date_trunc('hour', transaction_timestamp()) - interval '2 hours') / 3600)::bigint as key_epoch;

select has_table('private', 'public_read_rate_keys', 'private rate-key table exists');
select is(
  (select relrowsecurity from pg_class where oid = 'private.public_read_rate_keys'::regclass),
  true,
  'rate-key table has RLS enabled'
);
select is(has_table_privilege('anon', 'private.public_read_rate_keys', 'SELECT,INSERT,UPDATE,DELETE'),
  false, 'anon has no rate-key table privilege');
select is(has_table_privilege('authenticated', 'private.public_read_rate_keys', 'SELECT,INSERT,UPDATE,DELETE'),
  false, 'authenticated has no rate-key table privilege');
select is(has_table_privilege('service_role', 'private.public_read_rate_keys', 'SELECT,INSERT,UPDATE,DELETE'),
  false, 'service_role has no rate-key table privilege');
select has_function(
  'private', 'public_read_rate_subject', array['inet', 'timestamp with time zone'],
  'private keyed pseudonym function exists'
);
select is(has_function_privilege('anon', 'private.public_read_rate_subject(inet,timestamptz)', 'EXECUTE'),
  false, 'anon cannot derive pseudonyms directly');
select is(has_function_privilege('authenticated', 'private.public_read_rate_subject(inet,timestamptz)', 'EXECUTE'),
  false, 'authenticated cannot derive pseudonyms directly');
select is(has_function_privilege('service_role', 'private.public_read_rate_subject(inet,timestamptz)', 'EXECUTE'),
  false, 'service_role cannot derive pseudonyms directly');

create temporary table keyed_first_hour on commit drop as
select private.public_read_rate_subject('198.51.100.20'::inet, hour_start + interval '10 minutes') as subject
from keyed_clock;

select matches((select subject from keyed_first_hour), '^[a-f0-9]{64}$',
  'keyed pseudonym is a fixed-length hex value');
select is(
  (select count(*)::integer from private.public_read_rate_keys as keys
   join keyed_clock on keys.key_epoch = keyed_clock.key_epoch
   where octet_length(keys.secret) = 32),
  1,
  'first request of an hour creates exactly one 32-byte key'
);
select is(
  (select subject from keyed_first_hour),
  (select encode(extensions.hmac(
     convert_to('scanfair-public-read-rate-v2|' || '198.51.100.20'::inet::text, 'UTF8'),
     keys.secret, 'sha256'), 'hex')
   from private.public_read_rate_keys as keys
   join keyed_clock on keys.key_epoch = keyed_clock.key_epoch),
  'pseudonym is the HMAC-SHA-256 of the IP under the hourly key'
);
select isnt(
  (select subject from keyed_first_hour),
  encode(extensions.digest(
    convert_to('scanfair-public-read-rate-v1|' || '198.51.100.20'::inet::text, 'UTF8'), 'sha256'), 'hex'),
  'pseudonym no longer equals the reversible unkeyed v1 digest'
);
select is(
  (select private.public_read_rate_subject('198.51.100.20'::inet, hour_start + interval '59 minutes') from keyed_clock),
  (select subject from keyed_first_hour),
  'the same IP keeps one pseudonym within its hour'
);
select isnt(
  (select private.public_read_rate_subject('198.51.100.21'::inet, hour_start + interval '10 minutes') from keyed_clock),
  (select subject from keyed_first_hour),
  'different IPs receive different pseudonyms'
);

select isnt(
  (select private.public_read_rate_subject('198.51.100.20'::inet, hour_start + interval '61 minutes') from keyed_clock),
  (select subject from keyed_first_hour),
  'the same IP receives an unlinkable pseudonym in the next hour'
);
select is(
  (select count(*)::integer from private.public_read_rate_keys as keys
   join keyed_clock on keys.key_epoch = keyed_clock.key_epoch),
  0,
  'the first request of a new hour erases the previous key'
);
select is(
  (select count(*)::integer from private.public_read_rate_keys),
  1,
  'only the key of the current hour remains'
);
select isnt(
  (select private.public_read_rate_subject('198.51.100.20'::inet, hour_start + interval '10 minutes') from keyed_clock),
  (select subject from keyed_first_hour),
  'an erased key cannot be reproduced for its past hour'
);

delete from private.public_read_rate_keys;
insert into private.public_read_rate_keys (key_epoch, secret)
select key_epoch, extensions.gen_random_bytes(32)
from (
  select floor(extract(epoch from transaction_timestamp()) / 3600)::bigint - 3 as key_epoch
  union all
  select floor(extract(epoch from transaction_timestamp()) / 3600)::bigint
) as epochs;
select private.cleanup_public_read_rate_windows(transaction_timestamp());
select is(
  (select count(*)::integer from private.public_read_rate_keys
   where key_epoch < floor(extract(epoch from transaction_timestamp()) / 3600)::bigint),
  0,
  'scheduled cleanup erases keys of past hours without public traffic'
);
select is(
  (select count(*)::integer from private.public_read_rate_keys
   where key_epoch = floor(extract(epoch from transaction_timestamp()) / 3600)::bigint),
  1,
  'scheduled cleanup keeps the key of the current hour'
);

select throws_ok(
  $$ select private.public_read_rate_subject('198.51.100.20'::inet, clock_timestamp() + interval '6 minutes') $$,
  '22023', 'public read rate key clock cannot be in the future',
  'a future clock cannot erase the current key'
);
select throws_ok(
  $$ select private.public_read_rate_subject(null, clock_timestamp()) $$,
  '22004', 'public read rate subject requires an IP and a timestamp',
  'a missing IP cannot derive a pseudonym'
);

delete from private.public_read_rate_windows;
set local role anon;
select set_config('request.path', '/rpc/get_fresh_cached_product', true);
select set_config('request.method', 'POST', true);
select set_config('request.headers', '{"x-forwarded-for":"198.51.100.30"}', true);
select public.enforce_public_read_rate_limit();
reset role;
select is(
  (select count(*)::integer
   from private.public_read_rate_windows as windows
   join private.public_read_rate_keys as keys
     on keys.key_epoch = floor(extract(epoch from windows.window_started_at) / 3600)::bigint
   where windows.subject_hash = encode(extensions.hmac(
     convert_to('scanfair-public-read-rate-v2|' || '198.51.100.30'::inet::text, 'UTF8'),
     keys.secret, 'sha256'), 'hex')),
  1,
  'the request hook stores the keyed pseudonym of the trusted peer'
);
select ok(
  (select prosrc not like '%scanfair-public-read-rate-v1%'
   from pg_proc where oid = 'public.enforce_public_read_rate_limit()'::regprocedure),
  'the request hook no longer derives the unkeyed v1 digest'
);

select * from finish();

rollback;
