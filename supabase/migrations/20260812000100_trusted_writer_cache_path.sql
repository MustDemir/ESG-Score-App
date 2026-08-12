-- Trusted server-writer and bounded read path for the Open Food Facts cache.
-- Privileged functions are callable only by the server-side service role.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter table public.cached_products
  add column if not exists source_observed_at timestamptz;

update public.cached_products
set source_observed_at = fetched_at
where source_observed_at is null;

alter table public.cached_products
  alter column source_observed_at set not null;

create table if not exists private.writer_idempotency_keys (
  idempotency_key text primary key
    check (idempotency_key ~ '^[a-f0-9]{64}$'),
  source_id text not null references public.data_sources(id),
  source_record_id text not null,
  source_observed_at timestamptz not null,
  payload_sha256 text not null check (payload_sha256 ~ '^[a-f0-9]{64}$'),
  created_at timestamptz not null default clock_timestamp()
);

create table if not exists private.writer_audit_log (
  id bigint generated always as identity primary key,
  request_id text not null,
  idempotency_key text not null,
  actor_type text not null,
  action text not null,
  source_id text not null,
  target_record text not null,
  input_sha256 text not null check (input_sha256 ~ '^[a-f0-9]{64}$'),
  outcome text not null,
  status_code integer not null check (status_code between 100 and 599),
  started_at timestamptz not null,
  completed_at timestamptz not null,
  correlation_id text not null,
  created_at timestamptz not null default clock_timestamp(),
  check (completed_at >= started_at)
);

create table if not exists private.writer_rate_windows (
  scope text not null,
  actor_type text not null,
  window_started_at timestamptz not null,
  request_count integer not null check (request_count >= 0),
  primary key (scope, actor_type, window_started_at)
);

create table if not exists private.writer_daily_usage (
  usage_date date primary key,
  upstream_request_count integer not null
    check (upstream_request_count >= 0)
);

create table if not exists private.writer_circuit_state (
  source_id text primary key references public.data_sources(id),
  consecutive_failures integer not null default 0
    check (consecutive_failures >= 0),
  opened_until timestamptz,
  updated_at timestamptz not null default clock_timestamp()
);

revoke all on all tables in schema private from public, anon, authenticated;
revoke all on all sequences in schema private from public, anon, authenticated;

create or replace function private.reject_writer_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'writer audit records are append-only'
    using errcode = 'P0001';
end;
$$;

drop trigger if exists reject_writer_audit_mutation
  on private.writer_audit_log;
create trigger reject_writer_audit_mutation
before update or delete on private.writer_audit_log
for each row execute function private.reject_writer_audit_mutation();

-- Direct table reads would expose an enumerable list endpoint. Clients receive
-- only the bounded single-barcode function below.
revoke select on table public.cached_products from anon, authenticated;

create or replace function public.get_fresh_cached_product(
  p_source_id text,
  p_barcode text
)
returns table (
  payload jsonb,
  fetched_at timestamptz,
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

create or replace function public.claim_writer_capacity(
  p_request_id text,
  p_actor_type text,
  p_batch_size integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_minute_window timestamptz;
  v_utc_date date;
  v_actor_count integer;
  v_global_count integer;
  v_daily_count integer;
begin
  if p_request_id !~ '^[A-Za-z0-9._:-]{8,128}$' then
    raise exception 'invalid writer request id' using errcode = '22023';
  end if;
  if p_actor_type not in ('scheduled_ingestion_job', 'audited_operator_replay') then
    raise exception 'writer actor is not authorized' using errcode = '42501';
  end if;
  if p_batch_size < 1 or p_batch_size > 25 then
    raise exception 'writer batch size is outside the allowed range'
      using errcode = '22023';
  end if;
  if exists (
    select 1
    from private.writer_circuit_state as circuit
    where circuit.source_id = 'open-food-facts'
      and circuit.opened_until > v_now
  ) then
    raise exception 'writer upstream circuit is open' using errcode = 'P0001';
  end if;

  v_minute_window := date_trunc('minute', v_now);
  v_utc_date := (v_now at time zone 'UTC')::date;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'scanfair-writer-capacity:' || v_minute_window::text,
      0
    )
  );

  insert into private.writer_rate_windows as windows (
    scope,
    actor_type,
    window_started_at,
    request_count
  ) values ('actor', p_actor_type, v_minute_window, 1)
  on conflict (scope, actor_type, window_started_at)
  do update set request_count = windows.request_count + 1
  where windows.request_count < 10
  returning request_count into v_actor_count;
  if v_actor_count is null then
    raise exception 'writer actor rate limit exceeded' using errcode = 'P0001';
  end if;

  insert into private.writer_rate_windows as windows (
    scope,
    actor_type,
    window_started_at,
    request_count
  ) values ('global', '*', v_minute_window, 1)
  on conflict (scope, actor_type, window_started_at)
  do update set request_count = windows.request_count + 1
  where windows.request_count < 30
  returning request_count into v_global_count;
  if v_global_count is null then
    raise exception 'writer global rate limit exceeded' using errcode = 'P0001';
  end if;

  insert into private.writer_daily_usage as usage (
    usage_date,
    upstream_request_count
  )
  values (v_utc_date, p_batch_size)
  on conflict (usage_date)
  do update set
    upstream_request_count = usage.upstream_request_count
      + excluded.upstream_request_count
  where usage.upstream_request_count
      + excluded.upstream_request_count <= 500
  returning upstream_request_count into v_daily_count;
  if v_daily_count is null then
    raise exception 'writer daily upstream budget exceeded'
      using errcode = 'P0001';
  end if;

  return pg_catalog.jsonb_build_object(
    'actor_minute_count', v_actor_count,
    'global_minute_count', v_global_count,
    'daily_upstream_count', v_daily_count
  );
