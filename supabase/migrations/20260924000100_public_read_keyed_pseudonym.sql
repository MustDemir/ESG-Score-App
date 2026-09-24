-- TKT-037-06: replace the unkeyed IP digest with an hourly rotating secret key.
--
-- An unkeyed SHA-256 of an IPv4 address with a public prefix can be reversed
-- by exhaustive search. Each UTC hour now receives a random 32-byte key that
-- never leaves the private schema. Keys of past hours are deleted by the first
-- request of a new hour and by the existing five-minute cleanup, after which
-- the remaining counter rows can no longer be attributed to an IP address.
-- Forward-only correction of migrations 14 and 15 (ADR 0035, ADR 0040).

create table if not exists private.public_read_rate_keys (
  key_epoch bigint primary key check (key_epoch > 0),
  secret bytea not null check (pg_catalog.octet_length(secret) = 32),
  created_at timestamptz not null default clock_timestamp()
);

alter table private.public_read_rate_keys enable row level security;
revoke all on table private.public_read_rate_keys
  from public, anon, authenticated, service_role;

-- Counters derived with the unkeyed v1 digest are transient and must not
-- survive next to keyed values.
delete from private.public_read_rate_windows;

create or replace function private.public_read_rate_subject(
  p_client_ip inet,
  p_now timestamptz
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key_epoch bigint;
  v_secret bytea;
begin
  if p_client_ip is null or p_now is null then
    raise exception 'public read rate subject requires an IP and a timestamp'
      using errcode = '22004';
  end if;
  if p_now > clock_timestamp() + interval '5 minutes' then
    raise exception 'public read rate key clock cannot be in the future'
      using errcode = '22023';
  end if;

  v_key_epoch := pg_catalog.floor(extract(epoch from p_now) / 3600)::bigint;

  select keys.secret into v_secret
  from private.public_read_rate_keys as keys
  where keys.key_epoch = v_key_epoch;

  if v_secret is null then
    insert into private.public_read_rate_keys (key_epoch, secret)
    values (v_key_epoch, extensions.gen_random_bytes(32))
    on conflict (key_epoch) do nothing;

    -- Erase past keys as soon as a new hour starts instead of waiting for cron.
    delete from private.public_read_rate_keys
    where key_epoch < v_key_epoch;

    select keys.secret into strict v_secret
    from private.public_read_rate_keys as keys
    where keys.key_epoch = v_key_epoch;
  end if;

  return pg_catalog.encode(
    extensions.hmac(
      pg_catalog.convert_to('scanfair-public-read-rate-v2|' || p_client_ip::text, 'UTF8'),
      v_secret,
      'sha256'
    ),
    'hex'
  );
end;
$$;

revoke all on function private.public_read_rate_subject(inet, timestamptz)
  from public, anon, authenticated, service_role;

create or replace function public.enforce_public_read_rate_limit()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_path text := coalesce(pg_catalog.current_setting('request.path', true), '');
  v_method text := coalesce(pg_catalog.current_setting('request.method', true), '');
  v_ip_text text;
  v_client_ip inet;
  v_subject_hash text;
  v_now timestamptz := clock_timestamp();
  v_window_started_at timestamptz := pg_catalog.date_trunc('minute', v_now);
  v_request_count integer;
begin
  -- PostgREST resolves decoded route segments but exposes the raw HTTP path.
  -- Reject aliases instead of letting an encoded protected RPC skip this hook.
  if pg_catalog.strpos(v_path, '%') > 0
     or pg_catalog.strpos(v_path, '//') > 0 then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_path_invalid',
        'message', 'Encoded or ambiguous Data API paths are not allowed.'
      )::text,
      detail = pg_catalog.json_build_object('status', 403, 'status_text', 'Forbidden', 'headers', '{}'::json)::text;
  end if;
  v_path := pg_catalog.rtrim(v_path, '/');

  -- EXECUTE is needed after PostgREST SET ROLE, but the hook is not an API RPC.
  if v_path = '/rpc/enforce_public_read_rate_limit' then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_hook_not_callable',
        'message', 'The request hook cannot be invoked as an API RPC.'
      )::text,
      detail = pg_catalog.json_build_object('status', 403, 'status_text', 'Forbidden', 'headers', '{}'::json)::text;
  end if;

  if v_path not in (
    '/rpc/get_fresh_cached_product',
    '/rpc/get_published_product_evidence',
    '/rpc/get_published_score_snapshot'
  ) then
    return;
  end if;

  if v_method <> 'POST' then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_method_not_allowed',
        'message', 'Public read RPCs accept POST only.'
      )::text,
      detail = pg_catalog.json_build_object('status', 405, 'status_text', 'Method Not Allowed', 'headers', '{}'::json)::text;
  end if;

  -- The final trusted ingress appends the peer it observed. Earlier entries
  -- may be supplied by the caller and must never select the rate bucket.
  -- Deployment must prove this single-ingress trust boundary through HTTP;
  -- additional trusted proxy hops need a separately reviewed chain policy.
  v_ip_text := nullif(
    pg_catalog.btrim(pg_catalog.split_part(
      coalesce(pg_catalog.current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''),
      ',', -1
    )), ''
  );
  if v_ip_text is null then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_identity_unavailable',
        'message', 'A client IP is required for public read protection.'
      )::text,
      detail = pg_catalog.json_build_object('status', 403, 'status_text', 'Forbidden', 'headers', '{}'::json)::text;
  end if;
  begin
    v_client_ip := v_ip_text::inet;
  exception when invalid_text_representation then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_identity_invalid',
        'message', 'The public read client IP is invalid.'
      )::text,
      detail = pg_catalog.json_build_object('status', 403, 'status_text', 'Forbidden', 'headers', '{}'::json)::text;
  end;

  -- Key epoch and minute window share one timestamp, so a window never spans keys.
  v_subject_hash := private.public_read_rate_subject(v_client_ip, v_now);
  insert into private.public_read_rate_windows as windows (
    subject_hash, window_started_at, request_count, expires_at
  ) values (
    v_subject_hash, v_window_started_at, 1, v_window_started_at + interval '1 hour'
  )
  on conflict (subject_hash, window_started_at) do update set
    request_count = windows.request_count + 1
  returning request_count into v_request_count;

  if v_request_count > 30 then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_rate_limit_exceeded',
        'message', 'Public read rate limit exceeded.'
      )::text,
      detail = pg_catalog.json_build_object(
        'status', 429, 'status_text', 'Too Many Requests',
        'headers', pg_catalog.json_build_object('Retry-After', '60')
      )::text;
  end if;
end;
$$;

revoke all on function public.enforce_public_read_rate_limit() from public;
grant execute on function public.enforce_public_read_rate_limit()
  to anon, authenticated, service_role, authenticator;

-- The scheduled cleanup also erases past keys, so key deletion does not
-- depend on public traffic. The return value still counts counter rows only.
create or replace function private.cleanup_public_read_rate_windows(
  p_now timestamptz default clock_timestamp()
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted integer := 0;
begin
  if p_now > clock_timestamp() + interval '5 minutes' then
    raise exception 'public read rate cleanup clock cannot be in the future'
      using errcode = '22023';
  end if;

  delete from private.public_read_rate_keys
  where key_epoch < pg_catalog.floor(extract(epoch from p_now) / 3600)::bigint;

  delete from private.public_read_rate_windows
  where ctid in (
    select ctid
    from private.public_read_rate_windows
    where expires_at <= p_now
    order by expires_at
    limit 10000
  );
  get diagnostics v_deleted = row_count;

  return v_deleted;
end;
$$;

revoke all on function private.cleanup_public_read_rate_windows(timestamptz)
  from public, anon, authenticated, service_role;

notify pgrst, 'reload schema';
