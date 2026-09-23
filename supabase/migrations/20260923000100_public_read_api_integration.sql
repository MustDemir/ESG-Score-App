-- TKT-037-05: integrate the limiter with the real PostgREST execution context.
-- Forward-only correction of migration 14; hash inputs and retention stay unchanged.
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
  v_window_started_at timestamptz := pg_catalog.date_trunc('minute', clock_timestamp());
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

  v_subject_hash := pg_catalog.encode(
    extensions.digest(pg_catalog.convert_to(
      'scanfair-public-read-rate-v1|' || v_client_ip::text, 'UTF8'
    ), 'sha256'), 'hex'
  );
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
revoke all on table private.public_read_rate_windows
  from public, anon, authenticated, service_role;

-- The request includes a counter write, even though the main RPC only reads.
-- PostgREST otherwise starts READ ONLY for POST on STABLE functions.
alter function public.get_fresh_cached_product(text, text) volatile;
alter function public.get_published_product_evidence(text) volatile;
alter function public.get_published_score_snapshot(text, text) volatile;

alter role authenticator
  set pgrst.db_pre_request = 'public.enforce_public_read_rate_limit';
notify pgrst, 'reload config';
notify pgrst, 'reload schema';