end;
$$;

revoke all on function public.claim_writer_capacity(text, text, integer)
  from public, anon, authenticated;
grant execute on function public.claim_writer_capacity(text, text, integer)
  to service_role;

create or replace function public.record_writer_upstream_health(
  p_source_id text,
  p_succeeded boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_failures integer;
  v_opened_until timestamptz;
begin
  if p_source_id <> 'open-food-facts' or p_succeeded is null then
    raise exception 'invalid writer upstream health input'
      using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('scanfair-writer-circuit:' || p_source_id, 0)
  );
  insert into private.writer_circuit_state as circuit (
    source_id,
    consecutive_failures,
    opened_until,
    updated_at
  ) values (
    p_source_id,
    case when p_succeeded then 0 else 1 end,
    null,
    v_now
  )
  on conflict (source_id) do update set
    consecutive_failures = case
      when p_succeeded then 0
      else circuit.consecutive_failures + 1
    end,
    opened_until = case
      when p_succeeded then null
      when circuit.consecutive_failures + 1 >= 5 then
        greatest(
          coalesce(circuit.opened_until, v_now),
          v_now + interval '15 minutes'
        )
      else circuit.opened_until
    end,
    updated_at = v_now
  returning consecutive_failures, opened_until
  into v_failures, v_opened_until;

  return pg_catalog.jsonb_build_object(
    'consecutive_failures', v_failures,
    'circuit_open', v_opened_until > v_now,
    'opened_until', v_opened_until
  );
end;
$$;

revoke all on function public.record_writer_upstream_health(text, boolean)
  from public, anon, authenticated;
grant execute on function public.record_writer_upstream_health(text, boolean)
  to service_role;

