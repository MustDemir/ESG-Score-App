-- Fail-closed rate protection for the public, bounded read RPCs.
--
-- The Flutter adapter uses POST for RPC calls. PostgREST exposes request path
-- and X-Forwarded-For to a pre-request function, so the database can protect
-- these exact endpoints without introducing a new provider or client secret.
-- Only a SHA-256 pseudonym of the client IP is retained, and its one-minute
-- bucket is removed by a private five-minute cleanup job.

create table if not exists private.public_read_rate_windows (
  subject_hash text not null check (subject_hash ~ '^[a-f0-9]{64}$'),
  window_started_at timestamptz not null,
  request_count integer not null default 1 check (request_count > 0),
  expires_at timestamptz not null,
  primary key (subject_hash, window_started_at),
  check (expires_at = window_started_at + interval '1 hour')
);

create index if not exists public_read_rate_windows_expires_at_idx
  on private.public_read_rate_windows (expires_at);

alter table private.public_read_rate_windows enable row level security;
revoke all on table private.public_read_rate_windows
  from public, anon, authenticated, service_role;

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
  if v_path not in (
    'rpc/get_fresh_cached_product',
    'rpc/get_published_product_evidence',
    'rpc/get_published_score_snapshot'
  ) then
    return;
  end if;

  if v_method <> 'POST' then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_method_not_allowed',
        'message', 'Public read RPCs accept POST only.'
      )::text,
      detail = pg_catalog.json_build_object(
        'status', 405,
        'status_text', 'Method Not Allowed'
      )::text;
  end if;

  v_ip_text := nullif(
    pg_catalog.btrim(
      pg_catalog.split_part(
        coalesce(
          pg_catalog.current_setting('request.headers', true)::json ->> 'x-forwarded-for',
          ''
        ),
        ',',
        1
      )
    ),
    ''
  );

  if v_ip_text is null then
    raise sqlstate 'PGRST' using
      message = pg_catalog.json_build_object(
        'code', 'public_read_identity_unavailable',
        'message', 'A client IP is required for public read protection.'
      )::text,
      detail = pg_catalog.json_build_object(
        'status', 403,
        'status_text', 'Forbidden'
      )::text;
  end if;

  begin
    v_client_ip := v_ip_text::inet;
  exception
    when invalid_text_representation then
      raise sqlstate 'PGRST' using
        message = pg_catalog.json_build_object(
          'code', 'public_read_identity_invalid',
          'message', 'The public read client IP is invalid.'
        )::text,
        detail = pg_catalog.json_build_object(
          'status', 403,
          'status_text', 'Forbidden'
        )::text;
  end;

  v_subject_hash := pg_catalog.encode(
    extensions.digest(
      pg_catalog.convert_to(
        'scanfair-public-read-rate-v1|' || v_client_ip::text,
        'UTF8'
      ),
      'sha256'
    ),
    'hex'
  );

  insert into private.public_read_rate_windows as windows (
    subject_hash,
    window_started_at,
    request_count,
    expires_at
  ) values (
    v_subject_hash,
    v_window_started_at,
    1,
    v_window_started_at + interval '1 hour'
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
        'status', 429,
        'status_text', 'Too Many Requests',
        'headers', pg_catalog.json_build_object('Retry-After', '60')
      )::text;
  end if;
end;
$$;

revoke all on function public.enforce_public_read_rate_limit()
  from public, anon, authenticated, service_role;
grant execute on function public.enforce_public_read_rate_limit()
  to authenticator;

alter role authenticator
  set pgrst.db_pre_request = 'public.enforce_public_read_rate_limit';
notify pgrst, 'reload config';

select cron.unschedule(jobid)
from cron.job
where jobname = 'scanfair-public-read-rate-cleanup';

select cron.schedule(
  'scanfair-public-read-rate-cleanup',
  '*/5 * * * *',
  'select private.cleanup_public_read_rate_windows();'
);
