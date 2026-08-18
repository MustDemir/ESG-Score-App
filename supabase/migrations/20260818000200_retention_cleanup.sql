-- Retention and bounded cleanup for the disabled development backend.
-- The schedule is UTC. Runtime activation remains a separate reviewed step.

create extension if not exists pg_cron;

-- One durable row per upstream record preserves monotonic ordering after
-- event-level idempotency keys and expired cache payloads are deleted.
create table if not exists private.writer_record_watermarks (
  source_id text not null references public.data_sources(id),
  source_record_id text not null,
  source_observed_at timestamptz not null,
  payload_sha256 text not null check (payload_sha256 ~ '^[a-f0-9]{64}$'),
  updated_at timestamptz not null default clock_timestamp(),
  primary key (source_id, source_record_id)
);

insert into private.writer_record_watermarks as watermarks (
  source_id,
  source_record_id,
  source_observed_at,
  payload_sha256,
  updated_at
)
select distinct on (history.source_id, history.source_record_id)
  history.source_id,
  history.source_record_id,
  history.source_observed_at,
  history.payload_sha256,
  history.recorded_at
from (
  select
    cached.source_id,
    cached.barcode as source_record_id,
    cached.source_observed_at,
    cached.payload_sha256,
    cached.updated_at as recorded_at
  from public.cached_products as cached
  union all
  select
    keys.source_id,
    keys.source_record_id,
    keys.source_observed_at,
    keys.payload_sha256,
    keys.created_at as recorded_at
  from private.writer_idempotency_keys as keys
) as history
order by
  history.source_id,
  history.source_record_id,
  history.source_observed_at desc,
  history.recorded_at desc
on conflict (source_id, source_record_id) do update set
  source_observed_at = excluded.source_observed_at,
  payload_sha256 = excluded.payload_sha256,
  updated_at = excluded.updated_at
where excluded.source_observed_at > watermarks.source_observed_at;

alter table private.writer_record_watermarks enable row level security;
revoke all on table private.writer_record_watermarks
  from public, anon, authenticated, service_role;

-- Direct mutation remains forbidden. Only the owner-executed cleanup function
-- may delete records after the approved retention period.
create or replace function private.reject_writer_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE'
    and current_user = 'postgres'
    and pg_catalog.current_setting(
      'scanfair.audit_retention_cleanup',
      true
    ) = 'enabled'
  then
    return old;
  end if;

  raise exception 'writer audit records are append-only'
    using errcode = 'P0001';
end;
$$;

-- Publication uses the durable watermark instead of the disposable cache as
-- the ordering authority. Exact replays may safely repopulate an expired cache;
-- same-timestamp/different-payload observations fail closed.
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
  v_current_payload_sha256 text;
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
    or p_expires_at > p_fetched_at + interval '7 days'
    or p_fetched_at > clock_timestamp() + interval '5 minutes'
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

  select watermarks.source_observed_at, watermarks.payload_sha256
  into v_current_observed_at, v_current_payload_sha256
  from private.writer_record_watermarks as watermarks
  where watermarks.source_id = v_source_id
    and watermarks.source_record_id = p_barcode
  for update;

  if v_current_observed_at is not null
    and v_current_observed_at > p_source_observed_at
  then
    v_audit_outcome := 'rejected_older_observation';
    v_response_status := 409;
  elsif v_current_observed_at = p_source_observed_at
    and v_current_payload_sha256 <> v_payload_sha256
  then
    v_audit_outcome := 'rejected_conflicting_observation';
    v_response_status := 409;
  elsif v_current_observed_at = p_source_observed_at
    and v_current_payload_sha256 = v_payload_sha256
  then
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
    ) on conflict (idempotency_key) do nothing;

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
      fetched_at = case
        when excluded.fetched_at > cached_products.fetched_at
          then excluded.fetched_at
        else cached_products.fetched_at
      end,
      expires_at = case
        when excluded.expires_at > cached_products.expires_at
          then excluded.expires_at
        else cached_products.expires_at
      end,
      updated_at = clock_timestamp();

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

    insert into private.writer_record_watermarks as watermarks (
      source_id,
      source_record_id,
      source_observed_at,
      payload_sha256,
      updated_at
    ) values (
      v_source_id,
      p_barcode,
      p_source_observed_at,
      v_payload_sha256,
      clock_timestamp()
    )
    on conflict (source_id, source_record_id) do update set
      source_observed_at = excluded.source_observed_at,
      payload_sha256 = excluded.payload_sha256,
      updated_at = excluded.updated_at
    where excluded.source_observed_at
      > watermarks.source_observed_at;

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

create or replace function private.run_retention_cleanup(
  p_now timestamptz default clock_timestamp()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rate_windows integer := 0;
  v_cached_products integer := 0;
  v_idempotency_keys integer := 0;
  v_audit_records integer := 0;
  v_daily_usage integer := 0;
  v_cron_history integer := 0;
begin
  if p_now > clock_timestamp() + interval '5 minutes' then
    raise exception 'cleanup clock cannot be in the future'
      using errcode = '22023';
  end if;

  delete from private.writer_rate_windows
  where ctid in (
    select ctid
    from private.writer_rate_windows
    where window_started_at < p_now - interval '1 hour'
    order by window_started_at
    limit 10000
  );
  get diagnostics v_rate_windows = row_count;

  delete from public.cached_products
  where ctid in (
    select ctid
    from public.cached_products
    where expires_at < p_now - interval '1 day'
    order by expires_at
    limit 10000
  );
  get diagnostics v_cached_products = row_count;

  delete from private.writer_idempotency_keys
  where ctid in (
    select ctid
    from private.writer_idempotency_keys
    where created_at < p_now - interval '30 days'
    order by created_at
    limit 10000
  );
  get diagnostics v_idempotency_keys = row_count;

  perform pg_catalog.set_config(
    'scanfair.audit_retention_cleanup',
    'enabled',
    true
  );
  delete from private.writer_audit_log
  where ctid in (
    select ctid
    from private.writer_audit_log
    where created_at < p_now - interval '90 days'
    order by created_at
    limit 10000
  );
  get diagnostics v_audit_records = row_count;
  perform pg_catalog.set_config(
    'scanfair.audit_retention_cleanup',
    'disabled',
    true
  );

  delete from private.writer_daily_usage
  where usage_date < (p_now at time zone 'UTC')::date - 400;
  get diagnostics v_daily_usage = row_count;

  delete from cron.job_run_details
  where runid in (
    select runid
    from cron.job_run_details
    where end_time < p_now - interval '30 days'
    order by end_time
    limit 10000
  );
  get diagnostics v_cron_history = row_count;

  return pg_catalog.jsonb_build_object(
    'rate_windows_deleted', v_rate_windows,
    'cached_products_deleted', v_cached_products,
    'idempotency_keys_deleted', v_idempotency_keys,
    'audit_records_deleted', v_audit_records,
    'daily_usage_deleted', v_daily_usage,
    'cron_history_deleted', v_cron_history
  );
end;
$$;

revoke all on function private.run_retention_cleanup(timestamptz)
  from public, anon, authenticated, service_role;

select cron.schedule(
  'scanfair-retention-cleanup',
  '20 3 * * *',
  'select private.run_retention_cleanup();'
);