create or replace function public.publish_off_product(
  p_request_id text,
  p_correlation_id text,
  p_actor_type text,
  p_barcode text,
  p_payload jsonb,
  p_source_observed_at timestamptz,
  p_fetched_at timestamptz,
  p_expires_at timestamptz,
  p_source_schema_version text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_source_id constant text := 'open-food-facts';
  v_started_at timestamptz := clock_timestamp();
  v_payload_sha256 text;
  v_idempotency_key text;
  v_current_observed_at timestamptz;
  v_audit_outcome text;
  v_response_status integer;
begin
  if p_request_id !~ '^[A-Za-z0-9._:-]{8,128}$'
    or p_correlation_id !~ '^[A-Za-z0-9._:-]{8,128}$'
  then
    raise exception 'invalid request or correlation id' using errcode = '22023';
  end if;
  if p_actor_type not in ('scheduled_ingestion_job', 'audited_operator_replay') then
    raise exception 'writer actor is not authorized' using errcode = '42501';
  end if;
  if p_barcode !~ '^[0-9]{8,14}$' then
    raise exception 'invalid barcode' using errcode = '22023';
  end if;
  if pg_catalog.jsonb_typeof(p_payload) <> 'object'
    or pg_catalog.octet_length(p_payload::text) > 1048576
  then
    raise exception 'invalid or oversized product payload' using errcode = '22023';
  end if;
  if p_expires_at <= p_fetched_at
    or p_source_observed_at > p_fetched_at + interval '1 day'
  then
    raise exception 'invalid writer timestamps' using errcode = '22023';
  end if;

  v_payload_sha256 := pg_catalog.encode(
    extensions.digest(pg_catalog.convert_to(p_payload::text, 'UTF8'), 'sha256'),
    'hex'
  );
  v_idempotency_key := pg_catalog.encode(
    extensions.digest(
      pg_catalog.convert_to(
        v_source_id || '|' || p_barcode || '|' ||
        p_source_observed_at::text || '|' || v_payload_sha256,
        'UTF8'
      ),
      'sha256'
    ),
    'hex'
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_source_id || ':' || p_barcode, 0)
  );

  select cached.source_observed_at
  into v_current_observed_at
  from public.cached_products as cached
  where cached.source_id = v_source_id and cached.barcode = p_barcode
  for update;

  if v_current_observed_at is not null
    and v_current_observed_at > p_source_observed_at
  then
    v_audit_outcome := 'rejected_older_observation';
    v_response_status := 409;
  elsif exists (
    select 1
    from private.writer_idempotency_keys as keys
    where keys.idempotency_key = v_idempotency_key
  ) then
    update public.cached_products as cached
    set
      fetched_at = case
        when p_fetched_at > cached.fetched_at then p_fetched_at
        else cached.fetched_at
      end,
      expires_at = case
        when p_expires_at > cached.expires_at then p_expires_at
        else cached.expires_at
      end,
      updated_at = clock_timestamp()
    where cached.source_id = v_source_id
      and cached.barcode = p_barcode
      and cached.source_observed_at = p_source_observed_at
      and cached.payload_sha256 = v_payload_sha256
      and (
        cached.fetched_at < p_fetched_at
        or cached.expires_at < p_expires_at
      );

    v_audit_outcome := 'duplicate_existing';
    v_response_status := 200;
  else
    insert into private.writer_idempotency_keys (
      idempotency_key,
      source_id,
      source_record_id,
      source_observed_at,
      payload_sha256
    ) values (
      v_idempotency_key,
      v_source_id,
      p_barcode,
      p_source_observed_at,
      v_payload_sha256
    );

    insert into public.cached_products (
      source_id,
      barcode,
      payload,
      source_schema_version,
      payload_sha256,
      source_observed_at,
      fetched_at,
      expires_at
    ) values (
      v_source_id,
      p_barcode,
      p_payload,
      p_source_schema_version,
      v_payload_sha256,
      p_source_observed_at,
      p_fetched_at,
      p_expires_at
    )
    on conflict (source_id, barcode) do update set
      payload = excluded.payload,
      source_schema_version = excluded.source_schema_version,
      payload_sha256 = excluded.payload_sha256,
      source_observed_at = excluded.source_observed_at,
      fetched_at = excluded.fetched_at,
      expires_at = excluded.expires_at,
      updated_at = clock_timestamp();

    v_audit_outcome := 'published';
    v_response_status := 201;
  end if;

  insert into private.writer_audit_log (
    request_id,
    idempotency_key,
    actor_type,
    action,
    source_id,
    target_record,
    input_sha256,
    outcome,
    status_code,
    started_at,
    completed_at,
    correlation_id
  ) values (
    p_request_id,
    v_idempotency_key,
    p_actor_type,
    'publish_product_cache',
    v_source_id,
    p_barcode,
    v_payload_sha256,
    v_audit_outcome,
    v_response_status,
    v_started_at,
    clock_timestamp(),
    p_correlation_id
  );

  return pg_catalog.jsonb_build_object(
    'status', v_audit_outcome,
    'status_code', v_response_status,
    'idempotency_key', v_idempotency_key,
    'payload_sha256', v_payload_sha256
  );
end;
$$;

revoke all on function public.publish_off_product(
  text, text, text, text, jsonb, timestamptz, timestamptz, timestamptz, text
) from public, anon, authenticated;
grant execute on function public.publish_off_product(
  text, text, text, text, jsonb, timestamptz, timestamptz, timestamptz, text
) to service_role;

create or replace function public.record_writer_outcome(
  p_request_id text,
  p_correlation_id text,
  p_actor_type text,
  p_barcode text,
  p_input_sha256 text,
  p_outcome text,
  p_status_code integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  recorded_at timestamptz := clock_timestamp();
begin
  if p_request_id !~ '^[A-Za-z0-9._:-]{8,128}$'
    or p_correlation_id !~ '^[A-Za-z0-9._:-]{8,128}$'
    or p_barcode !~ '^[0-9]{8,14}$'
    or p_input_sha256 !~ '^[a-f0-9]{64}$'
    or p_actor_type not in ('scheduled_ingestion_job', 'audited_operator_replay')
    or p_outcome not in (
      'not_found',
      'upstream_rejected',
      'upstream_unavailable',
      'database_rejected',
      'database_unavailable',
      'writer_internal_error'
    )
    or p_status_code not between 400 and 599
  then
    raise exception 'invalid writer outcome audit input' using errcode = '22023';
  end if;

  insert into private.writer_audit_log (
    request_id,
    idempotency_key,
    actor_type,
    action,
    source_id,
    target_record,
    input_sha256,
    outcome,
    status_code,
    started_at,
    completed_at,
    correlation_id
  ) values (
    p_request_id,
    p_input_sha256,
    p_actor_type,
    case
      when p_outcome in ('database_rejected', 'database_unavailable')
        then 'publish_product_cache'
      else 'fetch_product_cache'
    end,
    'open-food-facts',
    p_barcode,
    p_input_sha256,
    p_outcome,
    p_status_code,
    recorded_at,
    recorded_at,
    p_correlation_id
  );
end;
$$;

revoke all on function public.record_writer_outcome(
  text, text, text, text, text, text, integer
) from public, anon, authenticated;
grant execute on function public.record_writer_outcome(
  text, text, text, text, text, text, integer
) to service_role;
